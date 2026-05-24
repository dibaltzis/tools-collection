master = {
  memory    = 4096
  vcpu      = 4
  disk_size = 20 * 1024 * 1024 * 1024

  host = 50
}

worker = {
  count = 3

  memory    = 2048
  vcpu      = 2
  disk_size = 20 * 1024 * 1024 * 1024

  start_host = 51
}

network = {
  subnet = "192.168.122.0"
  gateway = "192.168.122.1"
  cidr = 24

  dns = ["1.1.1.1", "8.8.8.8"]
}


base_image = "debian-13-genericcloud-amd64.qcow2"

ssh_user = "debian-vm-user"
ssh_public_key_path = "~/.ssh/id_ed25519_fedora_vm.pub"
