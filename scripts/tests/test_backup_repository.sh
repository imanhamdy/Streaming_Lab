#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
VM_BACKUP_HOST="${VM_BACKUP_HOST:-vm-backup}"
VM_BACKUP_USER="${VM_BACKUP_USER:-principal}"

ok()   { printf "  [PASS] %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }

echo "========================================"
echo " Veeam Backup Repository Check (vm-backup)"
echo "========================================"
echo ""

# 1. SSH reachability
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$VM_BACKUP_USER@$VM_BACKUP_HOST" "echo ok" &>/dev/null; then
  ok "SSH to $VM_BACKUP_HOST: reachable"
else
  fail "SSH to $VM_BACKUP_HOST: unreachable (set VM_BACKUP_HOST and ensure SSH key is configured)"
  echo ""
  echo "Results: $PASS PASS, $FAIL FAIL"
  exit 1
fi

# 2. /backup directory
BACKUP_EXISTS=$(ssh "$VM_BACKUP_USER@$VM_BACKUP_HOST" "test -d /backup && echo yes || echo no" 2>/dev/null)
if [ "$BACKUP_EXISTS" = "yes" ]; then
  ok "/backup directory exists"
else
  fail "/backup directory missing on $VM_BACKUP_HOST"
fi

# 3. Disk space
DISK=$(ssh "$VM_BACKUP_USER@$VM_BACKUP_HOST" "df -h /backup | tail -1" 2>/dev/null || echo "")
if [ -n "$DISK" ]; then
  ok "Disk: $DISK"
else
  fail "Could not check disk space on /backup"
fi

# 4. qemu-guest-agent on vm-backup
QEMU=$(ssh "$VM_BACKUP_USER@$VM_BACKUP_HOST" "systemctl is-active qemu-guest-agent 2>/dev/null || echo inactive")
if [ "$QEMU" = "active" ]; then
  ok "qemu-guest-agent active on $VM_BACKUP_HOST"
else
  fail "qemu-guest-agent not active on $VM_BACKUP_HOST (status: $QEMU)"
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
