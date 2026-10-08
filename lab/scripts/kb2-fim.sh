#!/usr/bin/env bash
# Kịch bản 2 — File Integrity Monitoring (FIM)
set -euo pipefail

DIR="${1:-/tmp/wazuh-lab}"
FILE="$DIR/test.txt"

echo "== KB2 FIM =="
echo "Thu muc: $DIR"
echo "Can agent dang giam sat thu muc nay (realtime khuyen nghi)."
echo

mkdir -p "$DIR"

echo "[1/3] Tao file..."
echo "hello-wazuh-lab" > "$FILE"
sleep 3

echo "[2/3] Sua file..."
echo "modified-$(date -Iseconds)" >> "$FILE"
sleep 3

echo "[3/3] Xoa file..."
rm -f "$FILE"

echo
echo "Xong. Dashboard → FIM / Threat Hunting:"
echo "  rule.groups:syscheck"
echo "  syscheck.path:*wazuh-lab*   hoặc   syscheck.path:*test.txt*"
echo "Rule thuong gap: 554 (tao), 550 (sua), 553 (xoa)"
