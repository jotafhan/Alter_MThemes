#!/bin/bash
# =========================================================
# Alter_MThemes v7.0 - Customizador de Tema R36S
# =========================================================

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

CURR_TTY="/dev/tty1"
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=linux
unset FBTERM

printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY"

SCRIPT_NAME=$(basename "$0")

BACKUP_DIR="/home/ark/darkos_backups"
WALLPAPER_DIR="/home/ark/darkos_wallpapers"
FONT_DIR="/home/ark/darkos_fonts"

for DIR in "$BACKUP_DIR" "$WALLPAPER_DIR" "$FONT_DIR"; do
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR" 2>/dev/null || true
        chown ark:ark "$DIR" 2>/dev/null || true
        chmod 755 "$DIR" 2>/dev/null || true
    fi
done

if [ -x /opt/inttools/gptokeyb ]; then
    [[ -e /dev/uinput ]] && chmod 666 /dev/uinput 2>/dev/null || true
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    pkill -f "gptokeyb -1 $SCRIPT_NAME" 2>/dev/null || true

    # Gera o keys.gptk do Alter_MThemes em runtime, em vez de
    # depender de um arquivo .gptk transferido separadamente
    # (sujeito a vir com extensao errada, BOM ou quebra de linha
    # CRLF e o gptokeyb nao reconhecer o conteudo). Isso tambem
    # evita depender do /opt/inttools/keys.gptk global, que em
    # alguns firmwares vem com "b" mapeado para backspace/repeat
    # em vez de esc, fazendo o botao VOLTAR parecer travado
    # dentro do dialog.
    GPTK_FILE="$LIB_DIR/keys_alter_mthemes.gptk"
    mkdir -p "$LIB_DIR" 2>/dev/null || true
    cat > "$GPTK_FILE" << 'GPTKEOF'
back = esc
start = enter
a = enter
b = esc
x = space
y = space
l1 = pageup
l2 = space
l3 = space
r1 = pagedown
r2 = space
r3 = space
up = up
down = down
left = left
right = right
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
right_analog_up = space
right_analog_down = space
right_analog_left = space
right_analog_right = space
GPTKEOF
    # Fallback para o keys.gptk global apenas se a geracao falhar
    # (ex: particao somente leitura) — preserva o comportamento
    # anterior nesse caso extremo.
    [ ! -s "$GPTK_FILE" ] && GPTK_FILE="/opt/inttools/keys.gptk"

    /opt/inttools/gptokeyb -1 "$SCRIPT_NAME" \
        -c "$GPTK_FILE" >/dev/null 2>&1 &
fi

# ---------------------------------------------------------
# Carrega modulos
# ---------------------------------------------------------
MODULOS=(
    "core.sh"
    "init.sh"
    "validator.sh"
    "cat_1_font_studio.sh"
    "cat_2_visual_studio.sh"
    "cat_3_logo_center.sh"
    "cat_4_theme_hub.sh"
    "cat_5_backup_center.sh"
    "cat_6_interface_ui.sh"
    "cat_7_atualizador.sh"
)

for MOD in "${MODULOS[@]}"; do
    if [ -f "$LIB_DIR/$MOD" ]; then
        source "$LIB_DIR/$MOD"
    else
        printf "\033c" > "$CURR_TTY"
        printf "ERRO: Modulo ausente: lib/%s\n" "$MOD" > "$CURR_TTY"
        printf "Verifique a instalacao em: %s\n" "$SCRIPT_DIR" > "$CURR_TTY"
        sleep 5
        exit 1
    fi
done

APP_NAME="Alter_MThemes"
APP_VER="v7.0"

# ==========================================================
# LOOP DO MENU PRINCIPAL
# ==========================================================

# Controla se o hook deve rodar (evita checar na primeira abertura)
_HOOK_PRIMEIRA_VEZ=1

while true; do

    # ----------------------------------------------------------
    # HOOK DE VALIDACAO AUTOMATICA
    # Roda toda vez que o usuario volta ao menu principal,
    # ou seja, após qualquer acao em qualquer modulo.
    # Nao roda na primeira abertura (XML ainda nao foi editado).
    # ----------------------------------------------------------
    if [ "${_HOOK_PRIMEIRA_VEZ}" -eq 0 ] && [ -f "$XML_FILE" ]; then
        _HOOK_ERROS=""
        _val_checar_estrutura         "$XML_FILE" _HOOK_ERROS
        _val_checar_tags_obrigatorias "$XML_FILE" _HOOK_ERROS
        _val_checar_numericos         "$XML_FILE" _HOOK_ERROS
        _val_checar_encoding          "$XML_FILE" _HOOK_ERROS
        _val_checar_duplicatas        "$XML_FILE" _HOOK_ERROS

        if [ -n "$_HOOK_ERROS" ]; then
            # Busca o backup mais recente para oferecer restauracao
            _HOOK_ULTIMO=$(find "$BACKUP_DIR" -maxdepth 1 \
                -name "${THEME_NAME}_*.xml" 2>/dev/null | sort -r | head -1)

            if [ -n "$_HOOK_ULTIMO" ]; then
                _HOOK_BCK_NOME=$(basename "$_HOOK_ULTIMO")
                # Trunca nome se passar de 50 chars para caber na tela
                if [ ${#_HOOK_BCK_NOME} -gt 50 ]; then
                    _HOOK_BCK_NOME="${_HOOK_BCK_NOME:0:47}..."
                fi
                _HOOK_BCK_INFO="Backup: ${_HOOK_BCK_NOME}"
            else
                _HOOK_BCK_INFO="Sem backup disponivel para restaurar."
            fi

            # Limita a 5 erros na tela para nao cortar o dialog
            _HOOK_ERROS_RESUMO=$(echo "$_HOOK_ERROS" \
                | grep '^\s*\[!\]' | head -5)
            _HOOK_TOTAL=$(echo "$_HOOK_ERROS" | grep -c '^\s*\[!\]' || echo 0)
            [ "$_HOOK_TOTAL" -gt 5 ] \
                && _HOOK_ERROS_RESUMO="${_HOOK_ERROS_RESUMO}\n  ... e mais $(( _HOOK_TOTAL - 5 )) problema(s)"

            dialog --output-fd 1 \
                --backtitle "$BT_MAIN" \
                --title " AVISO - XML COM PROBLEMAS " \
                --ok-label "IGNORAR" \
                --extra-button --extra-label "RESTAURAR" \
                --cancel-label "SAIR" \
                --msgbox \
"${_HOOK_TOTAL} problema(s) detectado(s):

${_HOOK_ERROS_RESUMO}

${_HOOK_BCK_INFO}
IGNORAR   : continua (risco!)
RESTAURAR : volta ao ultimo backup
SAIR      : encerra" \
                18 66 >"$CURR_TTY"

            _HOOK_RET=$?
            # Normaliza ESC (255) como IGNORAR (0), nao como SAIR (1).
            # Antes, ESC fechava o Alter_MThemes inteiro sem aviso —
            # diferente de como ESC se comporta em todo o resto do
            # projeto (onde sempre equivale a VOLTAR/cancelar a acao
            # atual, nunca a encerrar o programa). Isso e o que fazia
            # o botao B "nao funcionar" aqui: o usuario esperava so
            # fechar o aviso e o app inteiro encerrava.
            [ $_HOOK_RET -eq 255 ] && _HOOK_RET=0

            case "$_HOOK_RET" in
                0)  # IGNORAR — continua normalmente
                    ;;
                1)  # SAIR
                    ExitAll ;;
                3)  # RESTAURAR BACKUP
                    if [ -n "$_HOOK_ULTIMO" ]; then
                        if cp "$_HOOK_ULTIMO" "$XML_FILE" 2>/dev/null; then
                            DIALOG_MSG "$BT_MAIN" " RESTAURADO " 10 62 \
                                "XML restaurado com sucesso!\n\nBackup: $(basename "$_HOOK_ULTIMO")\n\nReinicie o ES para aplicar."
                            PerguntarReiniciar
                        else
                            DIALOG_MSG "$BT_MAIN" " ERRO " 9 55 \
                                "Erro ao restaurar o backup!\n\nVerifique as permissoes."
                        fi
                    fi ;;
            esac
        fi
    fi
    _HOOK_PRIMEIRA_VEZ=0

    NUM_BCK=$(find "$BACKUP_DIR" -maxdepth 1 \
        -name "${THEME_NAME}_*.xml" 2>/dev/null | wc -l)
    ULTIMO_BCK=$(find "$BACKUP_DIR" -maxdepth 1 \
        -name "${THEME_NAME}_*.xml" 2>/dev/null | sort -r | head -1)
    if [ -n "$ULTIMO_BCK" ]; then
        DATA_BCK=$(stat -c "%y" "$ULTIMO_BCK" 2>/dev/null \
            | cut -d' ' -f1 || echo "?")
        HORA_BCK=$(stat -c "%y" "$ULTIMO_BCK" 2>/dev/null \
            | cut -d' ' -f2 | cut -d'.' -f1 || echo "")
        STATUS_BCK="${NUM_BCK} backup(s)  |  Ultimo: ${DATA_BCK} ${HORA_BCK}"
    else
        STATUS_BCK="Nenhum backup encontrado"
    fi

    AGORA=$(date '+%d/%m/%Y %H:%M' 2>/dev/null || echo "")
    BT_MAIN="${APP_NAME} ${APP_VER}  |  Tema: $THEME_NAME  |  ${AGORA}"

    SEP="${MENU_SEPARADOR:-------------------------------------------------------------------}"
    if [ "${MENU_BACKUP:-1}" -eq 1 ]; then
        BODY_STATUS="Backup: $STATUS_BCK
${SEP}"
    else
        BODY_STATUS="${SEP}"
    fi

    # Menu exibe numeros sequenciais que agora coincidem
    # exatamente com a CATEGORIA/funcao de cada modulo
    ITEM_SEL=$(dialog --output-fd 1 \
        --backtitle "$BT_MAIN" \
        --title "${MENU_TITULO:- MENU PRINCIPAL }" \
        --ok-label "OK" \
        --extra-button --extra-label "VOLTAR" \
        --cancel-label "SAIR" \
        --menu \
"${BODY_STATUS}" \
        "${MENU_ALTURA:-22}" "${MENU_LARGURA:-68}" "${MENU_ITENS_VIS:-9}" \
        1 "Font Studio" \
        2 "Visual Studio" \
        3 "Logo Center" \
        4 "Theme Hub" \
        5 "Backup Center" \
        6 "Interface do Usuario (UI)" \
        7 "Atualizador" \
        8 "Salvar e Reiniciar o ES" \
        2>"$CURR_TTY")
    RET_MENU=$?
    NORM_RET_MENU

    [ $RET_MENU -eq 1 ]   && ExitAll
    [ $RET_MENU -eq 3 ]   && ExitAll
    [ $RET_MENU -eq 255 ] && ExitAll
    if [ "$ITEM_SEL" = "8" ]; then
        printf "\033c" > "$CURR_TTY"
        printf "[*] Reiniciando o EmulationStation...\n" > "$CURR_TTY"
        pkill -f "gptokeyb" 2>/dev/null || true
        systemctl restart emulationstation 2>/dev/null \
            || killall emulationstation 2>/dev/null \
            || pkill -f emulationstation 2>/dev/null \
            || true
        exit 0
    fi

    # Mapeia item selecionado para CATEGORIA (agora 1:1, sem desencontro)
    case "$ITEM_SEL" in
        1) CATEGORIA="1"; categoria_1 ;;
        2) CATEGORIA="2"; categoria_2 ;;
        3) CATEGORIA="3"; categoria_3 ;;
        4) CATEGORIA="4"; categoria_4 ;;
        5) CATEGORIA="5"; categoria_5 ;;   # backup_center
        6) categoria_6 ;;                  # interface_ui
        7) categoria_7 ;;                  # atualizador
    esac

done
