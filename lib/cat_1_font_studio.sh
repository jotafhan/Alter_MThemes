# =============================================================================
# cat_1_font_studio.sh  –  Modulo: Aparencia da Fonte
# Funcionalidades:
#   1. Cor da Fonte  (grupos + HEX manual)
#   2. Tamanho da Fonte
#   3. Estilo da Fonte
#   4. Familia da Fonte  (sistema / tema / minhas)
#   5. Espacamento entre Linhas  (lineSpacing)
#   6. Favoritos de Fontes       (salva/carrega $FONT_DIR/.favoritos)
#   7. Instalar Fonte via USB    (copia .ttf/.otf do pendrive)
#   8. Apagar Fonte              (remove de $FONT_DIR)
# =============================================================================

# -----------------------------------------------------------------------------
# _FAV_ARQUIVO  –  caminho do arquivo de favoritos
# -----------------------------------------------------------------------------
_FAV_ARQUIVO="${FONT_DIR}/.favoritos"

# _FAV_ADICIONAR "caminho_fonte"
_FAV_ADICIONAR() {
    local _f="$1"
    mkdir -p "$FONT_DIR" 2>/dev/null || true
    touch "$_FAV_ARQUIVO" 2>/dev/null || true
    if ! grep -qxF "$_f" "$_FAV_ARQUIVO" 2>/dev/null; then
        echo "$_f" >> "$_FAV_ARQUIVO"
    fi
}

# _FAV_REMOVER "caminho_fonte"
_FAV_REMOVER() {
    local _f="$1"
    [ -f "$_FAV_ARQUIVO" ] || return
    grep -vxF "$_f" "$_FAV_ARQUIVO" > "${_FAV_ARQUIVO}.tmp" 2>/dev/null \
        && mv "${_FAV_ARQUIVO}.tmp" "$_FAV_ARQUIVO"
}

# _FAV_EH_FAV "caminho_fonte"  →  retorna 0 se é favorito
_FAV_EH_FAV() {
    grep -qxF "$1" "$_FAV_ARQUIVO" 2>/dev/null
}

# =============================================================================
# categoria_1  –  entrada principal do módulo
# =============================================================================
categoria_1() {
    if [ "$CATEGORIA" = "1" ]; then
        while true; do
            MENU_FONTE=$(dialog \
                --output-fd 1 \
                --backtitle "$BT" \
                --title " APARENCIA DA FONTE " \
                --ok-label "OK" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu "" 25 57 8 \
                1 "Cor da Fonte" \
                2 "Tamanho da Fonte" \
                3 "Estilo da Fonte (Negrito/Normal)" \
                4 "Familia da Fonte (.ttf/.otf)" \
                5 "Espacamento entre Letras" \
                6 "Favoritos de Fontes" \
                7 "Instalar Fonte via USB" \
                8 "Apagar Fonte" \
                2>"$CURR_TTY")
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break   # VOLTAR → menu principal

        # ==============================================================
        # OPÇÃO 1 – Cor da Fonte
        # ==============================================================
        if [ "$MENU_FONTE" = "1" ]; then
        while true; do
            GRUPO_COR=$(dialog \
                --output-fd 1 \
                --backtitle "$BT" \
                --title " COR DA FONTE - GRUPO " \
                --ok-label "OK" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu "" 28 62 9 \
                1 "Classicas     (Branco, Cinza, Preto)" \
                2 "Quentes       (Vermelho, Laranja, Rosa)" \
                3 "Frias         (Azul, Ciano, Roxo)" \
                4 "Naturais      (Verde, Lima, Marrom)" \
                5 "Especiais     (Ouro, Prata, Neon)" \
                6 "Pastel        (tons suaves)" \
                7 "Dark Neon     (escuros vibrantes)" \
                8 "Cor Personalizada (HEX manual)" \
                9 "Ultima Cor Usada" \
                2>"$CURR_TTY")
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break

            HEX_COR="" ; NOME_COR=""

            case "$GRUPO_COR" in
                # ---- Classicas ----
                1)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES CLASSICAS " \
                        16 58 5 \
                        1 "Branco Puro      (#FFFFFF)" \
                        2 "Cinza Claro      (#CCCCCC)" \
                        3 "Cinza Medio      (#888888)" \
                        4 "Cinza Escuro     (#444444)" \
                        5 "Preto Puro       (#000000)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="FFFFFF" ; NOME_COR="Branco Puro" ;;
                        2) HEX_COR="CCCCCC" ; NOME_COR="Cinza Claro" ;;
                        3) HEX_COR="888888" ; NOME_COR="Cinza Medio" ;;
                        4) HEX_COR="444444" ; NOME_COR="Cinza Escuro" ;;
                        5) HEX_COR="000000" ; NOME_COR="Preto Puro" ;;
                    esac ;;

                # ---- Quentes ----
                2)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES QUENTES " \
                        18 58 7 \
                        1 "Vermelho Puro    (#FF0000)" \
                        2 "Vermelho Escuro  (#CC0000)" \
                        3 "Laranja Vivo     (#FF6600)" \
                        4 "Laranja Suave    (#FF9933)" \
                        5 "Rosa Neon        (#FF00AA)" \
                        6 "Rosa Quente      (#FF1466)" \
                        7 "Coral            (#FF4444)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="FF0000" ; NOME_COR="Vermelho Puro" ;;
                        2) HEX_COR="CC0000" ; NOME_COR="Vermelho Escuro" ;;
                        3) HEX_COR="FF6600" ; NOME_COR="Laranja Vivo" ;;
                        4) HEX_COR="FF9933" ; NOME_COR="Laranja Suave" ;;
                        5) HEX_COR="FF00AA" ; NOME_COR="Rosa Neon" ;;
                        6) HEX_COR="FF1466" ; NOME_COR="Rosa Quente" ;;
                        7) HEX_COR="FF4444" ; NOME_COR="Coral" ;;
                    esac ;;

                # ---- Frias ----
                3)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES FRIAS " \
                        19 58 8 \
                        1 "Azul Celeste     (#00AAFF)" \
                        2 "Azul Royal       (#4169E1)" \
                        3 "Azul Marinho     (#003366)" \
                        4 "Ciano Neon       (#00FFFF)" \
                        5 "Ciano Suave      (#00CCCC)" \
                        6 "Roxo Vibrante    (#9933FF)" \
                        7 "Lilas Suave      (#CC99FF)" \
                        8 "Indigo           (#6600CC)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="00AAFF" ; NOME_COR="Azul Celeste" ;;
                        2) HEX_COR="4169E1" ; NOME_COR="Azul Royal" ;;
                        3) HEX_COR="003366" ; NOME_COR="Azul Marinho" ;;
                        4) HEX_COR="00FFFF" ; NOME_COR="Ciano Neon" ;;
                        5) HEX_COR="00CCCC" ; NOME_COR="Ciano Suave" ;;
                        6) HEX_COR="9933FF" ; NOME_COR="Roxo Vibrante" ;;
                        7) HEX_COR="CC99FF" ; NOME_COR="Lilas Suave" ;;
                        8) HEX_COR="6600CC" ; NOME_COR="Indigo" ;;
                    esac ;;

                # ---- Naturais ----
                4)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES NATURAIS " \
                        18 58 7 \
                        1 "Verde Retro      (#00FF00)" \
                        2 "Verde Floresta   (#228B22)" \
                        3 "Verde Menta      (#66FF99)" \
                        4 "Lima Vibrante    (#AAFF00)" \
                        5 "Marrom Quente    (#CC6633)" \
                        6 "Terracota        (#CC4400)" \
                        7 "Oliva            (#808000)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="00FF00" ; NOME_COR="Verde Retro" ;;
                        2) HEX_COR="228B22" ; NOME_COR="Verde Floresta" ;;
                        3) HEX_COR="66FF99" ; NOME_COR="Verde Menta" ;;
                        4) HEX_COR="AAFF00" ; NOME_COR="Lima Vibrante" ;;
                        5) HEX_COR="CC6633" ; NOME_COR="Marrom Quente" ;;
                        6) HEX_COR="CC4400" ; NOME_COR="Terracota" ;;
                        7) HEX_COR="808000" ; NOME_COR="Oliva" ;;
                    esac ;;

                # ---- Especiais ----
                5)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES ESPECIAIS " \
                        19 58 8 \
                        1 "Ouro Classico    (#FFD700)" \
                        2 "Ouro Antigo      (#DAA520)" \
                        3 "Prata Brilhante  (#C0C0C0)" \
                        4 "Bronze           (#CD7F32)" \
                        5 "Neon Amarelo     (#FFFF00)" \
                        6 "Salmon Suave     (#FA8072)" \
                        7 "Magenta Neon     (#FF00FF)" \
                        8 "Cobre            (#B87333)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="FFD700" ; NOME_COR="Ouro Classico" ;;
                        2) HEX_COR="DAA520" ; NOME_COR="Ouro Antigo" ;;
                        3) HEX_COR="C0C0C0" ; NOME_COR="Prata Brilhante" ;;
                        4) HEX_COR="CD7F32" ; NOME_COR="Bronze" ;;
                        5) HEX_COR="FFFF00" ; NOME_COR="Neon Amarelo" ;;
                        6) HEX_COR="FA8072" ; NOME_COR="Salmon Suave" ;;
                        7) HEX_COR="FF00FF" ; NOME_COR="Magenta Neon" ;;
                        8) HEX_COR="B87333" ; NOME_COR="Cobre" ;;
                    esac ;;

                # ---- Pastel ----
                6)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " CORES PASTEL " \
                        18 58 7 \
                        1 "Rosa Pastel      (#FFB3C6)" \
                        2 "Azul Bebe        (#AED6F1)" \
                        3 "Verde Agua       (#A8DADC)" \
                        4 "Lavanda          (#D7BDE2)" \
                        5 "Pessego          (#FFDAB9)" \
                        6 "Menta Pastel     (#B2DFDB)" \
                        7 "Amarelo Suave    (#FFF9C4)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="FFB3C6" ; NOME_COR="Rosa Pastel" ;;
                        2) HEX_COR="AED6F1" ; NOME_COR="Azul Bebe" ;;
                        3) HEX_COR="A8DADC" ; NOME_COR="Verde Agua" ;;
                        4) HEX_COR="D7BDE2" ; NOME_COR="Lavanda" ;;
                        5) HEX_COR="FFDAB9" ; NOME_COR="Pessego" ;;
                        6) HEX_COR="B2DFDB" ; NOME_COR="Menta Pastel" ;;
                        7) HEX_COR="FFF9C4" ; NOME_COR="Amarelo Suave" ;;
                    esac ;;

                # ---- Dark Neon ----
                7)
                    DIALOG_MENU OPCAO_COR \
                        "$BT" " DARK NEON " \
                        18 58 7 \
                        1 "Neon Verde       (#39FF14)" \
                        2 "Neon Ciano       (#00FFEF)" \
                        3 "Neon Rosa        (#FF6EC7)" \
                        4 "Neon Laranja     (#FF6600)" \
                        5 "Neon Roxo        (#BF00FF)" \
                        6 "Neon Azul        (#1B03A3)" \
                        7 "Neon Vermelho    (#FF0000)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$OPCAO_COR" in
                        1) HEX_COR="39FF14" ; NOME_COR="Neon Verde" ;;
                        2) HEX_COR="00FFEF" ; NOME_COR="Neon Ciano" ;;
                        3) HEX_COR="FF6EC7" ; NOME_COR="Neon Rosa" ;;
                        4) HEX_COR="FF6600" ; NOME_COR="Neon Laranja" ;;
                        5) HEX_COR="BF00FF" ; NOME_COR="Neon Roxo" ;;
                        6) HEX_COR="1B03A3" ; NOME_COR="Neon Azul" ;;
                        7) HEX_COR="FF0000" ; NOME_COR="Neon Vermelho" ;;
                    esac ;;

                # ---- HEX Manual ----
                8)
                    HEX_BUILD=""
                    HEX_ABORTADO=0
                    while [ ${#HEX_BUILD} -lt 6 ]; do
                        POS=$(( ${#HEX_BUILD} + 1 ))
                        BAR="[ "
                        for i in 1 2 3 4 5 6; do
                            if [ $i -le ${#HEX_BUILD} ]; then
                                BAR+="${HEX_BUILD:$((i-1)):1} "
                            else
                                BAR+="_ "
                            fi
                        done
                        BAR+="]"
                        DIGITO=$(dialog --output-fd 1 \
                            --backtitle "$BT" \
                            --title " COR PERSONALIZADA " \
                            --ok-label "OK" \
                            --extra-button --extra-label "VOLTAR" \
                            --cancel-label "SAIR" \
                            --menu \
"Cor: # $BAR
      Digito $POS de 6  (VOLTAR apaga ultimo)" \
                            20 52 8 \
                            "0" "  0  Zero" \
                            "1" "  1  Um" \
                            "2" "  2  Dois" \
                            "3" "  3  Tres" \
                            "4" "  4  Quatro" \
                            "5" "  5  Cinco" \
                            "6" "  6  Seis" \
                            "7" "  7  Sete" \
                            "8" "  8  Oito" \
                            "9" "  9  Nove" \
                            "A" "  A  Vermelho/Verde alto" \
                            "B" "  B  ~" \
                            "C" "  C  ~" \
                            "D" "  D  ~" \
                            "E" "  E  ~" \
                            "F" "  F  Maximo (255)" \
                            2>"$CURR_TTY")
                        RET=$? ; NORM_RET
                        [ $RET -eq 1 ] && ExitAll
                        if [ $RET -eq 3 ]; then
                            if [ ${#HEX_BUILD} -gt 0 ]; then
                                HEX_BUILD="${HEX_BUILD%?}"
                            else
                                HEX_ABORTADO=1 ; break
                            fi
                            continue
                        fi
                        HEX_BUILD="${HEX_BUILD}${DIGITO}"
                    done
                    [ $HEX_ABORTADO -eq 1 ] && continue
                    dialog --output-fd 1 \
                        --backtitle "$BT" --title " CONFIRMAR COR " \
                        --ok-label "APLICAR" \
                        --extra-button --extra-label "VOLTAR" \
                        --cancel-label "SAIR" \
                        --msgbox "Cor selecionada: #${HEX_BUILD}\n\nAPLICAR = usar esta cor\nVOLTAR  = escolher novamente\nSAIR    = cancelar" \
                        10 48 >"$CURR_TTY"
                    RET_CONF=$?
                    [ $RET_CONF -eq 1 ] && ExitAll
                    [ $RET_CONF -eq 3 ] && continue
                    HEX_COR="$HEX_BUILD" ; NOME_COR="Personalizada" ;;

                # ---- Ultima Cor Usada ----
                9)
                    if [ ! -f "${FONT_DIR}/.ultima_cor" ] || [ ! -s "${FONT_DIR}/.ultima_cor" ]; then
                        DIALOG_MSG "$BT" " ULTIMA COR " 9 55 \
                            "Nenhuma cor foi aplicada ainda.\n\nAplique uma cor primeiro para\npoder reutiliza-la aqui."
                        continue
                    fi
                    IFS='|' read -r HEX_COR NOME_COR < "${FONT_DIR}/.ultima_cor"
                    if [ -z "$HEX_COR" ]; then
                        DIALOG_MSG "$BT" " ULTIMA COR " 9 55 \
                            "Arquivo de ultima cor invalido ou vazio."
                        continue
                    fi ;;
            esac

            if [ -n "$HEX_COR" ]; then
                EscolherAlvo "ONDE APLICAR A COR"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                printf "\033c" > "$CURR_TTY"
                printf "[*] Aplicando cor %s (#%s) em: %s...\n" \
                    "$NOME_COR" "$HEX_COR" "$(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")" > "$CURR_TTY"

                AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "textColor"     "$HEX_COR"
                AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "selectedColor" "$HEX_COR"
                AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "color"         "$HEX_COR"

                if [ "$ALVO_ESCOLHIDO" = "global" ] || [ "$ALVO_ESCOLHIDO" = "menu" ]; then
                    for _TAG_MENU in \
                        "primaryColor" "menuTextColor" "menuPrimaryColor" \
                        "menuSelectedColor" "menuFooterTextColor" \
                        "menuButtonTextColor" "menuTitleTextColor" \
                        "menuText" "itemTextColor" "subtextColor"
                    do
                        sed -i -E \
                            "s|<${_TAG_MENU}>[^<]*</${_TAG_MENU}>|<${_TAG_MENU}>${HEX_COR}</${_TAG_MENU}>|g" \
                            "$XML_FILE" 2>/dev/null || true
                    done
                fi

                # Salva como ultima cor usada
                mkdir -p "$FONT_DIR" 2>/dev/null || true
                echo "${HEX_COR}|${NOME_COR}" > "${FONT_DIR}/.ultima_cor" 2>/dev/null || true

                DIALOG_MSG "$BT" " COR APLICADA " 11 54 \
                    "Cor aplicada!\n\nCor: $NOME_COR  HEX: #$HEX_COR\nOnde: $(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
                break
            fi
        done
        fi  # fim MENU_FONTE=1

        # ==============================================================
        # OPÇÃO 2 – Tamanho da Fonte
        # ==============================================================
        if [ "$MENU_FONTE" = "2" ]; then
            OPCAO_TAMANHO=$(dialog \
                --output-fd 1 \
                --backtitle "$BT" \
                --title " APARENCIA DA FONTE > Tamanho " \
                --ok-label "OK" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu "" 27 62 6 \
                1 "Minusculo  0.022 - Para listas longas" \
                2 "Pequeno    0.030 - Discreto e compacto" \
                3 "Medio      0.038 - Equilibrado (padrao)" \
                4 "Grande     0.048 - Boa visibilidade" \
                5 "Extra      0.058 - Muito visivel" \
                6 "Gigante    0.070 - Maxima legibilidade" \
                2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            case "$OPCAO_TAMANHO" in
                1) TAMANHO_FONTE="0.022" ; DESC_TAM="Minusculo" ;;
                2) TAMANHO_FONTE="0.030" ; DESC_TAM="Pequeno" ;;
                3) TAMANHO_FONTE="0.038" ; DESC_TAM="Medio" ;;
                4) TAMANHO_FONTE="0.048" ; DESC_TAM="Grande" ;;
                5) TAMANHO_FONTE="0.058" ; DESC_TAM="Extra" ;;
                6) TAMANHO_FONTE="0.070" ; DESC_TAM="Gigante" ;;
                *) continue ;;
            esac

            EscolherAlvo "ONDE APLICAR O TAMANHO"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Aplicando tamanho %s em: %s...\n" \
                "$DESC_TAM" "$(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")" > "$CURR_TTY"

            AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "fontSize" "$TAMANHO_FONTE"

            DIALOG_MSG "$BT" " TAMANHO APLICADO " 11 54 \
                "Tamanho aplicado!\n\nTamanho: $DESC_TAM ($TAMANHO_FONTE)\nOnde: $(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
        fi

        # ==============================================================
        # OPÇÃO 3 – Estilo da Fonte
        # ==============================================================
        if [ "$MENU_FONTE" = "3" ]; then
            OPCAO_ESTILO=$(dialog \
                --output-fd 1 \
                --backtitle "$BT" \
                --title " APARENCIA DA FONTE > Estilo " \
                --ok-label "OK" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu "" 23 60 4 \
                1 "Normal          (sem formatacao extra)" \
                2 "Negrito         (texto em bold)" \
                3 "Italico         (texto inclinado)" \
                4 "Negrito+Italico (combinado)" \
                2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            case "$OPCAO_ESTILO" in
                1) ESTILO_FONTE="normal"      ; DESC_EST="Normal" ;;
                2) ESTILO_FONTE="bold"        ; DESC_EST="Negrito" ;;
                3) ESTILO_FONTE="italic"      ; DESC_EST="Italico" ;;
                4) ESTILO_FONTE="bold-italic" ; DESC_EST="Negrito+Italico" ;;
                *) continue ;;
            esac

            EscolherAlvo "ONDE APLICAR O ESTILO"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Aplicando estilo %s em: %s...\n" \
                "$DESC_EST" "$(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")" > "$CURR_TTY"

            AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "fontStyle" "$ESTILO_FONTE"

            DIALOG_MSG "$BT" " ESTILO APLICADO " 11 54 \
                "Estilo aplicado!\n\nEstilo: $DESC_EST\nOnde: $(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
        fi

        # ==============================================================
        # OPÇÃO 4 – Família da Fonte  (com preview lateral ao navegar)
        # ==============================================================
        if [ "$MENU_FONTE" = "4" ]; then
            TEMA_DIR=$(dirname "$XML_FILE")

            while true; do
                DIALOG_MENU MENU_FONT_SRC \
                    "$BT" " APARENCIA DA FONTE > Familia " \
                    14 60 3 \
                    1 "Fontes do Sistema (DejaVu)" \
                    2 "Fontes do Tema (originais)" \
                    3 "Minhas Fontes ($FONT_DIR)"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                FONT_PATH="" ; FONT_NOME=""

                case "$MENU_FONT_SRC" in

                    # ---- Fontes do sistema DejaVu ----
                    1)
                        # Lista de fontes disponíveis com preview lateral
                        declare -A _SYS_FONTS
                        _SYS_FONTS[1]="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
                        _SYS_FONTS[2]="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
                        _SYS_FONTS[3]="/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf"
                        _SYS_FONTS[4]="/usr/share/fonts/truetype/dejavu/DejaVuSans-ExtraLight.ttf"
                        _SYS_FONTS[5]="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
                        _SYS_FONTS[6]="/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
                        _SYS_FONTS[7]="/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
                        _SYS_FONTS[8]="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
                        _SYS_FONTS[9]="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Italic.ttf"
                        _SYS_FONTS[10]="/usr/share/fonts/truetype/dejavu/DejaVuMathTeXGyre.ttf"

                        _SEL_SYS=1
                        while true; do
                            OPCAO_DFONT=$(dialog --output-fd 1 \
                                --backtitle "$BT" \
                                --title " FONTES DO SISTEMA " \
                                --ok-label "OK" \
                                --extra-button --extra-label "VOLTAR" \
                                --cancel-label "SAIR" \
                                --default-item "$_SEL_SYS" \
                                --menu "" 24 68 10 \
                                1  "DejaVu Sans           (moderna, legivel)" \
                                2  "DejaVu Sans Bold       (negrito limpo)" \
                                3  "DejaVu Sans Oblique    (inclinada leve)" \
                                4  "DejaVu Sans ExtraLight (fina e elegante)" \
                                5  "DejaVu Sans Mono       (monoespaco retro)" \
                                6  "DejaVu Sans Mono Bold  (mono + negrito)" \
                                7  "DejaVu Serif           (serifada classica)" \
                                8  "DejaVu Serif Bold      (serifada negrito)" \
                                9  "DejaVu Serif Italic    (serifada italico)" \
                                10 "DejaVu Math TeX        (estilo cientifico)" \
                                2>"$CURR_TTY")
                            RET=$? ; NORM_RET
                            [ $RET -eq 1 ] && ExitAll
                            [ $RET -eq 3 ] && break
                            _SEL_SYS="$OPCAO_DFONT"

                            case "$OPCAO_DFONT" in
                                1)  FONT_PATH="${_SYS_FONTS[1]}"  ; FONT_NOME="DejaVu Sans" ;;
                                2)  FONT_PATH="${_SYS_FONTS[2]}"  ; FONT_NOME="DejaVu Sans Bold" ;;
                                3)  FONT_PATH="${_SYS_FONTS[3]}"  ; FONT_NOME="DejaVu Sans Oblique" ;;
                                4)  FONT_PATH="${_SYS_FONTS[4]}"  ; FONT_NOME="DejaVu Sans ExtraLight" ;;
                                5)  FONT_PATH="${_SYS_FONTS[5]}"  ; FONT_NOME="DejaVu Sans Mono" ;;
                                6)  FONT_PATH="${_SYS_FONTS[6]}"  ; FONT_NOME="DejaVu Sans Mono Bold" ;;
                                7)  FONT_PATH="${_SYS_FONTS[7]}"  ; FONT_NOME="DejaVu Serif" ;;
                                8)  FONT_PATH="${_SYS_FONTS[8]}"  ; FONT_NOME="DejaVu Serif Bold" ;;
                                9)  FONT_PATH="${_SYS_FONTS[9]}"  ; FONT_NOME="DejaVu Serif Italic" ;;
                                10) FONT_PATH="${_SYS_FONTS[10]}" ; FONT_NOME="DejaVu Math TeX" ;;
                                *) continue ;;
                            esac
                            break
                        done
                        [ -z "$FONT_PATH" ] && continue
                        ;;

                    # ---- Fontes originais do tema ----
                    2)
                        mapfile -t TEMA_FONTS < <(find "$TEMA_DIR" \
                            -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
                            2>/dev/null | sort)

                        if [ ${#TEMA_FONTS[@]} -eq 0 ]; then
                            DIALOG_MSG "$BT" " FONTES DO TEMA " 9 55 \
                                "Nenhuma fonte encontrada na pasta do tema.\n\nPasta: $TEMA_DIR"
                            continue
                        fi

                        _SEL_TF=1
                        while true; do
                            LISTA_TF=()
                            IDX=1
                            for f in "${TEMA_FONTS[@]}"; do
                                _FAV_EH_FAV "$f" && _STAR="[*] " || _STAR="    "
                                LISTA_TF+=("$IDX" "${_STAR}$(basename "$f")")
                                IDX=$((IDX + 1))
                            done
                            OPCAO_TF=$(dialog --output-fd 1 \
                                --backtitle "$BT" \
                                --title " FONTES DO TEMA  ([*]=favorito) " \
                                --ok-label "OK" \
                                --extra-button --extra-label "VOLTAR" \
                                --cancel-label "SAIR" \
                                --default-item "$_SEL_TF" \
                                --menu "" 22 68 8 \
                                "${LISTA_TF[@]}" \
                                2>"$CURR_TTY")
                            RET=$? ; NORM_RET
                            [ $RET -eq 1 ] && ExitAll
                            [ $RET -eq 3 ] && break
                            _SEL_TF="$OPCAO_TF"
                            FONT_PATH="${TEMA_FONTS[$((OPCAO_TF - 1))]}"
                            FONT_NOME=$(basename "$FONT_PATH")
                            break
                        done
                        [ -z "$FONT_PATH" ] && continue
                        ;;

                    # ---- Minhas fontes ----
                    3)
                        mapfile -t CUSTOM_FONTS < <(find "$FONT_DIR" \
                            -maxdepth 1 -type f \
                            \( -iname "*.ttf" -o -iname "*.otf" \) \
                            2>/dev/null | sort)

                        if [ ${#CUSTOM_FONTS[@]} -eq 0 ]; then
                            DIALOG_MSG "$BT" " MINHAS FONTES " 12 60 \
                                "Nenhuma fonte encontrada!\n\nColoque arquivos .ttf ou .otf em:\n\n$FONT_DIR\n\nou use 'Instalar Fonte via USB'."
                            continue
                        fi

                        _SEL_CF=1
                        while true; do
                            LISTA_CF=()
                            IDX=1
                            for f in "${CUSTOM_FONTS[@]}"; do
                                _FAV_EH_FAV "$f" && _STAR="[*] " || _STAR="    "
                                LISTA_CF+=("$IDX" "${_STAR}$(basename "$f")")
                                IDX=$((IDX + 1))
                            done
                            OPCAO_CF=$(dialog --output-fd 1 \
                                --backtitle "$BT" \
                                --title " MINHAS FONTES  ([*]=favorito) " \
                                --ok-label "OK" \
                                --extra-button --extra-label "VOLTAR" \
                                --cancel-label "SAIR" \
                                --default-item "$_SEL_CF" \
                                --menu "" 22 68 8 \
                                "${LISTA_CF[@]}" \
                                2>"$CURR_TTY")
                            RET=$? ; NORM_RET
                            [ $RET -eq 1 ] && ExitAll
                            [ $RET -eq 3 ] && break
                            _SEL_CF="$OPCAO_CF"
                            FONT_PATH="${CUSTOM_FONTS[$((OPCAO_CF - 1))]}"
                            FONT_NOME=$(basename "$FONT_PATH")
                            break
                        done
                        [ -z "$FONT_PATH" ] && continue
                        ;;

                    *) continue ;;
                esac

                # ---- Aplica a fonte selecionada ----
                if [ -n "$FONT_PATH" ] && [ -f "$FONT_PATH" ]; then
                    DIALOG_MENU ONDE_APLICAR \
                        "$BT" " ONDE APLICAR A FONTE " \
                        16 62 5 \
                        1 "Em Todos os Blocos (global)" \
                        2 "Apenas Lista de Jogos (gamelist)" \
                        3 "Apenas Carousel do Menu Principal" \
                        4 "Apenas Texto de Info do Sistema" \
                        5 "Apenas Menu de Opcoes do ES"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    printf "\033c" > "$CURR_TTY"
                    printf "[*] Aplicando fonte: %s...\n" "$FONT_NOME" > "$CURR_TTY"

                    FONT_DEST="$TEMA_DIR/_art/$(basename "$FONT_PATH")"
                    mkdir -p "$TEMA_DIR/_art" 2>/dev/null || true
                    cp "$FONT_PATH" "$FONT_DEST" 2>/dev/null || true
                    FONT_REL="./_art/$(basename "$FONT_PATH")"

                    case "$ONDE_APLICAR" in
                        1)
                            sed -i -E \
                                "s|<fontPath>[^<]*</fontPath>|<fontPath>${FONT_REL}</fontPath>|g" \
                                "$XML_FILE" 2>/dev/null || true
                            DESC_ONDE="Todos os blocos" ;;
                        2)
                            awk -v fp="$FONT_REL" '
                                /<textlist[^>]*name="gamelist"/ { dentro=1 }
                                dentro && /<fontPath>/ {
                                    sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>")
                                }
                                /<\/textlist>/ { dentro=0 }
                                { print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" \
                            && mv "${XML_FILE}.tmp" "$XML_FILE"
                            DESC_ONDE="Lista de jogos" ;;
                        3)
                            awk -v fp="$FONT_REL" '
                                /<carousel[^>]*name="systemcarousel"/ { dentro=1 }
                                dentro && /<fontPath>/ {
                                    sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>")
                                }
                                /<\/carousel>/ { dentro=0 }
                                { print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" \
                            && mv "${XML_FILE}.tmp" "$XML_FILE"
                            DESC_ONDE="Carousel do menu principal" ;;
                        4)
                            awk -v fp="$FONT_REL" '
                                /<text[^>]*name="systemInfo"/ { dentro=1 }
                                dentro && /<fontPath>/ {
                                    sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>")
                                }
                                /<\/text>/ { dentro=0 }
                                { print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" \
                            && mv "${XML_FILE}.tmp" "$XML_FILE"
                            DESC_ONDE="Texto de info do sistema" ;;
                        5)
                            awk -v fp="$FONT_REL" '
                                /<view[^>]*name="(menu|menuHelp|menuTheme)"/ { dentro=1 }
                                dentro && /<fontPath>/ {
                                    sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>")
                                }
                                /<\/view>/ { dentro=0 }
                                { print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" \
                            && mv "${XML_FILE}.tmp" "$XML_FILE"
                            for _MENU_EL in "menuText" "menuSubtext" "menuButton" "menuFooter"; do
                                sed -i -E \
                                    "s|(<${_MENU_EL}[^>]*>.*<fontPath>)[^<]*(</fontPath>)|\1${FONT_REL}\2|g" \
                                    "$XML_FILE" 2>/dev/null || true
                            done
                            DESC_ONDE="Menu de opcoes do ES" ;;
                        *) continue ;;
                    esac

                    DIALOG_MSG "$BT" " FONTE APLICADA " 12 62 \
                        "Fonte aplicada com sucesso!\n\nFonte: $FONT_NOME\nAplicada em: $DESC_ONDE\nCaminho: $FONT_REL\n\nReinicie o ES para ver a mudanca."
                    PerguntarReiniciar
                    break
                elif [ -n "$FONT_PATH" ]; then
                    DIALOG_MSG "$BT" " ERRO " 9 55 \
                        "Arquivo de fonte nao encontrado:\n$FONT_PATH"
                fi
            done
        fi  # fim MENU_FONTE=4

        # ==============================================================
        # OPÇÃO 5 – Espaçamento entre Linhas (lineSpacing — tag real do ES)
        # ==============================================================
        if [ "$MENU_FONTE" = "5" ]; then
            OPCAO_ESP=$(dialog \
                --output-fd 1 \
                --backtitle "$BT" \
                --title " ESPACAMENTO ENTRE LINHAS " \
                --ok-label "OK" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu "(tag: lineSpacing — suportada pelo ES)" 29 62 6 \
                1 "Compacto    1.0  (linhas juntas)" \
                2 "Normal      1.2  (padrao ES)" \
                3 "Confortavel 1.4  (leve respiro)" \
                4 "Aberto      1.6  (mais espaco)" \
                5 "Amplo       1.8  (bastante espaco)" \
                6 "Valor Personalizado..." \
                2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            ESP_VALOR="" ; ESP_DESC=""
            case "$OPCAO_ESP" in
                1) ESP_VALOR="1.0" ; ESP_DESC="Compacto" ;;
                2) ESP_VALOR="1.2" ; ESP_DESC="Normal" ;;
                3) ESP_VALOR="1.4" ; ESP_DESC="Confortavel" ;;
                4) ESP_VALOR="1.6" ; ESP_DESC="Aberto" ;;
                5) ESP_VALOR="1.8" ; ESP_DESC="Amplo" ;;
                6)
                    # Seletor: parte inteira (1) + decimal (0-9)
                    DIALOG_MENU _ESP_DEC \
                        "$BT" " ESPACAMENTO - DECIMAL (1.X) " \
                        15 48 9 \
                        0 "1.0  (minimo)" \
                        1 "1.1" \
                        2 "1.2  (padrao)" \
                        3 "1.3" \
                        4 "1.4" \
                        5 "1.5" \
                        6 "1.6" \
                        7 "1.7" \
                        8 "1.8" \
                        9 "1.9  (maximo recomendado)"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    ESP_VALOR="1.${_ESP_DEC}"
                    ESP_DESC="Personalizado ($ESP_VALOR)"
                    ;;
                *) continue ;;
            esac

            if [ -n "$ESP_VALOR" ]; then
                EscolherAlvo "ONDE APLICAR O ESPACAMENTO"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                printf "\033c" > "$CURR_TTY"
                printf "[*] Aplicando lineSpacing %s em: %s...\n" \
                    "$ESP_VALOR" "$(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")" > "$CURR_TTY"

                AplicarEmBloco "$ALVO_ESCOLHIDO" "" "" "lineSpacing" "$ESP_VALOR"

                DIALOG_MSG "$BT" " ESPACAMENTO APLICADO " 11 58 \
                    "Espacamento entre linhas aplicado!\n\nValor: $ESP_DESC ($ESP_VALOR)\nOnde: $(DESC_ALVO_NOME "$ALVO_ESCOLHIDO")\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi
        fi  # fim MENU_FONTE=5

        # ==============================================================
        # OPÇÃO 6 – Favoritos de Fontes
        # ==============================================================
        if [ "$MENU_FONTE" = "6" ]; then
            while true; do
                DIALOG_MENU MENU_FAV \
                    "$BT" " FAVORITOS DE FONTES " \
                    13 58 3 \
                    1 "Ver / Aplicar Favoritos" \
                    2 "Adicionar Fonte aos Favoritos" \
                    3 "Remover Fonte dos Favoritos"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                # ---- Ver / Aplicar favoritos ----
                if [ "$MENU_FAV" = "1" ]; then
                    if [ ! -f "$_FAV_ARQUIVO" ] || [ ! -s "$_FAV_ARQUIVO" ]; then
                        DIALOG_MSG "$BT" " FAVORITOS " 9 55 \
                            "Nenhum favorito salvo.\n\nUse 'Adicionar Fonte aos Favoritos'\npara salvar suas preferidas."
                        continue
                    fi
                    mapfile -t FAV_LISTA < <(grep -v '^$' "$_FAV_ARQUIVO" 2>/dev/null | sort)
                    LISTA_FAV=()
                    IDX=1
                    for f in "${FAV_LISTA[@]}"; do
                        LISTA_FAV+=("$IDX" "$(basename "$f")")
                        IDX=$((IDX + 1))
                    done
                    _SEL_FAV=1
                    while true; do
                        OPCAO_FAV=$(dialog --output-fd 1 \
                            --backtitle "$BT" \
                            --title " MEUS FAVORITOS " \
                            --ok-label "APLICAR" \
                            --extra-button --extra-label "VOLTAR" \
                            --cancel-label "SAIR" \
                            --default-item "$_SEL_FAV" \
                            --menu "" 22 65 8 \
                            "${LISTA_FAV[@]}" \
                            2>"$CURR_TTY")
                        RET=$? ; NORM_RET
                        [ $RET -eq 1 ] && ExitAll
                        [ $RET -eq 3 ] && break
                        _SEL_FAV="$OPCAO_FAV"
                        FAV_FONT_PATH="${FAV_LISTA[$((OPCAO_FAV-1))]}"
                        FAV_FONT_NOME=$(basename "$FAV_FONT_PATH")
                        if [ -f "$FAV_FONT_PATH" ]; then
                            FONT_PATH="$FAV_FONT_PATH"
                            FONT_NOME="$FAV_FONT_NOME"
                            # Aplica via fluxo normal de aplicação
                            TEMA_DIR=$(dirname "$XML_FILE")
                            DIALOG_MENU ONDE_APLICAR \
                                "$BT" " ONDE APLICAR " \
                                12 60 3 \
                                1 "Todos os Blocos (global)" \
                                2 "Lista de Jogos (gamelist)" \
                                3 "Carousel do Menu Principal"
                            RET=$? ; NORM_RET
                            [ $RET -eq 1 ] && ExitAll
                            [ $RET -eq 3 ] && continue
                            FONT_DEST="$TEMA_DIR/_art/$(basename "$FONT_PATH")"
                            mkdir -p "$TEMA_DIR/_art" 2>/dev/null || true
                            cp "$FONT_PATH" "$FONT_DEST" 2>/dev/null || true
                            FONT_REL="./_art/$(basename "$FONT_PATH")"
                            case "$ONDE_APLICAR" in
                                1) sed -i -E \
                                    "s|<fontPath>[^<]*</fontPath>|<fontPath>${FONT_REL}</fontPath>|g" \
                                    "$XML_FILE" 2>/dev/null || true ;;
                                2) awk -v fp="$FONT_REL" '
                                    /<textlist[^>]*name="gamelist"/ { d=1 }
                                    d && /<fontPath>/ { sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>") }
                                    /<\/textlist>/ { d=0 } { print }
                                   ' "$XML_FILE" > "${XML_FILE}.tmp" \
                                   && mv "${XML_FILE}.tmp" "$XML_FILE" ;;
                                3) awk -v fp="$FONT_REL" '
                                    /<carousel[^>]*name="systemcarousel"/ { d=1 }
                                    d && /<fontPath>/ { sub(/<fontPath>[^<]*<\/fontPath>/, "<fontPath>"fp"</fontPath>") }
                                    /<\/carousel>/ { d=0 } { print }
                                   ' "$XML_FILE" > "${XML_FILE}.tmp" \
                                   && mv "${XML_FILE}.tmp" "$XML_FILE" ;;
                            esac
                            DIALOG_MSG "$BT" " FAVORITO APLICADO " 10 58 \
                                "Fonte aplicada!\n\nFonte: $FAV_FONT_NOME\n\nReinicie o ES para ver a mudanca."
                            PerguntarReiniciar
                            break
                        else
                            DIALOG_MSG "$BT" " AVISO " 9 55 \
                                "Arquivo nao encontrado:\n$FAV_FONT_PATH\n\nRemova este favorito."
                        fi
                    done
                fi

                # ---- Adicionar aos favoritos ----
                if [ "$MENU_FAV" = "2" ]; then
                    mapfile -t ALL_FONTS < <(find "$FONT_DIR" \
                        -maxdepth 1 -type f \
                        \( -iname "*.ttf" -o -iname "*.otf" \) \
                        2>/dev/null | sort)
                    if [ ${#ALL_FONTS[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT" " FAVORITOS " 9 55 \
                            "Nenhuma fonte em $FONT_DIR.\n\nInstale fontes via USB primeiro."
                        continue
                    fi
                    LISTA_ADD=()
                    IDX=1
                    for f in "${ALL_FONTS[@]}"; do
                        _FAV_EH_FAV "$f" && _STAR="[*] " || _STAR="    "
                        LISTA_ADD+=("$IDX" "${_STAR}$(basename "$f")")
                        IDX=$((IDX + 1))
                    done
                    OPCAO_ADD=$(dialog --output-fd 1 \
                        --backtitle "$BT" \
                        --title " ADICIONAR FAVORITO " \
                        --ok-label "FAVORITAR" \
                        --extra-button --extra-label "VOLTAR" \
                        --cancel-label "SAIR" \
                        --menu "Selecione a fonte para favoritar:\n([*] = ja e favorito)" \
                        20 62 8 \
                        "${LISTA_ADD[@]}" \
                        2>"$CURR_TTY")
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    _F_SEL="${ALL_FONTS[$((OPCAO_ADD-1))]}"
                    _FAV_ADICIONAR "$_F_SEL"
                    DIALOG_MSG "$BT" " FAVORITO ADICIONADO " 8 52 \
                        "Adicionado aos favoritos:\n$(basename "$_F_SEL")"
                fi

                # ---- Remover dos favoritos ----
                if [ "$MENU_FAV" = "3" ]; then
                    if [ ! -f "$_FAV_ARQUIVO" ] || [ ! -s "$_FAV_ARQUIVO" ]; then
                        DIALOG_MSG "$BT" " FAVORITOS " 8 50 "Nenhum favorito para remover."
                        continue
                    fi
                    mapfile -t FAV_REM < <(grep -v '^$' "$_FAV_ARQUIVO" 2>/dev/null)
                    LISTA_REM=()
                    IDX=1
                    for f in "${FAV_REM[@]}"; do
                        LISTA_REM+=("$IDX" "$(basename "$f")")
                        IDX=$((IDX + 1))
                    done
                    OPCAO_REM=$(dialog --output-fd 1 \
                        --backtitle "$BT" \
                        --title " REMOVER FAVORITO " \
                        --ok-label "REMOVER" \
                        --extra-button --extra-label "VOLTAR" \
                        --cancel-label "SAIR" \
                        --menu "Selecione o favorito a remover:" \
                        18 60 8 \
                        "${LISTA_REM[@]}" \
                        2>"$CURR_TTY")
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    _F_REM="${FAV_REM[$((OPCAO_REM-1))]}"
                    _FAV_REMOVER "$_F_REM"
                    DIALOG_MSG "$BT" " FAVORITO REMOVIDO " 8 52 \
                        "Removido dos favoritos:\n$(basename "$_F_REM")"
                fi
            done
        fi  # fim MENU_FONTE=6

        # ==============================================================
        # OPÇÃO 7 – Instalar Fonte via USB
        # ==============================================================
        if [ "$MENU_FONTE" = "7" ]; then
            # Detecta pontos de montagem de pendrive
            if ! _detectar_usb; then
                DIALOG_MSG "$BT" " INSTALAR VIA USB " 10 58 \
                    "Nenhum pendrive/cartao detectado!\n\nInsira o USB com as fontes e\ntente novamente."
                continue
            fi
            _selecionar_usb
            local RET_USB=$? ; [ $RET_USB -eq 1 ] && ExitAll ; [ $RET_USB -eq 3 ] && continue

            # Busca fontes no USB (raiz e subpastas)
            mapfile -t USB_FONTS < <(find "$_USB_PATH" \
                -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
                2>/dev/null | sort)

            if [ ${#USB_FONTS[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " INSTALAR VIA USB " 10 60 \
                    "Nenhum arquivo .ttf ou .otf encontrado em:\n$_USB_PATH\n\nColoque as fontes na raiz do pendrive."
                continue
            fi

            # Lista com índice numérico como tag (evita overflow do caminho)
            LISTA_USB_F=()
            IDX=1
            for f in "${USB_FONTS[@]}"; do
                LISTA_USB_F+=("$IDX" "$(basename "$f")" "off")
                IDX=$((IDX + 1))
            done

            _INDICES_USB=$(dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " INSTALAR VIA USB " \
                --ok-label "INSTALAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --checklist \
                "Selecione as fontes a instalar:\n(ESPACO = marcar  |  destino: $FONT_DIR)" \
                22 58 10 \
                "${LISTA_USB_F[@]}" \
                2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            if [ -z "$_INDICES_USB" ]; then
                DIALOG_MSG "$BT" " AVISO " 7 45 "Nenhuma fonte selecionada."
                continue
            fi

            mkdir -p "$FONT_DIR" 2>/dev/null || true
            chown ark:ark "$FONT_DIR" 2>/dev/null || true

            printf "\033c" > "$CURR_TTY"
            _CNT=0
            _ERR=0
            for _IDX in $_INDICES_USB; do
                _IDX="${_IDX//\"/}"
                _FSRC="${USB_FONTS[$((_IDX - 1))]}"
                _FDST="$FONT_DIR/$(basename "$_FSRC")"
                printf "[*] Copiando: %s...\n" "$(basename "$_FSRC")" > "$CURR_TTY"
                if cp "$_FSRC" "$_FDST" 2>/dev/null; then
                    chown ark:ark "$_FDST" 2>/dev/null || true
                    _CNT=$((_CNT + 1))
                else
                    _ERR=$((_ERR + 1))
                fi
            done

            DIALOG_MSG "$BT" " INSTALACAO CONCLUIDA " 10 58 \
                "Instalacao finalizada!\n\nInstaladas com sucesso : $_CNT fonte(s)\nErros                  : $_ERR\n\nDestino: $FONT_DIR"
        fi  # fim MENU_FONTE=7

        # ==============================================================
        # OPÇÃO 8 – Apagar Fonte (menu simples — sem checklist, funciona só com botão A)
        # ==============================================================
        if [ "$MENU_FONTE" = "8" ]; then
            while true; do
                mapfile -t DEL_FONTS < <(find "$FONT_DIR" \
                    -maxdepth 1 -type f \
                    \( -iname "*.ttf" -o -iname "*.otf" \) \
                    2>/dev/null | sort)

                if [ ${#DEL_FONTS[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " APAGAR FONTE " 9 55 \
                        "Nenhuma fonte em:\n$FONT_DIR\n\nNada a apagar."
                    break
                fi

                LISTA_DEL=()
                IDX=1
                for f in "${DEL_FONTS[@]}"; do
                    LISTA_DEL+=("$IDX" "$(basename "$f")")
                    IDX=$((IDX + 1))
                done

                _SEL_DEL=$(dialog --output-fd 1 \
                    --backtitle "$BT" \
                    --title " APAGAR FONTE " \
                    --ok-label "APAGAR" \
                    --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --menu "Selecione a fonte a apagar:" \
                    20 56 10 \
                    "${LISTA_DEL[@]}" \
                    2>"$CURR_TTY")
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                _FPATH="${DEL_FONTS[$((_SEL_DEL - 1))]}"
                _FNOME=$(basename "$_FPATH")

                dialog --output-fd 1 \
                    --backtitle "$BT" \
                    --title " CONFIRMAR EXCLUSAO " \
                    --ok-label "SIM, APAGAR" \
                    --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --msgbox "Apagar a fonte:\n\n  $_FNOME\n\nEsta acao NAO pode ser desfeita!" \
                    12 54 >"$CURR_TTY"
                RET_CONF=$?
                [ $RET_CONF -eq 1 ] && ExitAll
                [ $RET_CONF -eq 3 ] && continue

                _FAV_REMOVER "$_FPATH"
                if rm -f "$_FPATH" 2>/dev/null; then
                    DIALOG_MSG "$BT" " FONTE APAGADA " 8 50 \
                        "Removida com sucesso:\n\n  $_FNOME"
                else
                    DIALOG_MSG "$BT" " ERRO " 8 50 \
                        "Nao foi possivel remover:\n\n  $_FNOME"
                fi
            done
        fi  # fim MENU_FONTE=8

        done  # fim while categoria 1
    fi  # fim if CATEGORIA=1
}
