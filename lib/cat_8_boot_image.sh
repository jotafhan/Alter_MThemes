# =============================================================================
# cat_8_boot_image.sh — Central de Imagens de Boot
# Alter_MThemes v7.0 - Modulo 8
#
# Gerencia:
#   1. Boot Logo   — /boot/logo.bmp  (partição BOOT, vfat)
#   2. Loading Screen — /roms/launchimages/loading.*  (partição EASYROMS)
#
# Formato boot logo : BMP 24-bit, 640x480 (obrigatorio pelo firmware)
# Formato loading   : .jpg, .gif, .mp4, .ascii (ES escolhe automaticamente)
# =============================================================================

# -----------------------------------------------------------------------------
# Caminhos — detectados dinamicamente com fallback
# -----------------------------------------------------------------------------

# Partição BOOT (vfat, montada em /boot)
_BOOT_PARTITIONS=("/boot" "/media/boot" "/mnt/boot")
_BOOT_DIR=""
for _p in "${_BOOT_PARTITIONS[@]}"; do
    if mountpoint -q "$_p" 2>/dev/null || [ -d "$_p" ] && mount | grep -q "$_p"; then
        _BOOT_DIR="$_p"
        break
    fi
done
# Fallback: verifica se /boot tem logo.bmp mesmo sem ser mountpoint reportado
[ -z "$_BOOT_DIR" ] && [ -f "/boot/logo.bmp" ] && _BOOT_DIR="/boot"
[ -z "$_BOOT_DIR" ] && [ -d "/boot" ] && _BOOT_DIR="/boot"

# Pasta de loading screens (partição EASYROMS)
_LAUNCH_PARTITIONS=(
    "/roms/launchimages"
    "/roms2/launchimages"
    "/home/ark/roms/launchimages"
    "/easyroms/launchimages"
)
_LAUNCH_DIR=""
for _p in "${_LAUNCH_PARTITIONS[@]}"; do
    if [ -d "$_p" ]; then
        _LAUNCH_DIR="$_p"
        break
    fi
done
# Tenta criar a pasta se a partição roms existir mas a subpasta não
if [ -z "$_LAUNCH_DIR" ]; then
    for _base in "/roms" "/roms2" "/home/ark/roms" "/easyroms"; do
        if [ -d "$_base" ]; then
            mkdir -p "${_base}/launchimages" 2>/dev/null && \
                _LAUNCH_DIR="${_base}/launchimages"
            break
        fi
    done
fi

# Pasta de BMPs para ciclo de logos (opcional, dentro do BOOT)
_BOOT_BMPS_DIR="${_BOOT_DIR}/BMPs"

# Pasta de imagens de boot do usuario — dentro da mesma particao roms,
# ao lado de launchimages/, para que o usuario possa copiar diretamente
# pelo cartao SD no PC sem precisar de USB ou SSH.
# Estrutura:
#   /roms/boot_images/    ← boot logos (.bmp/.png/.jpg)
#   /roms/launchimages/   ← loading screens (ja existente)
_BOOT_IMG_USER_DIR=""
for _base in "/roms" "/roms2" "/home/ark/roms" "/easyroms"; do
    if [ -d "$_base" ]; then
        _BOOT_IMG_USER_DIR="${_base}/boot_images"
        mkdir -p "$_BOOT_IMG_USER_DIR" 2>/dev/null || true
        chown ark:ark "$_BOOT_IMG_USER_DIR" 2>/dev/null || true
        break
    fi
done
# Fallback para home se nenhuma particao roms for encontrada
if [ -z "$_BOOT_IMG_USER_DIR" ]; then
    _BOOT_IMG_USER_DIR="/home/ark/darkos_boot_images"
    mkdir -p "$_BOOT_IMG_USER_DIR" 2>/dev/null || true
    chown ark:ark "$_BOOT_IMG_USER_DIR" 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# _boot_status_linha — resume o estado atual dos arquivos de boot
# -----------------------------------------------------------------------------
_boot_status_linha() {
    local logo_status="" launch_status=""

    if [ -f "${_BOOT_DIR}/logo.bmp" ]; then
        local tam
        tam=$(du -sh "${_BOOT_DIR}/logo.bmp" 2>/dev/null | cut -f1 || echo "?")
        logo_status="logo.bmp (${tam})"
    else
        logo_status="nenhum"
    fi

    if [ -n "$_LAUNCH_DIR" ]; then
        local arqs
        arqs=$(find "$_LAUNCH_DIR" -maxdepth 1 \
            -name "loading.*" 2>/dev/null | wc -l)
        launch_status="${arqs} arquivo(s) loading"
    else
        launch_status="pasta nao encontrada"
    fi

    echo "Boot: $logo_status  |  Loading: $launch_status"
}

# -----------------------------------------------------------------------------
# _boot_backup — faz backup antes de qualquer substituicao
# $1 = arquivo a fazer backup
# -----------------------------------------------------------------------------
_boot_backup() {
    local arquivo="$1"
    [ -f "$arquivo" ] || return
    local bak_nome
    bak_nome="${arquivo}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$arquivo" "$bak_nome" 2>/dev/null && \
        printf "[*] Backup criado: %s\n" "$(basename "$bak_nome")" > "$CURR_TTY" || true
}

# -----------------------------------------------------------------------------
# _boot_converter_bmp — converte imagem para BMP 24-bit 640x480
# $1 = arquivo origem   $2 = arquivo destino
# Requer ImageMagick (convert). Se nao disponivel, copia direto (risco).
# -----------------------------------------------------------------------------
_boot_converter_bmp() {
    local src="$1" dst="$2"
    if command -v convert >/dev/null 2>&1; then
        convert "$src" \
            -resize 640x480! \
            -depth 8 \
            -type TrueColor \
            BMP3:"$dst" 2>/dev/null
        return $?
    else
        # ImageMagick ausente: copia direto e avisa
        cp "$src" "$dst" 2>/dev/null
        return 1
    fi
}

# -----------------------------------------------------------------------------
# _boot_instalar_logo — instala imagem como boot logo
# $1 = arquivo de origem (qualquer formato)
# -----------------------------------------------------------------------------
_boot_instalar_logo() {
    local src="$1"
    local nome_src
    nome_src=$(basename "$src")
    local ext="${src##*.}"
    local dst="${_BOOT_DIR}/logo.bmp"

    printf "\033c" > "$CURR_TTY"
    printf "[*] Instalando boot logo: %s\n" "$nome_src" > "$CURR_TTY"

    # Verifica espaco na particao BOOT
    local livre_kb
    livre_kb=$(df -k "$_BOOT_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "0")
    if [ "$livre_kb" -lt 1000 ] 2>/dev/null; then
        DIALOG_MSG "$BT" " BOOT - ESPACO INSUFICIENTE " 10 60 \
            "Espaco livre insuficiente na particao BOOT!\n\nLivre: ${livre_kb}KB\nNecessario: ~1MB\n\nRemova arquivos antigos da pasta:\n${_BOOT_DIR}"
        return 1
    fi

    # Backup do logo atual
    _boot_backup "$dst"

    printf "[*] Convertendo para BMP 24-bit 640x480...\n" > "$CURR_TTY"
    local tmp_bmp
    tmp_bmp=$(mktemp /tmp/alter_boot_XXXXXX.bmp)

    local sem_imagemagick=0
    if ! _boot_converter_bmp "$src" "$tmp_bmp"; then
        sem_imagemagick=1
    fi

    if [ "$sem_imagemagick" -eq 1 ] && ! command -v convert >/dev/null 2>&1; then
        DIALOG_MSG "$BT" " AVISO — SEM IMAGEMAGICK " 12 62 \
            "ImageMagick nao encontrado!\n\nO arquivo sera copiado sem conversao.\nSe a imagem nao estiver no formato\nexato (BMP 24-bit 640x480), pode\nnao aparecer corretamente no boot.\n\nInstale o ImageMagick para conversao\nautomatica:\n  sudo apt-get install imagemagick"
        cp "$src" "$dst" 2>/dev/null
    else
        cp "$tmp_bmp" "$dst" 2>/dev/null
    fi
    rm -f "$tmp_bmp" 2>/dev/null || true

    # Verifica se o arquivo foi gravado
    if [ -f "$dst" ] && [ -s "$dst" ]; then
        printf "[OK] Boot logo instalado!\n" > "$CURR_TTY"
        return 0
    else
        printf "[ERRO] Falha ao gravar o arquivo.\n" > "$CURR_TTY"
        return 1
    fi
}

# =============================================================================
# categoria_8 — entry point do modulo
# =============================================================================
categoria_8() {
    # Avisa se a pasta BOOT nao foi detectada
    if [ -z "$_BOOT_DIR" ]; then
        DIALOG_MSG "$BT" " BOOT - PARTICAO NAO ENCONTRADA " 12 62 \
            "Particao BOOT nao encontrada!\n\nEsta funcionalidade requer que a\nparticao BOOT esteja montada em:\n  /boot\n\nSe o R36S estiver inicializando\ncorretamente, isso pode ser um\nproblema de permissao ou montagem."
        return
    fi

    while true; do
        local STATUS
        STATUS="$(_boot_status_linha)"

        local BT_BOOT="Alter_MThemes v7.0  |  Boot Center  |  BOOT: ${_BOOT_DIR}"

        DIALOG_MENU MENU_BOOT \
            "$BT_BOOT" " CENTRAL DE IMAGENS DE BOOT " \
            20 68 6 \
            1 "Boot Logo          (tela ao ligar o console)" \
            2 "Loading Screen     (tela ao abrir um jogo)" \
            3 "Ciclo de Logos     (multiplos BMPs na pasta BMPs/)" \
            4 "Restaurar Originais (a partir de backup)" \
            5 "Status Atual" \
            6 "Instalar Imagem via USB"
        RET=$?
        NORM_RET
        [ $RET -eq 1 ] && ExitAll
        [ $RET -eq 3 ] && break

        # ------------------------------------------------------------------
        # OPCAO 1 — Boot Logo
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "1" ]; then
            while true; do
                DIALOG_MENU MENU_LOGO_BOOT \
                    "$BT_BOOT" " BOOT LOGO " \
                    16 65 4 \
                    1 "Usar imagem da pasta do usuario (/roms/boot_images/)" \
                    2 "Usar imagem via USB (pendrive)" \
                    3 "Ver logo atual" \
                    4 "Remover logo atual (volta ao padrao)"
                RET=$?
                NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                # -- 1.1: imagens da pasta do usuario --
                if [ "$MENU_LOGO_BOOT" = "1" ]; then
                    mapfile -t IMGS_USER < <(find "$_BOOT_IMG_USER_DIR" \
                        -maxdepth 1 -type f \
                        \( -iname "*.bmp" -o -iname "*.png" \
                           -o -iname "*.jpg" -o -iname "*.jpeg" \) \
                        2>/dev/null | sort)

                    if [ ${#IMGS_USER[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO " 12 62 \
                            "Nenhuma imagem encontrada em:\n${_BOOT_IMG_USER_DIR}\n\nCopie arquivos .bmp, .png ou .jpg\npara essa pasta diretamente pelo\ncartao SD no PC, ou use a opcao\n'Instalar Imagem via USB'."
                        continue
                    fi

                    LISTA_IU=(); local IDX=1
                    for _f in "${IMGS_USER[@]}"; do
                        local tam
                        tam=$(du -sh "$_f" 2>/dev/null | cut -f1 || echo "?")
                        LISTA_IU+=("$IDX" "$(basename "$_f")  (${tam})")
                        IDX=$((IDX+1))
                    done

                    DIALOG_MENU SEL_IU "$BT_BOOT" " ESCOLHA A IMAGEM " \
                        18 65 8 "${LISTA_IU[@]}"
                    RET=$?; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    local img_sel="${IMGS_USER[$((SEL_IU-1))]}"
                    if _boot_instalar_logo "$img_sel"; then
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO INSTALADO " 11 60 \
                            "Boot logo instalado!\n\nArquivo: $(basename "$img_sel")\nDestino: ${_BOOT_DIR}/logo.bmp\n\nReinicie o console para ver\na mudanca."
                    else
                        DIALOG_MSG "$BT_BOOT" " ERRO " 9 55 \
                            "Erro ao instalar o boot logo!\n\nVerifique permissoes em:\n${_BOOT_DIR}"
                    fi
                fi

                # -- 1.2: imagem via USB --
                if [ "$MENU_LOGO_BOOT" = "2" ]; then
                    if ! _detectar_usb; then
                        DIALOG_MSG "$BT_BOOT" " USB NAO ENCONTRADO " 9 58 \
                            "Nenhum pendrive detectado!\n\nInsira o USB com as imagens e\ntente novamente."
                        continue
                    fi
                    _selecionar_usb
                    local RET_USB=$? ; [ $RET_USB -eq 1 ] && ExitAll ; [ $RET_USB -eq 3 ] && continue

                    mapfile -t USB_IMGS < <(find "$_USB_PATH" \
                        -type f \
                        \( -iname "*.bmp" -o -iname "*.png" \
                           -o -iname "*.jpg" -o -iname "*.jpeg" \) \
                        2>/dev/null | sort)

                    if [ ${#USB_IMGS[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT_BOOT" " USB " 9 58 \
                            "Nenhuma imagem encontrada no USB.\n\nFormatos aceitos: .bmp, .png, .jpg"
                        continue
                    fi

                    local LISTA_USB_I=(); local IDX=1
                    for _f in "${USB_IMGS[@]}"; do
                        LISTA_USB_I+=("$IDX" "$(basename "$_f")")
                        IDX=$((IDX+1))
                    done

                    DIALOG_MENU SEL_USB_I "$BT_BOOT" " ESCOLHA A IMAGEM " \
                        18 65 8 "${LISTA_USB_I[@]}"
                    RET=$?; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    local img_sel="${USB_IMGS[$((SEL_USB_I-1))]}"
                    if _boot_instalar_logo "$img_sel"; then
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO INSTALADO " 11 60 \
                            "Boot logo instalado!\n\nArquivo: $(basename "$img_sel")\nDestino: ${_BOOT_DIR}/logo.bmp\n\nReinicie o console para ver\na mudanca."
                    else
                        DIALOG_MSG "$BT_BOOT" " ERRO " 9 55 \
                            "Erro ao instalar o boot logo!"
                    fi
                fi

                # -- 1.3: ver logo atual --
                if [ "$MENU_LOGO_BOOT" = "3" ]; then
                    if [ -f "${_BOOT_DIR}/logo.bmp" ]; then
                        local tam data
                        tam=$(du -sh "${_BOOT_DIR}/logo.bmp" 2>/dev/null | cut -f1 || echo "?")
                        data=$(stat -c "%y" "${_BOOT_DIR}/logo.bmp" 2>/dev/null | cut -d'.' -f1 || echo "?")
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO ATUAL " 11 60 \
                            "Arquivo: logo.bmp\nLocal  : ${_BOOT_DIR}/logo.bmp\nTamanho: ${tam}\nData   : ${data}"
                    else
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO " 8 55 \
                            "Nenhum logo.bmp encontrado em:\n${_BOOT_DIR}"
                    fi
                fi

                # -- 1.4: remover logo --
                if [ "$MENU_LOGO_BOOT" = "4" ]; then
                    if [ ! -f "${_BOOT_DIR}/logo.bmp" ]; then
                        DIALOG_MSG "$BT_BOOT" " BOOT LOGO " 8 52 \
                            "Nenhum logo.bmp para remover."
                        continue
                    fi
                    dialog --output-fd 1 \
                        --backtitle "$BT_BOOT" \
                        --title " REMOVER LOGO " \
                        --ok-label "REMOVER" \
                        --cancel-label "CANCELAR" \
                        --yesno "Remover o boot logo atual?\n\nUm backup sera criado antes." \
                        8 50 >"$CURR_TTY"
                    RET=$?; NORM_RET
                    [ $RET -ne 0 ] && continue
                    _boot_backup "${_BOOT_DIR}/logo.bmp"
                    rm -f "${_BOOT_DIR}/logo.bmp" 2>/dev/null
                    DIALOG_MSG "$BT_BOOT" " LOGO REMOVIDO " 9 55 \
                        "Boot logo removido!\n\nO firmware usara a imagem padrao\nao reiniciar."
                fi
            done
        fi

        # ------------------------------------------------------------------
        # OPCAO 2 — Loading Screen
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "2" ]; then
            if [ -z "$_LAUNCH_DIR" ]; then
                DIALOG_MSG "$BT_BOOT" " LOADING SCREEN " 10 62 \
                    "Pasta launchimages nao encontrada!\n\nEsperado em:\n  /roms/launchimages/\n\nVerifique se a particao EASYROMS\nesta montada."
                continue
            fi

            while true; do
                # Descobre o que esta instalado atualmente
                local _cur_loading=""
                for _ext in jpg gif mp4 ascii; do
                    [ -f "${_LAUNCH_DIR}/loading.${_ext}" ] && \
                        _cur_loading="${_cur_loading}loading.${_ext}  "
                done
                [ -z "$_cur_loading" ] && _cur_loading="nenhum"

                DIALOG_MENU MENU_LOADING \
                    "$BT_BOOT" " LOADING SCREEN  [atual: ${_cur_loading}] " \
                    16 68 4 \
                    1 "Usar imagem da pasta launchimages (/roms/launchimages/)" \
                    2 "Instalar via USB" \
                    3 "Ver arquivos atuais" \
                    4 "Remover loading screen"
                RET=$?; NORM_RET
                [ $RET -eq 1 ] && ExitAll
                [ $RET -eq 3 ] && break

                _boot_instalar_loading() {
                    local src="$1"
                    local ext="${src##*.}"
                    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
                    local dst="${_LAUNCH_DIR}/loading.${ext}"

                    # Backup do arquivo atual do mesmo tipo se existir
                    _boot_backup "$dst"

                    printf "\033c" > "$CURR_TTY"
                    printf "[*] Instalando loading screen: %s...\n" "$(basename "$src")" > "$CURR_TTY"

                    if cp "$src" "$dst" 2>/dev/null; then
                        chown ark:ark "$dst" 2>/dev/null || true
                        printf "[OK] Loading screen instalada!\n" > "$CURR_TTY"
                        return 0
                    else
                        printf "[ERRO] Falha ao copiar o arquivo.\n" > "$CURR_TTY"
                        return 1
                    fi
                }

                # -- 2.1: da pasta launchimages (usuario coloca direto pelo SD) --
                if [ "$MENU_LOADING" = "1" ]; then
                    mapfile -t LOADING_USER < <(find "$_LAUNCH_DIR" \
                        -maxdepth 1 -type f \
                        \( -iname "*.jpg" -o -iname "*.jpeg" \
                           -o -iname "*.gif" -o -iname "*.mp4" \
                           -o -iname "*.ascii" \) \
                        2>/dev/null | sort)

                    if [ ${#LOADING_USER[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT_BOOT" " LOADING SCREEN " 12 62 \
                            "Nenhuma imagem encontrada em:\n${_LAUNCH_DIR}\n\nCopie arquivos .jpg, .gif ou .mp4\npara essa pasta diretamente pelo\ncartao SD no PC, ou use 'Instalar via USB'."
                        continue
                    fi

                    local LISTA_LU=(); local IDX=1
                    for _f in "${LOADING_USER[@]}"; do
                        LISTA_LU+=("$IDX" "$(basename "$_f")")
                        IDX=$((IDX+1))
                    done

                    DIALOG_MENU SEL_LU "$BT_BOOT" " ESCOLHA O ARQUIVO " \
                        18 65 8 "${LISTA_LU[@]}"
                    RET=$?; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    local lf="${LOADING_USER[$((SEL_LU-1))]}"
                    if _boot_instalar_loading "$lf"; then
                        DIALOG_MSG "$BT_BOOT" " LOADING SCREEN INSTALADA " 10 60 \
                            "Loading screen instalada!\n\nArquivo: $(basename "$lf")\nDestino: ${_LAUNCH_DIR}/\n\nA mudanca aparece na proxima\nvez que abrir um jogo."
                    else
                        DIALOG_MSG "$BT_BOOT" " ERRO " 9 55 "Erro ao instalar a loading screen!"
                    fi
                fi

                # -- 2.2: via USB --
                if [ "$MENU_LOADING" = "2" ]; then
                    if ! _detectar_usb; then
                        DIALOG_MSG "$BT_BOOT" " USB " 8 55 \
                            "Nenhum pendrive detectado!"
                        continue
                    fi
                    _selecionar_usb
                    local RET_USB=$? ; [ $RET_USB -eq 1 ] && ExitAll ; [ $RET_USB -eq 3 ] && continue
                    mapfile -t USB_LOADING < <(find "$_USB_PATH" \
                        -type f \
                        \( -iname "*.jpg" -o -iname "*.jpeg" \
                           -o -iname "*.gif" -o -iname "*.mp4" \
                           -o -iname "*.ascii" \) \
                        2>/dev/null | sort)

                    if [ ${#USB_LOADING[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT_BOOT" " USB " 9 58 \
                            "Nenhuma imagem compativel encontrada.\n\nFormatos: .jpg, .gif, .mp4, .ascii"
                        continue
                    fi

                    local LISTA_UL=(); local IDX=1
                    for _f in "${USB_LOADING[@]}"; do
                        LISTA_UL+=("$IDX" "$(basename "$_f")")
                        IDX=$((IDX+1))
                    done

                    DIALOG_MENU SEL_UL "$BT_BOOT" " ESCOLHA O ARQUIVO " \
                        18 65 8 "${LISTA_UL[@]}"
                    RET=$?; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    local lf="${USB_LOADING[$((SEL_UL-1))]}"
                    if _boot_instalar_loading "$lf"; then
                        DIALOG_MSG "$BT_BOOT" " LOADING SCREEN INSTALADA " 10 60 \
                            "Loading screen instalada!\n\nArquivo: $(basename "$lf")"
                    else
                        DIALOG_MSG "$BT_BOOT" " ERRO " 9 55 "Erro ao instalar a loading screen!"
                    fi
                fi

                # -- 2.3: ver arquivos atuais --
                if [ "$MENU_LOADING" = "3" ]; then
                    local INFO=""
                    for _ext in jpg gif mp4 ascii; do
                        local _f="${_LAUNCH_DIR}/loading.${_ext}"
                        if [ -f "$_f" ]; then
                            local tam data
                            tam=$(du -sh "$_f" 2>/dev/null | cut -f1 || echo "?")
                            data=$(stat -c "%y" "$_f" 2>/dev/null | cut -d'.' -f1 || echo "?")
                            INFO="${INFO}  loading.${_ext}  (${tam})  ${data}\n"
                        fi
                    done
                    [ -z "$INFO" ] && INFO="  Nenhum arquivo loading encontrado.\n"
                    DIALOG_MSG "$BT_BOOT" " LOADING SCREENS ATUAIS " 14 68 \
                        "Pasta: ${_LAUNCH_DIR}\n\n${INFO}"
                fi

                # -- 2.4: remover loading --
                if [ "$MENU_LOADING" = "4" ]; then
                    local PARA_REMOVER=()
                    for _ext in jpg gif mp4 ascii; do
                        [ -f "${_LAUNCH_DIR}/loading.${_ext}" ] && \
                            PARA_REMOVER+=("loading.${_ext}")
                    done

                    if [ ${#PARA_REMOVER[@]} -eq 0 ]; then
                        DIALOG_MSG "$BT_BOOT" " LOADING " 8 52 \
                            "Nenhum arquivo loading para remover."
                        continue
                    fi

                    local LISTA_REM=(); local IDX=1
                    for _f in "${PARA_REMOVER[@]}"; do
                        LISTA_REM+=("$IDX" "$_f")
                        IDX=$((IDX+1))
                    done

                    DIALOG_MENU SEL_REM "$BT_BOOT" " REMOVER LOADING " \
                        14 55 6 "${LISTA_REM[@]}"
                    RET=$?; NORM_RET
                    [ $RET -eq 1 ] && ExitAll
                    [ $RET -eq 3 ] && continue

                    local arq="${PARA_REMOVER[$((SEL_REM-1))]}"
                    _boot_backup "${_LAUNCH_DIR}/${arq}"
                    rm -f "${_LAUNCH_DIR}/${arq}" 2>/dev/null
                    DIALOG_MSG "$BT_BOOT" " REMOVIDO " 8 52 \
                        "Arquivo removido:\n${arq}"
                fi
            done
        fi

        # ------------------------------------------------------------------
        # OPCAO 3 — Ciclo de Logos (pasta BMPs/)
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "3" ]; then
            mkdir -p "$_BOOT_BMPS_DIR" 2>/dev/null || true
            local num_bmps
            num_bmps=$(find "$_BOOT_BMPS_DIR" -maxdepth 1 \
                -iname "*.bmp" 2>/dev/null | wc -l)

            DIALOG_MSG "$BT_BOOT" " CICLO DE LOGOS " 14 65 \
"O firmware suporta ciclo automatico de boot logos.

Como funciona:
  - Coloque varios arquivos .bmp em:
    ${_BOOT_BMPS_DIR}/
  - A cada boot, o proximo .bmp da lista
    sera usado como logo.bmp automaticamente.

BMPs na pasta: ${num_bmps} arquivo(s)

Use a opcao 'Instalar Imagem via USB' para
adicionar imagens a essa pasta."
        fi

        # ------------------------------------------------------------------
        # OPCAO 4 — Restaurar Originais
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "4" ]; then
            # Busca todos os backups criados pelo modulo
            mapfile -t BAKS < <(
                find "$_BOOT_DIR" "$_LAUNCH_DIR" \
                    -maxdepth 1 -name "*.bak.*" \
                    2>/dev/null | sort -r)

            if [ ${#BAKS[@]} -eq 0 ]; then
                DIALOG_MSG "$BT_BOOT" " RESTAURAR " 9 55 \
                    "Nenhum backup encontrado.\n\nOs backups sao criados automaticamente\nantes de qualquer substituicao."
                continue
            fi

            local LISTA_BAK=(); local IDX=1
            for _b in "${BAKS[@]}"; do
                local data_bak
                data_bak=$(stat -c "%y" "$_b" 2>/dev/null | cut -d'.' -f1 || echo "?")
                LISTA_BAK+=("$IDX" "$(basename "$_b")  ${data_bak}")
                IDX=$((IDX+1))
            done

            DIALOG_MENU SEL_BAK "$BT_BOOT" " ESCOLHA O BACKUP " \
                20 72 8 "${LISTA_BAK[@]}"
            RET=$?; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            local bak_sel="${BAKS[$((SEL_BAK-1))]}"
            # Determina o destino pelo nome do arquivo (remove .bak.YYYYMMDD_HHMMSS)
            local destino
            destino=$(echo "$bak_sel" | sed -E 's/\.bak\.[0-9]{8}_[0-9]{6}$//')

            printf "\033c" > "$CURR_TTY"
            printf "[*] Restaurando: %s\n" "$(basename "$bak_sel")" > "$CURR_TTY"

            if cp "$bak_sel" "$destino" 2>/dev/null; then
                DIALOG_MSG "$BT_BOOT" " RESTAURADO " 10 60 \
                    "Arquivo restaurado!\n\nBackup: $(basename "$bak_sel")\nDestino: $(basename "$destino")\n\nReinicie para aplicar."
            else
                DIALOG_MSG "$BT_BOOT" " ERRO " 9 55 \
                    "Erro ao restaurar o backup!\n\nVerifique as permissoes."
            fi
        fi

        # ------------------------------------------------------------------
        # OPCAO 5 — Status Atual
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "5" ]; then
            local INFO_STATUS=""

            # Boot logo
            local logo_file="${_BOOT_DIR}/logo.bmp"
            if [ -f "$logo_file" ]; then
                local tam data
                tam=$(du -sh "$logo_file" 2>/dev/null | cut -f1 || echo "?")
                data=$(stat -c "%y" "$logo_file" 2>/dev/null | cut -d'.' -f1 || echo "?")
                INFO_STATUS="${INFO_STATUS}BOOT LOGO:\n  ${logo_file}\n  Tamanho: ${tam}  |  Data: ${data}\n\n"
            else
                INFO_STATUS="${INFO_STATUS}BOOT LOGO:\n  Nenhum logo.bmp instalado\n\n"
            fi

            # BMPs para ciclo
            local num_bmps
            num_bmps=$(find "$_BOOT_BMPS_DIR" -maxdepth 1 \
                -iname "*.bmp" 2>/dev/null | wc -l)
            INFO_STATUS="${INFO_STATUS}CICLO DE LOGOS (BMPs/):\n  ${num_bmps} arquivo(s) em ${_BOOT_BMPS_DIR}\n\n"

            # Loading screens
            if [ -n "$_LAUNCH_DIR" ]; then
                INFO_STATUS="${INFO_STATUS}LOADING SCREENS:\n"
                local achou_loading=0
                for _ext in jpg gif mp4 ascii; do
                    local _f="${_LAUNCH_DIR}/loading.${_ext}"
                    if [ -f "$_f" ]; then
                        local tam
                        tam=$(du -sh "$_f" 2>/dev/null | cut -f1 || echo "?")
                        INFO_STATUS="${INFO_STATUS}  loading.${_ext}  (${tam})\n"
                        achou_loading=1
                    fi
                done
                [ "$achou_loading" -eq 0 ] && \
                    INFO_STATUS="${INFO_STATUS}  Nenhum arquivo loading encontrado\n"
            else
                INFO_STATUS="${INFO_STATUS}LOADING SCREENS:\n  Pasta nao encontrada\n"
            fi

            # Espaco na particao BOOT
            local livre_boot
            livre_boot=$(df -h "$_BOOT_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
            INFO_STATUS="${INFO_STATUS}\nEspaco livre na particao BOOT: ${livre_boot}"

            DIALOG_MSG "$BT_BOOT" " STATUS DAS IMAGENS DE BOOT " 22 70 \
                "${INFO_STATUS}"
        fi

        # ------------------------------------------------------------------
        # OPCAO 6 — Instalar Imagem via USB (copia para pasta do usuario)
        # ------------------------------------------------------------------
        if [ "$MENU_BOOT" = "6" ]; then
            if ! _detectar_usb; then
                DIALOG_MSG "$BT_BOOT" " USB " 9 55 \
                    "Nenhum pendrive detectado!\n\nInsira o USB com as imagens e\ntente novamente."
                continue
            fi
            _selecionar_usb
            local RET_USB=$? ; [ $RET_USB -eq 1 ] && ExitAll ; [ $RET_USB -eq 3 ] && continue

            mapfile -t USB_ALL < <(find "$_USB_PATH" \
                -type f \
                \( -iname "*.bmp" -o -iname "*.png" \
                   -o -iname "*.jpg" -o -iname "*.jpeg" \
                   -o -iname "*.gif" -o -iname "*.mp4" \) \
                2>/dev/null | sort)

            if [ ${#USB_ALL[@]} -eq 0 ]; then
                DIALOG_MSG "$BT_BOOT" " USB " 9 58 \
                    "Nenhuma imagem compativel encontrada.\n\nFormatos: .bmp, .png, .jpg, .gif, .mp4"
                continue
            fi

            local LISTA_USB_ALL=(); local IDX=1
            for _f in "${USB_ALL[@]}"; do
                LISTA_USB_ALL+=("$IDX" "$(basename "$_f")" "off")
                IDX=$((IDX+1))
            done

            local SELECIONADOS
            SELECIONADOS=$(dialog --output-fd 1 \
                --backtitle "$BT_BOOT" \
                --title " INSTALAR IMAGENS VIA USB " \
                --ok-label "COPIAR" \
                --extra-button --extra-label "VOLTAR" \
                --cancel-label "SAIR" \
                --checklist \
                "Selecione as imagens a copiar para:\n${_BOOT_IMG_USER_DIR}" \
                22 68 10 \
                "${LISTA_USB_ALL[@]}" \
                2>"$CURR_TTY")
            RET=$?; NORM_RET
            [ $RET -eq 1 ] && ExitAll
            [ $RET -eq 3 ] && continue

            if [ -z "$SELECIONADOS" ]; then
                DIALOG_MSG "$BT_BOOT" " AVISO " 7 45 "Nenhuma imagem selecionada."
                continue
            fi

            printf "\033c" > "$CURR_TTY"
            local _CNT=0 _ERR=0
            for _IDX in $SELECIONADOS; do
                _IDX="${_IDX//\"/}"
                local _FSRC="${USB_ALL[$((_IDX-1))]}"
                local _FDST="${_BOOT_IMG_USER_DIR}/$(basename "$_FSRC")"
                printf "[*] Copiando: %s...\n" "$(basename "$_FSRC")" > "$CURR_TTY"
                if cp "$_FSRC" "$_FDST" 2>/dev/null; then
                    chown ark:ark "$_FDST" 2>/dev/null || true
                    _CNT=$((_CNT+1))
                else
                    _ERR=$((_ERR+1))
                fi
            done

            DIALOG_MSG "$BT_BOOT" " COPIA CONCLUIDA " 10 58 \
                "Imagens copiadas para:\n${_BOOT_IMG_USER_DIR}\n\nSucesso: ${_CNT}  |  Erros: ${_ERR}\n\nUse as opcoes 1 ou 2 para instalar."
        fi

    done
}
