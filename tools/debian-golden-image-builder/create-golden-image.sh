#!/usr/bin/env bash
set -euo pipefail

############################
# CONFIG (EDIT THESE)
############################
VM_NAME="debian-amd64-golden"
VM_USER="homelab_server"

# move the pub key to the current directory to auto grab it
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_PUB_KEY="$(tr -d '\n' < "$WORKDIR/id_ed25519.pub")"

BRIDGE_IF="br0"

# Base cloud image in same directory as script
BASE_IMAGE="$WORKDIR/debian-13-genericcloud-amd64.qcow2"

LIBVIRT_IMG_DIR="/var/lib/libvirt/images"
DISK_SIZE="40G"

############################
# FILE PATHS
############################
USER_DATA="$WORKDIR/user-data-golden.yaml"
META_DATA="$WORKDIR/meta-data-golden.yaml"
SEED_ISO="$WORKDIR/seed-golden.iso"
GOLDEN_DISK="$LIBVIRT_IMG_DIR/${VM_NAME}.qcow2"

############################
# SAFETY CHECKS
############################
if [[ ! -f "$BASE_IMAGE" ]]; then
  echo "ERROR: Base image not found: $BASE_IMAGE"
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

package_update: true
package_upgrade: true

packages:
  - openssh-server
  - qemu-guest-agent
  - curl
  - git
  - ca-certificates

network:
  version: 2
  ethernets:
    all:
      dhcp4: true
      dhcp6: false

growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

runcmd:
  - systemctl enable systemd-networkd
  - systemctl enable systemd-networkd-wait-online
  - systemctl restart systemd-networkd
  - systemctl enable ssh
  - systemctl start ssh
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF2

cat > "$META_DATA" <<EOF2
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF2

echo "[*] Generating seed ISO..."
rm -f "$SEED_ISO"
cloud-localds "$SEED_ISO" "$USER_DATA" "$META_DATA"

############################
# CLEAN UP OLD VM IF EXISTS
############################
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
sudo rm -f "$GOLDEN_DISK"

############################
# CREATE GOLDEN DISK
############################
echo "[*] Creating golden qcow2..."
sudo qemu-img convert -O qcow2 "$BASE_IMAGE" "$GOLDEN_DISK"
sudo qemu-img resize "$GOLDEN_DISK" "$DISK_SIZE"

############################
# CREATE GOLDEN VM
############################
echo "[*] Creating golden VM..."
sudo virt-install \
  --name "$VM_NAME" \
  --memory 4096 \
  --vcpus 4 \
  --os-variant debian13 \
  --disk path="$GOLDEN_DISK",bus=virtio \
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

echo "✅ Golden VM created: $VM_NAME"
echo
echo "🛑 IMPORTANT:"
echo "Golden VM should now be SHUT DOWN before cloning."
echo
echo "Run this:"
echo "  sudo virsh shutdown ${VM_NAME}"
echo
echo "Verify with:"
echo "  sudo virsh list --all"
echo
echo "Only then run create-clone.sh"