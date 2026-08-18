variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint without the /api2/json suffix."
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+(?::[0-9]+)?/?$", var.proxmox_endpoint))
    error_message = "proxmox_endpoint must be an HTTPS URL, for example https://pve.example.com:8006/."
  }
}

variable "proxmox_insecure" {
  description = "Allow connections to Proxmox VE using a self-signed TLS certificate."
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Name of the Proxmox VE node on which the template will be created."
  type        = string

  validation {
    condition     = length(trimspace(var.proxmox_node)) > 0
    error_message = "proxmox_node must not be empty."
  }
}

variable "image_datastore" {
  description = "Proxmox datastore used to store the downloaded Ubuntu image."
  type        = string
  default     = "local"
}

variable "vm_datastore" {
  description = "Proxmox datastore used for the template disk."
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge attached to the template."
  type        = string
  default     = "vmbr0"
}

variable "template_vm_id" {
  description = "Identifier assigned to the Proxmox VM template."
  type        = number
  default     = 9000

  validation {
    condition     = var.template_vm_id >= 100 && var.template_vm_id <= 999999999 && floor(var.template_vm_id) == var.template_vm_id
    error_message = "template_vm_id must be an integer from 100 to 999999999."
  }
}

variable "template_name" {
  description = "Name assigned to the Proxmox VM template."
  type        = string
  default     = "ubuntu-noble-cloud-template"

  validation {
    condition     = length(trimspace(var.template_name)) > 0
    error_message = "template_name must not be empty."
  }
}

variable "template_disk_size" {
  description = "Template system disk size in gigabytes."
  type        = number
  default     = 20

  validation {
    condition     = var.template_disk_size >= 8 && floor(var.template_disk_size) == var.template_disk_size
    error_message = "template_disk_size must be an integer of at least 8 GB."
  }
}

variable "ubuntu_image_url" {
  description = "URL of the Ubuntu Noble cloud image imported into Proxmox."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

  validation {
    condition     = can(regex("^https://", var.ubuntu_image_url))
    error_message = "ubuntu_image_url must be an HTTPS URL."
  }
}

variable "ubuntu_image_file_name" {
  description = "File name used for the downloaded Ubuntu Noble image."
  type        = string
  default     = "noble-server-cloudimg-amd64.qcow2"

  validation {
    condition     = length(trimspace(var.ubuntu_image_file_name)) > 0
    error_message = "ubuntu_image_file_name must not be empty."
  }
}
