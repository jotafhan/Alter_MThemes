# cat_2_visual_avancado.sh - Visual Avancado
categoria_2() {
    if [ "$CATEGORIA" = "2" ]; then
        TEMA_DIR=$(dirname "$XML_FILE")
        GerarHexPicker() {
            local _titulo="$1" ; local _var="$2"
            local HEX_BUILD="" ; local HEX_ABORTADO=0
            while [ ${#HEX_BUILD} -lt 6 ]; do
                local POS=$(( ${#HEX_BUILD} + 1 ))
                local BAR="[ "
                for i in 1 2 3 4 5 6; do
                    [ $i -le ${#HEX_BUILD} ] && BAR+="${HEX_BUILD:$((i-1)):1} " || BAR+="_ "
                done ; BAR+="]"
                local DIGITO
                DIGITO=$(dialog --output-fd 1 \
                    --backtitle "$BT" --title " $_titulo - Digito $POS " \
                    --ok-label "OK" --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --menu "Cor: # $BAR" 18 46 16 \
                    "0" "0" "1" "1" "2" "2" "3" "3" "4" "4" "5" "5" \
                    "6" "6" "7" "7" "8" "8" "9" "9" \
                    "A" "A" "B" "B" "C" "C" "D" "D" "E" "E" "F" "F" \
                    2>"$CURR_TTY")
                local RET_H=$? ; [ $RET_H -eq 255 ] && RET_H=3
                [ $RET_H -eq 1 ] && ExitAll
                if [ $RET_H -eq 3 ]; then
                    [ ${#HEX_BUILD} -gt 0 ] && HEX_BUILD="${HEX_BUILD%?}" \
                        || { HEX_ABORTADO=1 ; break ; }
                    continue
                fi
                HEX_BUILD="${HEX_BUILD}${DIGITO}"
            done
            [ $HEX_ABORTADO -eq 1 ] && { printf -v "$_var" \'\' ; return 1 ; }
            printf -v "$_var" '%s' "$HEX_BUILD"
            return 0
        }

        while true; do

            # Estado atual do scanline
            grep -qiE "(scanline|scan_line)" "$XML_FILE" 2>/dev/null \
                && SCAN_ESTADO="Sim" || SCAN_ESTADO="Nao"

            DIALOG_MENU MENU_VA \
                "$BT" " VISUAL AVANCADO " \
                24 68 9 \
                1  "Wallpaper do Tema" \
                2  "Scanlines (Efeito Retro)      [Ativo: $SCAN_ESTADO]" \
                3  "Cor de Fundo do Tema" \
                4  "Cor do Item Selecionado" \
                5  "Opacidade de Elementos" \
                6  "Blur / Desfoque de Fundo" \
                7  "Cor de Destaque" \
                8  "Transparencia dos Menus" \
                9  "Resetar Visual (restaurar XML)"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break

        # ----------------------------------------------------------
        # VISUAL - OPÇÃO 1 - Wallpaper
        # ----------------------------------------------------------
        if [ "$MENU_VA" = "1" ]; then

            mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" \
                -maxdepth 1 -type f \
                \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) \
                2>/dev/null | sort)

            if [ ${#WALLPAPERS[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " WALLPAPER " 12 60 \
                    "Nenhuma imagem encontrada!\n\nColoque seus wallpapers (.jpg ou .png) em:\n\n$WALLPAPER_DIR\n\ne execute esta opcao novamente."
                continue
            fi

            LISTA_WP=()
            IDX=1
            for wp in "${WALLPAPERS[@]}"; do
                LISTA_WP+=("$IDX" "$(basename "$wp")")
                IDX=$((IDX + 1))
            done

            DIALOG_MENU OPCAO_WP \
                "$BT" " VISUAL AVANCADO > Wallpaper " \
                18 65 8 \
                "${LISTA_WP[@]}"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue   # VOLTAR → menu Visual Avancado

            WP_ESCOLHIDO="${WALLPAPERS[$((OPCAO_WP - 1))]}"
            WP_NOME=$(basename "$WP_ESCOLHIDO")
            TEMA_DIR=$(dirname "$XML_FILE")

            printf "\033c" > "$CURR_TTY"
            printf "[*] Aplicando wallpaper: %s...\n" "$WP_NOME" > "$CURR_TTY"

            cp "$WP_ESCOLHIDO" "$TEMA_DIR/$WP_NOME" 2>/dev/null || true
            WP_RELATIVO="./$WP_NOME"

            awk -v wp="$WP_RELATIVO" '
                {
                    if (/<background>/ || /<image[^>]*name="background"/) dentro_bg=1
                    if (dentro_bg && $0 ~ /<path>/) {
                        sub(/<path>[^<]*<\/path>/, "<path>"wp"</path>")
                        dentro_bg=0
                    }
                    if (/<\/background>/ || /<\/image>/) dentro_bg=0
                    print
                }
            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"

            sed -i -E \
                "s|(<src>)[^<]*(</src>)|\1${WP_RELATIVO}\2|g" \
                "$XML_FILE" 2>/dev/null || true

            DIALOG_MSG "$BT" " WALLPAPER APLICADO " 13 60 \
                "Wallpaper aplicado!\n\nArquivo: $WP_NOME\nCopiado para: $TEMA_DIR\n\nReinicie o ES para ver a mudanca.\n\nObs: se o fundo nao mudar, o tema pode usar\numa tag diferente de <path> ou <src>."
            PerguntarReiniciar
        fi

        if [ "$MENU_VA" = "2" ]; then

            if grep -qiE "(scanline|scan_line)" "$XML_FILE" 2>/dev/null; then
                ESTADO_ATUAL="Ativado"
            else
                ESTADO_ATUAL="Desativado"
            fi

            DIALOG_MENU OPCAO_SCAN \
                "$BT" " VISUAL AVANCADO > Scanlines " \
                17 60 5 \
                1 "Desativar Scanlines             [ $ESTADO_ATUAL ]" \
                2 "Leve   - Sutil, quase imperceptivel" \
                3 "Medio  - Efeito CRT classico" \
                4 "Forte  - Retro intenso" \
                5 "Arcade - Maximo contraste"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue   # VOLTAR → menu Visual Avancado

            printf "\033c" > "$CURR_TTY"

            case "$OPCAO_SCAN" in
                1)
                    sed -i -E '/<scanlines>/,/<\/scanlines>/d' "$XML_FILE" 2>/dev/null || true
                    sed -i -E '/scanline/Id' "$XML_FILE" 2>/dev/null || true
                    DESC_SCAN="Desativado" ;;
                2) OPACIDADE_SCAN="0.15" ; DESC_SCAN="Leve" ;;
                3) OPACIDADE_SCAN="0.30" ; DESC_SCAN="Medio" ;;
                4) OPACIDADE_SCAN="0.50" ; DESC_SCAN="Forte" ;;
                5) OPACIDADE_SCAN="0.70" ; DESC_SCAN="Arcade" ;;
                *) continue ;;
            esac

            if [ "$OPCAO_SCAN" != "1" ]; then
                printf "[*] Aplicando scanlines (%s)...\n" "$DESC_SCAN" > "$CURR_TTY"
                sed -i -E '/<scanlines>/,/<\/scanlines>/d' "$XML_FILE" 2>/dev/null || true
                awk -v op="$OPACIDADE_SCAN" '
                    /<\/theme>/ { ultima_linha=NR }
                    { linhas[NR]=$0 }
                    END {
                        for (i=1; i<=NR; i++) {
                            if (i == ultima_linha) {
                                print "\t<scanlines>"
                                print "\t\t<opacity>" op "</opacity>"
                                print "\t</scanlines>"
                            }
                            print linhas[i]
                        }
                    }
                ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
            fi

            DIALOG_MSG "$BT" " SCANLINES CONFIGURADAS " 12 58 \
                "Scanlines configuradas!\n\nIntensidade: $DESC_SCAN\n\nReinicie o ES para ver a mudanca.\nObs: suporte depende do tema e versao do ES."
            PerguntarReiniciar
        fi

            # ----------------------------------------------------------
            # VA - OPÇÃO 1 - Cor de Fundo
            # ----------------------------------------------------------
            if [ "$MENU_VA" = "3" ]; then
                while true; do
                    DIALOG_MENU GRUPO_BG \
                        "$BT" " COR DE FUNDO > GRUPO " \
                        17 58 6 \
                        1 "Escuras  (Preto, Cinza Escuro)" \
                        2 "Quentes  (Vinho, Marrom, Laranja)" \
                        3 "Frias    (Azul Escuro, Verde Escuro)" \
                        4 "Roxos    (Roxo, Lilas)" \
                        5 "Claras   (Branco, Cinza Claro)" \
                        6 "Cor Personalizada (HEX manual)"
                    RET=$?
                    NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && break

                    HEX_BG="" ; NOME_BG=""

                    case "$GRUPO_BG" in
                        1)
                            DIALOG_MENU OPC_BG "$BT" " FUNDOS ESCUROS " 14 58 4 \
                                1 "Preto Puro       (#000000)" \
                                2 "Preto Suave      (#0D0D0D)" \
                                3 "Cinza Muito Esc  (#1A1A1A)" \
                                4 "Cinza Escuro     (#2D2D2D)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_BG" in
                                1) HEX_BG="000000" ; NOME_BG="Preto Puro" ;;
                                2) HEX_BG="0D0D0D" ; NOME_BG="Preto Suave" ;;
                                3) HEX_BG="1A1A1A" ; NOME_BG="Cinza Muito Escuro" ;;
                                4) HEX_BG="2D2D2D" ; NOME_BG="Cinza Escuro" ;;
                            esac ;;
                        2)
                            DIALOG_MENU OPC_BG "$BT" " FUNDOS QUENTES " 14 58 4 \
                                1 "Vinho Escuro     (#1A0000)" \
                                2 "Marrom Escuro    (#1A0D00)" \
                                3 "Laranja Escuro   (#1A0800)" \
                                4 "Vermelho Escuro  (#2D0000)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_BG" in
                                1) HEX_BG="1A0000" ; NOME_BG="Vinho Escuro" ;;
                                2) HEX_BG="1A0D00" ; NOME_BG="Marrom Escuro" ;;
                                3) HEX_BG="1A0800" ; NOME_BG="Laranja Escuro" ;;
                                4) HEX_BG="2D0000" ; NOME_BG="Vermelho Escuro" ;;
                            esac ;;
                        3)
                            DIALOG_MENU OPC_BG "$BT" " FUNDOS FRIOS " 14 58 4 \
                                1 "Azul Muito Esc   (#00001A)" \
                                2 "Azul Escuro      (#00002D)" \
                                3 "Verde Muito Esc  (#001A00)" \
                                4 "Verde Escuro     (#002D00)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_BG" in
                                1) HEX_BG="00001A" ; NOME_BG="Azul Muito Escuro" ;;
                                2) HEX_BG="00002D" ; NOME_BG="Azul Escuro" ;;
                                3) HEX_BG="001A00" ; NOME_BG="Verde Muito Escuro" ;;
                                4) HEX_BG="002D00" ; NOME_BG="Verde Escuro" ;;
                            esac ;;
                        4)
                            DIALOG_MENU OPC_BG "$BT" " FUNDOS ROXOS " 13 58 3 \
                                1 "Roxo Escuro      (#1A001A)" \
                                2 "Roxo Medio       (#2D002D)" \
                                3 "Indigo Escuro    (#0D0033)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_BG" in
                                1) HEX_BG="1A001A" ; NOME_BG="Roxo Escuro" ;;
                                2) HEX_BG="2D002D" ; NOME_BG="Roxo Medio" ;;
                                3) HEX_BG="0D0033" ; NOME_BG="Indigo Escuro" ;;
                            esac ;;
                        5)
                            DIALOG_MENU OPC_BG "$BT" " FUNDOS CLAROS " 13 58 3 \
                                1 "Branco Puro      (#FFFFFF)" \
                                2 "Cinza Claro      (#EEEEEE)" \
                                3 "Cinza Medio      (#CCCCCC)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_BG" in
                                1) HEX_BG="FFFFFF" ; NOME_BG="Branco Puro" ;;
                                2) HEX_BG="EEEEEE" ; NOME_BG="Cinza Claro" ;;
                                3) HEX_BG="CCCCCC" ; NOME_BG="Cinza Medio" ;;
                            esac ;;
                        6)
                            HEX_BUILD="" ; HEX_ABORTADO=0
                            while [ ${#HEX_BUILD} -lt 6 ]; do
                                POS=$(( ${#HEX_BUILD} + 1 ))
                                BAR="[ " ; for i in 1 2 3 4 5 6; do
                                    [ $i -le ${#HEX_BUILD} ] && BAR+="${HEX_BUILD:$((i-1)):1} " || BAR+="_ "
                                done ; BAR+="]"
                                DIGITO=$(dialog --output-fd 1 \
                                    --backtitle "$BT" --title " COR DE FUNDO PERSONALIZADA " \
                                    --ok-label "OK" --extra-button --extra-label "VOLTAR" --cancel-label "SAIR" \
                                    --menu "Cor: # $BAR\n      Digito $POS de 6" 18 50 8 \
                                    "0" "0" "1" "1" "2" "2" "3" "3" "4" "4" "5" "5" \
                                    "6" "6" "7" "7" "8" "8" "9" "9" \
                                    "A" "A" "B" "B" "C" "C" "D" "D" "E" "E" "F" "F" \
                                    2>"$CURR_TTY")
                                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll
                                if [ $RET -eq 3 ]; then
                                    [ ${#HEX_BUILD} -gt 0 ] && HEX_BUILD="${HEX_BUILD%?}" || { HEX_ABORTADO=1 ; break ; }
                                    continue
                                fi
                                HEX_BUILD="${HEX_BUILD}${DIGITO}"
                            done
                            [ $HEX_ABORTADO -eq 1 ] && continue
                            HEX_BG="$HEX_BUILD" ; NOME_BG="Personalizada" ;;
                        *) continue ;;
                    esac

                    if [ -n "$HEX_BG" ]; then
                        printf "\033c" > "$CURR_TTY"
                        printf "[*] Aplicando cor de fundo #%s...\n" "$HEX_BG" > "$CURR_TTY"
                        sed -i -E \
                            "s/<backgroundColor>[0-9a-fA-F]{6,8}<\/backgroundColor>/<backgroundColor>${HEX_BG}FF<\/backgroundColor>/g" \
                            "$XML_FILE" 2>/dev/null || true
                        awk -v cor="${HEX_BG}FF" '
                            { if (/<background>/) dentro=1
                              if (dentro && $0 ~ /<color>[0-9A-Fa-f]+<\/color>/)
                                  sub(/<color>[0-9A-Fa-f]+<\/color>/, "<color>"cor"</color>")
                              if (/<\/background>/) dentro=0
                              print }
                        ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
                        DIALOG_MSG "$BT" " FUNDO APLICADO " 10 50 \
                            "Cor de fundo aplicada!\n\nCor: $NOME_BG\nHEX: #$HEX_BG\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
                        break
                    fi
                done
            fi

            # ----------------------------------------------------------
            # VA - OPÇÃO 2 - Cor do Item Selecionado
            # ----------------------------------------------------------
            if [ "$MENU_VA" = "4" ]; then
                while true; do
                    DIALOG_MENU GRUPO_SEL \
                        "$BT" " COR DO ITEM SELECIONADO > GRUPO " \
                        17 58 5 \
                        1 "Quentes  (Vermelho, Laranja, Rosa)" \
                        2 "Frias    (Azul, Ciano, Roxo)" \
                        3 "Naturais (Verde, Lima)" \
                        4 "Especiais (Ouro, Prata, Neon)" \
                        5 "Cor Personalizada (HEX manual)"
                    RET=$?
                    NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && break

                    HEX_SEL="" ; NOME_SEL=""

                    case "$GRUPO_SEL" in
                        1)
                            DIALOG_MENU OPC_SEL "$BT" " SELECAO QUENTES " 15 58 5 \
                                1 "Vermelho Vivo    (#FF3333)" \
                                2 "Laranja Neon     (#FF6600)" \
                                3 "Rosa Vibrante    (#FF3399)" \
                                4 "Salmon           (#FF6666)" \
                                5 "Coral            (#FF4444)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_SEL" in
                                1) HEX_SEL="FF3333" ; NOME_SEL="Vermelho Vivo" ;;
                                2) HEX_SEL="FF6600" ; NOME_SEL="Laranja Neon" ;;
                                3) HEX_SEL="FF3399" ; NOME_SEL="Rosa Vibrante" ;;
                                4) HEX_SEL="FF6666" ; NOME_SEL="Salmon" ;;
                                5) HEX_SEL="FF4444" ; NOME_SEL="Coral" ;;
                            esac ;;
                        2)
                            DIALOG_MENU OPC_SEL "$BT" " SELECAO FRIAS " 15 58 5 \
                                1 "Azul Celeste     (#00AAFF)" \
                                2 "Ciano Neon       (#00FFFF)" \
                                3 "Azul Royal       (#4169E1)" \
                                4 "Roxo Vibrante    (#9933FF)" \
                                5 "Lilas            (#CC99FF)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_SEL" in
                                1) HEX_SEL="00AAFF" ; NOME_SEL="Azul Celeste" ;;
                                2) HEX_SEL="00FFFF" ; NOME_SEL="Ciano Neon" ;;
                                3) HEX_SEL="4169E1" ; NOME_SEL="Azul Royal" ;;
                                4) HEX_SEL="9933FF" ; NOME_SEL="Roxo Vibrante" ;;
                                5) HEX_SEL="CC99FF" ; NOME_SEL="Lilas" ;;
                            esac ;;
                        3)
                            DIALOG_MENU OPC_SEL "$BT" " SELECAO NATURAIS " 13 58 3 \
                                1 "Verde Neon       (#00FF00)" \
                                2 "Verde Menta      (#66FF99)" \
                                3 "Lima Vibrante    (#AAFF00)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_SEL" in
                                1) HEX_SEL="00FF00" ; NOME_SEL="Verde Neon" ;;
                                2) HEX_SEL="66FF99" ; NOME_SEL="Verde Menta" ;;
                                3) HEX_SEL="AAFF00" ; NOME_SEL="Lima Vibrante" ;;
                            esac ;;
                        4)
                            DIALOG_MENU OPC_SEL "$BT" " SELECAO ESPECIAIS " 14 58 4 \
                                1 "Ouro Classico    (#FFD700)" \
                                2 "Ouro Antigo      (#DAA520)" \
                                3 "Prata            (#C0C0C0)" \
                                4 "Neon Amarelo     (#FFFF00)"
                            RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                            case "$OPC_SEL" in
                                1) HEX_SEL="FFD700" ; NOME_SEL="Ouro Classico" ;;
                                2) HEX_SEL="DAA520" ; NOME_SEL="Ouro Antigo" ;;
                                3) HEX_SEL="C0C0C0" ; NOME_SEL="Prata" ;;
                                4) HEX_SEL="FFFF00" ; NOME_SEL="Neon Amarelo" ;;
                            esac ;;
                        5)
                            HEX_BUILD="" ; HEX_ABORTADO=0
                            while [ ${#HEX_BUILD} -lt 6 ]; do
                                POS=$(( ${#HEX_BUILD} + 1 ))
                                BAR="[ " ; for i in 1 2 3 4 5 6; do
                                    [ $i -le ${#HEX_BUILD} ] && BAR+="${HEX_BUILD:$((i-1)):1} " || BAR+="_ "
                                done ; BAR+="]"
                                DIGITO=$(dialog --output-fd 1 \
                                    --backtitle "$BT" --title " COR SELECAO PERSONALIZADA " \
                                    --ok-label "OK" --extra-button --extra-label "VOLTAR" --cancel-label "SAIR" \
                                    --menu "Cor: # $BAR\n      Digito $POS de 6" 18 50 8 \
                                    "0" "0" "1" "1" "2" "2" "3" "3" "4" "4" "5" "5" \
                                    "6" "6" "7" "7" "8" "8" "9" "9" \
                                    "A" "A" "B" "B" "C" "C" "D" "D" "E" "E" "F" "F" \
                                    2>"$CURR_TTY")
                                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll
                                if [ $RET -eq 3 ]; then
                                    [ ${#HEX_BUILD} -gt 0 ] && HEX_BUILD="${HEX_BUILD%?}" || { HEX_ABORTADO=1 ; break ; }
                                    continue
                                fi
                                HEX_BUILD="${HEX_BUILD}${DIGITO}"
                            done
                            [ $HEX_ABORTADO -eq 1 ] && continue
                            HEX_SEL="$HEX_BUILD" ; NOME_SEL="Personalizada" ;;
                        *) continue ;;
                    esac

                    if [ -n "$HEX_SEL" ]; then
                        printf "\033c" > "$CURR_TTY"
                        printf "[*] Aplicando cor de selecao #%s...\n" "$HEX_SEL" > "$CURR_TTY"
                        sed -i -E \
                            "s/<selectedColor>[0-9a-fA-F]{6,8}<\/selectedColor>/<selectedColor>${HEX_SEL}<\/selectedColor>/g" \
                            "$XML_FILE" 2>/dev/null || true
                        sed -i -E \
                            "s/<selectorColor>[0-9a-fA-F]{6,8}<\/selectorColor>/<selectorColor>${HEX_SEL}<\/selectorColor>/g" \
                            "$XML_FILE" 2>/dev/null || true
                        sed -i -E \
                            "s/<selectionColor>[0-9a-fA-F]{6,8}<\/selectionColor>/<selectionColor>${HEX_SEL}<\/selectionColor>/g" \
                            "$XML_FILE" 2>/dev/null || true
                        DIALOG_MSG "$BT" " SELECAO APLICADA " 10 52 \
                            "Cor do item selecionado aplicada!\n\nCor: $NOME_SEL\nHEX: #$HEX_SEL\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
                        break
                    fi
                done
            fi

            # ----------------------------------------------------------
            # VA - OPÇÃO 3 - Opacidade de Elementos
            # ----------------------------------------------------------
            if [ "$MENU_VA" = "5" ]; then
                while true; do
                    DIALOG_MENU MENU_OPAC \
                        "$BT" " OPACIDADE DE ELEMENTOS " \
                        14 58 3 \
                        1 "Opacidade Geral (todos elementos)" \
                        2 "Opacidade do Fundo" \
                        3 "Opacidade de Imagens/Logos"
                    RET=$?
                    NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && break

                    DIALOG_MENU OPCAO_OPAC \
                        "$BT" " NIVEL DE OPACIDADE " \
                        16 58 6 \
                        1 "100%  - Totalmente visivel (padrao)" \
                        2 "90%   - Leve transparencia" \
                        3 "75%   - Semitransparente" \
                        4 "50%   - Meio a meio" \
                        5 "25%   - Bem transparente" \
                        6 "10%   - Quase invisivel"
                    RET=$?
                    NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    case "$OPCAO_OPAC" in
                        1) VAL_OPAC="1"    ; DESC_OPAC="100%" ;;
                        2) VAL_OPAC="0.9"  ; DESC_OPAC="90%" ;;
                        3) VAL_OPAC="0.75" ; DESC_OPAC="75%" ;;
                        4) VAL_OPAC="0.5"  ; DESC_OPAC="50%" ;;
                        5) VAL_OPAC="0.25" ; DESC_OPAC="25%" ;;
                        6) VAL_OPAC="0.1"  ; DESC_OPAC="10%" ;;
                        *) continue ;;
                    esac

                    printf "\033c" > "$CURR_TTY"
                    printf "[*] Aplicando opacidade %s...\n" "$DESC_OPAC" > "$CURR_TTY"

                    case "$MENU_OPAC" in
                        1)
                            sed -i -E \
                                "s/<opacity>[0-9.]+<\/opacity>/<opacity>${VAL_OPAC}<\/opacity>/g" \
                                "$XML_FILE" 2>/dev/null || true
                            DESC_ELEM="Todos os elementos" ;;
                        2)
                            awk -v op="$VAL_OPAC" '
                                { if (/<background>/) dentro=1
                                  if (dentro && $0 ~ /<opacity>/)
                                      sub(/<opacity>[^<]*<\/opacity>/, "<opacity>"op"</opacity>")
                                  if (/<\/background>/) dentro=0
                                  print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
                            DESC_ELEM="Fundo" ;;
                        3)
                            awk -v op="$VAL_OPAC" '
                                { if (/<image>/) dentro=1
                                  if (dentro && $0 ~ /<opacity>/)
                                      sub(/<opacity>[^<]*<\/opacity>/, "<opacity>"op"</opacity>")
                                  if (/<\/image>/) dentro=0
                                  print }
                            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
                            DESC_ELEM="Imagens e logos" ;;
                    esac

                    DIALOG_MSG "$BT" " OPACIDADE APLICADA " 10 52 \
                        "Opacidade aplicada!\n\nElemento: $DESC_ELEM\nNivel: $DESC_OPAC\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
                    break
                done
            fi

            # Blur (6) - simulated via ImageMagick
            if [ "$MENU_VA" = "6" ]; then
                DIALOG_MENU OPCAO_BLUR \
                    "$BT" " BLUR DE FUNDO " \
                    14 60 4 \
                    1 "Sem blur         (remover efeito)" \
                    2 "Leve             (blur: 2x2)" \
                    3 "Medio            (blur: 5x5)" \
                    4 "Forte            (blur: 10x10)"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue

                WALLPAPER_ATUAL=$(awk '
                    /<image[^>]*name="background"/ { dentro=1 }
                    dentro && /<path>/ {
                        linha=$0
                        sub(/^[^<]*<path>/, "", linha)
                        sub(/<\/path>.*$/, "", linha)
                        print linha
                        exit
                    }
                    /<\/image>/ { dentro=0 }
                ' "$XML_FILE" 2>/dev/null | head -1)

                TEMA_DIR_BLR=$(dirname "$XML_FILE")
                IMG_ORIG="$TEMA_DIR_BLR/$WALLPAPER_ATUAL"

                if [ ! -f "$IMG_ORIG" ]; then
                    DIALOG_MSG "$BT" " BLUR " 9 58 \
                        "Nenhum wallpaper definido no tema.\n\nDefina um wallpaper primeiro\nna opcao 1 - Wallpaper do Tema."
                    continue
                fi

                case "$OPCAO_BLUR" in
                    1) BLUR_SIGMA="" ; DESC_BLUR="Sem blur" ;;
                    2) BLUR_SIGMA="2x2" ; DESC_BLUR="Leve" ;;
                    3) BLUR_SIGMA="5x5" ; DESC_BLUR="Medio" ;;
                    4) BLUR_SIGMA="10x10" ; DESC_BLUR="Forte" ;;
                    *) continue ;;
                esac

                printf "\033c" > "$CURR_TTY"
                printf "[*] Aplicando blur: %s...\n" "$DESC_BLUR" > "$CURR_TTY"

                BLUR_OUT="$TEMA_DIR_BLR/_art/darkos_blur_bg.png"
                if [ -z "$BLUR_SIGMA" ]; then
                    # Remove blur — restaura wallpaper original
                    cp "$IMG_ORIG" "$BLUR_OUT" 2>/dev/null || true
                else
                    convert "$IMG_ORIG" -blur "$BLUR_SIGMA" "$BLUR_OUT" 2>/dev/null || true
                fi

                if [ -f "$BLUR_OUT" ]; then
                    BLR_REL="./_art/darkos_blur_bg.png"
                    awk -v wp="$BLR_REL" '
                        /<image[^>]*name="background"/ { dentro=1 }
                        dentro && /<path>/ {
                            sub(/<path>[^<]*<\/path>/, "<path>"wp"<\/path>")
                            dentro=0 }
                        /<\/image>/ { dentro=0 }
                        { print }
                    ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
                fi

                DIALOG_MSG "$BT" " BLUR APLICADO " 10 55 \
                    "Blur aplicado!\n\nEstilo: $DESC_BLUR\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            # Cor de Destaque (7)
            if [ "$MENU_VA" = "7" ]; then
                DIALOG_MENU OPCAO_DEST \
                    "$BT" " COR DE DESTAQUE " \
                    16 58 6 \
                    1 "Ciano Neon     (#00FFFF)" \
                    2 "Verde Neon     (#00FF00)" \
                    3 "Amarelo Ouro   (#FFD700)" \
                    4 "Laranja Vivo   (#FF6600)" \
                    5 "Rosa Neon      (#FF00AA)" \
                    6 "Personalizada  (HEX manual)"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue

                case "$OPCAO_DEST" in
                    1) HEX_DEST="00FFFF" ; NOME_DEST="Ciano Neon" ;;
                    2) HEX_DEST="00FF00" ; NOME_DEST="Verde Neon" ;;
                    3) HEX_DEST="FFD700" ; NOME_DEST="Amarelo Ouro" ;;
                    4) HEX_DEST="FF6600" ; NOME_DEST="Laranja Vivo" ;;
                    5) HEX_DEST="FF00AA" ; NOME_DEST="Rosa Neon" ;;
                    6) GerarHexPicker "COR DE DESTAQUE" HEX_DEST || continue
                       NOME_DEST="Personalizada" ;;
                    *) continue ;;
                esac

                printf "\033c" > "$CURR_TTY"
                sed -i -E "s|<selectedColor>[^<]*</selectedColor>|<selectedColor>${HEX_DEST}</selectedColor>|g" \
                    "$XML_FILE" 2>/dev/null || true
                sed -i -E "s|<selectorColor>[^<]*</selectorColor>|<selectorColor>${HEX_DEST}</selectorColor>|g" \
                    "$XML_FILE" 2>/dev/null || true

                DIALOG_MSG "$BT" " COR DE DESTAQUE " 10 52 \
                    "Cor de destaque aplicada!\n\nCor: $NOME_DEST (#$HEX_DEST)\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            # Transparencia dos Menus (8)
            if [ "$MENU_VA" = "8" ]; then
                DIALOG_MENU OPCAO_TRANSP \
                    "$BT" " TRANSPARENCIA DOS MENUS " \
                    14 58 4 \
                    1 "100% - Solido (sem transparencia)" \
                    2 "85%  - Levemente transparente" \
                    3 "70%  - Moderado" \
                    4 "50%  - Semitransparente"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue

                case "$OPCAO_TRANSP" in
                    1) ALPHA_HEX="FF" ; DESC_TR="100% Solido" ;;
                    2) ALPHA_HEX="D9" ; DESC_TR="85%" ;;
                    3) ALPHA_HEX="B3" ; DESC_TR="70%" ;;
                    4) ALPHA_HEX="80" ; DESC_TR="50%" ;;
                    *) continue ;;
                esac

                printf "\033c" > "$CURR_TTY"
                # Aplica alpha no menuBackground
                awk -v alpha="$ALPHA_HEX" '
                    /<menuBackground[^>]*>/ { dentro=1 }
                    /<\/menuBackground>/ { dentro=0 }
                    dentro && /<color>[0-9A-Fa-f]+<\/color>/ {
                        rgb=$0
                        sub(/^[^<]*<color>/, "", rgb)
                        sub(/<\/color>.*$/, "", rgb)
                        rgb=substr(rgb, 1, 6)
                        sub(/<color>[0-9A-Fa-f]+<\/color>/, "<color>" rgb alpha "</color>")
                    }
                    { print }
                ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"

                DIALOG_MSG "$BT" " TRANSPARENCIA APLICADA " 10 55 \
                    "Transparencia aplicada!\n\nNivel: $DESC_TR\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            # Resetar Visual (9)
            if [ "$MENU_VA" = "9" ]; then
                if [ ! -f "${XML_FILE}.bak" ]; then
                    DIALOG_MSG "$BT" " RESETAR VISUAL " 9 55 \
                        "Nenhum backup encontrado!\n\nO backup e criado automaticamente\nao abrir o script."
                    continue
                fi

                dialog --output-fd 1 \
                    --backtitle "$BT" \
                    --title " RESETAR VISUAL " \
                    --ok-label "RESETAR" \
                    --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --msgbox "Isso ira restaurar o XML para o estado\nde quando o script foi aberto.\n\nTodas as alteracoes visuais feitas\nnesta sessao serao perdidas.\n\nDeseja continuar?" \
                    12 55 >"$CURR_TTY"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                printf "\033c" > "$CURR_TTY"
                printf "[*] Restaurando visual original...\n" > "$CURR_TTY"
                cp "${XML_FILE}.bak" "$XML_FILE" 2>/dev/null || true

                DIALOG_MSG "$BT" " VISUAL RESETADO " 10 55 \
                    "Visual restaurado com sucesso!\n\nO tema voltou ao estado inicial\nde quando o script foi aberto.\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

        done  # fim while categoria 2
    fi  # fim if CATEGORIA=2
}
