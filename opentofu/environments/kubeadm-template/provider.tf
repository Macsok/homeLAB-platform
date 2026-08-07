# Configure provider options
provider "proxmox" {
    # Referencing variables defined in variables.tf
    endpoint = var.proxmox_endpoint
    insecure = var.proxmox_insecure
}
