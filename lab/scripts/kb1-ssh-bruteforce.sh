#!/usr/bin/env bash
# Kịch bản 1 — SSH Brute Force (lab nội bộ)
# Chỉ dùng tới máy victim do nhóm quản lý.
set -euo pipefail

TARGET="${1:-}"
USER_NAME="${2:-nosuchuser}"
ATTEMPTS="${3:-10}"
WRONG_PASS="${SSH_LAB_WRONG_PASS:-WrongPassLab123!}"

if [[ -z "$TARGET" ]]; then
  echo "Cach dung: $0 <IP_VICTIM> [user] [so_lan]"
  echo "Vi du:   $0 192.168.1.50 nosuchuser 12"
  echo
  echo "Can: ssh. Khuyen nghi cai sshpass de gui mat khau sai tu dong:"
  echo "  sudo apt install sshpass   # Debian/Ubuntu"
  exit 1
fi

echo "== KB1 SSH Brute Force (lab) =="
echo "Target  : $TARGET"
echo "User    : $USER_NAME"
echo "Attempts: $ATTEMPTS"
echo

if command -v sshpass >/dev/null 2>&1; then
  MODE="sshpass"
  echo "Che do: sshpass (gui mat khau sai → Failed password / Invalid user)"
else
  MODE="batch"
  echo "Che do: BatchMode (khong co sshpass)."
  echo "  Voi user khong ton tai thuong van co log Invalid user (rule 5710)."
  echo "  De co Failed password day du: sudo apt install sshpass roi chay lai."
fi
echo

for i in $(seq 1 "$ATTEMPTS"); do
  echo "[$i/$ATTEMPTS] ssh $USER_NAME@$TARGET ..."
  if [[ "$MODE" == "sshpass" ]]; then
    sshpass -p "$WRONG_PASS" ssh \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      "${USER_NAME}@${TARGET}" true 2>/dev/null || true
  else
    ssh -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 \
        -o PreferredAuthentications=password \
        -o PubkeyAuthentication=no \
        "${USER_NAME}@${TARGET}" true 2>/dev/null || true
  fi
  sleep 1
done

echo
echo "Xong. Mo Dashboard → Threat Hunting, loc:"
echo "  rule.id:(5710 OR 5716 OR 5763 OR 5551)"
echo "  rule.groups:authentication_failed"
echo
echo "Cach thu cong (thuyet trinh): ssh $USER_NAME@$TARGET  → nhap sai mat khau nhieu lan"
