variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_insecure" {
  description = "Whether to skip SSL verification for Proxmox API (self-signed certificates)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "image_datastore" {
  description = "Proxmox datastore name for VM images"
  type        = string
  default     = "local"
}

variable "vm_datastore" {
  description = "Proxmox datastore name for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge name for VM networking"
  type        = string
  default     = "vnet1"
}

variable "vm_id" {
  description = "Proxmox VM identifier (unique ID for the VM)"
  type        = number
  default     = 2001
}

variable "vm_name" {
  description = "Proxmox VM name"
  type        = string
  default     = "iac-test-01"
}

variable "vm_ipv4_cidr" {
  description = "Static IPv4 address with CIDR notation for the VM"
  type        = string
}

variable "gateway_ipv4" {
  description = "Gateway IPv4 address for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for VM access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}