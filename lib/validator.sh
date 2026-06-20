# =============================================================
# validator.sh - Validacao automatica do XML antes de salvar
# Alter_MThemes - Modulo de validacao
# =============================================================
#
# USO NOS MODULOS:
#   ValidarXML "$XML_FILE" && aplicar_mudanca || continue
#
# FLUXO RECOMENDADO (apply-then-validate):
#   cp "$XML_FILE" "$XML_FILE.tmp_edit"
#   sed -i ... "$XML_FILE.tmp_edit"
#   if ValidarXML "$XML_FILE.tmp_edit"; then
#       cp "$XML_FILE.tmp_edit" "$XML_FILE"
#   fi
#   rm -f "$XML_FILE.tmp_edit"
# =============================================================

# -------------------------------------------------------------
# Constantes de validacao
# -------------------------------------------------------------
_VAL_MIN_LINHAS=10          # XML menor que isso foi truncado
_VAL_MAX_REDUCAO_PCT=60     # Se reduziu mais de 60% das linhas, alerta
_VAL_MAX_OPCAIDADE=1.0      # opacity nao pode passar de 1.0
_VAL_MIN_OPACITY=0.0        # opacity nao pode ser negativa
_VAL_MAX_FONTSIZE=200       # fontSize absurdo
_VAL_MIN_FONTSIZE=4         # fontSize minimo legivel

# -------------------------------------------------------------
# _val_erro VAR_ERROS "mensagem"
#   Acumula mensagens de erro numa variavel
# -------------------------------------------------------------
_val_erro() {
    local _ref="$1" ; shift
    printf -v "$_ref" '%s\n  [!] %s' "${!_ref}" "$*"
}

# -------------------------------------------------------------
# _val_checar_estrutura ARQUIVO VAR_ERROS
#   Verifica se o XML esta bem formado (tags abertas = fechadas)
# -------------------------------------------------------------
_val_checar_estrutura() {
    local arquivo="$1" local_erros="$2"

    # Conta tags abertas e fechadas do nível raiz
    local abertas fechadas
    abertas=$(grep -oE '<[a-zA-Z][a-zA-Z0-9_]*( [^>]*)?' "$arquivo" 2>/dev/null \
        | grep -v '</' | grep -v '/>' | wc -l || echo 0)
    fechadas=$(grep -oE '</[a-zA-Z][a-zA-Z0-9_]*>' "$arquivo" 2>/dev/null | wc -l || echo 0)
    local autoclose
    autoclose=$(grep -oE '<[^>]+/>' "$arquivo" 2>/dev/null | wc -l || echo 0)

    # Heuristica: abertas devem ser proximo de fechadas + autoclose
    local diff=$(( abertas - fechadas - autoclose ))
    [ $diff -lt 0 ] && diff=$(( -diff ))
    if [ "$diff" -gt 5 ]; then
        _val_erro "$local_erros" \
            "Estrutura XML desequilibrada (tags abertas: $abertas, fechadas: $fechadas, autoclose: $autoclose)"
    fi

    # Checa se tem pelo menos a tag raiz <theme>
    if ! grep -q '<theme' "$arquivo" 2>/dev/null; then
        _val_erro "$local_erros" "Tag raiz <theme> ausente — XML invalido ou corrompido"
    fi

    # Checa se </theme> fecha o arquivo
    if ! grep -q '</theme>' "$arquivo" 2>/dev/null; then
        _val_erro "$local_erros" "Tag </theme> de fechamento ausente — arquivo truncado?"
    fi
}

# -------------------------------------------------------------
# _val_checar_tags_obrigatorias ARQUIVO VAR_ERROS
#   Garante que tags essenciais do ES nao foram removidas
# -------------------------------------------------------------
_val_checar_tags_obrigatorias() {
    local arquivo="$1" local_erros="$2"

    local tags_obrig=("formatVersion" "view")
    for tag in "${tags_obrig[@]}"; do
        if ! grep -q "<${tag}" "$arquivo" 2>/dev/null; then
            _val_erro "$local_erros" \
                "Tag obrigatoria ausente: <${tag}> — pode travar o ES"
        fi
    done
}

# -------------------------------------------------------------
# _val_checar_cores ARQUIVO VAR_ERROS
#   Valida formato HEX de todas as tags de cor
# -------------------------------------------------------------
_val_checar_cores() {
    local arquivo="$1" local_erros="$2"

    # Tags de cor conhecidas do ES
    local tags_cor=(
        "color" "textColor" "selectedColor" "selectorColor"
        "backgroundColor" "primaryColor" "secondaryColor"
        "scrollbarColor" "borderColor" "iconColor"
    )

    for tag in "${tags_cor[@]}"; do
        # Extrai todos os valores dessa tag
        while IFS= read -r valor; do
            [ -z "$valor" ] && continue
            # Remove espacos e torna uppercase para checagem
            local v
            v=$(echo "$valor" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
            # Aceita RRGGBB ou RRGGBBAA (6 ou 8 hex digits)
            if ! echo "$v" | grep -qE '^[0-9A-F]{6}([0-9A-F]{2})?$'; then
                _val_erro "$local_erros" \
                    "Cor invalida em <${tag}>: '${valor}' (esperado #RRGGBB ou #RRGGBBAA)"
            fi
        done < <(grep -oE "<${tag}>[^<]*</${tag}>" "$arquivo" 2>/dev/null \
                    | sed -E "s|<${tag}>([^<]*)</${tag}>|\1|" \
                    | sed 's/#//g')
    done
}

# -------------------------------------------------------------
# _val_checar_numericos ARQUIVO VAR_ERROS
#   Valida opacity e fontSize dentro de ranges seguros
# -------------------------------------------------------------
_val_checar_numericos() {
    local arquivo="$1" local_erros="$2"

    # --- opacity: deve estar entre 0.0 e 1.0 ---
    while IFS= read -r valor; do
        [ -z "$valor" ] && continue
        # Compara usando awk (suporte a float)
        local ok
        ok=$(awk -v v="$valor" \
            'BEGIN { print (v+0 >= 0.0 && v+0 <= 1.0) ? "ok" : "fail" }')
        if [ "$ok" != "ok" ]; then
            _val_erro "$local_erros" \
                "Opacity fora do range [0.0-1.0]: '${valor}' — pode causar comportamento indefinido"
        fi
    done < <(grep -oE '<opacity>[^<]*</opacity>' "$arquivo" 2>/dev/null \
                | sed -E 's|<opacity>([^<]*)</opacity>|\1|')

    # --- fontSize: o ES aceita tres formatos:
    #     Zero:     0 / 0.0 / 0.000 = elemento oculto (valido no ES)
    #     Relativo: decimal 0.001-0.999 (ex: 0.035 = 3.5% da tela)
    #     Absoluto: inteiro 4-500
    #     Invalidos: negativo ou acima de 500
    while IFS= read -r valor; do
        [ -z "$valor" ] && continue
        local vclean
        vclean=$(echo "$valor" | tr -d ' \t\r\n')
        [ -z "$vclean" ] && continue
        local ok
        ok=$(awk -v v="$vclean" \
            'BEGIN {
                n = v + 0
                # Zero e valido no ES (oculta o elemento)
                if (n == 0) { print "ok"; exit }
                # Rejeita negativo
                if (n < 0) { print "fail"; exit }
                # Rejeita absurdamente grande
                if (n > 500) { print "fail"; exit }
                print "ok"
            }')
        if [ "$ok" != "ok" ]; then
            _val_erro "$local_erros" \
                "fontSize invalido: '${vclean}' (esperado 0, decimal 0.001-0.999 ou inteiro 4-500)"
        fi
    done < <(grep -oE '<fontSize>[^<]*</fontSize>' "$arquivo" 2>/dev/null \
                | sed -E 's|<fontSize>([^<]*)</fontSize>|\1|')
}

# -------------------------------------------------------------
# _val_checar_tamanho ARQUIVO ORIGINAL VAR_ERROS
#   Detecta truncamento ou inchaço excessivo do arquivo
# -------------------------------------------------------------
_val_checar_tamanho() {
    local arquivo="$1" original="$2" local_erros="$3"

    local linhas_novo linhas_orig
    linhas_novo=$(wc -l < "$arquivo" 2>/dev/null || echo 0)
    linhas_orig=$(wc -l < "$original" 2>/dev/null || echo 0)

    # Minimo absoluto
    if [ "$linhas_novo" -lt "$_VAL_MIN_LINHAS" ]; then
        _val_erro "$local_erros" \
            "Arquivo muito pequeno (${linhas_novo} linhas) — possivel truncamento critico"
    fi

    # Reducao excessiva em relacao ao original
    if [ "$linhas_orig" -gt 0 ]; then
        local pct_restante
        pct_restante=$(awk -v n="$linhas_novo" -v o="$linhas_orig" \
            'BEGIN { printf "%d", (n * 100 / o) }')
        local pct_reducao=$(( 100 - pct_restante ))
        if [ "$pct_reducao" -gt "$_VAL_MAX_REDUCAO_PCT" ]; then
            _val_erro "$local_erros" \
                "Arquivo reduziu ${pct_reducao}% em relacao ao original (${linhas_orig} -> ${linhas_novo} linhas) — possivel perda de dados"
        fi
    fi
}

# -------------------------------------------------------------
# _val_checar_encoding ARQUIVO VAR_ERROS
#   Detecta bytes invalidos que quebram o parser XML do ES
# -------------------------------------------------------------
_val_checar_encoding() {
    local arquivo="$1" local_erros="$2"

    # Verifica se o arquivo e UTF-8 valido
    if ! iconv -f UTF-8 -t UTF-8 "$arquivo" >/dev/null 2>&1; then
        _val_erro "$local_erros" \
            "Encoding invalido detectado — caracteres nao-UTF-8 podem travar o parser do ES"
    fi
}

# -------------------------------------------------------------
# _val_checar_duplicatas ARQUIVO VAR_ERROS
#   Detecta duplicacao de tags unicas que gera conflito no ES
# -------------------------------------------------------------
_val_checar_duplicatas() {
    local arquivo="$1" local_erros="$2"

    local tags_unicas=("formatVersion" "resolution")
    for tag in "${tags_unicas[@]}"; do
        local count
        count=$(grep -c "<${tag}>" "$arquivo" 2>/dev/null || echo 0)
        if [ "$count" -gt 1 ]; then
            _val_erro "$local_erros" \
                "Tag <${tag}> duplicada (${count}x) — conflito de valores, comportamento indefinido"
        fi
    done
}

# -------------------------------------------------------------
# ValidarXML ARQUIVO_EDITADO [ARQUIVO_ORIGINAL]
#
#   Funcao principal. Retorna 0 se OK, 1 se bloqueante.
#   Exibe dialog com erros encontrados e pede confirmacao.
#
#   $1 = arquivo a validar (pode ser .tmp_edit)
#   $2 = arquivo original (para comparar tamanho) — opcional
#        se omitido, usa $XML_FILE
# -------------------------------------------------------------
ValidarXML() {
    local arquivo="$1"
    local original="${2:-$XML_FILE}"
    local ERROS=""

    # Arquivo precisa existir e ser legivel
    if [ ! -f "$arquivo" ] || [ ! -r "$arquivo" ]; then
        DIALOG_MSG "$BT" " VALIDADOR XML " 9 58 \
            "Erro interno: arquivo nao encontrado para validacao:\n${arquivo}"
        return 1
    fi

    printf "\033c" > "$CURR_TTY"
    printf "[*] Validando XML antes de salvar...\n" > "$CURR_TTY"

    # Executa todas as verificacoes
    _val_checar_estrutura      "$arquivo" ERROS
    _val_checar_tags_obrigatorias "$arquivo" ERROS
    _val_checar_cores          "$arquivo" ERROS
    _val_checar_numericos      "$arquivo" ERROS
    _val_checar_tamanho        "$arquivo" "$original" ERROS
    _val_checar_encoding       "$arquivo" ERROS
    _val_checar_duplicatas     "$arquivo" ERROS

    # Sem erros: aprovado
    if [ -z "$ERROS" ]; then
        printf "[OK] XML valido — prosseguindo.\n" > "$CURR_TTY"
        return 0
    fi

    # Com erros: exibe dialog e deixa usuario decidir
    local NUM_ERROS
    NUM_ERROS=$(echo "$ERROS" | grep -c '^\s*\[!\]' || echo "?")

    dialog --output-fd 1 \
        --backtitle "$BT" \
        --title " VALIDACAO DO XML — PROBLEMAS ENCONTRADOS " \
        --ok-label "SALVAR ASSIM MESMO" \
        --extra-button --extra-label "CANCELAR" \
        --cancel-label "SAIR" \
        --msgbox \
"${NUM_ERROS} problema(s) encontrado(s) antes de salvar:
${ERROS}

-------------------------------------------------------
CANCELAR  : descarta a alteracao (recomendado)
SALVAR    : aplica mesmo com os problemas acima
SAIR      : encerra o programa
-------------------------------------------------------
Dica: erros de estrutura e truncamento sao criticos.
Erros de cor/opacity podem ser avisos apenas." \
        22 72 >"$CURR_TTY"

    local RET_VAL=$?
    NORM_RET_RAW "$RET_VAL"   # usa versao sem side-effect se existir, senao usa NORM_RET
    RET_VAL=$?

    case "$RET_VAL" in
        0)  # SALVAR ASSIM MESMO
            printf "[AVISO] Salvo com problemas de validacao.\n" > "$CURR_TTY"
            return 0 ;;
        1)  # SAIR
            ExitAll ;;
        3)  # CANCELAR — descarta
            printf "[INFO] Alteracao cancelada pelo validador.\n" > "$CURR_TTY"
            return 1 ;;
        *)
            return 1 ;;
    esac
}

# -------------------------------------------------------------
# AplicarComValidacao ARQUIVO_TMP DESTINO [MSG_SUCESSO]
#
#   Helper de alto nivel para o fluxo completo:
#     1. Valida o ARQUIVO_TMP
#     2. Se OK, copia para DESTINO
#     3. Remove o temporario
#   Retorna 0 em sucesso, 1 se cancelado/invalido.
#
#   Uso:
#     sed ... "$XML_FILE" > "$XML_FILE.tmp_edit"
#     AplicarComValidacao "$XML_FILE.tmp_edit" "$XML_FILE" \
#         "Cor aplicada com sucesso!" && PerguntarReiniciar
# -------------------------------------------------------------
AplicarComValidacao() {
    local tmp="$1"
    local destino="$2"
    local msg_sucesso="${3:-Alteracao aplicada com sucesso!}"

    # Valida o temporario comparando com o destino atual (original)
    if ValidarXML "$tmp" "$destino"; then
        if cp "$tmp" "$destino" 2>/dev/null; then
            rm -f "$tmp" 2>/dev/null || true
            DIALOG_MSG "$BT" " APLICADO " 9 58 "${msg_sucesso}"
            return 0
        else
            rm -f "$tmp" 2>/dev/null || true
            DIALOG_MSG "$BT" " ERRO " 9 58 \
                "Erro ao salvar o arquivo!\n\nVerifique as permissoes de:\n${destino}"
            return 1
        fi
    else
        rm -f "$tmp" 2>/dev/null || true
        return 1
    fi
}
