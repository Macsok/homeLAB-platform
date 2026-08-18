output "virtual_machines" {
  description = "Configuration details of the created kubeadm nodes."
  value = [
    for index, vm in proxmox_virtual_environment_vm.test_vm : {
      id        = vm.vm_id
      name      = vm.name
      role      = local.vm_nodes[index].role
      ipv4_cidr = format("%s/%s", cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index), local.vm_ipv4_prefix)
      cpu_cores = local.vm_nodes[index].cpu_cores
      memory_mb = local.vm_nodes[index].memory_mb
    }
  ]
}

output "ansible_inventory" {
  description = "Ansible YAML inventory for bootstrapping the kubeadm cluster."
  value = yamlencode({
    all = {
      vars = {
        ansible_user         = "ubuntu"
        metallb_address_pool = var.metallb_address_pool
      }
      children = {
        control_plane = {
          hosts = {
            for index, node in local.vm_nodes : node.name => {
              ansible_host = cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index)
              node_ip      = cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index)
            } if node.role == "control-plane"
          }
        }
        workers = {
          hosts = {
            for index, node in local.vm_nodes : node.name => {
              ansible_host = cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index)
              node_ip      = cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + index)
            } if node.role == "worker"
          }
        }
      }
    }
  })
}
