# cat_7_otimizacao.sh - Central de Otimizacao do Sistema

categoria_7() {
    while true; do

        # Status rápido para o backtitle
        MEM_LIVRE=$(free -m 2>/dev/null | awk '/^Mem:/{print $4}' || echo "?")
        DISCO_LIVRE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
        BT_OTM="Alter_MThemes v7.0 | Otimizacao | RAM livre: ${MEM_LIVRE}MB | Disco livre: ${DISCO_LIVRE}"

        DIALOG_MENU MENU_OTM \
            "$BT_OTM" " CENTRAL DE OTIMIZACAO DO SISTEMA " \
            26 70 11 \
            1  "Limpar Cache do ES" \
            2  "Remover Arquivos Temporarios" \
            3  "Corrigir Permissoes (pastas)" \
            4  "Corrigir Permissoes de Arquivos (chmod)" \
            5  "Limpar Imagens Soltas (Orfas)" \
            6  "Reindexar Jogos" \
            7  "Reparar Gamelists" \
            8  "Reinicializacao Tecnica" \
            9  "Atualizar Temas" \
            10 "Atualizar Overlays" \
            11 "Executar Otimizacao Completa"
        RET=$?
        NORM_RET
        [ $RET -eq 1 ] && ExitAll
        [ $RET -eq 3 ] && break

        # ----------------------------------------------------------
        # OPÇÃO 1 - Limpar Cache do ES
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "1" ]; then
            CACHE_DIRS=(
                "/home/ark/.emulationstation/downloaded_images"
                "/home/ark/.emulationstation/downloaded_videos"
                "/home/ark/.emulationstation/.emulationstation_logo_cache"
                "/tmp/emulationstation"
                "/var/tmp/emulationstation"
            )

            printf "\033c" > "$CURR_TTY"
            printf "[*] Calculando cache...\n" > "$CURR_TTY"

            INFO_C="" ; TOTAL_C=0
            for d in "${CACHE_DIRS[@]}"; do
                if [ -e "$d" ]; then
                    TAM_C=$(du -sh "$d" 2>/dev/null | cut -f1 || echo "0")
                    INFO_C="${INFO_C}  $TAM_C  $(basename "$d")\n"
                    BYTES_C=$(du -sb "$d" 2>/dev/null | cut -f1 || echo "0")
                    TOTAL_C=$(( TOTAL_C + BYTES_C ))
                fi
            done
            TOTAL_MB=$(( TOTAL_C / 1024 / 1024 ))

            if [ -z "$INFO_C" ]; then
                DIALOG_MSG "$BT" " CACHE " 9 55 \
                    "Cache ja esta limpo!\n\nNenhum arquivo de cache encontrado."
                continue
            fi

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " LIMPAR CACHE DO ES " \
                --ok-label "LIMPAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox "Cache encontrado:\n\n${INFO_C}\nTotal: ~${TOTAL_MB}MB\n\nLIMPAR remove estes arquivos.\nO ES vai baixar as imagens novamente." \
                16 60 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Limpando cache...\n" > "$CURR_TTY"

            REMOVIDOS=0
            for d in "${CACHE_DIRS[@]}"; do
                if [ -e "$d" ]; then
                    rm -rf "$d" 2>/dev/null && REMOVIDOS=$(( REMOVIDOS + 1 ))
                    printf "  Removido: %s\n" "$(basename "$d")" > "$CURR_TTY"
                fi
            done

            DIALOG_MSG "$BT" " CACHE LIMPO " 10 55 \
                "Cache limpo!\n\n$REMOVIDOS pasta(s) removida(s)\nEspaco liberado: ~${TOTAL_MB}MB\n\nReinicie o ES para reindexar."
            PerguntarReiniciar
        fi

        # ----------------------------------------------------------
        # OPÇÃO 2 - Remover Arquivos Temporários
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "2" ]; then
            TEMP_DIRS=(
                "/tmp"
                "/var/tmp"
                "/home/ark/.emulationstation/tmp"
                "/home/ark/darkos_backups/.tmp"
            )
            TEMP_PADROES=(
                "*.tmp"
                "*.log"
                "*.pid"
                "core.*"
                "*.crash"
            )

            printf "\033c" > "$CURR_TTY"
            printf "[*] Buscando arquivos temporarios...\n" > "$CURR_TTY"

            TOTAL_TEMP=0
            INFO_TEMP=""
            for d in "${TEMP_DIRS[@]}"; do
                [ ! -d "$d" ] && continue
                for p in "${TEMP_PADROES[@]}"; do
                    COUNT=$(find "$d" -maxdepth 2 -name "$p" \
                        2>/dev/null | wc -l)
                    [ "$COUNT" -gt 0 ] && \
                        INFO_TEMP="${INFO_TEMP}  $COUNT arquivo(s) $p em $(basename $d)\n"
                    TOTAL_TEMP=$(( TOTAL_TEMP + COUNT ))
                done
            done

            if [ "$TOTAL_TEMP" -eq 0 ]; then
                DIALOG_MSG "$BT" " TEMPORARIOS " 9 55 \
                    "Nenhum arquivo temporario encontrado!\n\nO sistema esta limpo."
                continue
            fi

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " REMOVER TEMPORARIOS " \
                --ok-label "REMOVER" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox "Arquivos temporarios encontrados:\n\n${INFO_TEMP}\nTotal: $TOTAL_TEMP arquivo(s)\n\nDeseja remover?" \
                18 62 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Removendo arquivos temporarios...\n" > "$CURR_TTY"

            REMOVIDOS_T=0
            for d in "${TEMP_DIRS[@]}"; do
                [ ! -d "$d" ] && continue
                for p in "${TEMP_PADROES[@]}"; do
                    while IFS= read -r -d '' f; do
                        rm -f "$f" 2>/dev/null && \
                            REMOVIDOS_T=$(( REMOVIDOS_T + 1 ))
                    done < <(find "$d" -maxdepth 2 -name "$p" \
                        -print0 2>/dev/null)
                done
            done

            DIALOG_MSG "$BT" " TEMPORARIOS REMOVIDOS " 9 55 \
                "Concluido!\n\n$REMOVIDOS_T arquivo(s) removido(s)."
        fi

        # ----------------------------------------------------------
        # OPÇÃO 3 - Corrigir Permissões
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "3" ]; then
            DIALOG_MENU OPCAO_PERM \
                "$BT" " CORRIGIR PERMISSOES " \
                16 65 5 \
                1 "Pastas do Alter_MThemes (backups/logos/fontes)" \
                2 "Pasta de ROMs /roms" \
                3 "Pasta do ES /home/ark/.emulationstation" \
                4 "Scripts em /opt/system/Tools" \
                5 "Tudo acima (correcao completa)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Corrigindo permissoes...\n" > "$CURR_TTY"

            case "$OPCAO_PERM" in
                1)
                    for d in "/home/ark/darkos_backups" \
                             "/home/ark/darkos_wallpapers" \
                             "/home/ark/darkos_fonts" \
                             "/home/ark/darkos_logos"; do
                        [ -d "$d" ] && chown -R ark:ark "$d" 2>/dev/null \
                            && chmod -R 755 "$d" 2>/dev/null \
                            && printf "  OK: %s\n" "$d" > "$CURR_TTY" || true
                    done
                    DESC_PERM="Pastas do Alter_MThemes" ;;
                2)
                    chown -R ark:ark /roms 2>/dev/null || true
                    find /roms -type d -exec chmod 755 {} \; 2>/dev/null || true
                    find /roms -type f -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_PERM="Pasta de ROMs" ;;
                3)
                    chown -R ark:ark /home/ark/.emulationstation 2>/dev/null || true
                    find /home/ark/.emulationstation -type d \
                        -exec chmod 755 {} \; 2>/dev/null || true
                    find /home/ark/.emulationstation -type f \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_PERM="Pasta do ES" ;;
                4)
                    find /opt/system/Tools -name "*.sh" \
                        -exec chmod +x {} \; 2>/dev/null || true
                    DESC_PERM="Scripts em /opt/system/Tools" ;;
                5)
                    for d in "/home/ark/darkos_backups" \
                             "/home/ark/darkos_wallpapers" \
                             "/home/ark/darkos_fonts" \
                             "/home/ark/darkos_logos"; do
                        [ -d "$d" ] && chown -R ark:ark "$d" 2>/dev/null \
                            && chmod -R 755 "$d" 2>/dev/null || true
                    done
                    chown -R ark:ark /home/ark/.emulationstation 2>/dev/null || true
                    find /home/ark/.emulationstation -type d \
                        -exec chmod 755 {} \; 2>/dev/null || true
                    find /home/ark/.emulationstation -type f \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    find /opt/system/Tools -name "*.sh" \
                        -exec chmod +x {} \; 2>/dev/null || true
                    DESC_PERM="Correcao completa" ;;
                *) continue ;;
            esac

            DIALOG_MSG "$BT" " PERMISSOES CORRIGIDAS " 9 55 \
                "Permissoes corrigidas!\n\nEscopo: $DESC_PERM"
        fi

        # ----------------------------------------------------------
        # OPÇÃO 4 - Corrigir Permissões de Arquivos (Chmod)
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "4" ]; then
            DIALOG_MENU OPCAO_CHMOD \
                "$BT" " CORRIGIR PERMISSOES DE ARQUIVOS " \
                18 68 6 \
                1 "ROMs          chmod 644 (somente leitura)" \
                2 "Scripts .sh   chmod 755 (executavel)" \
                3 "Configs .xml  chmod 644 (somente leitura)" \
                4 "Fontes .ttf   chmod 644 (somente leitura)" \
                5 "Tudo acima    (correcao completa de arquivos)" \
                6 "Custom        (escolher pasta e permissao)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Corrigindo permissoes de arquivos...\n" > "$CURR_TTY"

            case "$OPCAO_CHMOD" in
                1)
                    find /roms -type f 2>/dev/null \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_CHM="ROMs — chmod 644" ;;
                2)
                    find /opt/system/Tools /home/ark -name "*.sh" \
                        -type f 2>/dev/null \
                        -exec chmod 755 {} \; 2>/dev/null || true
                    DESC_CHM="Scripts .sh — chmod 755" ;;
                3)
                    find /home/ark/.emulationstation -name "*.xml" \
                        -type f 2>/dev/null \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_CHM="Configs .xml — chmod 644" ;;
                4)
                    find /home/ark/darkos_fonts -name "*.ttf" \
                        -o -name "*.otf" 2>/dev/null \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_CHM="Fontes .ttf/.otf — chmod 644" ;;
                5)
                    find /roms -type f 2>/dev/null \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    find /opt/system/Tools /home/ark -name "*.sh" \
                        -type f 2>/dev/null \
                        -exec chmod 755 {} \; 2>/dev/null || true
                    find /home/ark/.emulationstation -name "*.xml" \
                        -type f 2>/dev/null \
                        -exec chmod 644 {} \; 2>/dev/null || true
                    DESC_CHM="Correcao completa de arquivos" ;;
                6)
                    # Escolhe pasta
                    DIALOG_MENU PASTA_CHMOD \
                        "$BT" " ESCOLHA A PASTA " \
                        14 62 5 \
                        1 "/roms" \
                        2 "/home/ark/.emulationstation" \
                        3 "/home/ark/darkos_backups" \
                        4 "/opt/system/Tools" \
                        5 "/home/ark"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$PASTA_CHMOD" in
                        1) PASTA_ALV="/roms" ;;
                        2) PASTA_ALV="/home/ark/.emulationstation" ;;
                        3) PASTA_ALV="/home/ark/darkos_backups" ;;
                        4) PASTA_ALV="/opt/system/Tools" ;;
                        5) PASTA_ALV="/home/ark" ;;
                        *) continue ;;
                    esac
                    # Escolhe permissão
                    DIALOG_MENU PERM_CHMOD \
                        "$BT" " ESCOLHA A PERMISSAO " \
                        13 55 4 \
                        1 "644 — leitura/escrita dono, leitura outros" \
                        2 "755 — executavel pelo dono" \
                        3 "777 — todos podem tudo (cuidado!)" \
                        4 "600 — somente dono le e escreve"
                    RET=$? ; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue
                    case "$PERM_CHMOD" in
                        1) PERM_VAL="644" ;;
                        2) PERM_VAL="755" ;;
                        3) PERM_VAL="777" ;;
                        4) PERM_VAL="600" ;;
                        *) continue ;;
                    esac
                    find "$PASTA_ALV" -type f 2>/dev/null \
                        -exec chmod "$PERM_VAL" {} \; 2>/dev/null || true
                    DESC_CHM="$PASTA_ALV — chmod $PERM_VAL" ;;
                *) continue ;;
            esac

            DIALOG_MSG "$BT" " CHMOD APLICADO " 9 58 \
                "Permissoes de arquivos corrigidas!\n\nEscopo: $DESC_CHM"
        fi

        # ----------------------------------------------------------
        # OPÇÃO 5 - Limpar Imagens Soltas (Orfãs)
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "5" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Buscando imagens orfas...\n" > "$CURR_TTY"

            IMG_DIR="/home/ark/.emulationstation/downloaded_images"

            if [ ! -d "$IMG_DIR" ]; then
                DIALOG_MSG "$BT" " IMAGENS ORFAS " 9 55 \
                    "Pasta de imagens nao encontrada.\n\nO ES ainda nao baixou imagens."
                continue
            fi

            # Coleta todos os paths de imagem referenciados nas gamelists
            printf "[*] Lendo gamelists...\n" > "$CURR_TTY"
            REFS_FILE="/tmp/amthemes_refs_$$.txt"
            find /home/ark/.emulationstation -name "gamelist.xml" \
                2>/dev/null \
                | xargs grep -hE "<(image|thumbnail|marquee)>" 2>/dev/null \
                | grep -oE '[^<>]+\.(png|jpg|jpeg|svg)' \
                | xargs -I{} basename {} 2>/dev/null \
                | sort -u > "$REFS_FILE"

            # Lista imagens existentes na pasta
            mapfile -t IMGS_DISK < <(find "$IMG_DIR" -maxdepth 2 \
                -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) \
                2>/dev/null | sort)

            ORFAS=()
            for img in "${IMGS_DISK[@]}"; do
                NOME_IMG=$(basename "$img")
                if ! grep -qF "$NOME_IMG" "$REFS_FILE" 2>/dev/null; then
                    ORFAS+=("$img")
                fi
            done
            rm -f "$REFS_FILE" 2>/dev/null || true

            TOTAL_ORFAS=${#ORFAS[@]}
            TAM_ORFAS=0
            for f in "${ORFAS[@]}"; do
                B=$(du -sb "$f" 2>/dev/null | cut -f1 || echo "0")
                TAM_ORFAS=$(( TAM_ORFAS + B ))
            done
            TAM_ORFAS_MB=$(( TAM_ORFAS / 1024 / 1024 ))

            if [ "$TOTAL_ORFAS" -eq 0 ]; then
                DIALOG_MSG "$BT" " IMAGENS ORFAS " 9 55 \
                    "Nenhuma imagem orfa encontrada!\n\nTodas as imagens estao referenciadas\nnas gamelists."
                continue
            fi

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " IMAGENS ORFAS " \
                --ok-label "REMOVER" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Imagens sem jogo correspondente:

  Total encontrado : $TOTAL_ORFAS imagem(ns)
  Espaco ocupado   : ~${TAM_ORFAS_MB}MB

Estas imagens existem na pasta de cache
mas nao aparecem em nenhuma gamelist.

REMOVER vai apaga-las permanentemente." \
                16 60 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Removendo imagens orfas...\n" > "$CURR_TTY"

            REMOVIDOS_ORF=0
            for f in "${ORFAS[@]}"; do
                rm -f "$f" 2>/dev/null && REMOVIDOS_ORF=$(( REMOVIDOS_ORF + 1 ))
            done

            DIALOG_MSG "$BT" " ORFAS REMOVIDAS " 10 55 \
                "Imagens orfas removidas!\n\n$REMOVIDOS_ORF imagem(ns) apagada(s)\nEspaco liberado: ~${TAM_ORFAS_MB}MB"
        fi

        # ----------------------------------------------------------
        # OPÇÃO 8 - Reinicialização Técnica
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "8" ]; then
            DIALOG_MENU OPCAO_RESTART \
                "$BT" " REINICIALIZACAO TECNICA " \
                14 65 4 \
                1 "Reiniciar apenas o EmulationStation" \
                2 "Recarregar Lista de Jogos (sem reiniciar)" \
                3 "Matar e reiniciar ES forcado" \
                4 "Reiniciar o sistema completo (R36S)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"

            case "$OPCAO_RESTART" in
                1)
                    printf "[*] Reiniciando EmulationStation...\n" > "$CURR_TTY"
                    sleep 1
                    sudo systemctl restart emulationstation 2>/dev/null \
                        || sudo /etc/init.d/S09emulationstation restart 2>/dev/null \
                        || true
                    ExitAll ;;
                2)
                    printf "[*] Recarregando lista de jogos...\n" > "$CURR_TTY"
                    # Força o ES a reler as gamelists enviando sinal SIGUSR1
                    ES_PID=$(pgrep -f emulationstation 2>/dev/null | head -1)
                    if [ -n "$ES_PID" ]; then
                        kill -SIGUSR1 "$ES_PID" 2>/dev/null || true
                        printf "[*] Sinal enviado ao ES (PID: %s)\n" "$ES_PID" > "$CURR_TTY"
                        sleep 1
                        DIALOG_MSG "$BT" " LISTA RECARREGADA " 9 55 \
                            "Sinal de recarga enviado!\n\nPID: $ES_PID\n\nO ES deve recarregar as listas em breve."
                    else
                        DIALOG_MSG "$BT" " ERRO " 9 55 \
                            "EmulationStation nao esta em execucao!\n\nInicie o ES primeiro."
                    fi ;;
                3)
                    printf "[*] Matando ES e reiniciando...\n" > "$CURR_TTY"
                    sleep 1
                    pkill -9 -f emulationstation 2>/dev/null || true
                    sleep 2
                    sudo systemctl start emulationstation 2>/dev/null \
                        || sudo /etc/init.d/S09emulationstation start 2>/dev/null \
                        || true
                    ExitAll ;;
                4)
                    dialog --output-fd 1 \
                        --backtitle "$BT" \
                        --title " REINICIAR R36S " \
                        --ok-label "REINICIAR" \
                        --cancel-label "CANCELAR" \
                        --yesno "Tem certeza que deseja reiniciar\no sistema completo do R36S?" \
                        8 50 >"$CURR_TTY"
                    RET=$? ; NORM_RET
                    [ $RET -ne 0 ] && continue
                    printf "[*] Reiniciando o sistema...\n" > "$CURR_TTY"
                    sleep 1
                    sudo reboot 2>/dev/null || true ;;
                *) continue ;;
            esac
        fi

        # ----------------------------------------------------------
        # OPÇÃO 4 - Corrigir Permissões de Arquivos (Chmod)
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "4" ]; then
            DIALOG_MENU OPCAO_CHMOD \
                "$BT_OTM" " CORRIGIR PERMISSOES DE ARQUIVOS " \
                20 68 7 \
                1 "ROMs - somente leitura     (644 arquivos / 755 pastas)" \
                2 "Saves - leitura e escrita  (666 arquivos / 777 pastas)" \
                3 "Scripts - tornar executaveis (+x em *.sh)" \
                4 "Temas - leitura e escrita  (644 arquivos / 755 pastas)" \
                5 "Fontes/Logos/Wallpapers    (644 arquivos / 755 pastas)" \
                6 "Gamelists - leitura+escrita (666 arquivos)" \
                7 "Tudo (correcao completa de permissoes)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Aplicando permissoes...\n" > "$CURR_TTY"

            case "$OPCAO_CHMOD" in
                1)
                    find /roms -type f -exec chmod 644 {} \; 2>/dev/null || true
                    find /roms -type d -exec chmod 755 {} \; 2>/dev/null || true
                    DESC_CHM="ROMs (644/755)" ;;
                2)
                    find /home/ark/.emulationstation/saves \
                         /home/ark/.config/retroarch/saves \
                         /roms/saves \
                        -type f -exec chmod 666 {} \; 2>/dev/null || true
                    find /home/ark/.emulationstation/saves \
                         /home/ark/.config/retroarch/saves \
                         /roms/saves \
                        -type d -exec chmod 777 {} \; 2>/dev/null || true
                    DESC_CHM="Saves (666/777)" ;;
                3)
                    find /opt/system/Tools /home/ark/Alter_MThemes \
                        -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
                    DESC_CHM="Scripts (+x)" ;;
                4)
                    for d in /etc/emulationstation/themes \
                              /home/ark/.emulationstation/themes \
                              /roms/themes; do
                        [ -d "$d" ] && \
                            find "$d" -type f -exec chmod 644 {} \; 2>/dev/null || true
                        [ -d "$d" ] && \
                            find "$d" -type d -exec chmod 755 {} \; 2>/dev/null || true
                    done
                    DESC_CHM="Temas (644/755)" ;;
                5)
                    for d in /home/ark/darkos_fonts \
                              /home/ark/darkos_logos \
                              /home/ark/darkos_wallpapers; do
                        [ -d "$d" ] && \
                            find "$d" -type f -exec chmod 644 {} \; 2>/dev/null || true
                        [ -d "$d" ] && \
                            find "$d" -type d -exec chmod 755 {} \; 2>/dev/null || true
                        [ -d "$d" ] && chown -R ark:ark "$d" 2>/dev/null || true
                    done
                    DESC_CHM="Fontes/Logos/Wallpapers (644/755)" ;;
                6)
                    find /home/ark/.emulationstation \
                        -name "gamelist.xml" \
                        -exec chmod 666 {} \; 2>/dev/null || true
                    DESC_CHM="Gamelists (666)" ;;
                7)
                    find /roms -type f -exec chmod 644 {} \; 2>/dev/null || true
                    find /roms -type d -exec chmod 755 {} \; 2>/dev/null || true
                    find /opt/system/Tools /home/ark/Alter_MThemes \
                        -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
                    find /home/ark/.emulationstation \
                        -name "gamelist.xml" \
                        -exec chmod 666 {} \; 2>/dev/null || true
                    for d in /home/ark/darkos_fonts \
                              /home/ark/darkos_logos \
                              /home/ark/darkos_wallpapers \
                              /home/ark/darkos_backups; do
                        [ -d "$d" ] && chown -R ark:ark "$d" 2>/dev/null || true
                        [ -d "$d" ] && chmod -R 755 "$d" 2>/dev/null || true
                    done
                    DESC_CHM="Correcao completa" ;;
                *) continue ;;
            esac

            DIALOG_MSG "$BT_OTM" " CHMOD APLICADO " 9 55 \
                "Permissoes corrigidas!\n\nEscopo: $DESC_CHM"
        fi

        # ----------------------------------------------------------
        # OPÇÃO 5 - Limpar Imagens Soltas (Órfãs)
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "5" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Buscando imagens orfas...\n" > "$CURR_TTY"

            IMG_DIR="/home/ark/.emulationstation/downloaded_images"
            ES_CFG_DIR="/home/ark/.emulationstation"

            if [ ! -d "$IMG_DIR" ]; then
                DIALOG_MSG "$BT_OTM" " IMAGENS ORFAS " 9 55 \
                    "Pasta de imagens nao encontrada!\n\n$IMG_DIR\n\nNenhuma imagem para verificar."
                continue
            fi

            # Coleta todos os paths de imagens referenciados nas gamelists
            printf "[*] Lendo gamelists...\n" > "$CURR_TTY"
            declare -A IMGS_USADAS
            while IFS= read -r -d '' gl; do
                while IFS= read -r linha; do
                    # Extrai caminhos de image/thumbnail/marquee
                    PATH_IMG=$(echo "$linha" | \
                        grep -oE '(image|thumbnail|marquee)>[^<]+<' | \
                        grep -oE '>[^<]+<' | tr -d '><' | \
                        sed 's|~|/home/ark|g')
                    [ -n "$PATH_IMG" ] && IMGS_USADAS["$PATH_IMG"]=1
                done < "$gl"
            done < <(find "$ES_CFG_DIR" \
                -name "gamelist.xml" -print0 2>/dev/null)

            # Encontra imagens não referenciadas
            mapfile -t ORFAS < <(find "$IMG_DIR" -type f \
                \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) \
                2>/dev/null)

            TOTAL_ORFAS=0
            BYTES_ORFAS=0
            LISTA_ORFAS=()
            for img in "${ORFAS[@]}"; do
                if [ -z "${IMGS_USADAS[$img]+x}" ]; then
                    LISTA_ORFAS+=("$img")
                    B=$(du -b "$img" 2>/dev/null | cut -f1 || echo "0")
                    BYTES_ORFAS=$(( BYTES_ORFAS + B ))
                    TOTAL_ORFAS=$(( TOTAL_ORFAS + 1 ))
                fi
            done

            TAM_ORFAS_MB=$(( BYTES_ORFAS / 1024 / 1024 ))
            TOTAL_IMGS=${#ORFAS[@]}

            if [ "$TOTAL_ORFAS" -eq 0 ]; then
                DIALOG_MSG "$BT_OTM" " IMAGENS ORFAS " 10 58 \
                    "Nenhuma imagem orfa encontrada!\n\nTotal de imagens: $TOTAL_IMGS\nTodas estao referenciadas nas gamelists."
                continue
            fi

            dialog --output-fd 1 \
                --backtitle "$BT_OTM" \
                --title " IMAGENS ORFAS " \
                --ok-label "REMOVER" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Imagens encontradas : $TOTAL_IMGS
Imagens orfas        : $TOTAL_ORFAS
Espaco desperdicado  : ~${TAM_ORFAS_MB}MB

Imagens orfas sao arquivos que existem
na pasta de cache mas nao aparecem em
nenhuma gamelist — podem ser removidas
com seguranca.

REMOVER apaga as $TOTAL_ORFAS imagem(ns) orfas." \
                18 62 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Removendo %d imagens orfas...\n" "$TOTAL_ORFAS" > "$CURR_TTY"

            REMOVIDOS_O=0
            for img in "${LISTA_ORFAS[@]}"; do
                rm -f "$img" 2>/dev/null && \
                    REMOVIDOS_O=$(( REMOVIDOS_O + 1 ))
            done

            DIALOG_MSG "$BT_OTM" " LIMPEZA CONCLUIDA " 10 58 \
                "Imagens orfas removidas!\n\n$REMOVIDOS_O arquivo(s) apagado(s)\nEspaco liberado: ~${TAM_ORFAS_MB}MB"
        fi

        # ----------------------------------------------------------
        # OPÇÃO 6 - Reindexar Jogos
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "6" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Contando ROMs por sistema...\n" > "$CURR_TTY"

            # Conta ROMs por extensão conhecida
            TOTAL_ROMS=$(find /roms -type f \
                \( -iname "*.nes" -o -iname "*.sfc" -o -iname "*.smc" \
                -o -iname "*.md"  -o -iname "*.bin" -o -iname "*.iso" \
                -o -iname "*.gba" -o -iname "*.gbc" -o -iname "*.gb"  \
                -o -iname "*.nds" -o -iname "*.n64" -o -iname "*.z64" \
                -o -iname "*.zip" -o -iname "*.7z"  -o -iname "*.cue" \
                -o -iname "*.chd" \) \
                2>/dev/null | wc -l)

            ES_CFG_DIR="/home/ark/.emulationstation"
            GAMELIST_COUNT=$(find "$ES_CFG_DIR" -name "gamelist.xml" \
                2>/dev/null | wc -l)

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " REINDEXAR JOGOS " \
                --ok-label "REINDEXAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Status atual:
  ROMs encontradas : $TOTAL_ROMS arquivo(s)
  Gamelists ativas : $GAMELIST_COUNT lista(s)

O reindexar forca o ES a escanear todas as
pastas de ROMs e atualizar as listas de jogos.

Isso pode demorar alguns minutos dependendo
da quantidade de jogos." \
                16 60 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Preparando reindexacao...\n" > "$CURR_TTY"

            # Remove gamelists antigas para forcar rescan
            DIALOG_MENU OPCAO_IDX \
                "$BT" " MODO DE REINDEXACAO " \
                13 62 3 \
                1 "Rescan suave    (manter dados existentes)" \
                2 "Rescan completo (apagar e recriar gamelists)" \
                3 "Apenas reiniciar ES (ES rescana ao iniciar)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Reindexando jogos...\n" > "$CURR_TTY"

            case "$OPCAO_IDX" in
                1)
                    # Toca nos gamelists para forcar releitura
                    find "$ES_CFG_DIR" -name "gamelist.xml" \
                        -exec touch {} \; 2>/dev/null || true
                    DESC_IDX="Rescan suave aplicado" ;;
                2)
                    # Remove gamelists para ES recriar do zero
                    find "$ES_CFG_DIR" -name "gamelist.xml" \
                        -delete 2>/dev/null || true
                    DESC_IDX="Gamelists removidas — ES vai recriar ao iniciar" ;;
                3)
                    DESC_IDX="ES sera reiniciado" ;;
            esac

            DIALOG_MSG "$BT" " REINDEXACAO CONCLUIDA " 11 60 \
                "$DESC_IDX\n\nReinicie o ES para aplicar a reindexacao."
            PerguntarReiniciar
        fi

        # ----------------------------------------------------------
        # OPÇÃO 5 - Reparar Gamelists
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "7" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Verificando gamelists...\n" > "$CURR_TTY"

            ES_CFG_DIR="/home/ark/.emulationstation"
            mapfile -t GAMELISTS < <(find "$ES_CFG_DIR" \
                -name "gamelist.xml" 2>/dev/null | sort)

            if [ ${#GAMELISTS[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " GAMELISTS " 9 55 \
                    "Nenhuma gamelist encontrada!\n\nO ES ainda nao gerou as listas de jogos."
                continue
            fi

            # Verifica XML corrompido
            CORROMPIDOS=0
            INFO_GL=""
            for gl in "${GAMELISTS[@]}"; do
                SISTEMA=$(basename "$(dirname "$gl")")
                JOGOS=$(grep -c "<game>" "$gl" 2>/dev/null || echo "0")
                # Testa se o XML é válido (tem abertura e fechamento)
                if ! grep -q "<gameList>" "$gl" 2>/dev/null || \
                   ! grep -q "</gameList>" "$gl" 2>/dev/null; then
                    INFO_GL="${INFO_GL}  [CORROMPIDO] $SISTEMA\n"
                    CORROMPIDOS=$(( CORROMPIDOS + 1 ))
                else
                    INFO_GL="${INFO_GL}  OK  $SISTEMA  ($JOGOS jogos)\n"
                fi
            done

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " REPARAR GAMELISTS " \
                --ok-label "REPARAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Gamelists encontradas: ${#GAMELISTS[@]}
Corrompidas: $CORROMPIDOS

${INFO_GL}
REPARAR recria gamelists corrompidas." \
                22 65 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Reparando gamelists...\n" > "$CURR_TTY"

            REPARADOS=0
            for gl in "${GAMELISTS[@]}"; do
                SISTEMA=$(basename "$(dirname "$gl")")
                # Repara XML corrompido: recria com estrutura mínima válida
                if ! grep -q "<gameList>" "$gl" 2>/dev/null || \
                   ! grep -q "</gameList>" "$gl" 2>/dev/null; then
                    # Backup antes de apagar
                    cp "$gl" "${gl}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                    # Recria gamelist mínima válida
                    cat > "$gl" << XMLEOF
<?xml version="1.0"?>
<gameList>
</gameList>
XMLEOF
                    REPARADOS=$(( REPARADOS + 1 ))
                    printf "  Reparado: %s\n" "$SISTEMA" > "$CURR_TTY"
                fi
            done

            if [ "$REPARADOS" -eq 0 ]; then
                DIALOG_MSG "$BT" " GAMELISTS " 9 55 \
                    "Nenhuma gamelist corrompida!\n\nTodas as ${#GAMELISTS[@]} listas estao OK."
            else
                DIALOG_MSG "$BT" " GAMELISTS REPARADAS " 10 58 \
                    "$REPARADOS gamelist(s) reparada(s)!\n\nReinicie o ES para reindexar os jogos."
                PerguntarReiniciar
            fi
        fi

        # ----------------------------------------------------------
        # ----------------------------------------------------------
        # OPÇÃO 8 - Reinicialização Técnica
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "8" ]; then
            while true; do
                DIALOG_MENU MENU_REINIT \
                    "$BT_OTM" " REINICIALIZACAO TECNICA " \
                    14 62 3 \
                    1 "Reiniciar apenas o EmulationStation" \
                    2 "Recarregar Lista de Jogos (sem reiniciar)" \
                    3 "Reiniciar o sistema completo (reboot)"
                RET=$? ; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                case "$MENU_REINIT" in
                    1)
                        dialog --output-fd 1 \
                            --backtitle "$BT_OTM" \
                            --title " REINICIAR ES " \
                            --ok-label "REINICIAR" \
                            --cancel-label "CANCELAR" \
                            --yesno "Reiniciar apenas o EmulationStation?\n\nO sistema continuara rodando normalmente.\nApenas o ES sera encerrado e reaberto." \
                            9 56 >"$CURR_TTY"
                        RET=$? ; NORM_RET
                        [ $RET -ne 0 ] && continue
                        printf "\033c" > "$CURR_TTY"
                        printf "[*] Reiniciando EmulationStation...\n" > "$CURR_TTY"
                        sleep 1
                        sudo systemctl restart emulationstation 2>/dev/null || \
                            sudo killall emulationstation 2>/dev/null || true
                        ExitAll ;;
                    2)
                        printf "\033c" > "$CURR_TTY"
                        printf "[*] Recarregando lista de jogos...\n" > "$CURR_TTY"
                        # Toca gamelists para forcar releitura
                        find /home/ark/.emulationstation \
                            -name "gamelist.xml" \
                            -exec touch {} \; 2>/dev/null || true
                        # Envia sinal ao ES para recarregar se estiver rodando
                        pkill -HUP emulationstation 2>/dev/null || true
                        DIALOG_MSG "$BT_OTM" " LISTA RECARREGADA " 10 58 \
                            "Lista de jogos recarregada!\n\nAs gamelists foram atualizadas.\nO ES aplicara as mudancas na proxima\nvez que acessar a lista de jogos.\n\nSe necessario, reinicie o ES manualmente." ;;
                    3)
                        dialog --output-fd 1 \
                            --backtitle "$BT_OTM" \
                            --title " REBOOT " \
                            --ok-label "REINICIAR" \
                            --cancel-label "CANCELAR" \
                            --yesno "Reiniciar o sistema completo?\n\nTodos os processos serao encerrados\ne o R36S sera reiniciado." \
                            9 52 >"$CURR_TTY"
                        RET=$? ; NORM_RET
                        [ $RET -ne 0 ] && continue
                        printf "\033c" > "$CURR_TTY"
                        printf "[*] Reiniciando o sistema...\n" > "$CURR_TTY"
                        sleep 1.5
                        sudo reboot ;;
                esac
            done
        fi
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "9" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Verificando conexao...\n" > "$CURR_TTY"

            if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
                DIALOG_MSG "$BT" " SEM INTERNET " 9 55 \
                    "Sem conexao com a internet!\n\nConecte ao Wi-Fi e tente novamente."
                continue
            fi

            # Busca temas instalados
            TEMAS_DIRS=(
                "/etc/emulationstation/themes"
                "/home/ark/.emulationstation/themes"
                "/roms/themes"
            )

            mapfile -t TEMAS_INST < <(
                for d in "${TEMAS_DIRS[@]}"; do
                    [ -d "$d" ] && ls "$d" 2>/dev/null
                done | sort -u
            )

            if [ ${#TEMAS_INST[@]} -eq 0 ]; then
                DIALOG_MSG "$BT" " TEMAS " 9 55 \
                    "Nenhum tema instalado encontrado."
                continue
            fi

            # Monta lista para o dialog
            LISTA_TEMAS=()
            IDX=1
            for t in "${TEMAS_INST[@]}"; do
                LISTA_TEMAS+=("$IDX" "$t")
                IDX=$(( IDX + 1 ))
            done

            DIALOG_MENU OPCAO_TEMA \
                "$BT" " ATUALIZAR TEMA " \
                18 65 8 \
                "${LISTA_TEMAS[@]}"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            TEMA_SELECIONADO="${TEMAS_INST[$((OPCAO_TEMA - 1))]}"

            # Localiza pasta do tema
            TEMA_PATH=""
            for d in "${TEMAS_DIRS[@]}"; do
                [ -d "$d/$TEMA_SELECIONADO" ] && TEMA_PATH="$d/$TEMA_SELECIONADO" && break
            done

            # Verifica se é um repo git
            if [ -d "$TEMA_PATH/.git" ]; then
                printf "\033c" > "$CURR_TTY"
                printf "[*] Atualizando tema %s via git...\n" "$TEMA_SELECIONADO" > "$CURR_TTY"

                if git -C "$TEMA_PATH" pull 2>/dev/null; then
                    DIALOG_MSG "$BT" " TEMA ATUALIZADO " 9 58 \
                        "Tema atualizado!\n\n$TEMA_SELECIONADO\n\nReinicie o ES para aplicar."
                    PerguntarReiniciar
                else
                    DIALOG_MSG "$BT" " ERRO " 9 55 \
                        "Erro ao atualizar o tema!\n\nVerifique a conexao e tente novamente."
                fi
            else
                DIALOG_MSG "$BT" " ATUALIZAR TEMA " 12 62 \
                    "O tema '$TEMA_SELECIONADO' nao e um\nrepositorio git — nao pode ser atualizado\nautomaticamente.\n\nPara atualizar manualmente:\n1. Baixe a versao mais recente\n2. Substitua a pasta do tema\n3. Reinicie o ES"
            fi
        fi

        # ----------------------------------------------------------
        # OPÇÃO 7 - Atualizar Overlays
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "10" ]; then
            printf "\033c" > "$CURR_TTY"
            printf "[*] Verificando conexao...\n" > "$CURR_TTY"

            if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
                DIALOG_MSG "$BT" " SEM INTERNET " 9 55 \
                    "Sem conexao com a internet!\n\nConecte ao Wi-Fi e tente novamente."
                continue
            fi

            # Pastas comuns de overlays no ArkOS/R36S
            OVERLAY_DIRS=(
                "/home/ark/.config/retroarch/overlay"
                "/roms/overlays"
                "/opt/system/overlays"
            )

            INFO_OV=""
            for d in "${OVERLAY_DIRS[@]}"; do
                if [ -d "$d" ]; then
                    COUNT=$(find "$d" -name "*.cfg" -o -name "*.png" \
                        2>/dev/null | wc -l)
                    TAM=$(du -sh "$d" 2>/dev/null | cut -f1 || echo "?")
                    INFO_OV="${INFO_OV}  $TAM  $COUNT arquivo(s)  $(basename $d)\n"
                fi
            done

            [ -z "$INFO_OV" ] && INFO_OV="  Nenhuma pasta de overlay encontrada\n"

            DIALOG_MENU OPCAO_OV \
                "$BT" " ATUALIZAR OVERLAYS " \
                18 68 4 \
                1 "Pack Arcade (bezels classicos de fliperama)" \
                2 "Pack Clean  (bordas simples e discretas)" \
                3 "Pack Realistic (scanlines + bordas realistas)" \
                4 "Pack Minimal  (apenas bordas finas)"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            case "$OPCAO_OV" in
                1) OV_URL="https://github.com/thebezelproject/bezelproject-MAME/archive/refs/heads/master.zip"
                   OV_NOME="Pack Arcade" ;;
                2) OV_URL="https://github.com/thebezelproject/bezelproject-SNES/archive/refs/heads/master.zip"
                   OV_NOME="Pack Clean" ;;
                3) OV_URL="https://github.com/thebezelproject/bezelproject-NES/archive/refs/heads/master.zip"
                   OV_NOME="Pack Realistic" ;;
                4) OV_URL="https://github.com/thebezelproject/bezelproject-GBA/archive/refs/heads/master.zip"
                   OV_NOME="Pack Minimal" ;;
                *) continue ;;
            esac

            OVERLAY_DEST="/home/ark/.config/retroarch/overlay"
            mkdir -p "$OVERLAY_DEST" 2>/dev/null || true
            chown ark:ark "$OVERLAY_DEST" 2>/dev/null || true

            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " CONFIRMAR DOWNLOAD " \
                --ok-label "BAIXAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"Pack: $OV_NOME

Destino: $OVERLAY_DEST

O download pode demorar alguns minutos.
Deseja continuar?" \
                12 58 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "[*] Baixando overlays: %s...\n" "$OV_NOME" > "$CURR_TTY"
            printf "    Aguarde...\n" > "$CURR_TTY"

            OV_ZIP="/tmp/amthemes_ov_$$.zip"
            OV_DIR="/tmp/amthemes_ov_$$"

            if wget -q \
                --timeout=120 \
                --tries=3 \
                --user-agent="Mozilla/5.0 (Linux; Android)" \
                -O "$OV_ZIP" "$OV_URL" 2>/dev/null \
                && [ -s "$OV_ZIP" ]; then

                printf "[*] Extraindo overlays...\n" > "$CURR_TTY"
                mkdir -p "$OV_DIR" 2>/dev/null || true
                unzip -q "$OV_ZIP" -d "$OV_DIR" 2>/dev/null || true

                COPIADOS_OV=0
                while IFS= read -r -d '' f; do
                    cp "$f" "$OVERLAY_DEST/$(basename "$f")" 2>/dev/null && \
                        COPIADOS_OV=$(( COPIADOS_OV + 1 ))
                done < <(find "$OV_DIR" -type f \
                    \( -iname "*.cfg" -o -iname "*.png" \) \
                    -print0 2>/dev/null)

                chown -R ark:ark "$OVERLAY_DEST" 2>/dev/null || true
                rm -rf "$OV_ZIP" "$OV_DIR" 2>/dev/null || true

                DIALOG_MSG "$BT" " OVERLAYS ATUALIZADOS " 11 62 \
                    "Overlays instalados!\n\nPack: $OV_NOME\n$COPIADOS_OV arquivo(s) instalado(s)\nDestino: $OVERLAY_DEST"
            else
                rm -f "$OV_ZIP" 2>/dev/null || true
                DIALOG_MSG "$BT" " ERRO NO DOWNLOAD " 9 55 \
                    "Falha ao baixar o pack!\n\nVerifique a conexao e tente novamente."
            fi
        fi

        # ----------------------------------------------------------
        # OPÇÃO 8 - Otimização Completa (executa tudo em sequência)
        # ----------------------------------------------------------
        if [ "$MENU_OTM" = "11" ]; then
            dialog --output-fd 1 \
                --backtitle "$BT" \
                --title " OTIMIZACAO COMPLETA " \
                --ok-label "EXECUTAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --msgbox \
"A otimizacao completa executa:

  1. Limpar cache do ES
  2. Remover arquivos temporarios
  3. Corrigir permissoes das pastas
  4. Verificar e reparar gamelists

Isso pode levar alguns minutos.
Deseja continuar?" \
                16 58 >"$CURR_TTY"
            RET=$? ; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            printf "\033c" > "$CURR_TTY"
            printf "=== OTIMIZACAO COMPLETA ===\n\n" > "$CURR_TTY"

            # 1. Cache
            printf "[1/4] Limpando cache...\n" > "$CURR_TTY"
            CACHE_DIRS=(
                "/home/ark/.emulationstation/downloaded_images"
                "/home/ark/.emulationstation/downloaded_videos"
                "/tmp/emulationstation"
            )
            CACHE_MB=0
            for d in "${CACHE_DIRS[@]}"; do
                if [ -e "$d" ]; then
                    B=$(du -sb "$d" 2>/dev/null | cut -f1 || echo "0")
                    CACHE_MB=$(( CACHE_MB + B / 1024 / 1024 ))
                    rm -rf "$d" 2>/dev/null || true
                fi
            done
            printf "      Cache: ~%dMB liberados\n" "$CACHE_MB" > "$CURR_TTY"

            # 2. Temporários
            printf "[2/4] Removendo temporarios...\n" > "$CURR_TTY"
            REM_TMP=0
            for p in "*.tmp" "*.log" "*.pid" "core.*" "*.crash"; do
                while IFS= read -r -d '' f; do
                    rm -f "$f" 2>/dev/null && REM_TMP=$(( REM_TMP + 1 ))
                done < <(find /tmp /var/tmp -maxdepth 2 \
                    -name "$p" -print0 2>/dev/null)
            done
            printf "      Temporarios: %d arquivo(s) removidos\n" "$REM_TMP" > "$CURR_TTY"

            # 3. Permissões
            printf "[3/4] Corrigindo permissoes...\n" > "$CURR_TTY"
            for d in "/home/ark/darkos_backups" \
                     "/home/ark/darkos_wallpapers" \
                     "/home/ark/darkos_fonts" \
                     "/home/ark/darkos_logos"; do
                [ -d "$d" ] && chown -R ark:ark "$d" 2>/dev/null || true
            done
            chown -R ark:ark /home/ark/.emulationstation 2>/dev/null || true
            find /opt/system/Tools -name "*.sh" \
                -exec chmod +x {} \; 2>/dev/null || true
            printf "      Permissoes corrigidas\n" > "$CURR_TTY"

            # 4. Gamelists
            printf "[4/4] Verificando gamelists...\n" > "$CURR_TTY"
            GL_REP=0
            ES_CFG_DIR="/home/ark/.emulationstation"
            while IFS= read -r -d '' gl; do
                if ! grep -q "<gameList>" "$gl" 2>/dev/null || \
                   ! grep -q "</gameList>" "$gl" 2>/dev/null; then
                    cp "$gl" "${gl}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                    printf '<?xml version="1.0"?>\n<gameList>\n</gameList>\n' \
                        > "$gl" 2>/dev/null || true
                    GL_REP=$(( GL_REP + 1 ))
                fi
            done < <(find "$ES_CFG_DIR" -name "gamelist.xml" -print0 2>/dev/null)
            printf "      Gamelists: %d reparada(s)\n" "$GL_REP" > "$CURR_TTY"

            printf "\n=== CONCLUIDO ===\n" > "$CURR_TTY"
            sleep 1

            DIALOG_MSG "$BT" " OTIMIZACAO CONCLUIDA " 14 60 \
"Otimizacao completa executada!

  Cache liberado  : ~${CACHE_MB}MB
  Temp removidos  : ${REM_TMP} arquivo(s)
  Permissoes      : corrigidas
  Gamelists rep.  : ${GL_REP} arquivo(s)

Reinicie o ES para aplicar todas as mudancas."
            PerguntarReiniciar
        fi

    done
}
