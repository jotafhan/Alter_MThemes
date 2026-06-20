#!/bin/bash
# =========================================================
# cat_7_interface_ui.sh — Aparencia do Menu Principal
# Alter_MThemes v8.0 - Modulo 8
# =========================================================

MENU_CFG_FILE="$SCRIPT_DIR/lib/menu_aparencia.cfg"
DIALOGRC_CUSTOM="$SCRIPT_DIR/lib/menu_dialogrc"

# Valores padrao
_DEFAULT_TITULO=" MENU PRINCIPAL "
_DEFAULT_SEPARADOR="------------------------------------------------------------------"
_DEFAULT_LARGURA=68
_DEFAULT_ALTURA=22
_DEFAULT_ITENS_VISIVEIS=9
_DEFAULT_MOSTRAR_HORA=1
_DEFAULT_MOSTRAR_TEMA=1
_DEFAULT_MOSTRAR_BACKUP=1
_DEFAULT_TEMA_PRESET="nenhum"
_DEFAULT_FONTE_CONSOLE="Lat15-Terminus16"

# Cores manuais (usadas pelo editor manual)
_DEFAULT_COR_FUNDO="BLACK"
_DEFAULT_COR_TEXTO="GREEN"
_DEFAULT_COR_TITULO="GREEN"
_DEFAULT_COR_BORDA="GREEN"
_DEFAULT_COR_SELECAO_FG="BLACK"
_DEFAULT_COR_SELECAO_BG="GREEN"
_DEFAULT_COR_BOTAO_FG="BLACK"
_DEFAULT_COR_BOTAO_BG="GREEN"
_DEFAULT_COR_NUMEROS="RED"
_DEFAULT_SOMBRA="OFF"

# Cores disponiveis no dialog (terminais tty)
_CORES_DISPONIVEIS="BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE"

# -----------------------------------------------------------
# Carrega config salva
# -----------------------------------------------------------
_menu_cfg_carregar() {
    MENU_TITULO="$_DEFAULT_TITULO"
    MENU_SEPARADOR="$_DEFAULT_SEPARADOR"
    MENU_LARGURA=$_DEFAULT_LARGURA
    MENU_ALTURA=$_DEFAULT_ALTURA
    MENU_ITENS_VIS=$_DEFAULT_ITENS_VISIVEIS
    MENU_HORA=$_DEFAULT_MOSTRAR_HORA
    MENU_TEMA_NOME=$_DEFAULT_MOSTRAR_TEMA
    MENU_BACKUP=$_DEFAULT_MOSTRAR_BACKUP
    MENU_TEMA_PRESET="$_DEFAULT_TEMA_PRESET"
    MENU_FONTE_CONSOLE="$_DEFAULT_FONTE_CONSOLE"
    # Cores manuais
    MC_FUNDO="$_DEFAULT_COR_FUNDO"
    MC_TEXTO="$_DEFAULT_COR_TEXTO"
    MC_TITULO="$_DEFAULT_COR_TITULO"
    MC_BORDA="$_DEFAULT_COR_BORDA"
    MC_SEL_FG="$_DEFAULT_COR_SELECAO_FG"
    MC_SEL_BG="$_DEFAULT_COR_SELECAO_BG"
    MC_BTN_FG="$_DEFAULT_COR_BOTAO_FG"
    MC_BTN_BG="$_DEFAULT_COR_BOTAO_BG"
    MC_NUMS="$_DEFAULT_COR_NUMEROS"
    MC_SOMBRA="$_DEFAULT_SOMBRA"
    if [ -f "$MENU_CFG_FILE" ]; then
        source "$MENU_CFG_FILE" 2>/dev/null || true
    fi
    _menu_validar_tamanho
}

# -----------------------------------------------------------
# Valida MENU_ALTURA / MENU_LARGURA contra o tamanho real
# do terminal (via stty size). Evita dialog cortado/quebrado
# em telas pequenas ou apos mudanca de resolucao/console.
# Margem de seguranca de 1 linha e 2 colunas.
# -----------------------------------------------------------
_menu_validar_tamanho() {
    local real_linhas real_colunas
    if [ -n "$CURR_TTY" ] && [ -e "$CURR_TTY" ]; then
        read -r real_linhas real_colunas < <(stty size < "$CURR_TTY" 2>/dev/null)
    fi
    # Fallback: tenta o tty padrao se CURR_TTY nao estiver definido/acessivel
    if [ -z "$real_linhas" ] || [ -z "$real_colunas" ]; then
        read -r real_linhas real_colunas < <(stty size 2>/dev/null)
    fi

    # Se nao foi possivel detectar (ex: nao-tty), nao altera nada
    [ -z "$real_linhas" ] || [ -z "$real_colunas" ] && return
    [ "$real_linhas" -le 0 ] 2>/dev/null && return
    [ "$real_colunas" -le 0 ] 2>/dev/null && return

    local max_altura=$(( real_linhas - 1 ))
    local max_largura=$(( real_colunas - 2 ))
    local ajustado=0

    if [ "$MENU_ALTURA" -gt "$max_altura" ] 2>/dev/null; then
        MENU_ALTURA=$max_altura
        ajustado=1
    fi
    if [ "$MENU_LARGURA" -gt "$max_largura" ] 2>/dev/null; then
        MENU_LARGURA=$max_largura
        ajustado=1
    fi

    # Itens visiveis nao pode exceder altura util (titulo+botoes ~6 linhas)
    local max_itens=$(( MENU_ALTURA - 6 ))
    [ "$max_itens" -lt 3 ] && max_itens=3
    if [ "$MENU_ITENS_VIS" -gt "$max_itens" ] 2>/dev/null; then
        MENU_ITENS_VIS=$max_itens
        ajustado=1
    fi

    MENU_TELA_REAL="${real_linhas}x${real_colunas}"

    if [ "$ajustado" -eq 1 ]; then
        MENU_TELA_AJUSTADA=1
    else
        MENU_TELA_AJUSTADA=0
    fi
}

# -----------------------------------------------------------
# Salva config atual
# -----------------------------------------------------------
_menu_cfg_salvar() {
    cat > "$MENU_CFG_FILE" << EOF
# Alter_MThemes — Aparencia do Menu Principal
# Gerado: $(date '+%d/%m/%Y %H:%M')
MENU_TITULO="$MENU_TITULO"
MENU_SEPARADOR="$MENU_SEPARADOR"
MENU_LARGURA=$MENU_LARGURA
MENU_ALTURA=$MENU_ALTURA
MENU_ITENS_VIS=$MENU_ITENS_VIS
MENU_HORA=$MENU_HORA
MENU_TEMA_NOME=$MENU_TEMA_NOME
MENU_BACKUP=$MENU_BACKUP
MENU_TEMA_PRESET="$MENU_TEMA_PRESET"
MENU_FONTE_CONSOLE="$MENU_FONTE_CONSOLE"
MC_FUNDO="$MC_FUNDO"
MC_TEXTO="$MC_TEXTO"
MC_TITULO="$MC_TITULO"
MC_BORDA="$MC_BORDA"
MC_SEL_FG="$MC_SEL_FG"
MC_SEL_BG="$MC_SEL_BG"
MC_BTN_FG="$MC_BTN_FG"
MC_BTN_BG="$MC_BTN_BG"
MC_NUMS="$MC_NUMS"
MC_SOMBRA="$MC_SOMBRA"
EOF
    chmod 644 "$MENU_CFG_FILE" 2>/dev/null || true
}

# -----------------------------------------------------------
# Gera um dialogrc a partir das variaveis MC_*
# REGRA: border/menubox_border = mesma cor do fundo da janela
#        para ELIMINAR as marcas brancas
# -----------------------------------------------------------
_menu_gerar_dialogrc_manual() {
    # screen_color SEMPRE BLACK,BLACK para nao criar faixa colorida
    # ao redor da janela no hardware TTY real (causa das marcas brancas).
    # use_shadow = OFF obrigatorio — shadow no TTY gera artefatos brancos.
    # border_color e menubox_border_color com BG = $MC_FUNDO para
    # fundir a borda com o fundo da janela e nao aparecer linha branca.
    cat > "$DIALOGRC_CUSTOM" << RC
use_colors = ON
use_shadow = OFF
screen_color = (BLACK,BLACK,OFF)
shadow_color = (BLACK,BLACK,OFF)
dialog_color = ($MC_TEXTO,$MC_FUNDO,OFF)
title_color = ($MC_TITULO,$MC_FUNDO,ON)
border_color = ($MC_BORDA,$MC_FUNDO,ON)
border2_color = ($MC_BORDA,$MC_FUNDO,ON)
button_active_color = ($MC_BTN_FG,$MC_BTN_BG,ON)
button_inactive_color = ($MC_TEXTO,$MC_FUNDO,OFF)
button_key_active_color = ($MC_BTN_FG,$MC_BTN_BG,ON)
button_key_inactive_color = ($MC_NUMS,$MC_FUNDO,OFF)
button_label_active_color = ($MC_BTN_FG,$MC_BTN_BG,ON)
button_label_inactive_color = ($MC_TEXTO,$MC_FUNDO,ON)
inputbox_color = ($MC_TEXTO,$MC_FUNDO,OFF)
inputbox_border_color = ($MC_BORDA,$MC_FUNDO,ON)
inputbox_border2_color = ($MC_BORDA,$MC_FUNDO,ON)
searchbox_color = ($MC_TEXTO,$MC_FUNDO,OFF)
searchbox_title_color = ($MC_TITULO,$MC_FUNDO,ON)
searchbox_border_color = ($MC_BORDA,$MC_FUNDO,ON)
searchbox_border2_color = ($MC_BORDA,$MC_FUNDO,ON)
position_indicator_color = ($MC_TITULO,$MC_FUNDO,ON)
menubox_color = ($MC_TEXTO,$MC_FUNDO,OFF)
menubox_border_color = ($MC_BORDA,$MC_FUNDO,ON)
menubox_border2_color = ($MC_BORDA,$MC_FUNDO,ON)
item_color = ($MC_TEXTO,$MC_FUNDO,OFF)
item_selected_color = ($MC_SEL_FG,$MC_SEL_BG,ON)
tag_color = ($MC_NUMS,$MC_FUNDO,ON)
tag_selected_color = ($MC_SEL_FG,$MC_SEL_BG,ON)
tag_key_color = ($MC_NUMS,$MC_FUNDO,OFF)
tag_key_selected_color = ($MC_NUMS,$MC_SEL_BG,ON)
check_color = ($MC_TEXTO,$MC_FUNDO,OFF)
check_selected_color = ($MC_SEL_FG,$MC_SEL_BG,ON)
uarrow_color = ($MC_TITULO,$MC_FUNDO,ON)
darrow_color = ($MC_TITULO,$MC_FUNDO,ON)
RC
}

# -----------------------------------------------------------
# BANCO DE TEMAS PRE-PRONTOS
# REGRA ANTI-BORDA-BRANCA:
#   border_color e menubox_border_color SEMPRE com fundo
#   igual ao dialog_color para nao aparecer marca branca
# -----------------------------------------------------------
_tema_descricao() {
    case "$1" in
        "minimalista_claro")   echo "Minimalista Claro   — fundo branco, selecao azul" ;;
        "darkos_original")     echo "DarkOS Original     — azul escuro, texto ciano" ;;
        "terminal_verde")      echo "Terminal Verde      — preto e verde sem bordas" ;;
        "retro_ambar")         echo "Retro Ambar         — monitor CRT laranja" ;;
        "roxo_neon")           echo "Roxo Neon           — destaque magenta" ;;
        "vermelho_hacker")     echo "Vermelho Hacker     — borda vermelha agressiva" ;;
        "ciano_noturno")       echo "Ciano Noturno       — sci-fi preto e ciano" ;;
        "padrao_sistema")      echo "Padrao do Sistema   — sem customizacao" ;;
        *)                     echo "Desconhecido" ;;
    esac
}

_tema_aplicar_preset() {
    local preset="$1"
    MENU_TEMA_PRESET="$preset"

    case "$preset" in

        "minimalista_claro")
            MENU_TITULO=" MENU PRINCIPAL "
            MENU_SEPARADOR=""
            MENU_LARGURA=66; MENU_ALTURA=20; MENU_ITENS_VIS=8
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="WHITE"; MC_TEXTO="BLACK"; MC_TITULO="BLUE"
            MC_BORDA="WHITE"; MC_SEL_FG="WHITE"; MC_SEL_BG="BLUE"
            MC_BTN_FG="WHITE"; MC_BTN_BG="BLUE"
            MC_NUMS="BLUE"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "darkos_original")
            MENU_TITULO=" MENU PRINCIPAL "
            MENU_SEPARADOR="================================================================"
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="BLUE"; MC_TEXTO="CYAN"; MC_TITULO="WHITE"
            MC_BORDA="CYAN"; MC_SEL_FG="BLACK"; MC_SEL_BG="CYAN"
            MC_BTN_FG="BLACK"; MC_BTN_BG="CYAN"
            MC_NUMS="WHITE"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "terminal_verde")
            # Borda = mesma cor do fundo (BLACK) — zero marca branca
            MENU_TITULO="[ MENU PRINCIPAL ]"
            MENU_SEPARADOR="################################################################"
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="BLACK"; MC_TEXTO="GREEN"; MC_TITULO="GREEN"
            MC_BORDA="GREEN"; MC_SEL_FG="BLACK"; MC_SEL_BG="GREEN"
            MC_BTN_FG="BLACK"; MC_BTN_BG="GREEN"
            MC_NUMS="RED"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "retro_ambar")
            MENU_TITULO="*** MENU PRINCIPAL ***"
            MENU_SEPARADOR="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="BLACK"; MC_TEXTO="YELLOW"; MC_TITULO="YELLOW"
            MC_BORDA="YELLOW"; MC_SEL_FG="BLACK"; MC_SEL_BG="YELLOW"
            MC_BTN_FG="BLACK"; MC_BTN_BG="YELLOW"
            MC_NUMS="RED"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "roxo_neon")
            MENU_TITULO="~ MENU PRINCIPAL ~"
            MENU_SEPARADOR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="BLACK"; MC_TEXTO="MAGENTA"; MC_TITULO="MAGENTA"
            MC_BORDA="MAGENTA"; MC_SEL_FG="BLACK"; MC_SEL_BG="MAGENTA"
            MC_BTN_FG="BLACK"; MC_BTN_BG="MAGENTA"
            MC_NUMS="RED"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "vermelho_hacker")
            MENU_TITULO=">> MENU PRINCIPAL <<"
            MENU_SEPARADOR="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=0
            MC_FUNDO="BLACK"; MC_TEXTO="RED"; MC_TITULO="RED"
            MC_BORDA="RED"; MC_SEL_FG="BLACK"; MC_SEL_BG="RED"
            MC_BTN_FG="BLACK"; MC_BTN_BG="RED"
            MC_NUMS="YELLOW"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "ciano_noturno")
            MENU_TITULO=":: MENU PRINCIPAL ::"
            MENU_SEPARADOR="-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
            MENU_LARGURA=68; MENU_ALTURA=22; MENU_ITENS_VIS=9
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="BLACK"; MC_TEXTO="CYAN"; MC_TITULO="CYAN"
            MC_BORDA="CYAN"; MC_SEL_FG="BLACK"; MC_SEL_BG="CYAN"
            MC_BTN_FG="BLACK"; MC_BTN_BG="CYAN"
            MC_NUMS="RED"; MC_SOMBRA="OFF"
            _menu_gerar_dialogrc_manual ;;

        "padrao_sistema")
            MENU_TITULO="$_DEFAULT_TITULO"
            MENU_SEPARADOR="$_DEFAULT_SEPARADOR"
            MENU_LARGURA=$_DEFAULT_LARGURA; MENU_ALTURA=$_DEFAULT_ALTURA
            MENU_ITENS_VIS=$_DEFAULT_ITENS_VISIVEIS
            MENU_HORA=1; MENU_TEMA_NOME=1; MENU_BACKUP=1
            MC_FUNDO="$_DEFAULT_COR_FUNDO"; MC_TEXTO="$_DEFAULT_COR_TEXTO"
            MC_TITULO="$_DEFAULT_COR_TITULO"; MC_BORDA="$_DEFAULT_COR_BORDA"
            MC_SEL_FG="$_DEFAULT_COR_SELECAO_FG"; MC_SEL_BG="$_DEFAULT_COR_SELECAO_BG"
            MC_BTN_FG="$_DEFAULT_COR_BOTAO_FG"; MC_BTN_BG="$_DEFAULT_COR_BOTAO_BG"
            MC_NUMS="$_DEFAULT_COR_NUMEROS"; MC_SOMBRA="$_DEFAULT_SOMBRA"
            rm -f "$DIALOGRC_CUSTOM" 2>/dev/null || true ;;
    esac
}

# -----------------------------------------------------------
# Exporta DIALOGRC
# -----------------------------------------------------------
_menu_exportar_dialogrc() {
    if [ -f "$DIALOGRC_CUSTOM" ]; then
        export DIALOGRC="$DIALOGRC_CUSTOM"
    else
        unset DIALOGRC
    fi
}

# -----------------------------------------------------------
# Fonte do console (setfont) — afeta o tamanho das letras
# exibidas na TTY (e portanto em todo o dialog) ENQUANTO
# o usuario estiver dentro do modulo de Aparencia.
# A fonte original e restaurada ao sair do modulo.
# Se 'setfont' nao existir ou a fonte nao for encontrada,
# falha silenciosamente sem travar o script.
# -----------------------------------------------------------
_FONTES_DISPONIVEIS="Lat15-Terminus12x6 Lat15-Terminus14 Lat15-Terminus16 Lat15-Terminus18x10 Lat15-Terminus20x10 Lat15-Terminus22x11 Lat15-Terminus24x12"

_fonte_descricao() {
    case "$1" in
        "Lat15-Terminus12x6")  echo "Bem Pequena    (12x6)" ;;
        "Lat15-Terminus14")    echo "Pequena        (14 — proxima do padrao)" ;;
        "Lat15-Terminus16")    echo "Padrao         (16 — tamanho normal)" ;;
        "Lat15-Terminus18x10") echo "Media           (18x10)" ;;
        "Lat15-Terminus20x10") echo "Grande          (20x10)" ;;
        "Lat15-Terminus22x11") echo "Maior           (22x11)" ;;
        "Lat15-Terminus24x12") echo "A Maior         (24x12)" ;;
        *)                     echo "Desconhecida" ;;
    esac
}

_menu_fonte_aplicar() {
    command -v setfont >/dev/null 2>&1 || return
    local fonte="${MENU_FONTE_CONSOLE:-$_DEFAULT_FONTE_CONSOLE}"
    setfont "$fonte" 2>/dev/null || true
}

_menu_fonte_restaurar_original() {
    command -v setfont >/dev/null 2>&1 || return
    setfont "${_FONTE_CONSOLE_ORIGINAL:-$_DEFAULT_FONTE_CONSOLE}" 2>/dev/null || true
}

# -----------------------------------------------------------
# Preview backtitle
# -----------------------------------------------------------
_menu_preview_backtitle() {
    local bt="${APP_NAME} ${APP_VER}"
    [ "${MENU_TEMA_NOME:-1}" -eq 1 ] && bt="${bt}  |  Tema: ${THEME_NAME}"
    local agora
    agora=$(date '+%d/%m/%Y %H:%M' 2>/dev/null || echo "")
    [ "${MENU_HORA:-1}" -eq 1 ] && bt="${bt}  |  ${agora}"
    echo "$bt"
}

# -----------------------------------------------------------
# Aplica ao ser carregado pelo script principal
# -----------------------------------------------------------
menu_aparencia_aplicar() {
    _menu_cfg_carregar
    _menu_exportar_dialogrc
}

# -----------------------------------------------------------
# HELPER: escolher uma cor numa lista
# $1 = titulo do campo  $2 = cor atual
# Retorna a cor escolhida em stdout
# -----------------------------------------------------------
_escolher_cor() {
    local titulo="$1"
    local atual="$2"
    local i=1
    local opcoes=()
    for c in $_CORES_DISPONIVEIS; do
        local mark=""
        [ "$c" = "$atual" ] && mark=" <-- ATUAL"
        opcoes+=("$i" "$c$mark")
        (( i++ ))
    done
    local ESCOLHA
    ESCOLHA=$(dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " $titulo " \
        --ok-label "OK" --cancel-label "Cancelar" \
        --menu "Cor atual: $atual" \
        18 50 8 \
        "${opcoes[@]}" \
        2>"$CURR_TTY")
    [ $? -ne 0 ] && echo "$atual" && return
    # Converte indice para nome
    local idx=0
    for c in $_CORES_DISPONIVEIS; do
        (( idx++ ))
        [ "$idx" -eq "$ESCOLHA" ] && echo "$c" && return
    done
    echo "$atual"
}

# -----------------------------------------------------------
# SUB-MENU: Editor Manual de Cores
# -----------------------------------------------------------
_m8_cores_manual() {
    while true; do
        # Garante que dialogrc existe antes de entrar
        [ ! -f "$DIALOGRC_CUSTOM" ] && _menu_gerar_dialogrc_manual

        local OPCAO
        OPCAO=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Editor Manual de Cores " \
            --ok-label "OK" \
            --extra-button --extra-label "VOLTAR" \
            --cancel-label "SAIR" \
            --menu \
"Edite cada elemento individualmente.
As cores ja estao aplicadas ao vivo." \
            24 72 11 \
            1  "Fundo da Janela         (atual: $MC_FUNDO)" \
            2  "Texto Principal         (atual: $MC_TEXTO)" \
            3  "Titulo da Janela        (atual: $MC_TITULO)" \
            4  "Bordas                  (atual: $MC_BORDA)" \
            5  "Item Selecionado — FG   (atual: $MC_SEL_FG)" \
            6  "Item Selecionado — BG   (atual: $MC_SEL_BG)" \
            7  "Botao Ativo — FG        (atual: $MC_BTN_FG)" \
            8  "Botao Ativo — BG        (atual: $MC_BTN_BG)" \
            9  "Numeros dos Itens       (atual: $MC_NUMS)" \
            10 "Sombra                  (atual: $MC_SOMBRA)" \
            11 "Aplicar e Salvar" \
            2>"$CURR_TTY")
        local RET=$?
        NORM_RET
        [ $RET -eq 1 ] || [ $RET -eq 3 ] || [ $RET -eq 255 ] && break

        case "$OPCAO" in
            1)  MC_FUNDO="$(_escolher_cor   "Fundo da Janela"       "$MC_FUNDO")" ;;
            2)  MC_TEXTO="$(_escolher_cor   "Texto Principal"       "$MC_TEXTO")" ;;
            3)  MC_TITULO="$(_escolher_cor  "Titulo da Janela"      "$MC_TITULO")" ;;
            4)  MC_BORDA="$(_escolher_cor   "Bordas"                "$MC_BORDA")" ;;
            5)  MC_SEL_FG="$(_escolher_cor  "Selecao — Texto"       "$MC_SEL_FG")" ;;
            6)  MC_SEL_BG="$(_escolher_cor  "Selecao — Fundo"       "$MC_SEL_BG")" ;;
            7)  MC_BTN_FG="$(_escolher_cor  "Botao — Texto"         "$MC_BTN_FG")" ;;
            8)  MC_BTN_BG="$(_escolher_cor  "Botao — Fundo"         "$MC_BTN_BG")" ;;
            9)  MC_NUMS="$(_escolher_cor    "Numeros dos Itens"     "$MC_NUMS")" ;;
            10)
                local s
                s=$(dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Sombra " \
                    --ok-label "OK" --cancel-label "Cancelar" \
                    --menu "Exibir sombra na janela?" \
                    10 40 2 \
                    "OFF" "Sem sombra (recomendado para tty)" \
                    "ON"  "Com sombra" \
                    2>"$CURR_TTY")
                [ $? -eq 0 ] && MC_SOMBRA="$s" ;;
            11)
                MENU_TEMA_PRESET="personalizado"
                _menu_gerar_dialogrc_manual
                _menu_exportar_dialogrc
                _menu_cfg_salvar
                dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Cores Salvas " \
                    --msgbox "Cores personalizadas aplicadas e salvas!\n\nFundo    : $MC_FUNDO\nTexto    : $MC_TEXTO\nBordas   : $MC_BORDA\nSelecao  : $MC_SEL_FG / $MC_SEL_BG\nBotao    : $MC_BTN_FG / $MC_BTN_BG" \
                    12 55 2>"$CURR_TTY"
                break ;;
        esac

        # Preview ao vivo a cada mudanca (exceto salvar)
        [ "$OPCAO" != "11" ] && {
            _menu_gerar_dialogrc_manual
            _menu_exportar_dialogrc
        }
    done
}

# -----------------------------------------------------------
# SUB-MENU: Temas Pre-Prontos
# -----------------------------------------------------------
_m8_temas_prontos() {
    local ATUAL="${MENU_TEMA_PRESET:-nenhum}"
    local NOME_ATUAL
    case "$ATUAL" in
        "nenhum"|"personalizado") NOME_ATUAL="Personalizado" ;;
        *)                        NOME_ATUAL="$(_tema_descricao "$ATUAL")" ;;
    esac

    local TMPF
    TMPF=$(mktemp /tmp/alter_menu.XXXXXX)

    while true; do
        dialog \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Temas Pre-Prontos " \
            --ok-label "Aplicar" \
            --cancel-label "Voltar" \
            --menu \
"Tema ativo: $NOME_ATUAL" \
            24 74 8 \
            "minimalista_claro"  "$(_tema_descricao minimalista_claro)" \
            "darkos_original"    "$(_tema_descricao darkos_original)" \
            "terminal_verde"     "$(_tema_descricao terminal_verde)" \
            "retro_ambar"        "$(_tema_descricao retro_ambar)" \
            "roxo_neon"          "$(_tema_descricao roxo_neon)" \
            "vermelho_hacker"    "$(_tema_descricao vermelho_hacker)" \
            "ciano_noturno"      "$(_tema_descricao ciano_noturno)" \
            "padrao_sistema"     "$(_tema_descricao padrao_sistema)" \
            2>"$TMPF" 1>"$CURR_TTY"
        local RET=$?
        local ESCOLHA
        ESCOLHA=$(cat "$TMPF" 2>/dev/null)

        [ $RET -eq 1 ] || [ $RET -eq 255 ] && break

        _tema_aplicar_preset "$ESCOLHA"
        _menu_exportar_dialogrc
        _menu_cfg_salvar
        NOME_ATUAL="$(_tema_descricao "$ESCOLHA")"
        dialog \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Tema Aplicado " \
            --msgbox "Tema aplicado!\n$NOME_ATUAL" \
            6 54 2>/dev/null 1>"$CURR_TTY"
        break
    done

    rm -f "$TMPF" 2>/dev/null
}


# -----------------------------------------------------------
# Sub-menu: Titulo — 100% navegavel por D-pad (sem teclado)
# -----------------------------------------------------------
_m8_titulo() {
    local OPCAO
    OPCAO=$(dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Titulo da Janela " \
        --ok-label "OK" --cancel-label "Voltar" \
        --menu \
"Titulo atual: $MENU_TITULO
Escolha um titulo pronto ou use D-pad para selecionar:" \
        14 68 5 \
        "1" "MENU PRINCIPAL                (sem decoracao)" \
        "2" "MENU  PRINCIPAL                (espacado)" \
        "3" "MENUPRINCIPAL                  (sem espacos)" \
        "4" "Restaurar padrao         ( MENU PRINCIPAL )" \
        "5" "Digitar Titulo Personalizado (sem teclado)" \
        2>"$CURR_TTY")
    [ $? -ne 0 ] && return
    case "$OPCAO" in
        1) MENU_TITULO=" MENU PRINCIPAL" ;;
        2) MENU_TITULO="  MENU  PRINCIPAL" ;;
        3) MENU_TITULO="MENU PRINCIPAL" ;;
        4) MENU_TITULO="$_DEFAULT_TITULO" ;;
        5) _m8_titulo_digitar; return ;;
    esac
    MENU_TEMA_PRESET="personalizado"
    _menu_cfg_salvar
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Titulo Atualizado " \
        --msgbox "Titulo definido para:\n$MENU_TITULO" \
        6 50 2>"$CURR_TTY"
}

# -----------------------------------------------------------
# Sub-menu: Digitar Titulo Personalizado
# Picker de caractere por caractere via D-pad, sem teclado.
# Mesmo padrao usado no Font Studio (cat_1) para nomes de
# fontes/favoritos: navega com D-pad, confirma com A.
# -----------------------------------------------------------
_TITULO_MAX_LEN=40

_m8_titulo_digitar() {
    local TEXTO_ATUAL="$MENU_TITULO"
    # Remove espacos de decoracao das bordas para edicao mais limpa
    TEXTO_ATUAL="$(echo "$TEXTO_ATUAL" | sed -E 's/^ +| +$//g')"

    while true; do
        local PREVIEW="${TEXTO_ATUAL:-(vazio)}"
        local TAM=${#TEXTO_ATUAL}

        local OPCAO
        OPCAO=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Digitar Titulo — Preview: $PREVIEW " \
            --ok-label "OK" --cancel-label "Cancelar" \
            --menu \
"Texto atual (${TAM}/${_TITULO_MAX_LEN}): $PREVIEW
Escolha uma acao:" \
            18 68 6 \
            "1" "Adicionar Letra (A-Z)" \
            "2" "Adicionar Numero (0-9)" \
            "3" "Adicionar Espaco" \
            "4" "Adicionar Simbolo" \
            "5" "Apagar Ultimo Caractere" \
            "6" "Finalizar e Salvar" \
            2>"$CURR_TTY")
        local RET=$?
        [ $RET -ne 0 ] && return   # Cancelar sai sem salvar

        case "$OPCAO" in
            1)
                local LETRA
                LETRA="$(_m8_escolher_de_lista "Escolha a Letra" \
                    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)"
                [ -n "$LETRA" ] && [ "$TAM" -lt "$_TITULO_MAX_LEN" ] \
                    && TEXTO_ATUAL="${TEXTO_ATUAL}${LETRA}" ;;
            2)
                local NUM
                NUM="$(_m8_escolher_de_lista "Escolha o Numero" \
                    0 1 2 3 4 5 6 7 8 9)"
                [ -n "$NUM" ] && [ "$TAM" -lt "$_TITULO_MAX_LEN" ] \
                    && TEXTO_ATUAL="${TEXTO_ATUAL}${NUM}" ;;
            3)
                [ "$TAM" -lt "$_TITULO_MAX_LEN" ] \
                    && TEXTO_ATUAL="${TEXTO_ATUAL} " ;;
            4)
                local SIMB
                SIMB="$(_m8_escolher_de_lista "Escolha o Simbolo" \
                    "[" "]" "{" "}" "(" ")" "<" ">" "*" "=" "-" "_" \
                    "~" ":" "!" "+" "#" "@" "&" "%" "/" "." "," "'")"
                [ -n "$SIMB" ] && [ "$TAM" -lt "$_TITULO_MAX_LEN" ] \
                    && TEXTO_ATUAL="${TEXTO_ATUAL}${SIMB}" ;;
            5)
                TEXTO_ATUAL="${TEXTO_ATUAL%?}" ;;
            6)
                if [ -z "$TEXTO_ATUAL" ]; then
                    dialog --output-fd 1 \
                        --backtitle "$(_menu_preview_backtitle)" \
                        --title " Aviso " \
                        --msgbox "O titulo nao pode ficar vazio." \
                        6 44 2>"$CURR_TTY"
                    continue
                fi
                MENU_TITULO=" ${TEXTO_ATUAL} "
                MENU_TEMA_PRESET="personalizado"
                _menu_cfg_salvar
                dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Titulo Atualizado " \
                    --msgbox "Titulo definido para:\n$MENU_TITULO" \
                    6 50 2>"$CURR_TTY"
                return ;;
        esac
    done
}

# -----------------------------------------------------------
# HELPER: menu generico de escolha entre uma lista de valores
# avulsos (letras, numeros, simbolos), em formato de GRADE.
# Passo 1: escolhe a LINHA (grupo de ate 6 valores lado a lado)
# Passo 2: escolhe o valor exato dentro da linha escolhida
# Sem numeros de tag visiveis — so as letras/simbolos mesmo.
# Retorna o valor escolhido em stdout, ou nada se cancelado.
# -----------------------------------------------------------
_GRADE_POR_LINHA=6

_m8_escolher_de_lista() {
    local titulo="$1"; shift
    local valores=("$@")
    local total=${#valores[@]}

    while true; do
        # Monta as linhas: cada linha = ate _GRADE_POR_LINHA valores
        # separados por espaco duplo, lado a lado.
        local linhas_opcoes=()
        local linhas_valores=()
        local i=0
        while [ "$i" -lt "$total" ]; do
            local linha_txt=""
            local linha_vals=()
            local j=0
            while [ "$j" -lt "$_GRADE_POR_LINHA" ] && [ "$i" -lt "$total" ]; do
                linha_txt="${linha_txt}${valores[$i]}  "
                linha_vals+=("${valores[$i]}")
                (( i++ )); (( j++ ))
            done
            linhas_opcoes+=("$(( ${#linhas_valores[@]} + 1 ))" "$linha_txt")
            linhas_valores+=("$(printf '%s\x1F' "${linha_vals[@]}")")
        done

        local altura_lista=${#linhas_valores[@]}
        [ "$altura_lista" -gt 12 ] && altura_lista=12

        local ESCOLHA_LINHA
        ESCOLHA_LINHA=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " $titulo " \
            --ok-label "OK" --cancel-label "Voltar" \
            --no-tags \
            --menu "Use D-pad para escolher a linha:" \
            $(( altura_lista + 8 )) 50 "$altura_lista" \
            "${linhas_opcoes[@]}" \
            2>"$CURR_TTY")
        [ $? -ne 0 ] && return

        local idx_linha=$(( ESCOLHA_LINHA - 1 ))
        local vals_str="${linhas_valores[$idx_linha]}"
        IFS=$'\x1F' read -ra VALS_LINHA <<< "$vals_str"

        # Se a linha tem so 1 valor, retorna direto sem segundo passo
        if [ "${#VALS_LINHA[@]}" -eq 1 ]; then
            echo "${VALS_LINHA[0]}"
            return
        fi

        # Passo 2: escolhe o valor exato dentro da linha
        local opcoes_finais=()
        local k=1
        for v in "${VALS_LINHA[@]}"; do
            opcoes_finais+=("$k" "$v")
            (( k++ ))
        done
        local ESCOLHA_FINAL
        ESCOLHA_FINAL=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " $titulo " \
            --ok-label "OK" --cancel-label "Voltar" \
            --no-tags \
            --menu "Escolha o caractere exato:" \
            12 30 "${#VALS_LINHA[@]}" \
            "${opcoes_finais[@]}" \
            2>"$CURR_TTY")
        [ $? -ne 0 ] && continue   # Voltou: re-mostra a grade de linhas

        local idxf=$(( ESCOLHA_FINAL - 1 ))
        echo "${VALS_LINHA[$idxf]}"
        return
    done
}

# -----------------------------------------------------------
# Sub-menu: Separador — 100% navegavel por D-pad (sem teclado)
# -----------------------------------------------------------
_m8_separador() {
    local OPCAO
    OPCAO=$(dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Linha Separadora " \
        --ok-label "OK" --cancel-label "Voltar" \
        --menu \
"Separador atual: ${MENU_SEPARADOR:-(sem separador)}
Escolha um estilo de separador:" \
        22 72 11 \
        "1"  "----------------------------------------------------------------" \
        "2"  "================================================================" \
        "3"  "################################################################" \
        "4"  "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" \
        "5"  "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-" \
        "6"  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" \
        "7"  "-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-" \
        "8"  "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *" \
        "9"  ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ." \
        "10" "  (sem separador — linha em branco)" \
        "11" "Restaurar padrao (linha de traco)" \
        2>"$CURR_TTY")
    [ $? -ne 0 ] && return
    case "$OPCAO" in
        1)  MENU_SEPARADOR="----------------------------------------------------------------" ;;
        2)  MENU_SEPARADOR="================================================================" ;;
        3)  MENU_SEPARADOR="################################################################" ;;
        4)  MENU_SEPARADOR="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" ;;
        5)  MENU_SEPARADOR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-" ;;
        6)  MENU_SEPARADOR="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ;;
        7)  MENU_SEPARADOR="-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-" ;;
        8)  MENU_SEPARADOR="* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *" ;;
        9)  MENU_SEPARADOR=". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ." ;;
        10) MENU_SEPARADOR="" ;;
        11) MENU_SEPARADOR="$_DEFAULT_SEPARADOR" ;;
    esac
    MENU_TEMA_PRESET="personalizado"
    _menu_cfg_salvar
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Separador Atualizado " \
        --msgbox "Separador definido para:\n${MENU_SEPARADOR:-(sem separador)}" \
        6 68 2>"$CURR_TTY"
}

# -----------------------------------------------------------
# Sub-menu: Tamanho — 100% navegavel por D-pad (sem teclado)
# -----------------------------------------------------------
_m8_tamanho() {
    while true; do
        _menu_validar_tamanho
        local TELA_INFO="${MENU_TELA_REAL:-desconhecida}"

        local OPCAO
        OPCAO=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Tamanho da Janela " \
            --ok-label "OK" --cancel-label "Voltar" \
            --menu \
"Atual: ${MENU_ALTURA} linhas x ${MENU_LARGURA} col | ${MENU_ITENS_VIS} itens
Tela detectada: ${TELA_INFO} (linhas x colunas)" \
            17 70 5 \
            1 "Altura          (atual: ${MENU_ALTURA} linhas)" \
            2 "Largura         (atual: ${MENU_LARGURA} colunas)" \
            3 "Itens Visiveis  (atual: ${MENU_ITENS_VIS})" \
            4 "Restaurar Padrao (22 linhas x 68 col, 9 itens)" \
            5 "Validar/Ajustar a Tela Atual (${TELA_INFO})" \
            2>"$CURR_TTY")
        [ $? -ne 0 ] && break

        case "$OPCAO" in
            1)
                local AH
                AH=$(dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Altura da Janela " \
                    --ok-label "OK" --cancel-label "Voltar" \
                    --menu "Atual: ${MENU_ALTURA} linhas — escolha uma opcao:" \
                    20 55 10 \
                    "14" "14 linhas  (compacto)" \
                    "16" "16 linhas" \
                    "18" "18 linhas" \
                    "20" "20 linhas" \
                    "22" "22 linhas  (padrao)" \
                    "24" "24 linhas" \
                    "26" "26 linhas" \
                    "28" "28 linhas" \
                    "30" "30 linhas  (grande)" \
                    "32" "32 linhas  (maximo recomendado)" \
                    2>"$CURR_TTY")
                [ $? -ne 0 ] && continue
                MENU_ALTURA=$AH; MENU_TEMA_PRESET="personalizado"
                _menu_alertar_se_nao_couber; _menu_cfg_salvar ;;

            2)
                local AW
                AW=$(dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Largura da Janela " \
                    --ok-label "OK" --cancel-label "Voltar" \
                    --menu "Atual: ${MENU_LARGURA} colunas — escolha uma opcao:" \
                    20 58 10 \
                    "50" "50 colunas  (estreito)" \
                    "55" "55 colunas" \
                    "60" "60 colunas" \
                    "64" "64 colunas" \
                    "68" "68 colunas  (padrao)" \
                    "72" "72 colunas" \
                    "76" "76 colunas" \
                    "80" "80 colunas  (largo)" \
                    "84" "84 colunas" \
                    "88" "88 colunas  (maximo recomendado)" \
                    2>"$CURR_TTY")
                [ $? -ne 0 ] && continue
                MENU_LARGURA=$AW; MENU_TEMA_PRESET="personalizado"
                _menu_alertar_se_nao_couber; _menu_cfg_salvar ;;

            3)
                local AI
                AI=$(dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Itens Visiveis " \
                    --ok-label "OK" --cancel-label "Voltar" \
                    --menu "Atual: ${MENU_ITENS_VIS} itens — escolha uma opcao:" \
                    16 55 8 \
                    "4"  "4  itens visiveis  (compacto)" \
                    "5"  "5  itens visiveis" \
                    "6"  "6  itens visiveis" \
                    "7"  "7  itens visiveis" \
                    "8"  "8  itens visiveis" \
                    "9"  "9  itens visiveis  (padrao)" \
                    "10" "10 itens visiveis" \
                    "12" "12 itens visiveis  (grande)" \
                    2>"$CURR_TTY")
                [ $? -ne 0 ] && continue
                MENU_ITENS_VIS=$AI; MENU_TEMA_PRESET="personalizado"; _menu_cfg_salvar ;;

            4)
                MENU_ALTURA=$_DEFAULT_ALTURA
                MENU_LARGURA=$_DEFAULT_LARGURA
                MENU_ITENS_VIS=$_DEFAULT_ITENS_VISIVEIS
                MENU_TEMA_PRESET="personalizado"; _menu_cfg_salvar
                dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Restaurado " \
                    --msgbox "Tamanho restaurado ao padrao:\n22 linhas x 68 colunas, 9 itens" \
                    7 48 2>"$CURR_TTY" ;;

            5)
                local antes_a=$MENU_ALTURA antes_l=$MENU_LARGURA antes_i=$MENU_ITENS_VIS
                _menu_validar_tamanho
                if [ "$MENU_TELA_AJUSTADA" -eq 1 ]; then
                    MENU_TEMA_PRESET="personalizado"; _menu_cfg_salvar
                    dialog --output-fd 1 \
                        --backtitle "$(_menu_preview_backtitle)" \
                        --title " Ajustado " \
                        --msgbox "Tela detectada: ${MENU_TELA_REAL}\n\nAjustado de ${antes_a}x${antes_l} (${antes_i} itens)\npara ${MENU_ALTURA}x${MENU_LARGURA} (${MENU_ITENS_VIS} itens)\npara caber na tela atual." \
                        10 56 2>"$CURR_TTY"
                else
                    dialog --output-fd 1 \
                        --backtitle "$(_menu_preview_backtitle)" \
                        --title " OK " \
                        --msgbox "Tela detectada: ${MENU_TELA_REAL}\n\nTamanho atual (${MENU_ALTURA}x${MENU_LARGURA}, ${MENU_ITENS_VIS} itens) ja cabe sem ajustes." \
                        9 56 2>"$CURR_TTY"
                fi ;;
        esac
    done
}

# -----------------------------------------------------------
# Avisa o usuario, sem reverter a escolha, se o valor manual
# definido para altura/largura nao couber na tela detectada.
# -----------------------------------------------------------
_menu_alertar_se_nao_couber() {
    local real_linhas real_colunas
    if [ -n "$CURR_TTY" ] && [ -e "$CURR_TTY" ]; then
        read -r real_linhas real_colunas < <(stty size < "$CURR_TTY" 2>/dev/null)
    fi
    if [ -z "$real_linhas" ] || [ -z "$real_colunas" ]; then
        read -r real_linhas real_colunas < <(stty size 2>/dev/null)
    fi
    [ -z "$real_linhas" ] || [ -z "$real_colunas" ] && return

    local max_altura=$(( real_linhas - 1 ))
    local max_largura=$(( real_colunas - 2 ))

    if [ "$MENU_ALTURA" -gt "$max_altura" ] 2>/dev/null || \
       [ "$MENU_LARGURA" -gt "$max_largura" ] 2>/dev/null; then
        dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Aviso " \
            --msgbox "Atencao: o tamanho escolhido (${MENU_ALTURA}x${MENU_LARGURA}) pode nao caber na tela atual (${real_linhas}x${real_colunas}).\n\nUse 'Validar/Ajustar a Tela Atual' se a janela aparecer cortada." \
            10 58 2>"$CURR_TTY"
    fi
}

# -----------------------------------------------------------
# Sub-menu: Cabecalho
# -----------------------------------------------------------
_m8_cabecalho() {
    local ch ct cb
    [ "${MENU_HORA:-1}"      -eq 1 ] && ch="on" || ch="off"
    [ "${MENU_TEMA_NOME:-1}" -eq 1 ] && ct="on" || ct="off"
    [ "${MENU_BACKUP:-1}"    -eq 1 ] && cb="on" || cb="off"
    local ESC
    ESC=$(dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Informacoes do Cabecalho " \
        --ok-label "Salvar" --cancel-label "Cancelar" \
        --checklist "O que exibir na barra superior:" \
        12 65 3 \
        "HORA"   "Data e hora atual"         "$ch" \
        "TEMA"   "Nome do tema ativo"        "$ct" \
        "BACKUP" "Status de backup no corpo" "$cb" \
        2>"$CURR_TTY")
    [ $? -ne 0 ] && return
    MENU_HORA=0; MENU_TEMA_NOME=0; MENU_BACKUP=0
    echo "$ESC" | grep -q "HORA"   && MENU_HORA=1
    echo "$ESC" | grep -q "TEMA"   && MENU_TEMA_NOME=1
    echo "$ESC" | grep -q "BACKUP" && MENU_BACKUP=1
    MENU_TEMA_PRESET="personalizado"; _menu_cfg_salvar
}

# -----------------------------------------------------------
# Sub-menu: Tamanho da Fonte (console/TTY)
# Aplica ao vivo para preview; so persiste ao salvar.
# -----------------------------------------------------------
_m8_fonte() {
    while true; do
        local opcoes=()
        local i=1
        local atual="${MENU_FONTE_CONSOLE:-$_DEFAULT_FONTE_CONSOLE}"
        for f in $_FONTES_DISPONIVEIS; do
            local mark=""
            [ "$f" = "$atual" ] && mark=" <-- ATUAL"
            opcoes+=("$i" "$(_fonte_descricao "$f")$mark")
            (( i++ ))
        done

        local ESCOLHA
        ESCOLHA=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Tamanho da Fonte " \
            --ok-label "OK" --cancel-label "Voltar" \
            --menu \
"Fonte atual: $(_fonte_descricao "$atual")
Aplicada ao vivo so dentro deste modulo." \
            14 70 7 \
            "${opcoes[@]}" \
            2>"$CURR_TTY")
        [ $? -ne 0 ] && break

        local idx=0
        local nova=""
        for f in $_FONTES_DISPONIVEIS; do
            (( idx++ ))
            [ "$idx" -eq "$ESCOLHA" ] && nova="$f" && break
        done
        [ -z "$nova" ] && continue

        if command -v setfont >/dev/null 2>&1; then
            if setfont "$nova" 2>/dev/null; then
                MENU_FONTE_CONSOLE="$nova"
                MENU_TEMA_PRESET="personalizado"
                _menu_cfg_salvar
            else
                dialog --output-fd 1 \
                    --backtitle "$(_menu_preview_backtitle)" \
                    --title " Erro " \
                    --msgbox "Nao foi possivel aplicar essa fonte.\nEla pode nao estar instalada neste sistema." \
                    8 54 2>"$CURR_TTY"
            fi
        else
            dialog --output-fd 1 \
                --backtitle "$(_menu_preview_backtitle)" \
                --title " Indisponivel " \
                --msgbox "Comando 'setfont' nao encontrado neste sistema.\nNao e possivel alterar o tamanho da fonte." \
                8 56 2>"$CURR_TTY"
            return
        fi
    done
}

# -----------------------------------------------------------
# Sub-menu: Restaurar
# -----------------------------------------------------------
_m8_restaurar() {
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Restaurar " \
        --yesno "Restaurar TUDO ao padrao do sistema?" \
        6 50 2>"$CURR_TTY"
    [ $? -ne 0 ] && return
    _tema_aplicar_preset "padrao_sistema"
    MENU_FONTE_CONSOLE="$_DEFAULT_FONTE_CONSOLE"
    _menu_exportar_dialogrc; _menu_cfg_salvar
    if command -v setfont >/dev/null 2>&1; then
        setfont "$_DEFAULT_FONTE_CONSOLE" 2>/dev/null || true
    fi
    dialog --output-fd 1 \
        --backtitle "$(_menu_preview_backtitle)" \
        --title " Restaurado " \
        --msgbox "Configuracoes restauradas ao padrao." \
        6 46 2>"$CURR_TTY"
}

# -----------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------
categoria_8() {
    _menu_cfg_carregar

    # Guarda a fonte configurada ANTES de qualquer alteracao feita
    # dentro deste modulo, para poder restaurar exatamente o que
    # estava em uso ao sair (nao um "padrao" presumido).
    _FONTE_CONSOLE_ORIGINAL="${MENU_FONTE_CONSOLE:-$_DEFAULT_FONTE_CONSOLE}"
    _menu_fonte_aplicar

    while true; do
        local PLABEL
        case "${MENU_TEMA_PRESET:-nenhum}" in
            "nenhum"|"padrao_sistema") PLABEL="Padrao do Sistema" ;;
            "personalizado")           PLABEL="Personalizado" ;;
            *) PLABEL="$(_tema_descricao "$MENU_TEMA_PRESET" | cut -d'-' -f1 | xargs)" ;;
        esac

        local OPCAO
        OPCAO=$(dialog --output-fd 1 \
            --backtitle "$(_menu_preview_backtitle)" \
            --title " Aparencia do Menu Principal " \
            --ok-label "OK" \
            --extra-button --extra-label "VOLTAR" \
            --cancel-label "SAIR" \
            --menu \
"Tema ativo: $PLABEL  |  Cores: $MC_TEXTO/$MC_FUNDO  |  Selecao: $MC_SEL_BG" \
            26 72 9 \
            1 "Temas Pre-Prontos         (aplicar tema completo)" \
            2 "Editor Manual de Cores    (personalizar elemento por elemento)" \
            3 "Titulo da Janela          (atual: $MENU_TITULO)" \
            4 "Linha Separadora" \
            5 "Tamanho da Janela         (${MENU_ALTURA}x${MENU_LARGURA})" \
            6 "Informacoes do Cabecalho" \
            7 "Tamanho da Fonte          (${MENU_FONTE_CONSOLE:-$_DEFAULT_FONTE_CONSOLE})" \
            8 "Restaurar Tudo ao Padrao" \
            2>"$CURR_TTY")
        local RET=$?
        NORM_RET
        if [ $RET -eq 1 ] || [ $RET -eq 3 ] || [ $RET -eq 255 ]; then
            _menu_fonte_restaurar_original
            break
        fi

        case "$OPCAO" in
            1) _m8_temas_prontos ;;
            2) _m8_cores_manual ;;
            3) _m8_titulo ;;
            4) _m8_separador ;;
            5) _m8_tamanho ;;
            6) _m8_cabecalho ;;
            7) _m8_fonte ;;
            8) _m8_restaurar ;;
        esac
    done
}

menu_aparencia_aplicar
