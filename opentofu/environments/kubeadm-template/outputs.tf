output "template" {
    description = "Details of the Ubuntu Noble VM template."
    value = {
        vm_id = proxmox_virtual_environment_vm.ubuntu_noble_template.vm_id
        name = proxmox_virtual_environment_vm.ubuntu_noble_template.name
        node = proxmox_virtual_environment_vm.ubuntu_noble_template.node_name
    }
}
