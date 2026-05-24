output "vm_info" {
  value = {
    for name, vm in local.vms :
    name => {
      ip = vm.ip

      role = startswith(name, "debian-vm-master") ? "master" : "worker"
    }
  }
}

output "ansible_config" {
  value = {
    ssh_user = var.ssh_user

    ssh_private_key_file = replace(
      var.ssh_public_key_path,
      ".pub",
      ""
    )
  }
}