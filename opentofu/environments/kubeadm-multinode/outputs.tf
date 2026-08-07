output "virtual_machines" {
    description = "Configuration details of the created kubeadm nodes."
    value = [
        for index, vm in proxmox_virtual_environment_vm.test_vm : {
            id = vm.vm_id
            name = vm.name
            role = local.vm_nodes[index].role
            ipv4_cidr = format("%s/%s", cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index), local.vm_ipv4_prefix)
            cpu_cores = local.vm_nodes[index].cpu_cores
            memory_mb = local.vm_nodes[index].memory_mb
        }
    ]
}
