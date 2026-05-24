#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="../ansible/inventory/hosts.ini"

VM_INFO=$(terraform output -json vm_info)
ANSIBLE_CONFIG=$(terraform output -json ansible_config)

SSH_USER=$(echo "$ANSIBLE_CONFIG" | jq -r '.ssh_user')
SSH_KEY=$(echo "$ANSIBLE_CONFIG" | jq -r '.ssh_private_key_file')

{
    echo "[kube_master]"

    echo "$VM_INFO" | jq -r '
        to_entries[]
        | select(.value.role == "master")
        | "\(.key) ansible_host=\(.value.ip)"
    '

    echo

    echo "[kube_workers]"

    echo "$VM_INFO" | jq -r '
        to_entries[]
        | select(.value.role == "worker")
        | "\(.key) ansible_host=\(.value.ip)"
    '

    echo
    echo "[all:vars]"
    echo "ansible_user=$SSH_USER"
    echo "ansible_ssh_private_key_file=$SSH_KEY"
    echo "ansible_python_interpreter=/usr/bin/python3"

} > "$OUTPUT_FILE"

echo "Ansible inventory written to $OUTPUT_FILE"