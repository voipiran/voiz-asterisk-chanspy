#!/bin/bash
set -u

clear
# ---- Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[1;35m'; NC='\033[0m'

echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${CYAN}██╗   ██╗ ██████╗ ██╗██████╗ ██╗██████╗  █████╗ ███╗   ██╗${NC}"
echo -e "${CYAN}██║   ██║██╔═══██╗██║██╔══██╗██║██╔══██╗██╔══██╗████╗  ██║${NC}"
echo -e "${CYAN}██║   ██║██║   ██║██║██████╔╝██║██████╔╝███████║██╔██╗ ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██║   ██║██║██╔═══╝ ██║██╔══██╗██╔══██║██║╚██╗██║${NC}"
echo -e "${CYAN} ╚████╔╝ ╚██████╔╝██║██║     ██║██║  ██║██║  ██║██║ ╚████║${NC}"
echo -e "${CYAN}  ╚═══╝   ╚═════╝ ╚═╝╚═╝     ╚═╝╚══╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${MAGENTA}                    https://voipiran.io                    ${NC}"
echo -e "${MAGENTA}###############################################################${NC}"

echo "Install VOIPIRAN ChanSpy Pro"
echo "VOIPIRAN ChanSpy 1.0"
sleep 1

# ------------------------------
# 1) تشخیص و دریافت اطلاعات دیتابیس (Issabel / FreePBX / root .my.cnf / پرسش از کاربر)
# خروجی: DB_USER, DB_PASS, DB_HOST, DB_NAME
# ------------------------------
DB_USER=""
DB_PASS=""
DB_HOST="127.0.0.1"
DB_NAME="asterisk"

if [[ -f /etc/issabel.conf ]]; then
  # Issabel
  echo -e "${CYAN}Detected Issabel...${NC}"
  rootpw=$(sed -ne 's/.*mysqlrootpwd=//p' /etc/issabel.conf | tr -d '[:space:]')
  if [[ -n "${rootpw:-}" ]]; then
    DB_USER="root"
    DB_PASS="$rootpw"
    DB_NAME="asterisk"
  fi
fi

if [[ -z "$DB_PASS" && -f /etc/freepbx.conf ]]; then
  # FreePBX (جدید)
  echo -e "${CYAN}Detected FreePBX (freepbx.conf)...${NC}"
  amp_user=$(grep -Po "(?<=amp_conf\['AMPDBUSER'\]\s*=\s*')[^']+" /etc/freepbx.conf | head -n1)
  amp_pass=$(grep -Po "(?<=amp_conf\['AMPDBPASS'\]\s*=\s*')[^']+" /etc/freepbx.conf | head -n1)
  amp_host=$(grep -Po "(?<=amp_conf\['AMPDBHOST'\]\s*=\s*')[^']+" /etc/freepbx.conf | head -n1)
  amp_name=$(grep -Po "(?<=amp_conf\['AMPDBNAME'\]\s*=\s*')[^']+" /etc/freepbx.conf | head -n1)

  [[ -n "$amp_user" ]] && DB_USER="$amp_user"
  [[ -n "$amp_pass" ]] && DB_PASS="$amp_pass"
  [[ -n "$amp_host" ]] && DB_HOST="$amp_host"
  [[ -n "$amp_name" ]] && DB_NAME="$amp_name"
fi

if [[ -z "$DB_PASS" && -f /etc/amportal.conf ]]; then
  # FreePBX (قدیمی)
  echo -e "${CYAN}Detected FreePBX (amportal.conf legacy)...${NC}"
  amp_user=$(awk -F= '/^AMPDBUSER/ {print $2}' /etc/amportal.conf | tr -d '[:space:]')
  amp_pass=$(awk -F= '/^AMPDBPASS/ {print $2}' /etc/amportal.conf | tr -d '[:space:]')
  amp_host=$(awk -F= '/^AMPDBHOST/ {print $2}' /etc/amportal.conf | tr -d '[:space:]')
  amp_name=$(awk -F= '/^AMPDBNAME/ {print $2}' /etc/amportal.conf | tr -d '[:space:]')

  [[ -n "$amp_user" ]] && DB_USER="$amp_user"
  [[ -n "$amp_pass" ]] && DB_PASS="$amp_pass"
  [[ -n "$amp_host" ]] && DB_HOST="$amp_host"
  [[ -n "$amp_name" ]] && DB_NAME="$amp_name"
fi

if [[ -z "$DB_PASS" && -f /root/.my.cnf ]]; then
  # اگر root .my.cnf موجود است
  echo -e "${CYAN}Using /root/.my.cnf credentials...${NC}"
  rootpw=$(awk -F= '/^[[:space:]]*password[[:space:]]*=/ {print $2}' /root/.my.cnf | tr -d '[:space:]')
  if [[ -n "${rootpw:-}" ]]; then
    DB_USER="root"
    DB_PASS="$rootpw"
  fi
fi

if [[ -z "$DB_USER" || -z "$DB_PASS" ]]; then
  echo -e "${YELLOW}Could not auto-detect DB credentials. Please enter manually.${NC}"
  read -rp "MySQL username (default root): " tmpu
  read -srp "MySQL password: " tmpp; echo
  [[ -n "${tmpu:-}" ]] && DB_USER="$tmpu" || DB_USER="root"
  DB_PASS="$tmpp"
fi

echo -e "DB user: ${GREEN}${DB_USER}${NC}"
echo -e "DB host: ${GREEN}${DB_HOST}${NC}"
echo -e "DB name: ${GREEN}${DB_NAME}${NC}"

# ------------------------------
# 2) افزودن کانتکست و اینکلود در extensions_custom.conf
# ------------------------------
FILE="/etc/asterisk/extensions_custom.conf"
LINE="[from-internal-custom]"

# اگر سکشن وجود ندارد، اضافه‌اش کن
if ! grep -qF "$LINE" "$FILE" 2>/dev/null; then
  echo -e "${YELLOW}Adding [from-internal-custom] to ${FILE}${NC}"
  echo "$LINE" | sudo tee -a "$FILE" >/dev/null
fi

# include => voipiran-chanspypro را بعد از سکشن اضافه کن اگر نبود
if grep -qF "include => voipiran-chanspypro" "$FILE" 2>/dev/null; then
  echo -e "${GREEN}include => voipiran-chanspypro already exists${NC}"
else
  echo -e "${YELLOW}Adding include => voipiran-chanspypro${NC}"
  sudo sed -i '/\[from-internal-custom\]/a include => voipiran-chanspypro' "$FILE"
fi

# خود کانتکست voipiran-chanspypro اگر نیست، اضافه کن
if grep -qF "[voipiran-chanspypro]" "$FILE" 2>/dev/null; then
  echo -e "${GREEN}[voipiran-chanspypro] already exists${NC}"
else
  echo -e "${YELLOW}Appending [voipiran-chanspypro] context${NC}"

  cat <<'EOD' | sudo tee -a "$FILE" >/dev/null
[voipiran-chanspypro]
;; voipiran.io - Hamed Kouhfallah
;; ChanSpy Pro - SIP / PJSIP compatible
;; Uses Issabel device database to resolve the actual channel technology.

;; فقط شنیدن
exten => _*30X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},Eq)

;; فقط شنیدن - Only listen to audio coming from this channel
exten => _*31X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},Eqo)

;; Whisper به Agent
exten => _*32X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},Eqw)

;; Private Whisper
exten => _*33X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},EqW)

;; Barge-in
exten => _*34X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},EqB)

;; DTMF switchable
exten => _*35X.,1,Set(DEV=${DB(AMPUSER/${EXTEN:3}/device)})
 same => n,Set(DEV=${CUT(DEV,&,1)})
 same => n,Set(CHAN=${DB(DEVICE/${DEV}/dial)})
 same => n,ChanSpy(${CHAN},Eqd)
EOD
fi

# ------------------------------
# 3) درج/به‌روزرسانی Feature Codes در دیتابیس
# جدول: featurecodes  (FreePBX/Issabel هردو)
# ------------------------------
run_query () {
  local sql="$1"
  mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$sql" >/dev/null 2>&1
  return $?
}

echo -e "${CYAN}Updating feature codes...${NC}"

# شنود ساده
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-Simple','VOIZ-شنود ساده، کد + داخلی','*30',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*30', enabled='1';"

# فقط صدای کارشناس
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-OnlyListen','VOIZ-فقط صدای کارشناس، کد + داخلی','*31',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*31', enabled='1';"

# شنود + نجوا (Whisper)
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-Whisper','VOIZ-شنود و صحبت پنهانی، کد + داخلی','*32',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*32', enabled='1';"

# نجوا خصوصی
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-PrivateWhisper','VOIZ-صحبت با کارشناس بدون شنیدن مشتری، کد + داخلی','*33',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*33', enabled='1';"

# Barge
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-Barge','VOIZ-شنود و مکالمه با هر دو طرف، کد + داخلی','*34',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*34', enabled='1';"

# DTMF Mode Change
run_query "INSERT INTO featurecodes (modulename, featurename, description, defaultcode, customcode, enabled, providedest)
VALUES ('core','ChanSpy-DTMF','VOIZ-تغییر حالت شنود حین تماس با کلید 4/5/6، کد + داخلی','*35',NULL,'1','1')
ON DUPLICATE KEY UPDATE defaultcode='*35', enabled='1';"

echo -e "${GREEN}Feature codes updated.${NC}"

# ------------------------------
# 4) Reload (FreePBX اولویت دارد)
# ------------------------------
echo -e "${CYAN}Reloading dialplan...${NC}"
if command -v fwconsole >/dev/null 2>&1; then
  sudo fwconsole reload >/dev/null 2>&1 && echo -e "${GREEN}fwconsole reload done.${NC}" || echo -e "${YELLOW}fwconsole reload failed; trying asterisk reload...${NC}"
fi
sudo asterisk -rx "dialplan reload" >/dev/null 2>&1 && echo -e "${GREEN}Asterisk dialplan reloaded.${NC}"

echo -e "${GREEN}Installation completed successfully!${NC}"
