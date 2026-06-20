# categoria_8 - Modulo de categoria
categoria_6() {
    if [ "$CATEGORIA" = "6" ]; then
        while true; do
            NUM_BACKUPS=$(find "$BACKUP_DIR" -maxdepth 1 \
                -name "${THEME_NAME}_*.xml" 2>/dev/null | wc -l)
            TOTAL_TAM=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "?")
            DISCO_LIVRE=$(df -h "$BACKUP_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
            DISCO_USO_PCT=$(df "$BACKUP_DIR" 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%' || echo "0")
            AGORA_BCK=$(date '+%d/%m/%Y %H:%M' 2>/dev/null || echo "")
            BAR_FILL=$(( DISCO_USO_PCT * 20 / 100 ))
            [ $BAR_FILL -gt 20 ] && BAR_FILL=20
            BAR_EMPTY=$(( 20 - BAR_FILL ))
            STORAGE_BAR="["
            for i in $(seq 1 $BAR_FILL);  do STORAGE_BAR+="#"; done
            for i in $(seq 1 $BAR_EMPTY); do STORAGE_BAR+="."; done
            STORAGE_BAR+="] ${DISCO_USO_PCT}% usado"
            ULTIMO_BAK_G=$(find "$BACKUP_DIR" -maxdepth 1 \
                -name "${THEME_NAME}_*.xml" 2>/dev/null | sort -r | head -1)
            [ -n "$ULTIMO_BAK_G" ] \
                && ULTIMO_INFO_G=$(stat -c "%y" "$ULTIMO_BAK_G" 2>/dev/null | cut -d'.' -f1 || echo "?") \
                || ULTIMO_INFO_G="Nenhum ainda"
            BT_BCK="Backup Center  |  Backups: $NUM_BACKUPS  |  Usado: $TOTAL_TAM  |  Livre: $DISCO_LIVRE  |  $AGORA_BCK"

            mapfile -t LISTA_XML < <(find "$BACKUP_DIR" -maxdepth 1 \
                -name "${THEME_NAME}_*.xml" 2>/dev/null | sort -r)

            MENU_GER=$(dialog --output-fd 1 \
                --backtitle "$BT_BCK" \
                --title " BACKUP CENTER " \
                --ok-label "SELECIONAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --menu \
"Disco: $STORAGE_BAR  |  Ultimo: $ULTIMO_INFO_G
-------------------------------------------------------
  SELECIONAR: confirmar   VOLTAR: voltar   SAIR: fechar
-------------------------------------------------------" \
                28 70 14 \
                1  "Criar Backup Agora           (com nota opcional)" \
                2  "Listar Backups               [$NUM_BACKUPS salvo(s) / $TOTAL_TAM]" \
                3  "Restaurar Backup" \
                4  "Comparar Backup com Atual" \
                5  "Restaurar Configuracao Especifica" \
                6  "Verificar Integridade (MD5)" \
                7  "Apagar Backup Especifico" \
                8  "Apagar Backups Antigos (manter N recentes)" \
                9  "Exportar para Pendrive" \
                10 "Historico de Alteracoes" \
                11 "Espaco Utilizado" \
                12 "Automacao (Backup ao abrir)" \
                13 "Agendamento de Backup" \
                14 "Backup Completo do Tema (.ZIP)" \
                2>"$CURR_TTY")
            RET=$?
            NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && break

            # ----------------------------------------------------------
            # OPÇÃO 1 - Criar Backup com Nota Opcional
            # ----------------------------------------------------------
            if [ "$MENU_GER" = "1" ]; then
                # Seletor de nota predefinida
                DIALOG_MENU NOTA_IDX \
                    "$BT" " ADICIONAR NOTA AO BACKUP (opcional) " \
                    18 62 8 \
                    0  "Sem nota" \
                    1  "Configuracao estavel" \
                    2  "Antes de alteracao" \
                    3  "Teste de cor" \
                    4  "Teste de fonte" \
                    5  "Backup de seguranca" \
                    6  "Apos atualizacao de tema" \
                    7  "Configuracao final"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                case "$NOTA_IDX" in
                    0) NOTA_BCK="" ;;
                    1) NOTA_BCK="configuracao-estavel" ;;
                    2) NOTA_BCK="antes-de-alteracao" ;;
                    3) NOTA_BCK="teste-de-cor" ;;
                    4) NOTA_BCK="teste-de-fonte" ;;
                    5) NOTA_BCK="backup-de-seguranca" ;;
                    6) NOTA_BCK="apos-atualizacao" ;;
                    7) NOTA_BCK="configuracao-final" ;;
                    *) NOTA_BCK="" ;;
                esac

                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                if [ -n "$NOTA_BCK" ]; then
                    DEST_XML="$BACKUP_DIR/${THEME_NAME}_${TIMESTAMP}_${NOTA_BCK}.xml"
                else
                    DEST_XML="$BACKUP_DIR/${THEME_NAME}_${TIMESTAMP}.xml"
                fi

                printf "\033c" > "$CURR_TTY"
                printf "[*] Salvando backup...\n" > "$CURR_TTY"

                HIST_FILE="$BACKUP_DIR/.historico_${THEME_NAME}.log"
                if cp "$XML_FILE" "$DEST_XML" 2>/dev/null; then
                    # Gera MD5 junto com o backup
                    md5sum "$DEST_XML" > "${DEST_XML}.md5" 2>/dev/null || true
                    NOTA_LOG="${NOTA_BCK:-sem nota}"
                    echo "[$(date '+%d/%m/%Y %H:%M:%S')] BACKUP CRIADO: $(basename "$DEST_XML") | Nota: $NOTA_LOG" \
                        >> "$HIST_FILE" 2>/dev/null || true
                    NUM_NOW=$(find "$BACKUP_DIR" -maxdepth 1 \
                        -name "${THEME_NAME}_*.xml" 2>/dev/null | wc -l)
                    DIALOG_MSG "$BT" " BACKUP CRIADO " 12 65 \
                        "Backup criado!\n\nArquivo: $(basename "$DEST_XML")\nNota   : ${NOTA_BCK:-nenhuma}\nTotal  : $NUM_NOW backup(s)\nMD5    : gerado automaticamente"
                else
                    DIALOG_MSG "$BT" " ERRO " 9 55 \
                        "Erro ao criar backup!\n\nVerifique permissoes em:\n$BACKUP_DIR"
                fi
            fi

            if [ "$MENU_GER" = "2" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " BACKUPS " 8 54 "Nenhum backup encontrado para '$THEME_NAME'."
                else
                    INFO=""
                    for f in "${LISTA_XML[@]}"; do
                        TAM_F=$(du -sh "$f" 2>/dev/null | cut -f1 || echo "?")
                        DATA_F=$(stat -c "%y" "$f" 2>/dev/null | cut -d'.' -f1 || echo "?")
                        INFO="${INFO}  $(basename "$f")  ($TAM_F)  $DATA_F\n"
                    done
                    DIALOG_MSG "$BT" " BACKUPS EXISTENTES " 22 72 \
                        "Backups (mais recente primeiro):\n\n${INFO}\nTotal: $NUM_BACKUPS / $TOTAL_TAM"
                fi
            fi

            if [ "$MENU_GER" = "3" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " RESTAURAR " 8 52 "Nenhum backup disponivel."
                    continue
                fi
                LISTA_REST=() ; IDX=1
                for f in "${LISTA_XML[@]}"; do
                    TAM_F=$(du -sh "$f" 2>/dev/null | cut -f1 || echo "?")
                    LISTA_REST+=("$IDX" "$(basename "$f")  ($TAM_F)") ; IDX=$((IDX+1))
                done
                DIALOG_MENU XML_IDX "$BT" " RESTAURAR BACKUP " 20 72 8 "${LISTA_REST[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                XML_ESCOLHIDO="${LISTA_XML[$((XML_IDX-1))]}"
                printf "\033c" > "$CURR_TTY"
                printf "[*] Restaurando: %s...\n" "$(basename "$XML_ESCOLHIDO")" > "$CURR_TTY"
                if cp "$XML_ESCOLHIDO" "$XML_FILE" 2>/dev/null; then
                    HIST_FILE="$BACKUP_DIR/.historico_${THEME_NAME}.log"
                    echo "[$(date '+%d/%m/%Y %H:%M:%S')] RESTAURADO: $(basename "$XML_ESCOLHIDO")" >> "$HIST_FILE" 2>/dev/null || true
                    DIALOG_MSG "$BT" " XML RESTAURADO " 10 65 \
                        "XML restaurado!\n\nBackup: $(basename "$XML_ESCOLHIDO")\n\nReinicie o ES para aplicar."
                    PerguntarReiniciar
                else
                    DIALOG_MSG "$BT" " ERRO " 9 55 "Erro ao restaurar!\n\nVerifique as permissoes."
                fi
            fi

            if [ "$MENU_GER" = "4" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " COMPARAR " 8 52 "Nenhum backup disponivel."
                    continue
                fi
                LISTA_CMP=() ; IDX=1
                for f in "${LISTA_XML[@]}"; do LISTA_CMP+=("$IDX" "$(basename "$f")") ; IDX=$((IDX+1)) ; done
                DIALOG_MENU CMP_IDX "$BT" " COMPARAR COM ATUAL " 20 72 8 "${LISTA_CMP[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                XML_CMP="${LISTA_XML[$((CMP_IDX-1))]}"
                printf "\033c" > "$CURR_TTY"
                printf "[*] Comparando arquivos...\n" > "$CURR_TTY"
                DIFF_COUNT=$(diff "$XML_CMP" "$XML_FILE" 2>/dev/null | grep -c "^[<>]" || echo "0")
                LINHAS_BAK=$(wc -l < "$XML_CMP" 2>/dev/null || echo "?")
                LINHAS_ATU=$(wc -l < "$XML_FILE" 2>/dev/null || echo "?")
                DIFF_TAGS=$(diff "$XML_CMP" "$XML_FILE" 2>/dev/null \
                    | grep "^[<>]" \
                    | grep -oE "<(color|fontSize|fontPath|textColor|selectedColor|backgroundColor|opacity)[^>]*>[^<]*</[^>]+>" \
                    | sort -u | head -10 || echo "Nenhuma diferenca de tag")
                if [ "$DIFF_COUNT" -eq 0 ] 2>/dev/null; then
                    DIALOG_MSG "$BT" " COMPARACAO " 10 60 "Arquivos IDENTICOS!\n\nNenhuma diferenca encontrada."
                else
                    DIALOG_MSG "$BT" " COMPARACAO " 18 68 \
"Backup: $(basename "$XML_CMP")
Linhas: backup=$LINHAS_BAK atual=$LINHAS_ATU
Linhas diferentes: $DIFF_COUNT

=== TAGS ALTERADAS ===
$DIFF_TAGS"
                fi
            fi

            if [ "$MENU_GER" = "5" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " RESTAURAR ESPECIFICO " 8 52 "Nenhum backup disponivel." ; continue
                fi
                LISTA_ESP=() ; IDX=1
                for f in "${LISTA_XML[@]}"; do LISTA_ESP+=("$IDX" "$(basename "$f")") ; IDX=$((IDX+1)) ; done
                DIALOG_MENU ESP_IDX "$BT" " ESCOLHA O BACKUP " 20 72 8 "${LISTA_ESP[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                XML_ESP="${LISTA_XML[$((ESP_IDX-1))]}"
                DIALOG_MENU OPCAO_ESP "$BT" " O QUE RESTAURAR " 16 60 6 \
                    1 "Cores de Fonte" 2 "Tamanho de Fonte" 3 "Fonte (fontPath)" \
                    4 "Cor de Fundo" 5 "Cor Selecionado" 6 "Opacidade"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                case "$OPCAO_ESP" in
                    1) TAGS_ESP="color|textColor|selectedColor" ; DESC_ESP="Cores de Fonte" ;;
                    2) TAGS_ESP="fontSize"                      ; DESC_ESP="Tamanho de Fonte" ;;
                    3) TAGS_ESP="fontPath"                      ; DESC_ESP="Fonte (fontPath)" ;;
                    4) TAGS_ESP="backgroundColor"               ; DESC_ESP="Cor de Fundo" ;;
                    5) TAGS_ESP="selectedColor|selectorColor"   ; DESC_ESP="Cor Selecionado" ;;
                    6) TAGS_ESP="opacity"                       ; DESC_ESP="Opacidade" ;;
                esac
                printf "\033c" > "$CURR_TTY"
                printf "[*] Restaurando %s do backup...\n" "$DESC_ESP" > "$CURR_TTY"
                while IFS= read -r linha; do
                    TAG=$(echo "$linha" | grep -oE "<[a-zA-Z]+>" | head -1 | tr -d '<>')
                    VALOR=$(echo "$linha" | grep -oE "<${TAG}>[^<]*</${TAG}>" | head -1)
                    [ -z "$VALOR" ] && continue
                    sed -i "s|<${TAG}>[^<]*</${TAG}>|${VALOR}|g" "$XML_FILE" 2>/dev/null || true
                done < <(grep -E "<(${TAGS_ESP})>" "$XML_ESP" 2>/dev/null | sort -u)
                DIALOG_MSG "$BT" " RESTAURACAO ESPECIFICA " 11 60 \
                    "Configuracao restaurada!\n\nOrigem: $(basename "$XML_ESP")\nConfigs: $DESC_ESP\n\nReinicie o ES para aplicar."
                PerguntarReiniciar
            fi

            if [ "$MENU_GER" = "7" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " APAGAR " 8 52 "Nenhum backup disponivel." ; continue
                fi
                LISTA_APG=() ; IDX=1
                for f in "${LISTA_XML[@]}"; do
                    TAM_F=$(du -sh "$f" 2>/dev/null | cut -f1 || echo "?")
                    LISTA_APG+=("$IDX" "$(basename "$f")  ($TAM_F)") ; IDX=$((IDX+1))
                done
                DIALOG_MENU APG_IDX "$BT" " APAGAR BACKUP " 20 72 8 "${LISTA_APG[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                XML_APG="${LISTA_XML[$((APG_IDX-1))]}"
                dialog --output-fd 1 --backtitle "$BT" --title " CONFIRMAR EXCLUSAO " \
                    --ok-label "APAGAR" --cancel-label "CANCELAR" \
                    --yesno "Apagar: $(basename "$XML_APG")?\n\nEsta acao nao pode ser desfeita!" \
                    9 58 >"$CURR_TTY"
                RET=$? ; NORM_RET ; [ $RET -ne 0 ] && continue
                rm -f "$XML_APG" 2>/dev/null && \
                    DIALOG_MSG "$BT" " APAGADO " 8 52 "Backup apagado!\n\n$(basename "$XML_APG")" || \
                    DIALOG_MSG "$BT" " ERRO " 8 52 "Erro ao apagar!\n\nVerifique as permissoes."
            fi

            if [ "$MENU_GER" = "8" ]; then
                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " LIMPAR " 8 52 "Nenhum backup para limpar." ; continue
                fi
                DIALOG_MENU MANTER_N "$BT" " QUANTOS MANTER " 14 58 5 \
                    1 "Manter apenas o mais recente (1)" \
                    3 "Manter os 3 mais recentes" \
                    5 "Manter os 5 mais recentes" \
                    10 "Manter os 10 mais recentes" \
                    0 "Apagar TODOS os backups"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                MANTER=$MANTER_N ; TOTAL=${#LISTA_XML[@]}
                APAGAR_QTD=$(( TOTAL - MANTER )) ; [ "$MANTER" = "0" ] && APAGAR_QTD=$TOTAL
                if [ $APAGAR_QTD -le 0 ]; then
                    DIALOG_MSG "$BT" " LIMPAR " 9 55 "Nada a remover.\nVoce tem $TOTAL backup(s) e quer manter $MANTER."
                    continue
                fi
                dialog --output-fd 1 --backtitle "$BT" --title " CONFIRMAR LIMPEZA " \
                    --ok-label "APAGAR" --cancel-label "CANCELAR" \
                    --yesno "Apagar $APAGAR_QTD backup(s)?\nManter os $MANTER mais recentes." \
                    8 52 >"$CURR_TTY"
                RET=$? ; NORM_RET ; [ $RET -ne 0 ] && continue
                printf "\033c" > "$CURR_TTY" ; printf "[*] Removendo backups antigos...\n" > "$CURR_TTY"
                mapfile -t LISTA_ASC < <(find "$BACKUP_DIR" -maxdepth 1 -name "${THEME_NAME}_*.xml" 2>/dev/null | sort)
                [ "$MANTER" = "0" ] && PARA_APAGAR=("${LISTA_ASC[@]}") || PARA_APAGAR=("${LISTA_ASC[@]:0:$APAGAR_QTD}")
                REMOVIDOS=0 ; HIST_FILE="$BACKUP_DIR/.historico_${THEME_NAME}.log"
                for f in "${PARA_APAGAR[@]}"; do
                    rm -f "$f" 2>/dev/null && { REMOVIDOS=$(( REMOVIDOS+1 ))
                        echo "[$(date '+%d/%m/%Y %H:%M:%S')] APAGADO: $(basename "$f")" >> "$HIST_FILE" 2>/dev/null || true ; }
                done
                DIALOG_MSG "$BT" " LIMPEZA CONCLUIDA " 10 55 \
                    "Limpeza concluida!\n\n$REMOVIDOS backup(s) removido(s)\nMantidos: $MANTER"
            fi

            if [ "$MENU_GER" = "9" ]; then
                mapfile -t PENDRIVES < <(find /media /mnt -maxdepth 2 -type d -writable 2>/dev/null \
                    | grep -v "^/mnt/user\|^/media$\|^/mnt$")
                if [ ${#PENDRIVES[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " EXPORTAR " 10 60 \
                        "Nenhum pendrive detectado!\n\nConecte um pendrive e tente novamente."
                    continue
                fi
                LISTA_PD=() ; IDX=1
                for pd in "${PENDRIVES[@]}"; do
                    ESP_PD=$(df -h "$pd" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
                    LISTA_PD+=("$IDX" "$pd  (livre: $ESP_PD)") ; IDX=$((IDX+1))
                done
                DIALOG_MENU PD_IDX "$BT" " ESCOLHA O DESTINO " 14 68 5 "${LISTA_PD[@]}"
                RET=$? ; NORM_RET ; [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue
                PD_DEST="${PENDRIVES[$((PD_IDX-1))]}/darkos_backups"
                mkdir -p "$PD_DEST" 2>/dev/null || true
                printf "\033c" > "$CURR_TTY" ; printf "[*] Exportando backups...\n" > "$CURR_TTY"
                EXPORTADOS=0
                for f in "${LISTA_XML[@]}"; do cp "$f" "$PD_DEST/" 2>/dev/null && EXPORTADOS=$((EXPORTADOS+1)) ; done
                DIALOG_MSG "$BT" " EXPORTACAO " 11 62 \
                    "$EXPORTADOS arquivo(s) exportado(s)\nDestino: $PD_DEST"
            fi

            if [ "$MENU_GER" = "10" ]; then
                HIST_FILE="$BACKUP_DIR/.historico_${THEME_NAME}.log"
                if [ ! -f "$HIST_FILE" ] || [ ! -s "$HIST_FILE" ]; then
                    DIALOG_MSG "$BT" " HISTORICO " 9 55 \
                        "Nenhum historico encontrado.\n\nO historico e gerado automaticamente."
                    continue
                fi
                HIST_INFO=$(tail -30 "$HIST_FILE" 2>/dev/null | tac)
                TOTAL_ENTRADAS=$(wc -l < "$HIST_FILE" 2>/dev/null || echo "?")
                DIALOG_MSG "$BT" " HISTORICO " 24 72 \
                    "Historico ($TOTAL_ENTRADAS entrada(s)):\n\n${HIST_INFO}"
            fi

            if [ "$MENU_GER" = "11" ]; then
                printf "\033c" > "$CURR_TTY" ; printf "[*] Calculando espaco...\n" > "$CURR_TTY"
                TAM_TOTAL=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "?")
                TAM_BYTES=$(du -sb "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
                TAM_MB=$(( TAM_BYTES / 1024 / 1024 ))
                NUM_XML=$(find "$BACKUP_DIR" -maxdepth 1 -name "${THEME_NAME}_*.xml" 2>/dev/null | wc -l)
                DISCO_LIVRE_E=$(df -h "$BACKUP_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
                MAIOR=$(find "$BACKUP_DIR" -maxdepth 1 -name "${THEME_NAME}_*.xml" 2>/dev/null \
                    | xargs du -sh 2>/dev/null | sort -rh | head -1 || echo "?")
                MENOR=$(find "$BACKUP_DIR" -maxdepth 1 -name "${THEME_NAME}_*.xml" 2>/dev/null \
                    | xargs du -sh 2>/dev/null | sort -h | head -1 || echo "?")
                DIALOG_MSG "$BT" " ESPACO DOS BACKUPS " 16 62 \
"Total de backups : $NUM_XML
Espaco ocupado   : $TAM_TOTAL (~${TAM_MB}MB)
Disco disponivel : $DISCO_LIVRE_E
Pasta: $BACKUP_DIR
Maior: $MAIOR
Menor: $MENOR"
            fi

            # ----------------------------------------------------------
            # OPÇÃO 6 - Verificar Integridade (MD5)
            # ----------------------------------------------------------
            if [ "$MENU_GER" = "6" ]; then
                mapfile -t LISTA_XML < <(find "$BACKUP_DIR" -maxdepth 1 \
                    -name "${THEME_NAME}_*.xml" 2>/dev/null | sort -r)

                if [ ${#LISTA_XML[@]} -eq 0 ]; then
                    DIALOG_MSG "$BT" " MD5 " 8 52 \
                        "Nenhum backup encontrado para verificar."
                    continue
                fi

                printf "\033c" > "$CURR_TTY"
                printf "[*] Verificando integridade dos backups...\n" > "$CURR_TTY"

                INFO_MD5="" ; OK_COUNT=0 ; FAIL_COUNT=0
                for f in "${LISTA_XML[@]}"; do
                    NOME_F=$(basename "$f")
                    MD5_FILE="${f}.md5"

                    if [ -f "$MD5_FILE" ]; then
                        # Verifica checksum existente
                        if md5sum -c "$MD5_FILE" >/dev/null 2>&1; then
                            INFO_MD5="${INFO_MD5}  OK      $NOME_F\n"
                            OK_COUNT=$(( OK_COUNT + 1 ))
                        else
                            INFO_MD5="${INFO_MD5}  FALHOU  $NOME_F\n"
                            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
                        fi
                    else
                        # Gera MD5 se não existir
                        md5sum "$f" > "$MD5_FILE" 2>/dev/null || true
                        INFO_MD5="${INFO_MD5}  GERADO  $NOME_F\n"
                        OK_COUNT=$(( OK_COUNT + 1 ))
                    fi
                done

                DIALOG_MSG "$BT" " VERIFICACAO DE INTEGRIDADE " 22 68 \
"Resultado da verificacao MD5:

${INFO_MD5}
OK     : $OK_COUNT backup(s) integro(s)
FALHOU : $FAIL_COUNT backup(s) corrompido(s)

Backups com FALHOU devem ser descartados."
            fi

            # ----------------------------------------------------------
            # OPÇÃO 12 - Automacao (Backup ao abrir)
            # ----------------------------------------------------------
            if [ "$MENU_GER" = "12" ]; then
                FLAG_AUTO="$BACKUP_DIR/.auto_backup_enabled"
                if [ -f "$FLAG_AUTO" ]; then
                    ESTADO_AUTO="ATIVADO"
                else
                    ESTADO_AUTO="DESATIVADO"
                fi

                DIALOG_MENU OPCAO_AUTO \
                    "$BT" " BACKUP AUTOMATICO " \
                    14 62 3 \
                    1 "Ativar backup automatico ao abrir    [ATIVADO=$([[ -f $FLAG_AUTO ]] && echo SIM || echo NAO)]" \
                    2 "Desativar backup automatico" \
                    3 "Status atual: $ESTADO_AUTO"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                case "$OPCAO_AUTO" in
                    1)
                        touch "$FLAG_AUTO" 2>/dev/null || true
                        DIALOG_MSG "$BT" " AUTOMACAO " 10 58 \
                            "Backup automatico ATIVADO!\n\nUm backup do XML sera criado\nautomaticamente sempre que o\nAlter_MThemes for aberto." ;;
                    2)
                        rm -f "$FLAG_AUTO" 2>/dev/null || true
                        DIALOG_MSG "$BT" " AUTOMACAO " 9 55 \
                            "Backup automatico DESATIVADO!\n\nO backup manual continua disponivel." ;;
                    3)
                        DIALOG_MSG "$BT" " STATUS " 9 55 \
                            "Backup automatico: $ESTADO_AUTO\n\nFlag: $FLAG_AUTO" ;;
                esac
            fi

            # ----------------------------------------------------------
            # OPÇÃO 13 - Agendamento de Backup
            # ----------------------------------------------------------
            if [ "$MENU_GER" = "13" ]; then
                SCHED_FILE="$BACKUP_DIR/.backup_schedule"
                SCHED_ATUAL=$([ -f "$SCHED_FILE" ] && cat "$SCHED_FILE" || echo "desativado")

                DIALOG_MENU OPCAO_SCHED \
                    "$BT" " AGENDAMENTO DE BACKUP " \
                    16 65 5 \
                    1 "A cada abertura do Alter_MThemes" \
                    2 "Diario (1 backup por dia)" \
                    3 "Semanal (1 backup por semana)" \
                    4 "Desativar agendamento" \
                    5 "Status atual: $SCHED_ATUAL"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && continue

                case "$OPCAO_SCHED" in
                    1)
                        echo "abertura" > "$SCHED_FILE"
                        touch "$BACKUP_DIR/.auto_backup_enabled" 2>/dev/null || true
                        DESC_SCHED="A cada abertura" ;;
                    2)
                        echo "diario" > "$SCHED_FILE"
                        DESC_SCHED="Diario" ;;
                    3)
                        echo "semanal" > "$SCHED_FILE"
                        DESC_SCHED="Semanal" ;;
                    4)
                        rm -f "$SCHED_FILE" \
                              "$BACKUP_DIR/.auto_backup_enabled" 2>/dev/null || true
                        DIALOG_MSG "$BT" " AGENDAMENTO " 9 55 \
                            "Agendamento desativado!"
                        continue ;;
                    5)
                        DIALOG_MSG "$BT" " AGENDAMENTO " 9 55 \
                            "Agendamento atual: $SCHED_ATUAL"
                        continue ;;
                    *) continue ;;
                esac

                DIALOG_MSG "$BT" " AGENDAMENTO CONFIGURADO " 11 60 \
                    "Agendamento: $DESC_SCHED\n\nO backup sera criado automaticamente\nconforme o intervalo escolhido ao\nabrir o Alter_MThemes."
            fi

            # ----------------------------------------------------------
            # OPÇÃO 14 - Backup Completo do Tema (.ZIP)
            # ----------------------------------------------------------
            if [ "$MENU_GER" = "14" ]; then
                TEMA_DIR="/etc/emulationstation/themes"
                ZIP_DEST="$BACKUP_DIR"
                DATA=$(date +"%Y%m%d_%H%M%S")
                ZIP_FILE="${ZIP_DEST}/${THEME_NAME}_tema_completo_${DATA}.zip"

                # Verifica se o diretório de temas existe
                if [ ! -d "$TEMA_DIR" ]; then
                    DIALOG_MSG "$BT" " BACKUP DO TEMA " 9 58 \
                        "Diretorio de temas nao encontrado:\n\n${TEMA_DIR}\n\nVerifique a instalacao do ES."
                    continue
                fi

                TEMA_TAM=$(du -sh "$TEMA_DIR" 2>/dev/null | cut -f1 || echo "?")
                TEMA_NOME=$(ls "$TEMA_DIR" 2>/dev/null | head -5 | tr '\n' ' ' || echo "?")
                DISCO_LIVRE_Z=$(df -h "$ZIP_DEST" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")

                dialog --output-fd 1 \
                    --backtitle "$BT_BCK" --title " BACKUP COMPLETO DO TEMA (.ZIP) " \
                    --ok-label "FAZER BACKUP" --extra-button --extra-label "VOLTAR" \
                    --cancel-label "SAIR" \
                    --msgbox "Origem : ${TEMA_DIR}\nTamanho: ~${TEMA_TAM}\nTemas  : ${TEMA_NOME}\n\nDestino: ${ZIP_FILE}\nLivre  : ${DISCO_LIVRE_Z}\n\nConfirma o backup completo do tema?" \
                    15 68 >"$CURR_TTY"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll ; [ $RET -eq 3 ] && continue

                mkdir -p "$ZIP_DEST" 2>/dev/null
                if [ ! -d "$ZIP_DEST" ]; then
                    DIALOG_MSG "$BT" " BACKUP DO TEMA " 9 55 \
                        "Nao foi possivel criar o diretorio de destino:\n\n${ZIP_DEST}"
                    continue
                fi

                printf "\033c" > "$CURR_TTY"
                printf "[*] Criando backup completo do tema...\n" > "$CURR_TTY"
                printf "    Origem : %s\n" "$TEMA_DIR" > "$CURR_TTY"
                printf "    Destino: %s\n" "$ZIP_FILE" > "$CURR_TTY"

                if zip -r "$ZIP_FILE" "$TEMA_DIR" >/dev/null 2>&1; then
                    ZIP_TAM=$(du -sh "$ZIP_FILE" 2>/dev/null | cut -f1 || echo "?")
                    # Registra no histórico
                    HIST_FILE="$BACKUP_DIR/.historico_${THEME_NAME}.log"
                    echo "[$(date '+%d/%m/%Y %H:%M:%S')] BACKUP ZIP DO TEMA: $(basename "$ZIP_FILE") | Tamanho: ~${ZIP_TAM}" \
                        >> "$HIST_FILE" 2>/dev/null || true
                    DIALOG_MSG "$BT" " BACKUP CONCLUIDO " 12 68 \
                        "Backup do tema criado com sucesso!\n\nArquivo : $(basename "$ZIP_FILE")\nTamanho : ~${ZIP_TAM}\nLocal   : ${ZIP_DEST}"
                else
                    rm -f "$ZIP_FILE" 2>/dev/null
                    DIALOG_MSG "$BT" " ERRO NO BACKUP " 9 58 \
                        "Falha ao criar o backup do tema!\n\nVerifique o espaco em disco\ne as permissoes do diretorio:\n${ZIP_DEST}"
                fi
            fi

        done  # fim while categoria 6
    fi  # fim if CATEGORIA=6
}
