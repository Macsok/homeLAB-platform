output "vm_name" {
    description = "Created VM name"
    value = proxmox_virtual_environment_vm.test_vm.name
}

output "vm_id" {
    description = "Created VM ID"
    value = proxmox_virtual_environment_vm.test_vm.vm_id
}

output "vm_ipv4" {
    description = "Created VM IPv4 address"
    value = var.vm_ipv4_cidr
}

output "ssh_command" {
    description = "SSH command to connect to the VM"
    # Extract the IP address from the CIDR notation for SSH command
    value = "ssh ubuntu@${split("/", var.vm_ipv4_cidr)[0]}"
}