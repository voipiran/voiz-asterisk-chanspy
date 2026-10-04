#!/bin/bash
set -u

clear

# ============================================================
# VOIPIRAN ChanSpy Pro
# Version 2.0
#
# Safe installation for Issabel / FreePBX
#
# IMPORTANT:
# - Feature Codes are stored in the featurecodes DB table
# - VOIZ uses dedicated codes *930-*935
# - Never overwrite existing Feature Codes
# - Never run fwconsole/amportal reload from this installer
# - Only reload Asterisk dialplan
# ============================================================

# ------------------------------
# Colors
# ------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# ------------------------------
# VOIZ ChanSpy Feature Codes
# ------------------------------
CHANSY_SIMPLE="*930"
CHANSY_ONLYLISTEN="*931"
CHANSY_WHISPER="*932"
CHANSY_PRIVATEWHISPER="*933"
CHANSY_BARGE="*934"
CHANSY_DTMF="*935"

# ------------------------------
# Files
# ------------------------------
ASTERISK_CUSTOM="/etc/asterisk/extensions_custom.conf"

# ------------------------------
# Banner
# ------------------------------
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${CYAN}██╗   ██╗ ██████╗ ██╗██████╗ ██╗██████╗  █████╗ ███╗   ██╗${NC}"
echo -e "${CYAN}██║   ██║██╔═══██╗██║██╔══██╗██║██╔══██╗██╔══██╗████╗  ██║${NC}"
echo -e "${CYAN}██║   ██║██║   ██║██║██████╔╝██║██████╔╝███████║██╔██╗ ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██║   ██║██║██╔═══╝ ██║██╔══██╗██╔══██║██║╚██╗██║${NC}"
echo -e "${CYAN} ╚████╔╝ ╚██████╔╝██║██║     ██║██║  ██║██║  ██║██║ ╚████║${NC}"
echo -e "${CYAN}  ╚═══╝   ╚═════╝ ╚═╝╚═╝     ╚═╝╚══╝  ╚═╝╚═╝  ╚═══╝${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${MAGENTA}                    https://voipiran.io                    ${NC}"
echo -e "${MAGENTA}###############################################################${NC}"

echo
echo "Install VOIPIRAN ChanSpy Pro"
echo "VOIPIRAN ChanSpy Pro 2.0"
echo

sleep 1

# ============================================================
# 1) Detect PBX / Database credentials
# ============================================================

DB_USER=""
DB_PASS=""
DB_HOST="127.0.0.1"
DB_NAME="asterisk"

PBX_TYPE="unknown"

# ------------------------------------------------------------
# Issabel
# ------------------------------------------------------------
if [[ -f /etc/issabel.conf ]]; then

    echo -e "${CYAN}Detected Issabel...${NC}"

    PBX_TYPE="issabel"

    rootpw=$(sed -ne 's/.*mysqlrootpwd=//p' /etc/issabel.conf \
        | tr -d '[:space:]')

    if [[ -n "${rootpw:-}" ]]; then
        DB_USER="root"
        DB_PASS="$rootpw"
        DB_HOST="127.0.0.1"
        DB_NAME="asterisk"
    fi
fi

# ------------------------------------------------------------
# FreePBX
# ------------------------------------------------------------
if [[ -z "$DB_PASS" && -f /etc/freepbx.conf ]]; then

    echo -e "${CYAN}Detected FreePBX (freepbx.conf)...${NC}"

    PBX_TYPE="freepbx"

    amp_user=$(grep -Po "(?<=amp_conf\['AMPDBUSER'\]\s*=\s*')[^']+" \
        /etc/freepbx.conf | head -n1)

    amp_pass=$(grep -Po "(?<=amp_conf\['AMPDBPASS'\]\s*=\s*')[^']+" \
        /etc/freepbx.conf | head -n1)

    amp_host=$(grep -Po "(?<=amp_conf\['AMPDBHOST'\]\s*=\s*')[^']+" \
        /etc/freepbx.conf | head -n1)

    amp_name=$(grep -Po "(?<=amp_conf\['AMPDBNAME'\]\s*=\s*')[^']+" \
        /etc/freepbx.conf | head -n1)

    [[ -n "$amp_user" ]] && DB_USER="$amp_user"
    [[ -n "$amp_pass" ]] && DB_PASS="$amp_pass"
    [[ -n "$amp_host" ]] && DB_HOST="$amp_host"
    [[ -n "$amp_name" ]] && DB_NAME="$amp_name"
fi

# ------------------------------------------------------------
# Legacy FreePBX
# ------------------------------------------------------------
if [[ -z "$DB_PASS" && -f /etc/amportal.conf ]]; then

    echo -e "${CYAN}Detected FreePBX legacy (amportal.conf)...${NC}"

    PBX_TYPE="freepbx"

    amp_user=$(awk -F= '/^AMPDBUSER/ {print $2}' \
        /etc/amportal.conf | tr -d '[:space:]')

    amp_pass=$(awk -F= '/^AMPDBPASS/ {print $2}' \
        /etc/amportal.conf | tr -d '[:space:]')

    amp_host=$(awk -F= '/^AMPDBHOST/ {print $2}' \
        /etc/amportal.conf | tr -d '[:space:]')

    amp_name=$(awk -F= '/^AMPDBNAME/ {print $2}' \
        /etc/amportal.conf | tr -d '[:space:]')

    [[ -n "$amp_user" ]] && DB_USER="$amp_user"
    [[ -n "$amp_pass" ]] && DB_PASS="$amp_pass"
    [[ -n "$amp_host" ]] && DB_HOST="$amp_host"
    [[ -n "$amp_name" ]] && DB_NAME="$amp_name"
fi

# ------------------------------------------------------------
# /root/.my.cnf
# ------------------------------------------------------------
if [[ -z "$DB_PASS" && -f /root/.my.cnf ]]; then

    echo -e "${CYAN}Using /root/.my.cnf credentials...${NC}"

    rootpw=$(awk -F= \
        '/^[[:space:]]*password[[:space:]]*=/ {print $2}' \
        /root/.my.cnf | tr -d '[:space:]')

    if [[ -n "${rootpw:-}" ]]; then
        DB_USER="root"
        DB_PASS="$rootpw"
    fi
fi

# ------------------------------------------------------------
# Manual credentials
# ------------------------------------------------------------
if [[ -z "$DB_USER" || -z "$DB_PASS" ]]; then

    echo -e "${YELLOW}Could not auto-detect DB credentials.${NC}"

    read -rp "MySQL username (default root): " tmpu
    read -srp "MySQL password: " tmpp
    echo

    [[ -n "${tmpu:-}" ]] && DB_USER="$tmpu" || DB_USER="root"
    DB_PASS="$tmpp"
fi

echo
echo -e "PBX type : ${GREEN}${PBX_TYPE}${NC}"
echo -e "DB user  : ${GREEN}${DB_USER}${NC}"
echo -e "DB host  : ${GREEN}${DB_HOST}${NC}"
echo -e "DB name  : ${GREEN}${DB_NAME}${NC}"
echo

# ============================================================
# 2) MySQL helper
# ============================================================

mysql_query()
{
    local sql="$1"

    mysql \
        -h"$DB_HOST" \
        -u"$DB_USER" \
        -p"$DB_PASS" \
        "$DB_NAME" \
        -e "$sql"
}

mysql_query_quiet()
{
    local sql="$1"

    mysql \
        -h"$DB_HOST" \
        -u"$DB_USER" \
        -p"$DB_PASS" \
        "$DB_NAME" \
        -e "$sql" \
        >/dev/null 2>&1
}

# ============================================================
# 3) Test database connection
# ============================================================

echo -e "${CYAN}Testing database connection...${NC}"

if ! mysql_query "SELECT 1;" >/dev/null 2>&1; then

    echo -e "${RED}ERROR: Cannot connect to database.${NC}"
    echo -e "${YELLOW}Installation aborted. No changes were made.${NC}"

    exit 1
fi

echo -e "${GREEN}Database connection OK.${NC}"

# ============================================================
# 4) Verify featurecodes table
# ============================================================

echo -e "${CYAN}Checking featurecodes table...${NC}"

if ! mysql_query_quiet "
    SELECT 1
    FROM featurecodes
    LIMIT 1;
"; then

    echo -e "${RED}ERROR: featurecodes table is not available.${NC}"
    echo -e "${YELLOW}Installation aborted.${NC}"

    exit 1
fi

echo -e "${GREEN}featurecodes table OK.${NC}"

# ============================================================
# 5) Backup featurecodes table
# ============================================================

BACKUP_DIR="/var/backups/voipiran"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR"

FEATURECODES_BACKUP="${BACKUP_DIR}/featurecodes_before_chanspy_${TIMESTAMP}.sql"

echo -e "${CYAN}Backing up featurecodes table...${NC}"

if ! mysqldump \
    -h"$DB_HOST" \
    -u"$DB_USER" \
    -p"$DB_PASS" \
    "$DB_NAME" \
    featurecodes \
    > "$FEATURECODES_BACKUP" 2>/dev/null; then

    echo -e "${RED}ERROR: Could not backup featurecodes table.${NC}"
    echo -e "${YELLOW}Installation aborted.${NC}"

    rm -f "$FEATURECODES_BACKUP"

    exit 1
fi

echo -e "${GREEN}Backup created:${NC}"
echo "  $FEATURECODES_BACKUP"

# ============================================================
# 6) Check Feature Code conflicts
# ============================================================

echo
echo -e "${CYAN}Checking VOIZ Feature Code availability...${NC}"

CONFLICTS=$(mysql \
    -h"$DB_HOST" \
    -u"$DB_USER" \
    -p"$DB_PASS" \
    "$DB_NAME" \
    -N -B \
    -e "
        SELECT CONCAT(
            defaultcode,
            ' | ',
            modulename,
            ' | ',
            featurename
        )
        FROM featurecodes
        WHERE defaultcode IN (
            '$CHANSY_SIMPLE',
            '$CHANSY_ONLYLISTEN',
            '$CHANSY_WHISPER',
            '$CHANSY_PRIVATEWHISPER',
            '$CHANSY_BARGE',
            '$CHANSY_DTMF'
        )
        AND featurename NOT IN (
            'ChanSpy-Simple',
            'ChanSpy-OnlyListen',
            'ChanSpy-Whisper',
            'ChanSpy-PrivateWhisper',
            'ChanSpy-Barge',
            'ChanSpy-DTMF'
        );
    " 2>/dev/null
)

if [[ -n "$CONFLICTS" ]]; then

    echo
    echo -e "${RED}ERROR: Feature Code conflict detected!${NC}"
    echo
    echo "$CONFLICTS"
    echo
    echo -e "${YELLOW}VOIZ will NOT overwrite existing Feature Codes.${NC}"
    echo -e "${YELLOW}Installation aborted safely.${NC}"

    exit 1
fi

echo -e "${GREEN}No Feature Code conflicts found.${NC}"

# ============================================================
# 7) Backup extensions_custom.conf
# ============================================================

echo
echo -e "${CYAN}Preparing ${ASTERISK_CUSTOM}...${NC}"

if [[ -f "$ASTERISK_CUSTOM" ]]; then

    EXT_BACKUP="${BACKUP_DIR}/extensions_custom_${TIMESTAMP}.conf"

    cp -a "$ASTERISK_CUSTOM" "$EXT_BACKUP"

    echo -e "${GREEN}Backup created:${NC}"
    echo "  $EXT_BACKUP"

else

    echo -e "${YELLOW}${ASTERISK_CUSTOM} does not exist. Creating it...${NC}"

    touch "$ASTERISK_CUSTOM"
fi

# ============================================================
# 8) Add [from-internal-custom]
# ============================================================

if ! grep -qF "[from-internal-custom]" "$ASTERISK_CUSTOM" 2>/dev/null; then

    echo -e "${YELLOW}Adding [from-internal-custom]...${NC}"

    cat >> "$ASTERISK_CUSTOM" <<'EOF'

[from-internal-custom]
EOF

fi

# ============================================================
# 9) Add include safely
# ============================================================

if grep -qF "include => voipiran-chanspypro" "$ASTERISK_CUSTOM" 2>/dev/null; then

    echo -e "${GREEN}ChanSpy include already exists.${NC}"

else

    echo -e "${YELLOW}Adding ChanSpy include...${NC}"

    sed -i \
        '/^\[from-internal-custom\]$/a include => voipiran-chanspypro' \
        "$ASTERISK_CUSTOM"

fi

# ============================================================
# 10) Add / update ChanSpy context
# ============================================================

if grep -qF "[voipiran-chanspypro]" "$ASTERISK_CUSTOM" 2>/dev/null; then

    echo -e "${GREEN}[voipiran-chanspypro] already exists.${NC}"
    echo -e "${YELLOW}Existing ChanSpy context will not be duplicated.${NC}"

else

    echo -e "${YELLOW}Adding [voipiran-chanspypro] context...${NC}"

    cat >> "$ASTERISK_CUSTOM" <<'EOD'

; ============================================================
; VOIPIRAN ChanSpy Pro
; https://voipiran.io
; Hamed Kouhfallah
;
; Feature Codes:
; *930 + extension = Simple
; *931 + extension = Only Listen
; *932 + extension = Whisper
; *933 + extension = Private Whisper
; *934 + extension = Barge
; *935 + extension = DTMF
; ============================================================

[voipiran-chanspypro]

; ------------------------------------------------------------
; Simple ChanSpy
; *930 + extension
; ------------------------------------------------------------
exten => _*930X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},Eq)
 same => n,Hangup()

; ------------------------------------------------------------
; Only Listen
; *931 + extension
; ------------------------------------------------------------
exten => _*931X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},Eqo)
 same => n,Hangup()

; ------------------------------------------------------------
; Whisper
; *932 + extension
; ------------------------------------------------------------
exten => _*932X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},Eqw)
 same => n,Hangup()

; ------------------------------------------------------------
; Private Whisper
; *933 + extension
; ------------------------------------------------------------
exten => _*933X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},EqW)
 same => n,Hangup()

; ------------------------------------------------------------
; Barge
; *934 + extension
; ------------------------------------------------------------
exten => _*934X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},EqB)
 same => n,Hangup()

; ------------------------------------------------------------
; DTMF switchable
; *935 + extension
; ------------------------------------------------------------
exten => _*935X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:4}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,GotoIf($["${CHAN}"=""]?chanspy-error)
 same => n,ChanSpy(${CHAN},Eqd)
 same => n,Hangup()

; ------------------------------------------------------------
; Error handler
; ------------------------------------------------------------
exten => chanspy-error,1,NoOp(VOIZ ChanSpy: target channel not found)
 same => n,Playback(invalid)
 same => n,Hangup()

EOD

fi

# ============================================================
# 11) Insert / update Feature Codes
# ============================================================

echo
echo -e "${CYAN}Registering VOIZ Feature Codes in database...${NC}"

# IMPORTANT:
# We intentionally use modulename='core' because Issabel's
# feature code administration joins featurecodes with modules.
#
# We DO NOT use *30-*35.
# We DO NOT overwrite existing Feature Codes.
# We only update our own ChanSpy rows.

SQL="
START TRANSACTION;

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-Simple',
    'VOIZ - شنود ساده، کد + داخلی',
    '$CHANSY_SIMPLE',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-OnlyListen',
    'VOIZ - فقط صدای کارشناس، کد + داخلی',
    '$CHANSY_ONLYLISTEN',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-Whisper',
    'VOIZ - شنود و نجوا، کد + داخلی',
    '$CHANSY_WHISPER',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-PrivateWhisper',
    'VOIZ - نجوا خصوصی، کد + داخلی',
    '$CHANSY_PRIVATEWHISPER',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-Barge',
    'VOIZ - شنود و مکالمه با هر دو طرف، کد + داخلی',
    '$CHANSY_BARGE',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

INSERT INTO featurecodes
(
    modulename,
    featurename,
    description,
    defaultcode,
    customcode,
    enabled,
    providedest
)
VALUES
(
    'core',
    'ChanSpy-DTMF',
    'VOIZ - تغییر حالت شنود با DTMF، کد + داخلی',
    '$CHANSY_DTMF',
    NULL,
    '1',
    '1'
)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    defaultcode = VALUES(defaultcode),
    enabled = '1',
    providedest = '1';

COMMIT;
"

if ! mysql \
    -h"$DB_HOST" \
    -u"$DB_USER" \
    -p"$DB_PASS" \
    "$DB_NAME" \
    -e "$SQL"; then

    echo
    echo -e "${RED}ERROR: Failed to update featurecodes.${NC}"
    echo
    echo -e "${YELLOW}The database transaction was rolled back.${NC}"
    echo -e "${YELLOW}Configuration backup:${NC}"
    echo "  $EXT_BACKUP"
    echo -e "${YELLOW}Featurecodes backup:${NC}"
    echo "  $FEATURECODES_BACKUP"

    exit 1
fi

echo -e "${GREEN}Feature Codes registered successfully.${NC}"

# ============================================================
# 12) Verify database records
# ============================================================

echo
echo -e "${CYAN}Verifying Feature Codes...${NC}"

mysql_query "
SELECT
    modulename,
    featurename,
    defaultcode,
    enabled
FROM featurecodes
WHERE featurename IN
(
    'ChanSpy-Simple',
    'ChanSpy-OnlyListen',
    'ChanSpy-Whisper',
    'ChanSpy-PrivateWhisper',
    'ChanSpy-Barge',
    'ChanSpy-DTMF'
)
ORDER BY defaultcode;
"

# ============================================================
# 13) Validate extensions_custom.conf
# ============================================================

echo
echo -e "${CYAN}Validating ChanSpy configuration...${NC}"

if ! grep -qF "[voipiran-chanspypro]" "$ASTERISK_CUSTOM"; then

    echo -e "${RED}ERROR: ChanSpy context was not created.${NC}"
    exit 1
fi

if ! grep -qF "include => voipiran-chanspypro" "$ASTERISK_CUSTOM"; then

    echo -e "${RED}ERROR: ChanSpy include was not created.${NC}"
    exit 1
fi

echo -e "${GREEN}ChanSpy configuration exists.${NC}"

# ============================================================
# 14) Reload ONLY Asterisk dialplan
# ============================================================

echo
echo -e "${CYAN}Reloading Asterisk dialplan...${NC}"

if asterisk -rx "dialplan reload" >/dev/null 2>&1; then

    echo -e "${GREEN}Asterisk dialplan reloaded successfully.${NC}"

else

    echo -e "${RED}ERROR: Asterisk dialplan reload failed.${NC}"
    echo
    echo -e "${YELLOW}Configuration backup:${NC}"
    echo "  $EXT_BACKUP"
    echo
    echo -e "${YELLOW}Featurecodes backup:${NC}"
    echo "  $FEATURECODES_BACKUP"

    exit 1
fi

# ============================================================
# 15) Final verification
# ============================================================

echo
echo -e "${CYAN}Checking ChanSpy dialplan...${NC}"

asterisk -rx "dialplan show voipiran-chanspypro"

# ============================================================
# DONE
# ============================================================

echo
echo -e "${GREEN}===============================================================${NC}"
echo -e "${GREEN} VOIPIRAN ChanSpy Pro installed successfully.${NC}"
echo -e "${GREEN}===============================================================${NC}"

echo
echo "Feature Codes:"
echo "  $CHANSY_SIMPLE + extension  = Simple ChanSpy"
echo "  $CHANSY_ONLYLISTEN + extension = Only Listen"
echo "  $CHANSY_WHISPER + extension = Whisper"
echo "  $CHANSY_PRIVATEWHISPER + extension = Private Whisper"
echo "  $CHANSY_BARGE + extension = Barge"
echo "  $CHANSY_DTMF + extension = DTMF"
echo

echo "Example:"
echo "  *930100"
echo "  *932100"
echo

echo -e "${GREEN}Installation completed successfully!${NC}"