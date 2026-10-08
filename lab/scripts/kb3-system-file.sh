#!/usr/bin/env bash
# Kịch bản 3 — Phát hiện thay đổi file hệ thống (FIM + rule 100110)
# Chạy bằng sudo trên máy Linux có Wazuh Agent.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Can chay bang sudo: sudo $0"
  exit 1
fi

MARKER="/etc/wazuh-lab-marker.conf"
PASSWD="/etc/passwd"
TAG="# wazuh-lab-demo"

echo "== KB3 System file change =="
echo

echo "[1] Tao file marker trong /etc (FIM rule ~554/550)..."
echo "wazuh lab marker $(date -Iseconds)" > "$MARKER"
sleep 5

echo "[2] Them comment tam vao /etc/passwd (kich hoat custom rule 100110)..."
cp -a "$PASSWD" /tmp/passwd.wazuh-lab.bak
if ! grep -qxF "$TAG" "$PASSWD"; then
  echo "$TAG" >> "$PASSWD"
fi
echo "    Da them dong: $TAG"
echo "    Doi 15–30s roi mo Dashboard: rule.id:100110"
sleep 15

echo "[3] Hoan nguyen /etc/passwd..."
grep -vxF "$TAG" "$PASSWD" > /tmp/passwd.wazuh-lab.clean
mv /tmp/passwd.wazuh-lab.clean "$PASSWD"
chmod 644 "$PASSWD"

echo "[4] Xoa marker..."
rm -f "$MARKER"

echo
echo "Xong. Loc Dashboard:"
echo "  rule.id:(550 OR 554 OR 553 OR 100110)"
echo "  rule.groups:nos_lab"
echo "  syscheck.path:/etc/passwd"
echo
echo "Backup (neu can): /tmp/passwd.wazuh-lab.bak"
