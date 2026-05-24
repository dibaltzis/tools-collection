#cloud-config

hostname: ${hostname}

timezone: ${timezone}

users:
  - name: ${ssh_user}
    groups: users, sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

    ssh_authorized_keys:
      - ${ssh_public_key}

growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false
