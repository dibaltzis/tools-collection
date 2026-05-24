variable "master" {
  description = "Master node configuration"

  type = object({
    memory    = number
    vcpu      = number
    disk_size = number
    host      = number
  })
}

variable "worker" {
  description = "Worker node configuration"

  type = object({
    count      = number
    memory     = number
    vcpu       = number
    disk_size  = number
    start_host = number
  })

  validation {
    condition     = var.worker.count > 0
    error_message = "Worker count must be greater than 0."
  }
}

variable "network" {
  description = "Network configuration"

  type = object({
    subnet  = string
    gateway = string
    cidr    = number
    dns     = list(string)
  })

  validation {
    condition     = var.network.cidr >= 16 && var.network.cidr <= 30
    error_message = "CIDR must be between 16 and 30."
  }
}

variable "base_image" {
  description = "Base image used for VM provisioning"
  type        = string
  default     = "debian-13-genericcloud-amd64.qcow2"
}

variable "libvirt_pool" {
  description = "Libvirt storage pool"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Libvirt network"
  type        = string
  default     = "default"
}

variable "ssh_user" {
  description = "SSH username used to connect to the VMs"
  type        = string
  default     = "debian-vm-user"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_timezone" {
  description = "Timezone configured inside the VMs"
  type        = string
  default     = "Europe/Athens"
}

variable "vm_locale" {
  description = "Locale configured inside the VMs"
  type        = string
  default     = "en_US.UTF-8"
}