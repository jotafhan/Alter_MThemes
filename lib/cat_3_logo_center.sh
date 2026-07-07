# cat_3_logos.sh - Logos dos Sistemas
categoria_3() {
    if [ "$CATEGORIA" = "3" ]; then
        TEMA_DIR=$(dirname "$XML_FILE")
        LOGOS_DIR="/home/ark/darkos_logos"
        LOGOS_BAK_DIR="/home/ark/darkos_backups/logos"
        ASSETS_DIR="$TEMA_DIR/_assets/systems"
        mkdir -p "$LOGOS_DIR" "$LOGOS_BAK_DIR" "$ASSETS_DIR" 2>/dev/null || true
        chown ark:ark "$LOGOS_DIR" "$LOGOS_BAK_DIR" 2>/dev/null || true

        while true; do
            NUM_LOGOS_USER=$(find "$LOGOS_DIR" -maxdepth 1 \
                -type f \( -iname "*.png" -o -iname "*.svg" \) 2>/dev/null | wc -l)
            NUM_LOGOS_BAK=$(find "$LOGOS_BAK_DIR" -maxdepth 1 \
                -mindepth 1 -type d 2>/dev/null | wc -l)

            DIALOG_MENU MENU_LOGO \
    "$BT" " LOGOS DOS SISTEMAS " \
    20 68 10 \
    1 "Trocar Logo de um Sistema     [$NUM_LOGOS_USER logo(s)]" \
    2 "Backup Logos Atuais           [$NUM_LOGOS_BAK backup(s)]" \
    3 "Restaurar Logo Original" \
    4 "Ajustar Alinhamento do Logo" \
    5 "Ajustar Proporcao do Logo" \
    6 "Limpar Cache de Imagens" \
    7 "Baixar Pack de Logos (online)" \
    8 "Listar Logos do Tema" \
    9 "Apagar Pack de Logos" \
    10 "Apagar Logo Especifico"
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break

            if [ "$MENU_LOGO" = "1" ]; then
                mapfile -t LOGOS_USER < <(find "$LOGOS_DIR" -type f \
                    \( -iname "*.png" -o -iname "*.svg" -o -iname "*.jpg" \) \
                    2>/dev/null | sort)
                if [ ${#LOGOS_USER[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " LOGOS " 12 62 \
                        "Nenhum logo encontrado!\n\nColoque arquivos .png ou .svg em:\n\n$LOGOS_DIR\n\nNomeie como o sistema:\nex: nes.png, snes.png, psx.png"
                    continue
                fi
                LISTA_LU=() ; IDX=1
                for f in "${LOGOS_USER[@]}"; do
                    LISTA_LU+=("$IDX" "$(basename "$f")") ; IDX=$((IDX+1))
                done
                DIALOG_MENU OPCAO_LU "$BT" " ESCOLHA O LOGO " 18 65 8 "${LISTA_LU[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                LOGO_SRC="${LOGOS_USER[$((OPCAO_LU-1))]}"
                LOGO_NOME=$(basename "$LOGO_SRC") ; LOGO_BASE="${LOGO_NOME%.*}"
                SISTEMA_DIR="$TEMA_DIR/$LOGO_BASE"
                printf "\033c" > "$CURR_TTY"
                printf "[*] Instalando logo: %s...\n" "$LOGO_NOME" > "$CURR_TTY"
                LOGO_DEST="$ASSETS_DIR/$LOGO_NOME"
                [ -f "$LOGO_DEST" ] && cp "$LOGO_DEST" \
                    "$LOGOS_BAK_DIR/${LOGO_NOME}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                cp "$LOGO_SRC" "$ASSETS_DIR/$LOGO_NOME" 2>/dev/null || true
                [ -d "$SISTEMA_DIR" ] && cp "$LOGO_SRC" "$SISTEMA_DIR/logo.png" 2>/dev/null || true
                SISTEMA_XML="$SISTEMA_DIR/theme.xml"
                # NOTA: sem bloco XML delimitado conhecido para o <image name="logo">
                # do tema do sistema — se a tag <path> de logo nao existir em nenhum
                # lugar do arquivo, esta substituicao nao tem efeito (mesma limitacao
                # documentada em core.sh/AplicarEmBloco). Nao e seguro inserir um
                # <image name="logo"> inteiro as cegas sem saber pos/size esperados
                # pelo tema do sistema.
                [ -f "$SISTEMA_XML" ] && sed -i -E \
                    "s|<path>[^<]*(logo|titlelogo)[^<]*</path>|<path>./$LOGO_NOME</path>|g" \
                    "$SISTEMA_XML" 2>/dev/null || true
                DIALOG_MSG "$BT" " LOGO INSTALADO " 11 60 \
                    "Logo instalado!\n\nArquivo: $LOGO_NOME\nSistema: $LOGO_BASE\nDestino: $ASSETS_DIR\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            if [ "$MENU_LOGO" = "2" ]; then
                mapfile -t LOGOS_ATUAIS < <(find "$ASSETS_DIR" "$TEMA_DIR" \
                    -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.svg" \) \
                    2>/dev/null | grep -i "logo\|system\|title" | sort)
                if [ ${#LOGOS_ATUAIS[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " BACKUP LOGOS " 9 55 \
                        "Nenhum logo encontrado no tema para backup."
                    continue
                fi
                printf "\033c" > "$CURR_TTY"
                printf "[*] Fazendo backup dos logos...\n" > "$CURR_TTY"
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                BAK_PASTA="$LOGOS_BAK_DIR/backup_$TIMESTAMP"
                mkdir -p "$BAK_PASTA" 2>/dev/null || true
                COPIADOS=0
                for f in "${LOGOS_ATUAIS[@]}"; do
                    cp "$f" "$BAK_PASTA/$(basename "$f")" 2>/dev/null && COPIADOS=$((COPIADOS+1))
                done
                DIALOG_MSG "$BT" " BACKUP CRIADO " 11 60 \
                    "Backup dos logos criado!\n\n$COPIADOS arquivo(s) salvo(s)\nDestino: $BAK_PASTA"
            fi

            if [ "$MENU_LOGO" = "3" ]; then
                mapfile -t LOGOS_BAK < <(find "$LOGOS_BAK_DIR" -type f \
                    \( -iname "*.bak*" -o -iname "*.png" -o -iname "*.svg" \) \
                    2>/dev/null | sort -r)
                if [ ${#LOGOS_BAK[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " RESTAURAR LOGO " 9 58 \
                        "Nenhum backup de logo encontrado.\n\nFaca um backup primeiro pela opcao 2."
                    continue
                fi
                LISTA_BAK=() ; IDX=1
                for f in "${LOGOS_BAK[@]}"; do
                    LISTA_BAK+=("$IDX" "$(basename "$f")") ; IDX=$((IDX+1))
                done
                DIALOG_MENU OPCAO_BAK "$BT" " RESTAURAR LOGO " 18 65 8 "${LISTA_BAK[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                LOGO_BAK="${LOGOS_BAK[$((OPCAO_BAK-1))]}"
                LOGO_NOME=$(basename "$LOGO_BAK" | sed 's/\.bak\.[0-9_]*//')
                printf "\033c" > "$CURR_TTY"
                printf "[*] Restaurando logo: %s...\n" "$LOGO_NOME" > "$CURR_TTY"
                cp "$LOGO_BAK" "$ASSETS_DIR/$LOGO_NOME" 2>/dev/null || true
                DIALOG_MSG "$BT" " LOGO RESTAURADO " 9 55 \
                    "Logo restaurado!\n\n$LOGO_NOME\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            if [ "$MENU_LOGO" = "4" ]; then
                DIALOG_MENU OPCAO_ALIGN "$BT" " ALINHAMENTO DO LOGO " 15 62 5 \
                    1 "Centralizado    (pos: 0.5 0.5 | origin: 0.5 0.5)" \
                    2 "Esquerda        (pos: 0.03 0.5 | origin: 0.0 0.5)" \
                    3 "Direita         (pos: 0.97 0.5 | origin: 1.0 0.5)" \
                    4 "Superior centro (pos: 0.5 0.05 | origin: 0.5 0.0)" \
                    5 "Inferior centro (pos: 0.5 0.92 | origin: 0.5 1.0)"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                case "$OPCAO_ALIGN" in
                    1) POS_V="0.5 0.5"   ; ORIG_V="0.5 0.5" ; DESC_AL="Centralizado" ;;
                    2) POS_V="0.03 0.5"  ; ORIG_V="0.0 0.5" ; DESC_AL="Esquerda" ;;
                    3) POS_V="0.97 0.5"  ; ORIG_V="1.0 0.5" ; DESC_AL="Direita" ;;
                    4) POS_V="0.5 0.05"  ; ORIG_V="0.5 0.0" ; DESC_AL="Superior" ;;
                    5) POS_V="0.5 0.92"  ; ORIG_V="0.5 1.0" ; DESC_AL="Inferior" ;;
                    *) continue ;;
                esac
                printf "\033c" > "$CURR_TTY"
                printf "[*] Aplicando alinhamento: %s...\n" "$DESC_AL" > "$CURR_TTY"
                awk -v pv="$POS_V" -v ov="$ORIG_V" '
                    /<image[^>]*name="(titlelogo|logo)"/ { dentro=1 }
                    /<\/image>/ { dentro=0 }
                    dentro && /<pos>/ { sub(/<pos>[^<]*<\/pos>/, "<pos>"pv"</pos>") }
                    dentro && /<origin>/ { sub(/<origin>[^<]*<\/origin>/, "<origin>"ov"</origin>") }
                    { print }
                ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"
                DIALOG_MSG "$BT" " ALINHAMENTO APLICADO " 10 55 \
                    "Alinhamento: $DESC_AL\nPos: $POS_V  Origin: $ORIG_V\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            if [ "$MENU_LOGO" = "5" ]; then
                DIALOG_MENU OPCAO_PROP "$BT" " PROPORCAO DO LOGO " 14 60 4 \
                    1 "Original     (logoScale: 1)" \
                    2 "Pequeno      (maxSize: 0.10 0.10)" \
                    3 "Medio        (maxSize: 0.20 0.20)" \
                    4 "Grande       (maxSize: 0.35 0.35)"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                case "$OPCAO_PROP" in
                    1) LOGO_SCALE="1" ; MAX_SIZE="0.20 0.20" ; DESC_PR="Original" ;;
                    2) LOGO_SCALE="0" ; MAX_SIZE="0.10 0.10" ; DESC_PR="Pequeno" ;;
                    3) LOGO_SCALE="0" ; MAX_SIZE="0.20 0.20" ; DESC_PR="Medio" ;;
                    4) LOGO_SCALE="0" ; MAX_SIZE="0.35 0.35" ; DESC_PR="Grande" ;;
                    *) continue ;;
                esac
                printf "\033c" > "$CURR_TTY"
                printf "[*] Aplicando proporcao: %s...\n" "$DESC_PR" > "$CURR_TTY"
                sed -i -E "s|<logoScale>[^<]*</logoScale>|<logoScale>${LOGO_SCALE}</logoScale>|g" \
                    "$XML_FILE" 2>/dev/null || true
                sed -i -E "s|<logoSize>[^<]*</logoSize>|<logoSize>${MAX_SIZE}</logoSize>|g" \
                    "$XML_FILE" 2>/dev/null || true
                sed -i -E "s|<maxSize>[^<]*</maxSize>|<maxSize>${MAX_SIZE}</maxSize>|g" \
                    "$XML_FILE" 2>/dev/null || true
                DIALOG_MSG "$BT" " PROPORCAO APLICADA " 10 55 \
                    "Proporcao: $DESC_PR\nLogoScale: $LOGO_SCALE  MaxSize: $MAX_SIZE\n\nReinicie o ES para ver a mudanca."
                PerguntarReiniciar
            fi

            if [ "$MENU_LOGO" = "6" ]; then
                CACHE_DIRS=("/home/ark/.emulationstation/downloaded_images"
                    "/home/ark/.emulationstation/downloaded_videos" "/tmp/emulationstation")
                INFO_C="" ; TOTAL_C=0
                for d in "${CACHE_DIRS[@]}"; do
                    if [ -e "$d" ]; then
                        TAM_C=$(du -sh "$d" 2>/dev/null | cut -f1 || echo "0")
                        INFO_C="${INFO_C}  $TAM_C  $(basename "$d")\n"
                        BYTES_C=$(du -sb "$d" 2>/dev/null | cut -f1 || echo "0")
                        TOTAL_C=$(( TOTAL_C + BYTES_C ))
                    fi
                done
                TOTAL_MB_C=$(( TOTAL_C / 1024 / 1024 ))
                if [ -z "$INFO_C" ]; then
                    DIALOG_MSG "$BT" " CACHE " 9 55 "Cache de imagens esta limpo!"
                    continue
                fi
                dialog --output-fd 1 --backtitle "$BT" --title " LIMPAR CACHE " \
                    --ok-label "LIMPAR" --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --msgbox "Cache:\n\n${INFO_C}\nTotal: ~${TOTAL_MB_C}MB\n\nDeseja limpar?" \
                    14 58 >"$CURR_TTY"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                printf "\033c" > "$CURR_TTY"
                printf "[*] Limpando cache...\n" > "$CURR_TTY"
                REMOVIDOS_C=0
                for d in "${CACHE_DIRS[@]}"; do
                    [ -e "$d" ] && rm -rf "$d" 2>/dev/null && REMOVIDOS_C=$((REMOVIDOS_C+1))
                done
                DIALOG_MSG "$BT" " CACHE LIMPO " 9 55 \
                    "$REMOVIDOS_C pasta(s) removida(s)\nEspaco liberado: ~${TOTAL_MB_C}MB\n\nReinicie o ES para reindexar."
                PerguntarReiniciar
            fi

            if [ "$MENU_LOGO" = "7" ]; then
                DIALOG_MENU OPCAO_PACK "$BT" " BAIXAR PACK DE LOGOS " 18 70 6 \
                    1 "Monochrome SVG+PNG  - Logos monocromaticos (recomendado)" \
                    2 "es-theme-carbon     - Logos do tema Carbon (RetroPie)" \
                    3 "es-theme-art-book   - Logos estilo livro" \
                    4 "es-theme-alekfull   - Logos coloridos" \
                    5 "es-theme-switch-like - Logos estilo Nintendo Switch" \
                    6 "Apenas SVGs do Monochrome (menor tamanho)"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                case "$OPCAO_PACK" in
                    1) PACK_URL="https://github.com/HVR88/Monochrome-Gaming-Logos/archive/refs/heads/master.zip"
                       PACK_NOME="Monochrome SVG+PNG" ; PACK_EXT="png\|svg" ;;
                    2) PACK_URL="https://github.com/RetroPie/es-theme-carbon/archive/refs/heads/master.zip"
                       PACK_NOME="Carbon (RetroPie)" ; PACK_EXT="svg\|png" ;;
                    3) PACK_URL="https://github.com/anthonycaccese/es-theme-art-book/archive/refs/heads/master.zip"
                       PACK_NOME="Art Book" ; PACK_EXT="svg\|png" ;;
                    4) PACK_URL="https://github.com/fagnerpc/Alekfull-NX/archive/refs/heads/master.zip"
                       PACK_NOME="Alekfull NX" ; PACK_EXT="png\|svg" ;;
                    5) PACK_URL="https://github.com/lilbud/es-theme-switch/archive/refs/heads/master.zip"
                       PACK_NOME="Switch (lilbud)" ; PACK_EXT="png\|svg" ;;
                    6) PACK_URL="https://github.com/HVR88/Monochrome-Gaming-Logos/archive/refs/heads/master.zip"
                       PACK_NOME="Monochrome SVG" ; PACK_EXT="svg" ;;
                    *) continue ;;
                esac
                dialog --output-fd 1 --backtitle "$BT" --title " CONFIRMAR DOWNLOAD " \
                    --ok-label "BAIXAR" --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --msgbox "Pack: $PACK_NOME\n\nOs logos serao salvos em:\n$LOGOS_DIR\n\nO download pode demorar alguns\nminutos dependendo da conexao.\n\nDeseja continuar?" \
                    13 56 >"$CURR_TTY"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                printf "\033c" > "$CURR_TTY"
                printf "[*] Verificando conexao com a internet...\n" > "$CURR_TTY"

                if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
                    DIALOG_MSG "$BT" " SEM INTERNET " 9 55 \
                        "Sem conexao com a internet!\n\nConecte o R36S ao Wi-Fi\ne tente novamente."
                    continue
                fi

                # Verifica espaco livre antes de baixar (~50MB de margem)
                _LIVRE_KB=$(df -k "$LOGOS_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "0")
                if [ "$_LIVRE_KB" -lt 51200 ] 2>/dev/null; then
                    DIALOG_MSG "$BT" " ESPACO INSUFICIENTE " 10 58 \
                        "Espaco livre insuficiente para o download!\n\nLivre: $(( _LIVRE_KB / 1024 ))MB\nNecessario: ~50MB\n\nLibere espaco e tente novamente."
                    continue
                fi

                printf "[*] Baixando %s...\n" "$PACK_NOME" > "$CURR_TTY"
                printf "    Aguarde, isso pode levar alguns minutos.\n" > "$CURR_TTY"
                PACK_ZIP="/tmp/amthemes_pack_$$.zip"
                PACK_DIR="/tmp/amthemes_pack_$$"
                if wget -q \
                    --timeout=60 \
                    --tries=3 \
                    --user-agent="Mozilla/5.0 (Linux; Android)" \
                    -O "$PACK_ZIP" "$PACK_URL" 2>/dev/null \
                    && [ -s "$PACK_ZIP" ]; then
                    printf "[*] Extraindo logos...\n" > "$CURR_TTY"
                    mkdir -p "$PACK_DIR" 2>/dev/null || true
                    unzip -q "$PACK_ZIP" -d "$PACK_DIR" 2>/dev/null || true
                    # Salva em subpasta propria para que opcao 9 possa listar por pack
                    PACK_NOME_DIR=$(echo "$PACK_NOME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                    PACK_DEST_DIR="$LOGOS_DIR/$PACK_NOME_DIR"
                    mkdir -p "$PACK_DEST_DIR" 2>/dev/null || true
                    COPIADOS_P=0
                    while IFS= read -r -d '' img; do
                        DEST_NOME=$(basename "$img" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
                        cp "$img" "$PACK_DEST_DIR/$DEST_NOME" 2>/dev/null && \
                            COPIADOS_P=$(( COPIADOS_P + 1 ))
                    done < <(find "$PACK_DIR" -type f \
                        \( -iname "*.png" -o -iname "*.svg" \) \
                        -print0 2>/dev/null)
                    rm -rf "$PACK_ZIP" "$PACK_DIR" 2>/dev/null || true
                    DIALOG_MSG "$BT" " DOWNLOAD CONCLUIDO " 11 62 \
                        "Pack: $PACK_NOME\n$COPIADOS_P logo(s) salvo(s) em:\n$PACK_DEST_DIR\n\nUse a opcao 1 para instalar os logos."
                else
                    rm -f "$PACK_ZIP" 2>/dev/null || true
                    DIALOG_MSG "$BT" " ERRO NO DOWNLOAD " 11 62 \
                        "Falha ao baixar o pack!\n\nPossíveis causas:\n- Sem conexao com a internet\n- URL indisponivel temporariamente\n\nPack: $PACK_NOME\n\nTente outro pack ou tente mais tarde."
                fi
            fi

            if [ "$MENU_LOGO" = "8" ]; then
                mapfile -t LOGOS_TEMA < <(find "$TEMA_DIR" -type f \
                    \( -iname "*.png" -o -iname "*.svg" \) \
                    2>/dev/null | grep -i "logo\|system\|title" | sort)
                if [ ${#LOGOS_TEMA[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " LOGOS DO TEMA " 8 55 \
                        "Nenhum logo encontrado no tema."
                    continue
                fi
                INFO=""
                for f in "${LOGOS_TEMA[@]}"; do
                    TAM=$(du -sh "$f" 2>/dev/null | cut -f1 || echo "?")
                    INFO="${INFO}  ${TAM}  $(basename "$f")\n"
                done
                DIALOG_MSG "$BT" " LOGOS DO TEMA " 22 68 \
                    "Logos (${#LOGOS_TEMA[@]} total):\n\n${INFO}"
            fi

    
        # --------------------------------------------------
        # OPCAO 9 — Apagar Pack de Logos inteiro
        # --------------------------------------------------
        if [ "$MENU_LOGO" = "9" ]; then
            mapfile -t PACKS_DISP < <(find "$LOGOS_DIR" -maxdepth 1 \
                -mindepth 1 -type d 2>/dev/null | sort)
            if [ ${#PACKS_DISP[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " APAGAR PACK " 9 58 \
                    "Nenhum pack encontrado em:\n$LOGOS_DIR\n\nUse a opcao 7 para baixar packs."
                continue
            fi
            LISTA_PACK=(); IDX=1
            for pd in "${PACKS_DISP[@]}"; do
                NOME_PACK=$(basename "$pd")
                QTD=$(find "$pd" -type f \( -iname "*.png" -o -iname "*.svg" \) \
                    2>/dev/null | wc -l)
                LISTA_PACK+=("$IDX" "$NOME_PACK  ($QTD arquivo(s))")
                (( IDX++ ))
            done
            PACK_SEL=$(dialog --output-fd 1 \
                --backtitle "$BT" --title " APAGAR PACK DE LOGOS " \
                --ok-label "APAGAR" --cancel-label "CANCELAR" \
                --menu "Selecione o pack a apagar:" \
                20 68 8 "${LISTA_PACK[@]}" 2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && continue
            [ $RET -eq 3 ] && continue
            PACK_IDX=$(( PACK_SEL - 1 ))
            PACK_PATH="${PACKS_DISP[$PACK_IDX]}"
            PACK_NOME=$(basename "$PACK_PATH")
            QTD_PACK=$(find "$PACK_PATH" -type f \( -iname "*.png" -o -iname "*.svg" \) \
                2>/dev/null | wc -l)
            dialog --output-fd 1 \
                --backtitle "$BT" --title " CONFIRMAR EXCLUSAO " \
                --yes-label "APAGAR" --no-label "CANCELAR" \
                --yesno \
"Tem certeza que deseja apagar o pack:\n\n$PACK_NOME\n\n$QTD_PACK arquivo(s) serao removidos permanentemente." \
                10 60 2>"$CURR_TTY"
            [ $? -ne 0 ] && continue
            rm -rf "$PACK_PATH" 2>/dev/null
            DIALOG_MSG "$BT" " PACK APAGADO " 7 55 \
                "Pack removido com sucesso:\n$PACK_NOME"
            continue
        fi

        # --------------------------------------------------
        # OPCAO 10 — Apagar Logo Especifico
        # --------------------------------------------------
        if [ "$MENU_LOGO" = "10" ]; then
            mapfile -t LOGOS_USER < <(find "$LOGOS_DIR" -maxdepth 1 -type f \
                \( -iname "*.png" -o -iname "*.svg" -o -iname "*.jpg" \) \
                2>/dev/null | sort)
            if [ ${#LOGOS_USER[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " APAGAR LOGO " 8 58 \
                    "Nenhum logo encontrado em:\n$LOGOS_DIR\n\nInstale logos primeiro usando a opcao 1."
                continue
            fi
            LISTA_LOGO=(); IDX=1
            for lf in "${LOGOS_USER[@]}"; do
                NOME_L=$(basename "$lf")
                TAM_L=$(du -sh "$lf" 2>/dev/null | cut -f1 || echo "?")
                LISTA_LOGO+=("$IDX" "$NOME_L  ($TAM_L)")
                (( IDX++ ))
            done
            LOGO_SEL=$(dialog --output-fd 1 \
                --backtitle "$BT" --title " APAGAR LOGO ESPECIFICO " \
                --ok-label "APAGAR" --cancel-label "CANCELAR" \
                --menu "Selecione o logo a apagar:" \
                22 68 10 "${LISTA_LOGO[@]}" 2>"$CURR_TTY")
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && continue
            [ $RET -eq 3 ] && continue
            LOGO_IDX=$(( LOGO_SEL - 1 ))
            LOGO_PATH="${LOGOS_USER[$LOGO_IDX]}"
            LOGO_NOME=$(basename "$LOGO_PATH")
            dialog --output-fd 1 \
                --backtitle "$BT" --title " CONFIRMAR EXCLUSAO " \
                --yes-label "APAGAR" --no-label "CANCELAR" \
                --yesno \
"Tem certeza que deseja apagar o logo:\n\n$LOGO_NOME\n\nEsta acao nao pode ser desfeita." \
                9 58 2>"$CURR_TTY"
            [ $? -ne 0 ] && continue
            rm -f "$LOGO_PATH" 2>/dev/null
            DIALOG_MSG "$BT" " LOGO APAGADO " 7 50 \
                "Logo removido com sucesso:\n$LOGO_NOME"
            continue
        fi

    done
    fi  # fim if CATEGORIA=3
}
