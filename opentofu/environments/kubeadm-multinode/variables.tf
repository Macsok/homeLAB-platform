variable "proxmox_endpoint" {
    description = "Proxmox VE API endpoint without the /api2/json suffix."
    type = string

    validation {
        condition = can(regex("^https://[^/]+(?::[0-9]+)?/?$", var.proxmox_endpoint))
        error_message = "proxmox_endpoint must be an HTTPS URL, for example https://pve.example.com:8006/."
    }
}

variable "proxmox_insecure" {
    description = "Allow connections to Proxmox VE using a self-signed TLS certificate."
    type = bool
    default = false
}

variable "proxmox_node" {
    description = "Name of the Proxmox VE node on which the virtual machines will be created."
    type = string

    validation {
        condition = length(trimspace(var.proxmox_node)) > 0
        error_message = "proxmox_node must not be empty."
    }
}

variable "vm_datastore" {
    description = "Proxmox datastore used for virtual machine disks."
    type = string
    default = "local-lvm"
}

variable "template_vm_id" {
    description = "Identifier of the Proxmox VM template used as the clone source."
    type = number

    validation {
        condition = var.template_vm_id >= 100 && var.template_vm_id <= 999999999 && floor(var.template_vm_id) == var.template_vm_id
        error_message = "template_vm_id must be an integer from 100 to 999999999."
    }
}

variable "template_node" {
    description = "Name of the Proxmox VE node containing the source VM template."
    type = string

    validation {
        condition = length(trimspace(var.template_node)) > 0
        error_message = "template_node must not be empty."
    }
}

variable "vm_id" {
    description = "Base VM identifier; the other two machines will use the next consecutive identifiers."
    type = number

    validation {
        condition = var.vm_id >= 100 && var.vm_id <= 999999997 && floor(var.vm_id) == var.vm_id
        error_message = "vm_id must be an integer from 100 to 999999997, leaving room for three consecutive IDs."
    }
}

variable "vm_name" {
    description = "Base cluster name and the name of the control plane node."
    type = string
    default = "kubeadm"

    validation {
        condition = length(trimspace(var.vm_name)) > 0
        error_message = "vm_name must not be empty."
    }
}

variable "vm_tags" {
    description = "Common Proxmox tags assigned to every virtual machine. The node role is added automatically."
    type = list(string)

    validation {
        condition = alltrue([for tag in var.vm_tags : length(trimspace(tag)) > 0])
        error_message = "vm_tags must not contain empty values."
    }
}

variable "on_boot" {
    description = "Specifies whether a VM will be started during system boot."
    type = bool
    default = true
}

variable "network_bridge" {
    description = "Proxmox network bridge attached to the virtual machines."
    type = string
    default = "vmbr0"
}

variable "vm_ipv4_cidr" {
    description = "Base static IPv4 address with a prefix for the control plane; workers will use the next two addresses."
    type = string

    validation {
        condition = (
            can(cidrhost(var.vm_ipv4_cidr, 0)) &&
            length(split(".", split("/", var.vm_ipv4_cidr)[0])) == 4
        )
        error_message = "vm_ipv4_cidr must be a valid IPv4 address with a prefix, for example 192.168.1.20/24."
    }
}

variable "gateway_ipv4" {
    description = "Default gateway IPv4 address for all virtual machines."
    type = string

    validation {
        condition = can(cidrhost("${var.gateway_ipv4}/32", 0)) && length(split(".", var.gateway_ipv4)) == 4
        error_message = "gateway_ipv4 must be a valid IPv4 address, for example 192.168.1.1."
    }
}

variable "ssh_public_key_path" {
    description = "Path to the SSH public key added to the ubuntu user account."
    type = string
    default = "~/.ssh/id_ed25519.pub"

    validation {
        condition = length(trimspace(var.ssh_public_key_path)) > 0
        error_message = "ssh_public_key_path must not be empty."
    }
}
