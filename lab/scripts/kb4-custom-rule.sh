#!/usr/bin/env bash
# Kịch bản 4 — Custom Rule (WAZUH_LAB_ALERT → rule 100100)
set -euo pipefail

MSG="${1:-WAZUH_LAB_ALERT custom detection test}"

echo "== KB4 Custom Rule =="
echo "Chuoi: $MSG"
echo

if command -v logger >/dev/null 2>&1; then
  logger --tag noslab "$MSG"
  echo "Da ghi bang logger (syslog). Agent se thu thap neu theo doi /var/log/syslog hoac auth/messages."
else
  echo "Khong co logger. Thu ghi truc tiep:"
  echo "$(date '+%b %e %H:%M:%S') $(hostname) noslab: $MSG" | tee -a /var/log/syslog 2>/dev/null \
    || echo "Can quyen ghi log hoac cai bsd-utils (logger)."
fi

echo
echo "Buoc logtest tren Manager (Windows PowerShell):"
echo '  $mgr = (docker ps --format "{{.Names}}" | Select-String "wazuh.manager").ToString()'
echo '  docker exec -it $mgr /var/ossec/bin/wazuh-logtest'
echo "  Dan: Jan 1 12:00:00 testhost app: WAZUH_LAB_ALERT test message"
echo
echo "Dashboard: rule.id:100100   hoac   rule.groups:nos_lab"
