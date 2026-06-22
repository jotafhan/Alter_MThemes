#!/bin/bash
# =========================================================
# cat_7_atualizador.sh — Atualizador do Alter_MThemes
# Alter_MThemes v7.0 - Modulo 7
# =========================================================
#
# CONFIGURACAO: aponte para o seu repositorio
# Pode ser GitHub raw, servidor proprio, etc.
# =========================================================

# --- EDITE AQUI com sua URL base ---
# Usando raw.githubusercontent.com diretamente: sem cache de CDN,
# qualquer commit novo aparece imediatamente (jsDelivr pode demorar
# minutos/horas para sincronizar o cache do branch @main).
UPDATE_BASE_URL="https://raw.githubusercontent.com/jotafhan/Alter_MThemes/main"
# Exemplo GitHub (alternativa via jsDelivr, com cache):
# UPDATE_BASE_URL="https://cdn.jsdelivr.net/gh/USUARIO/REPO@main"
# Exemplo servidor proprio:
# UPDATE_BASE_URL="https://meuservidor.com/alter_mthemes"

# Arquivo de versao local
VERSION_FILE="$SCRIPT_DIR/lib/version.txt"
VERSION_LOCAL="7.0.0"
[ -f "$VERSION_FILE" ] && VERSION_LOCAL=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')

# Lista de arquivos que podem ser atualizados
# formato: "arquivo_local.sh|nome_no_servidor.sh"
ARQUIVOS_ATUALIZAVEIS=(
    "Alter_MThemes.sh|Alter_MThemes.sh"
    "lib/core.sh|lib/core.sh"
    "lib/init.sh|lib/init.sh"
    "lib/cat_1_font_studio.sh|lib/cat_1_font_studio.sh"
    "lib/cat_2_visual_studio.sh|lib/cat_2_visual_studio.sh"
    "lib/cat_3_logo_center.sh|lib/cat_3_logo_center.sh"
    "lib/cat_4_theme_hub.sh|lib/cat_4_theme_hub.sh"
    "lib/cat_5_backup_center.sh|lib/cat_5_backup_center.sh"
    "lib/cat_6_interface_ui.sh|lib/cat_6_interface_ui.sh"
    "lib/cat_7_atualizador.sh|lib/cat_7_atualizador.sh"
    "lib/menu_aparencia.cfg|lib/menu_aparencia.cfg"
    "lib/menu_dialogrc|lib/menu_dialogrc"
    "lib/validator.sh|lib/validator.sh"
)

# -----------------------------------------------------------
# Verifica conexao
# -----------------------------------------------------------
_upd_tem_internet() {
    ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1
}

# -----------------------------------------------------------
# Sincroniza data/hora do sistema (necessario para TLS/HTTPS
# funcionar corretamente — sem isso o wget pode rejeitar o
# certificado do servidor por achar que esta expirado/invalido)
# -----------------------------------------------------------
_upd_sincronizar_relogio() {
    sudo timedatectl set-ntp 1 2>/dev/null
}

# -----------------------------------------------------------
# Baixa um arquivo temporario e retorna o caminho
# -----------------------------------------------------------
_upd_baixar_tmp() {
    local url="$1"
    local tmp
    tmp=$(mktemp /tmp/alter_upd.XXXXXX)
    wget -q --timeout=15 --tries=2 --no-check-certificate \
        --header="Cache-Control: no-cache" \
        --header="Pragma: no-cache" \
        --user-agent="Mozilla/5.0 (Linux; Android)" \
        -O "$tmp" "$url" 2>>"/tmp/alter_upd_wget.log"
    if [ $? -eq 0 ] && [ -s "$tmp" ]; then
        echo "$tmp"
    else
        rm -f "$tmp"
        echo ""
    fi
}

# -----------------------------------------------------------
# Compara MD5 de dois arquivos
# Retorna 0 se diferentes (precisa atualizar), 1 se iguais
# -----------------------------------------------------------
_upd_diferente() {
    local local_f="$1"
    local remote_f="$2"
    [ ! -f "$local_f" ] && return 0   # nao existe localmente = precisa baixar
    local md5_local md5_remote
    md5_local=$(md5sum "$local_f" 2>/dev/null | cut -d' ' -f1)
    md5_remote=$(md5sum "$remote_f" 2>/dev/null | cut -d' ' -f1)
    [ "$md5_local" != "$md5_remote" ] && return 0
    return 1
}

# -----------------------------------------------------------
# SUB: Verificar atualizacoes disponiveis
# -----------------------------------------------------------
_upd_verificar() {
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
        --title " Verificando... " \
        --infobox "Conectando ao servidor de atualizacoes..." \
        5 50 2>"$CURR_TTY"

    if ! _upd_tem_internet; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Sem Internet " \
            --msgbox "Sem conexao com a internet.\nVerifique o Wi-Fi e tente novamente." \
            7 50 2>"$CURR_TTY"
        return 1
    fi

    # Sincroniza o relogio antes de baixar (evita falha de certificado TLS)
    _upd_sincronizar_relogio

    # Baixa version.txt remoto
    local TMP_VER
    rm -f "/tmp/alter_upd_wget.log"
    TMP_VER=$(_upd_baixar_tmp "${UPDATE_BASE_URL}/lib/version.txt")
    if [ -z "$TMP_VER" ]; then
        local ERRO_DETALHE
        ERRO_DETALHE=$(tail -3 "/tmp/alter_upd_wget.log" 2>/dev/null | tr -d '\r')
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Erro " \
            --msgbox "Nao foi possivel acessar o servidor.\nURL: ${UPDATE_BASE_URL}\n\nDetalhe:\n${ERRO_DETALHE:-desconhecido}\n\nVerifique a configuracao da URL no modulo 7." \
            13 70 2>"$CURR_TTY"
        return 1
    fi

    VERSION_REMOTA=$(cat "$TMP_VER" 2>/dev/null | tr -d '[:space:]')
    rm -f "$TMP_VER"

    # Compara versoes
    if [ "$VERSION_REMOTA" = "$VERSION_LOCAL" ]; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Atualizado " \
            --msgbox "Voce ja esta na versao mais recente!\n\nVersao local  : $VERSION_LOCAL\nVersao remota : $VERSION_REMOTA" \
            8 50 2>"$CURR_TTY"
        return 0
    fi

    # Ha atualizacao — verifica quais arquivos mudaram
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
        --title " Verificando Arquivos " \
        --infobox "Nova versao encontrada: $VERSION_REMOTA\nAnalisando arquivos modificados..." \
        6 55 2>"$CURR_TTY"

    ARQUIVOS_PARA_ATUALIZAR=()
    TMPS_PARA_ATUALIZAR=()

    for entry in "${ARQUIVOS_ATUALIZAVEIS[@]}"; do
        local_path="${entry%%|*}"
        remote_path="${entry##*|}"
        full_local="$SCRIPT_DIR/$local_path"
        url_remota="${UPDATE_BASE_URL}/${remote_path}"

        TMP_ARQ=$(_upd_baixar_tmp "$url_remota")
        if [ -n "$TMP_ARQ" ]; then
            if _upd_diferente "$full_local" "$TMP_ARQ"; then
                ARQUIVOS_PARA_ATUALIZAR+=("$local_path")
                TMPS_PARA_ATUALIZAR+=("$TMP_ARQ")
            else
                rm -f "$TMP_ARQ"
            fi
        fi
    done

    if [ ${#ARQUIVOS_PARA_ATUALIZAR[@]} -eq 0 ]; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Sem Mudancas " \
            --msgbox "Versao remota: $VERSION_REMOTA\n\nNenhum arquivo foi modificado.\nVersao local atualizada para $VERSION_REMOTA." \
            8 55 2>"$CURR_TTY"
        echo "$VERSION_REMOTA" > "$VERSION_FILE"
        return 0
    fi

    # Mostra lista do que vai ser atualizado
    local LISTA_INFO=""
    for arq in "${ARQUIVOS_PARA_ATUALIZAR[@]}"; do
        LISTA_INFO="${LISTA_INFO}\n  • ${arq}"
    done

    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
        --title " Atualizacao Disponivel " \
        --yes-label "ATUALIZAR" \
        --no-label "CANCELAR" \
        --yesno \
"Nova versao: $VERSION_REMOTA  (atual: $VERSION_LOCAL)

Arquivos que serao atualizados (${#ARQUIVOS_PARA_ATUALIZAR[@]} arquivo(s)):
${LISTA_INFO}

Deseja atualizar agora?" \
        $(( ${#ARQUIVOS_PARA_ATUALIZAR[@]} + 12 )) 65 2>"$CURR_TTY"

    if [ $? -ne 0 ]; then
        # Limpa temporarios
        for tmp in "${TMPS_PARA_ATUALIZAR[@]}"; do rm -f "$tmp"; done
        return 0
    fi

    # Aplica atualizacao
    _upd_aplicar
}

# -----------------------------------------------------------
# Aplica os arquivos ja baixados
# -----------------------------------------------------------
_upd_aplicar() {
    local ERROS=0
    local OK=0
    local BAK_DIR="$SCRIPT_DIR/lib/backups_update_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BAK_DIR" 2>/dev/null

    printf "\033c" > "$CURR_TTY"
    printf "Aplicando atualizacao v%s...\n\n" "$VERSION_REMOTA" > "$CURR_TTY"

    local i=0
    for arq in "${ARQUIVOS_PARA_ATUALIZAR[@]}"; do
        local full_local="$SCRIPT_DIR/$arq"
        local tmp="${TMPS_PARA_ATUALIZAR[$i]}"
        (( i++ ))

        printf "  Atualizando: %s\n" "$arq" > "$CURR_TTY"

        # Backup do arquivo local
        if [ -f "$full_local" ]; then
            local bak_nome
            bak_nome=$(echo "$arq" | tr '/' '_')
            cp "$full_local" "$BAK_DIR/${bak_nome}.bak" 2>/dev/null
        fi

        # Garante que o diretorio existe
        mkdir -p "$(dirname "$full_local")" 2>/dev/null

        # Aplica
        if cp "$tmp" "$full_local" 2>/dev/null; then
            chmod 755 "$full_local" 2>/dev/null
            (( OK++ ))
        else
            printf "  ERRO ao atualizar: %s\n" "$arq" > "$CURR_TTY"
            (( ERROS++ ))
        fi
        rm -f "$tmp"
    done

    # Salva nova versao
    echo "$VERSION_REMOTA" > "$VERSION_FILE"

    sleep 1

    if [ $ERROS -eq 0 ]; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Atualizacao Concluida " \
            --msgbox \
"Atualizacao concluida com sucesso!

Versao anterior : $VERSION_LOCAL
Versao atual    : $VERSION_REMOTA
Arquivos atualizados: $OK

Backup dos arquivos anteriores em:
$BAK_DIR

Reinicie o Alter_MThemes para aplicar." \
            13 62 2>"$CURR_TTY"
    else
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Atualizacao Parcial " \
            --msgbox \
"Atualizacao concluida com erros.

OK    : $OK arquivo(s)
Erros : $ERROS arquivo(s)

Backup disponivel em:
$BAK_DIR" \
            11 55 2>"$CURR_TTY"
    fi
}

# -----------------------------------------------------------
# SUB: Configurar URL do servidor
# -----------------------------------------------------------
_upd_configurar_url() {
    local URL_ATUAL
    URL_FILE="$SCRIPT_DIR/lib/update_url.cfg"
    [ -f "$URL_FILE" ] && UPDATE_BASE_URL=$(cat "$URL_FILE" 2>/dev/null | tr -d '[:space:]')

    local OPCAO
    OPCAO=$(dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
        --title " Servidor de Atualizacoes " \
        --ok-label "OK" --cancel-label "Voltar" \
        --menu \
"URL atual: ${UPDATE_BASE_URL:-nao configurada}

Escolha o servidor:" \
        18 72 5 \
        "1" "GitHub (usuario/repositorio publico)" \
        "2" "GitHub RAW — colar URL completa" \
        "3" "Servidor proprio — colar URL" \
        "4" "Ver URL atual" \
        "5" "Limpar configuracao" \
        2>"$CURR_TTY")
    [ $? -ne 0 ] && return

    case "$OPCAO" in
        1|2|3)
            local MSG
            case "$OPCAO" in
                1) MSG="Digite no formato:\nhttps://raw.githubusercontent.com/USUARIO/REPO/main" ;;
                2) MSG="Cole a URL RAW completa do GitHub:" ;;
                3) MSG="Digite a URL base do seu servidor:" ;;
            esac
            # Como nao ha teclado fisico, mostra instrucoes para editar via SSH
            dialog --output-fd 1 \
                --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                --title " Configurar URL " \
                --msgbox \
"Para configurar a URL, edite via SSH:

echo 'SUA_URL_AQUI' > $URL_FILE

Exemplo GitHub:
echo 'https://raw.githubusercontent.com/USUARIO/REPO/main' > $URL_FILE

Atual: ${UPDATE_BASE_URL:-nao configurada}" \
                14 68 2>"$CURR_TTY" ;;
        4)
            dialog --output-fd 1 \
                --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                --title " URL Atual " \
                --msgbox "URL configurada:\n${UPDATE_BASE_URL:-nao configurada}\n\nVersao local: ${VERSION_LOCAL}" \
                8 68 2>"$CURR_TTY" ;;
        5)
            rm -f "$URL_FILE" 2>/dev/null
            UPDATE_BASE_URL=""
            dialog --output-fd 1 \
                --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                --title " URL Removida " \
                --msgbox "Configuracao de URL removida." \
                6 40 2>"$CURR_TTY" ;;
    esac

    # Recarrega URL se arquivo existir
    [ -f "$URL_FILE" ] && UPDATE_BASE_URL=$(cat "$URL_FILE" 2>/dev/null | tr -d '[:space:]')
}

# -----------------------------------------------------------
# SUB: Ver historico de atualizacoes
# -----------------------------------------------------------
_upd_historico() {
    local BAKS
    BAKS=$(find "$SCRIPT_DIR/lib" -maxdepth 1 -name "backups_update_*" \
        -type d 2>/dev/null | sort -r)

    if [ -z "$BAKS" ]; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Historico " \
            --msgbox "Nenhuma atualizacao anterior encontrada." \
            6 48 2>"$CURR_TTY"
        return
    fi

    local INFO=""
    while IFS= read -r bdir; do
        local NOME=$(basename "$bdir")
        local QTD=$(find "$bdir" -type f | wc -l)
        local DATA=${NOME#backups_update_}
        INFO="${INFO}• ${DATA}  (${QTD} arquivo(s))\n"
    done <<< "$BAKS"

    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
        --title " Historico de Atualizacoes " \
        --msgbox "Atualizacoes anteriores:\n\n${INFO}\nVersao atual: $VERSION_LOCAL" \
        16 60 2>"$CURR_TTY"
}

# -----------------------------------------------------------
# Carrega URL customizada se existir
# -----------------------------------------------------------
URL_FILE="$SCRIPT_DIR/lib/update_url.cfg"
[ -f "$URL_FILE" ] && UPDATE_BASE_URL=$(cat "$URL_FILE" 2>/dev/null | tr -d '[:space:]')

# -----------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------
categoria_7() {
    while true; do
        local OPCAO
        OPCAO=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
            --title " Atualizador " \
            --ok-label "OK" \
            --extra-button --extra-label "VOLTAR" \
            --cancel-label "SAIR" \
            --menu \
"Versao local: $VERSION_LOCAL
Servidor   : ${UPDATE_BASE_URL:-nao configurado}" \
            18 68 5 \
            1 "Verificar e Instalar Atualizacoes" \
            2 "Configurar Servidor de Atualizacoes" \
            3 "Historico de Atualizacoes" \
            4 "Forcar Reverter para Backup" \
            5 "Voltar ao Menu Principal" \
            2>"$CURR_TTY")
        local RET=$?
        NORM_RET_MENU
        [ $RET -eq 1 ] || [ $RET -eq 3 ] || [ $RET -eq 255 ] && break

        case "$OPCAO" in
            1) _upd_verificar ;;
            2) _upd_configurar_url ;;
            3) _upd_historico ;;
            4)
                local BAKS_LIST
                BAKS_LIST=$(find "$SCRIPT_DIR/lib" -maxdepth 1 \
                    -name "backups_update_*" -type d 2>/dev/null | sort -r | head -5)
                if [ -z "$BAKS_LIST" ]; then
                    dialog --output-fd 1 \
                        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                        --title " Reverter " \
                        --msgbox "Nenhum backup de atualizacao encontrado." \
                        6 50 2>"$CURR_TTY"
                else
                    # Usa o backup mais recente
                    local ULTIMO_BAK
                    ULTIMO_BAK=$(echo "$BAKS_LIST" | head -1)
                    dialog --output-fd 1 \
                        --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                        --title " Reverter " \
                        --yes-label "REVERTER" --no-label "CANCELAR" \
                        --yesno "Reverter para o backup:\n$(basename "$ULTIMO_BAK")?" \
                        7 60 2>"$CURR_TTY"
                    if [ $? -eq 0 ]; then
                        for bak in "$ULTIMO_BAK"/*.bak; do
                            [ -f "$bak" ] || continue
                            DEST=$(basename "$bak" .bak | tr '_' '/')
                            cp "$bak" "$SCRIPT_DIR/$DEST" 2>/dev/null && \
                                chmod 755 "$SCRIPT_DIR/$DEST" 2>/dev/null
                        done
                        dialog --output-fd 1 \
                            --backtitle "$(_menu_preview_backtitle 2>/dev/null || echo "$APP_NAME $APP_VER")" \
                            --title " Revertido " \
                            --msgbox "Backup restaurado com sucesso!\nReinicie o Alter_MThemes." \
                            7 50 2>"$CURR_TTY"
                    fi
                fi ;;
            5) break ;;
        esac
    done
}
