# cat_4_temas_prontos.sh - Temas Prontos
categoria_4() {
    if [ "$CATEGORIA" = "4" ]; then

        # Função que aplica um tema completo de uma vez
        AplicarTemaPronto() {
            local NOME="$1"
            local COR_FONTE="$2"
            local COR_FUNDO="$3"
            local COR_SEL="$4"
            local TAMANHO="$5"
            local FONTE_PATH="$6"

            printf "\033c" > "$CURR_TTY"
            printf "[*] Aplicando tema: %s...\n" "$NOME" > "$CURR_TTY"

            # Cor da fonte em blocos de texto
            awk -v val="$COR_FONTE" '
                /<text[^>]*>/ || /<textlist[^>]*>/ { dentro=1 }
                /<\/text>/ || /<\/textlist>/        { dentro=0 }
                /<carousel[^>]*>/ || /<background[^>]*>/ || /<image[^>]*>/ { dentro=0 }
                dentro && $0 ~ /<color>/ {
                    sub(/<color>[^<]*<\/color>/, "<color>"val"</color>") }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"

            sed -i -E "s|<textColor>[^<]*</textColor>|<textColor>${COR_FONTE}</textColor>|g" \
                "$XML_FILE" 2>/dev/null || true
            sed -i -E "s|<selectedColor>[^<]*</selectedColor>|<selectedColor>${COR_SEL}</selectedColor>|g" \
                "$XML_FILE" 2>/dev/null || true

            # Cor de fundo em menuBackground
            awk -v val="${COR_FUNDO}FF" '
                /<menuBackground[^>]*>/ { dentro=1 }
                /<\/menuBackground>/     { dentro=0 }
                dentro && $0 ~ /<color>/ {
                    sub(/<color>[^<]*<\/color>/, "<color>"val"</color>") }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"

            sed -i -E "s|<backgroundColor>[^<]*</backgroundColor>|<backgroundColor>${COR_FUNDO}FF</backgroundColor>|g" \
                "$XML_FILE" 2>/dev/null || true

            # Tamanho da fonte
            sed -i -E "s|<fontSize>[^<]*</fontSize>|<fontSize>${TAMANHO}</fontSize>|g" \
                "$XML_FILE" 2>/dev/null || true

            # Fonte personalizada se informada
            if [ -n "$FONTE_PATH" ] && [ -f "$FONTE_PATH" ]; then
                TEMA_DIR=$(dirname "$XML_FILE")
                mkdir -p "$TEMA_DIR/_art" 2>/dev/null || true
                cp "$FONTE_PATH" "$TEMA_DIR/_art/$(basename "$FONTE_PATH")" 2>/dev/null || true
                FONT_REL="./_art/$(basename "$FONTE_PATH")"
                sed -i -E "s|<fontPath>[^<]*</fontPath>|<fontPath>${FONT_REL}</fontPath>|g" \
                    "$XML_FILE" 2>/dev/null || true
            fi

            # Cor do menuText (menu de opções do ES)
            awk -v val="$COR_FONTE" '
                /<menuText[^>]*>/ { dentro=1 }
                /<\/menuText>/    { dentro=0 }
                dentro && $0 ~ /<color>/ {
                    sub(/<color>[^<]*<\/color>/, "<color>"val"</color>") }
                { print }
            ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
        }

        while true; do
            DIALOG_MENU MENU_TP \
                "$BT" " TEMAS PRONTOS " \
                18 65 8 \
                1 "Dark        - Escuro com texto branco" \
                2 "Neon        - Fundo preto com verde neon" \
                3 "Retro       - Laranja retro anos 80" \
                4 "SNES        - Roxo classico do Super Nintendo" \
                5 "PS1         - Cinza azulado estilo PlayStation" \
                6 "Arcade      - Vermelho intenso estilo fliperama" \
                7 "Midnight    - Azul meia-noite elegante" \
                8 "Game Boy    - Verde monocromatico classico"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break

            FONTE_SYS="/usr/share/fonts/truetype/dejavu"

            case "$MENU_TP" in
                1) # Dark
                    NOME_TP="Dark"
                    COR_F="FFFFFF" ; COR_BG="1A1A1A"
                    COR_S="00AAFF" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSans-Bold.ttf" ;;
                2) # Neon
                    NOME_TP="Neon"
                    COR_F="00FF00" ; COR_BG="000000"
                    COR_S="00FFFF" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSansMono-Bold.ttf" ;;
                3) # Retro
                    NOME_TP="Retro"
                    COR_F="FF9933" ; COR_BG="1A0800"
                    COR_S="FFD700" ; TAM="0.040"
                    FONTE_TP="$FONTE_SYS/DejaVuSans-Bold.ttf" ;;
                4) # SNES
                    NOME_TP="SNES"
                    COR_F="FFFFFF" ; COR_BG="2D0050"
                    COR_S="CC99FF" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSans.ttf" ;;
                5) # PS1
                    NOME_TP="PS1"
                    COR_F="CCCCFF" ; COR_BG="0D1B2A"
                    COR_S="0066FF" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSans.ttf" ;;
                6) # Arcade
                    NOME_TP="Arcade"
                    COR_F="FFFF00" ; COR_BG="1A0000"
                    COR_S="FF0000" ; TAM="0.042"
                    FONTE_TP="$FONTE_SYS/DejaVuSans-Bold.ttf" ;;
                7) # Midnight
                    NOME_TP="Midnight"
                    COR_F="E0E8FF" ; COR_BG="000D1A"
                    COR_S="00AAFF" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSerif.ttf" ;;
                8) # Game Boy
                    NOME_TP="Game Boy"
                    COR_F="0F380F" ; COR_BG="9BBC0F"
                    COR_S="306230" ; TAM="0.038"
                    FONTE_TP="$FONTE_SYS/DejaVuSansMono.ttf" ;;
                *) continue ;;
            esac

            # Confirmação antes de aplicar
            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " CONFIRMAR TEMA " \
                --ok-label "APLICAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Tema: $NOME_TP

  Fonte     : #${COR_F}
  Fundo     : #${COR_BG}
  Selecionado: #${COR_S}
  Tamanho   : $TAM

APLICAR para confirmar ou VOLTAR para escolher outro." \
                14 52 >"$CURR_TTY"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            AplicarTemaPronto "$NOME_TP" "$COR_F" "$COR_BG" "$COR_S" "$TAM" "$FONTE_TP"

            DIALOG_MSG "$BT" " TEMA APLICADO " 12 55 \
                "Tema '$NOME_TP' aplicado!\n\nFonte    : #${COR_F}\nFundo    : #${COR_BG}\nSelecionado: #${COR_S}\nTamanho  : $TAM\n\nReinicie o ES para ver a mudanca."
            PerguntarReiniciar
            break
        done
    fi  # fim if CATEGORIA=4
}
