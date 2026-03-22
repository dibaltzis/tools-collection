#!/usr/bin/env bash
set -euo pipefail

############################
# CONFIG
############################
GOLDEN_VM="debian-amd64-golden"
VM_USER="homelab_server"

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_PUB_KEY="$(tr -d '\n' < "$WORKDIR/id_ed25519.pub")"

BRIDGE_IF="br0"
LIBVIRT_IMG_DIR="/var/lib/libvirt/images"

############################
# ARGUMENT
############################
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <clone-name>"
  echo "Example: $0 debian-amd64-dev-01"
  exit 1
fi

CLONE_NAME="$1"

############################
# FILE PATHS
############################
USER_DATA="$WORKDIR/user-data-${CLONE_NAME}.yaml"
META_DATA="$WORKDIR/meta-data-${CLONE_NAME}.yaml"
SEED_ISO="$WORKDIR/seed-${CLONE_NAME}.iso"

GOLDEN_DISK="$LIBVIRT_IMG_DIR/${GOLDEN_VM}.qcow2"
CLONE_DISK="$LIBVIRT_IMG_DIR/${CLONE_NAME}.qcow2"

############################
# SAFETY CHECKS
############################
if [[ ! -f "$GOLDEN_DISK" ]]; then
  echo "ERROR: Golden disk not found: $GOLDEN_DISK"
  echo "Did you run create-golden-image.sh?"
  exit 1
fi

if [[ ! -f "$WORKDIR/id_ed25519.pub" ]]; then
  echo "ERROR: SSH public key not found: $WORKDIR/id_ed25519.pub"
  exit 1
fi

############################
# GENERATE CLOUD-INIT FILES
############################
cat > "$USER_DATA" <<EOF2
#cloud-config
users:
  - name: ${VM_USER}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${SSH_PUB_KEY}

ssh_pwauth: false
disable_root: true

growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

network:
  version: 2
  ethernets:
    all:
      dhcp4: true
      dhcp6: false
EOF2

cat > "$META_DATA" <<EOF2
instance-id: ${CLONE_NAME}
local-hostname: ${CLONE_NAME}
EOF2

echo "[*] Generating seed ISO for clone..."
rm -f "$SEED_ISO"
cloud-localds "$SEED_ISO" "$USER_DATA" "$META_DATA"

############################
# CLEAN UP OLD CLONE IF EXISTS
############################
sudo virsh destroy "$CLONE_NAME" 2>/dev/null || true
sudo virsh undefine "$CLONE_NAME" --remove-all-storage 2>/dev/null || true
sudo rm -f "$CLONE_DISK"

############################
# CREATE CLONE DISK (BACKING ON GOLDEN)
############################
echo "[*] Creating clone disk from golden..."
sudo qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b "$GOLDEN_DISK" \
  -o backing_fmt=qcow2 \
  "$CLONE_DISK"

############################
# CREATE CLONE VM
############################
echo "[*] Creating clone VM: $CLONE_NAME"
sudo virt-install \
  --name "$CLONE_NAME" \
  --memory 4096 \
  --vcpus 4 \
  --os-variant debian13 \
  --disk path="$CLONE_DISK",bus=virtio \
  --disk path="$SEED_ISO",device=cdrom,readonly=on \
  --network bridge="$BRIDGE_IF",model=virtio \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --boot uefi \
  --graphics spice \
  --import \
  --noautoconsole

echo
echo "[*] Waiting 10 seconds for VM to boot..."
sleep 10

echo
echo "✅ Clone VM created: $CLONE_NAME"
echo "➡️  SSH when ready: ssh ${VM_USER}@<IP>"