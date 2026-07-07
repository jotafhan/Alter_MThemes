# core.sh - Funcoes base do Alter_MThemes
# ---------------------------------------------------------
# Elimina o delay de ~1 segundo ao apertar ESC (botao B)
# O dialog usa ncurses internamente, que por padrao espera
# ESCDELAY milissegundos (1000ms de fabrica) antes de decidir
# que um ESC sozinho e de fato "ESC" e nao o inicio de uma
# sequencia de escape maior (como as teclas de seta, que
# comecam com ESC). Isso fazia o botao B/VOLTAR/SAIR parecer
# "lento" de forma consistente (sempre ~1s) em qualquer
# dialog --menu ou --msgbox do projeto. Reduzir para 25ms
# torna a resposta praticamente instantanea sem efeito
# colateral perceptivel na navegacao por D-pad/gptokeyb.
# ---------------------------------------------------------
export ESCDELAY=25

# ---------------------------------------------------------
# Normaliza código de retorno do dialog:
# 0 = OK   1 = SAIR   3 = VOLTAR   255 = ESC/Botão B
# Após chamar: use $RET normalmente (255 vira 3)
# ---------------------------------------------------------
NORM_RET() {
    [ $RET -eq 255 ] && RET=3
    return $RET
}

NORM_RET_MENU() {
    [ $RET_MENU -eq 255 ] && RET_MENU=3
    return $RET_MENU
}

ExitAll() {
    printf "\033c" > "$CURR_TTY"
    printf "\e[?25h" > "$CURR_TTY"
    pkill -f "gptokeyb -1 $SCRIPT_NAME" 2>/dev/null || true
    exit 0
}

trap ExitAll EXIT SIGINT SIGTERM

# ---------------------------------------------------------
# Wrappers de dialog com botões padronizados
#
# Botões nos menus de seleção:  [ OK ]  [ VOLTAR ]  [ SAIR ]
#   OK      = confirma seleção       → retorna 0
#   VOLTAR  = extra-button           → retorna 3
#   SAIR    = cancel                 → retorna 1
#
# Botões nos msgbox de confirmação: [ OK ]  [ SAIR ]
# ---------------------------------------------------------
DIALOG_MENU() {
    # Uso: DIALOG_MENU <resultado_var> <backtitle> <title> <height> <width> <listheight> [itens...]
    local _var="$1" ; shift
    local _bt="$1"  ; shift
    local _ti="$1"  ; shift
    local _h="$1"   ; shift
    local _w="$1"   ; shift
    local _lh="$1"  ; shift

    local _saida
    _saida=$(dialog \
        --output-fd 1 \
        --backtitle "$_bt" \
        --title "$_ti" \
        --ok-label     "OK" \
        --extra-button \
        --extra-label  "VOLTAR" \
        --cancel-label "SAIR" \
        --menu "" "$_h" "$_w" "$_lh" \
        "$@" \
        2>"$CURR_TTY")
    local _ret=$?
    # _ret: 0=OK  3=VOLTAR  1=SAIR
    printf -v "$_var" '%s' "$_saida"
    return $_ret
}

DIALOG_MSG() {
    # Uso: DIALOG_MSG <backtitle> <title> <height> <width> <texto>
    dialog \
        --output-fd 1 \
        --backtitle "$1" \
        --title     "$2" \
        --ok-label     "OK" \
        --cancel-label "SAIR" \
        --msgbox "$5" "$3" "$4" \
        >"$CURR_TTY"
    # retorna 0=OK  1=SAIR
}

# ---------------------------------------------------------
# PerguntarReiniciar: pergunta se quer reiniciar o ES agora
# Uso: PerguntarReiniciar
# Se sim → reinicia e sai. Se não → continua no menu.
# ---------------------------------------------------------
PerguntarReiniciar() {
    dialog --output-fd 1 \
        --backtitle "$BT" \
        --title " REINICIAR EMULATIONSTATION? " \
        --ok-label     "SIM" \
        --cancel-label "NAO" \
        --yesno "Deseja reiniciar o EmulationStation agora\npara aplicar as mudancas?" \
        7 52 >"$CURR_TTY"
    local RET_R=$?
    if [ $RET_R -eq 0 ]; then
        ReiniciarES
    fi
}

# ---------------------------------------------------------
# EscolherAlvo: menu de onde aplicar a modificação
# Retorna ALVO_ESCOLHIDO = 1..5 ou "" se VOLTAR/SAIR
# ---------------------------------------------------------
EscolherAlvo() {
    local _titulo="$1"
    ALVO_ESCOLHIDO=""

    DIALOG_MENU ALVO_ESCOLHIDO \
        "$BT" " $_titulo " \
        16 62 5 \
        1 "Todos os Blocos        (aplicacao global)" \
        2 "Lista de Jogos         (gamelist)" \
        3 "Carousel Menu Principal (systemcarousel)" \
        4 "Texto Info do Sistema  (systemInfo)" \
        5 "Menu de Opcoes do ES   (view menu)"
    RET=$?
    NORM_RET
    return $RET
}

# ---------------------------------------------------------
# AplicarEmBloco: aplica sed/awk em bloco específico do XML
# Uso: AplicarEmBloco <alvo> <tag_busca> <tag_fecha> \
#                     <tag_xml> <valor_novo>
# alvo: 1=global 2=gamelist 3=carousel 4=systemInfo 5=menu
# ---------------------------------------------------------
AplicarEmBloco() {
    local ALVO="$1"
    local BLOCO_ABRE="$2"   # ex: '<textlist[^>]*name="gamelist"'
    local BLOCO_FECHA="$3"  # ex: '<\/textlist>'
    local TAG="$4"           # ex: 'color'
    local VALOR="$5"         # ex: 'FF0000'

    local REGEX_TAG="<${TAG}>[^<]*<\/${TAG}>"
    local REPLACE_TAG="<${TAG}>${VALOR}<\/${TAG}>"

    case "$ALVO" in
        1) # Global — altera cor APENAS em blocos de texto, nunca em fundo/imagem/carousel-bg
            if [ "$TAG" = "color" ] || [ "$TAG" = "textColor" ] || [ "$TAG" = "selectedColor" ]; then
                awk -v tag="$TAG" -v val="$VALOR" '
                    # Blocos de texto puro → altera color
                    match($0, /<text[ >]/) && $0 !~ /name="top_label"/ { dentro_texto=1; achou=0 }
                    /<textlist/  { dentro_texto=1; achou=0 }

                    # Blocos que NÃO são texto → nunca altera
                    /<carousel/  { dentro_texto=0; dentro_bg=1 }
                    /<background>/ || /<image[^>]*>/ || /<video[^>]*>/ {
                        dentro_texto=0; dentro_bg=1 }

                    # Altera color se a tag ja existir dentro do bloco de texto
                    dentro_texto && !dentro_bg && $0 ~ "<"tag">" {
                        sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                        achou=1
                    }

                    # Se o bloco de texto fecha sem a tag ter sido encontrada,
                    # insere a tag antes do fechamento (corrige falha silenciosa
                    # em temas que nao definem essa tag nesse bloco)
                    dentro_texto && !dentro_bg && (/<\/textlist>/ || /<\/text>/) && !achou {
                        match($0, /^[ \t]*/)
                        indent = substr($0, 1, RLENGTH) "    "
                        print indent "<" tag ">" val "</" tag ">"
                        achou=1
                    }

                    # Fecha blocos
                    /<\/textlist>/ || /<\/text>/   { dentro_texto=0 }
                    /<\/carousel>/ || /<\/background>/ || /<\/image>/ || /<\/video>/ {
                        dentro_bg=0 }

                    { print }
                ' "$XML_FILE" > "${XML_FILE}.tmp" \
                && mv "${XML_FILE}.tmp" "$XML_FILE"

                # textColor e selectedColor são sempre de texto — aplica globalmente
                sed -i -E \
                    "s|<textColor>[^<]*</textColor>|<textColor>${VALOR}</textColor>|g" \
                    "$XML_FILE" 2>/dev/null || true
                sed -i -E \
                    "s|<selectedColor>[^<]*</selectedColor>|<selectedColor>${VALOR}</selectedColor>|g" \
                    "$XML_FILE" 2>/dev/null || true
            else
                # fontSize, fontStyle, opacity etc — aplica globalmente sem restrição.
                # NOTA: este ramo nao tem um bloco XML delimitado (abre/fecha) para
                # decidir ONDE inserir a tag caso ela nao exista em lugar nenhum do
                # tema — diferente dos casos 2-5, que tem um bloco claro. Por isso
                # continua apenas substituindo ocorrencias existentes; se a tag nao
                # existir em nenhum lugar do XML, nada e alterado (mesma limitacao
                # de antes). Use os alvos 2-5 (gamelist/carousel/systemInfo/menu)
                # quando for necessario garantir a insercao da tag.
                sed -i -E "s|${REGEX_TAG}|${REPLACE_TAG}|g" \
                    "$XML_FILE" 2>/dev/null || true
            fi ;;
        2) # gamelist
            awk -v bloco_a='<textlist[^>]*name="gamelist"' \
                -v bloco_f='</textlist>' \
                -v tag="$TAG" -v val="$VALOR" '
                $0 ~ bloco_a { dentro=1; achou=0 }
                dentro && $0 ~ "<"tag">" {
                    sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                    achou=1
                }
                dentro && $0 ~ bloco_f && !achou {
                    match($0, /^[ \t]*/)
                    indent = substr($0, 1, RLENGTH) "    "
                    print indent "<" tag ">" val "</" tag ">"
                    achou=1
                }
                $0 ~ bloco_f { dentro=0 }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" \
            && mv "${XML_FILE}.tmp" "$XML_FILE" ;;
        3) # Carousel/Menu Principal — altera os blocos <text> da view system
           # (sys_line1, sys_line2, systemInfo) que são o texto visível no menu principal
           # O <color> dentro do <carousel> é cor de fundo — nunca alterar
            awk -v tag="$TAG" -v val="$VALOR" '
                # Entra em blocos de texto da view system (menu principal)
                /<text[^>]*name="sys_line[12]"/ ||
                /<text[^>]*name="systemInfo"/ ||
                /<text[^>]*name="sys_line"/ { dentro=1; achou=0 }

                # Altera a tag apenas dentro dos blocos de texto
                dentro && $0 ~ "<"tag">" {
                    sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                    achou=1
                }

                # Insere a tag antes do fechamento se nao foi encontrada
                dentro && /<\/text>/ && !achou {
                    match($0, /^[ \t]*/)
                    indent = substr($0, 1, RLENGTH) "    "
                    print indent "<" tag ">" val "</" tag ">"
                    achou=1
                }

                # Fecha bloco de texto
                /<\/text>/ { dentro=0 }

                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" \
            && mv "${XML_FILE}.tmp" "$XML_FILE"

            # fontPath dentro do carousel (fonte do nome do sistema no carousel)
            if [ "$TAG" = "fontPath" ]; then
                awk -v tag="$TAG" -v val="$VALOR" '
                    /<carousel[^>]*name="systemcarousel"/ { dentro=1; achou=0 }
                    dentro && $0 ~ "<"tag">" {
                        sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                        achou=1
                    }
                    dentro && /<\/carousel>/ && !achou {
                        match($0, /^[ \t]*/)
                        indent = substr($0, 1, RLENGTH) "    "
                        print indent "<" tag ">" val "</" tag ">"
                        achou=1
                    }
                    /<\/carousel>/ { dentro=0 }
                    { print }
                ' "$XML_FILE" > "${XML_FILE}.tmp" \
                && mv "${XML_FILE}.tmp" "$XML_FILE"
            fi ;;
        4) # systemInfo
            awk -v bloco_a='<text[^>]*name="systemInfo"' \
                -v bloco_f='</text>' \
                -v tag="$TAG" -v val="$VALOR" '
                $0 ~ bloco_a { dentro=1; achou=0 }
                dentro && $0 ~ "<"tag">" {
                    sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                    achou=1
                }
                dentro && $0 ~ bloco_f && !achou {
                    match($0, /^[ \t]*/)
                    indent = substr($0, 1, RLENGTH) "    "
                    print indent "<" tag ">" val "</" tag ">"
                    achou=1
                }
                $0 ~ bloco_f { dentro=0 }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" \
            && mv "${XML_FILE}.tmp" "$XML_FILE" ;;
        5) # view menu — altera APENAS <menuText>, nunca <menuBackground>
            awk -v tag="$TAG" -v val="$VALOR" '
                /<menuText[^>]*>/    { dentro=1; achou=0 }
                dentro && $0 ~ "<"tag">" {
                    sub("<"tag">[^<]*</"tag">", "<"tag">"val"</"tag">")
                    achou=1
                }
                dentro && /<\/menuText>/ && !achou {
                    match($0, /^[ \t]*/)
                    indent = substr($0, 1, RLENGTH) "    "
                    print indent "<" tag ">" val "</" tag ">"
                    achou=1
                }
                /<\/menuText>/       { dentro=0 }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" \
            && mv "${XML_FILE}.tmp" "$XML_FILE" ;;
    esac
}


# ---------------------------------------------------------
# _detectar_usb  —  detecta pendrives/cartões montados
# Preenche array global _USB_MOUNTS com os pontos de montagem
# Retorna 0 se encontrou ao menos um, 1 se nenhum
# Uso:
#   _detectar_usb
#   [ ${#_USB_MOUNTS[@]} -eq 0 ] && { msg "sem usb"; continue; }
# ---------------------------------------------------------
_detectar_usb() {
    mapfile -t _USB_MOUNTS < <(
        mount 2>/dev/null \
        | grep -E '/dev/sd[b-z]|/dev/mmcblk[1-9]' \
        | awk '{print $3}' \
        | sort -u
    )
    [ ${#_USB_MOUNTS[@]} -gt 0 ] && return 0 || return 1
}

# ---------------------------------------------------------
# _selecionar_usb  —  se houver mais de um mount, abre menu
# para o usuário escolher qual usar.
# Preenche _USB_PATH com o caminho escolhido.
# Retorna 0 em sucesso, 3 se VOLTAR, 1 se SAIR.
# Requer _detectar_usb ter sido chamado antes.
# ---------------------------------------------------------
_selecionar_usb() {
    if [ ${#_USB_MOUNTS[@]} -eq 1 ]; then
        _USB_PATH="${_USB_MOUNTS[0]}"
        return 0
    fi
    local LISTA_USB=() IDX=1
    for _m in "${_USB_MOUNTS[@]}"; do
        LISTA_USB+=("$IDX" "$_m")
        IDX=$(( IDX + 1 ))
    done
    local _SEL
    DIALOG_MENU _SEL "$BT" " SELECIONAR PENDRIVE " 14 55 6 "${LISTA_USB[@]}"
    local RET=$?
    NORM_RET
    [ $RET -eq 1 ] && ExitAll
    [ $RET -eq 3 ] && return 3
    _USB_PATH="${_USB_MOUNTS[$(( _SEL - 1 ))]}"
    return 0
}

DESC_ALVO_NOME() {
    case "$1" in
        1) echo "Todos os blocos" ;;
        2) echo "Lista de jogos" ;;
        3) echo "Carousel do menu principal" ;;
        4) echo "Texto info do sistema" ;;
        5) echo "Menu de opcoes do ES" ;;
        *) echo "?" ;;
    esac
}
