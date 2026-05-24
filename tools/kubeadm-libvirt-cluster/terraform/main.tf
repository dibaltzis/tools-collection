resource "libvirt_volume" "base_image" {
  name   = "debian13-base.qcow2"
  pool   = var.libvirt_pool
  source = "${path.module}/images/${var.base_image}"
  format = "qcow2"
}

locals {
  master_vm = {
    "debian-vm-master" = {
      memory    = var.master.memory
      vcpu      = var.master.vcpu
      disk_size = var.master.disk_size

      ip = cidrhost(
        "${var.network.subnet}/${var.network.cidr}",
        var.master.host
      )
    }
  }

  worker_vms = {
    for i in range(var.worker.count) :
    "debian-vm-worker-${i + 1}" => {
      memory    = var.worker.memory
      vcpu      = var.worker.vcpu
      disk_size = var.worker.disk_size

      ip = cidrhost(
        "${var.network.subnet}/${var.network.cidr}",
        var.worker.start_host + i
      )
    }
  }

  vms = merge(local.master_vm, local.worker_vms)
}

resource "libvirt_volume" "vm_disk" {
  for_each = local.vms

  name           = "${each.key}.qcow2"
  base_volume_id = libvirt_volume.base_image.id
  pool           = var.libvirt_pool
  size           = each.value.disk_size
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.vms

  name = "${each.key}-cloudinit.iso"
  pool = var.libvirt_pool

  user_data = templatefile("${path.module}/cloud_init.cfg.tpl", {
    hostname       = each.key

    timezone       = var.vm_timezone
    locale         = var.vm_locale

    ssh_user       = var.ssh_user
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })

  network_config = templatefile("${path.module}/network_config.cfg.tpl", {
    ip      = each.value.ip
    cidr    = var.network.cidr
    gateway = var.network.gateway
    dns     = var.network.dns
  })
}

resource "libvirt_domain" "vm" {
  for_each = local.vms

  name      = each.key
  memory    = each.value.memory
  vcpu      = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  autostart = true
  
  network_interface {
    network_name = var.network_name
    hostname     = each.key
  }

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}