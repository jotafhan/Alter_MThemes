# init.sh - Detecta tema ativo e define XML_FILE

SETTINGS_CFG="/var/local/emulationstation/es_settings.cfg"
[ ! -f "$SETTINGS_CFG" ] && SETTINGS_CFG="/home/ark/.emulationstation/es_settings.cfg"

THEME_NAME="darkos"
if [ -f "$SETTINGS_CFG" ]; then
    EXTRACTED=$(grep '<string name="ThemeSet"' "$SETTINGS_CFG" \
        | sed -E 's/.*value="([^"]+)".*/\1/' || echo "")
    [ -n "$EXTRACTED" ] && THEME_NAME="$EXTRACTED"
fi

XML_FILE=""
POSSIVEIS_PASTAS=(
    "/etc/emulationstation/themes/$THEME_NAME"
    "/home/ark/.emulationstation/themes/$THEME_NAME"
    "/roms/themes/$THEME_NAME"
    "/roms2/themes/$THEME_NAME"
)

for pasta in "${POSSIVEIS_PASTAS[@]}"; do
    if [ -f "$pasta/theme.xml" ]; then
        XML_FILE="$pasta/theme.xml"
        break
    fi
done

if [ -z "$XML_FILE" ]; then
    XML_FILE=$(find \
        /etc/emulationstation/themes/ \
        /home/ark/.emulationstation/themes/ \
        /roms/themes/ \
        /roms2/themes/ \
        -name "theme.xml" 2>/dev/null | head -n 1 || echo "")
fi

if [ -z "$XML_FILE" ] || [ ! -f "$XML_FILE" ]; then
    printf "\033c" > "$CURR_TTY"
    printf "Erro: Tema ativo nao encontrado (%s).\n" "$THEME_NAME" > "$CURR_TTY"
    sleep 5
    exit 1
fi

# Backup automático ao abrir (se ativado pelo usuário)
cp "$XML_FILE" "${XML_FILE}.bak" 2>/dev/null || true

# Verifica agendamento de backup automático
_SCHED_FILE="$BACKUP_DIR/.backup_schedule"
_AUTO_FLAG="$BACKUP_DIR/.auto_backup_enabled"
_HOJE=$(date +%Y%m%d)
_SEMANA=$(date +%Y%V)
_ULTIMO_SCHED="$BACKUP_DIR/.ultimo_backup_auto"

_FAZER_BACKUP=0
if [ -f "$_AUTO_FLAG" ] || [ -f "$_SCHED_FILE" ]; then
    _TIPO=$(cat "$_SCHED_FILE" 2>/dev/null || echo "abertura")
    case "$_TIPO" in
        abertura) _FAZER_BACKUP=1 ;;
        diario)
            _ULTIMO=$(cat "$_ULTIMO_SCHED" 2>/dev/null || echo "0")
            [ "$_ULTIMO" != "$_HOJE" ] && _FAZER_BACKUP=1 ;;
        semanal)
            _ULTIMO=$(cat "$_ULTIMO_SCHED" 2>/dev/null || echo "0")
            [ "$_ULTIMO" != "$_SEMANA" ] && _FAZER_BACKUP=1 ;;
    esac
fi

if [ "$_FAZER_BACKUP" -eq 1 ]; then
    _TS=$(date +%Y%m%d_%H%M%S)
    _DEST="$BACKUP_DIR/${THEME_NAME}_auto_${_TS}.xml"
    if cp "$XML_FILE" "$_DEST" 2>/dev/null; then
        md5sum "$_DEST" > "${_DEST}.md5" 2>/dev/null || true
        echo "$_HOJE" > "$_ULTIMO_SCHED" 2>/dev/null || true
        _HIST="$BACKUP_DIR/.historico_${THEME_NAME}.log"
        echo "[$(date '+%d/%m/%Y %H:%M:%S')] BACKUP AUTO: $(basename "$_DEST")" \
            >> "$_HIST" 2>/dev/null || true
    fi
fi

ReiniciarES() {
    printf "\033c" > "$CURR_TTY"
    printf "[*] Reiniciando EmulationStation...\n" > "$CURR_TTY"
    sleep 1.5
    sudo systemctl restart emulationstation
    ExitAll
}
