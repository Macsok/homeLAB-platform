locals {
  vm_nodes = [
    {
      name      = var.vm_name
      role      = "control-plane"
      cpu_cores = 4
      memory_mb = 4096
    },
    {
      name      = "${var.vm_name}-worker-1"
      role      = "worker"
      cpu_cores = 2
      memory_mb = 2048
    },
    {
      name      = "${var.vm_name}-worker-2"
      role      = "worker"
      cpu_cores = 2
      memory_mb = 2048
    }
  ]

  vm_ipv4_address        = split("/", var.vm_ipv4_cidr)[0]
  vm_ipv4_prefix         = split("/", var.vm_ipv4_cidr)[1]
  vm_ipv4_octets         = [for octet in split(".", local.vm_ipv4_address) : tonumber(octet)]
  vm_ipv4_network_octets = [for octet in split(".", cidrhost(var.vm_ipv4_cidr, 0)) : tonumber(octet)]
  vm_ipv4_host_number = sum([
    for index, octet in local.vm_ipv4_octets :
    (octet - local.vm_ipv4_network_octets[index]) * pow(256, 3 - index)
  ])
}

moved {
  from = proxmox_virtual_environment_vm.test_vm
  to   = proxmox_virtual_environment_vm.test_vm[0]
}

resource "proxmox_virtual_environment_vm" "test_vm" {
  count = length(local.vm_nodes)

  vm_id     = var.vm_id + count.index
  name      = local.vm_nodes[count.index].name
  node_name = var.proxmox_node

  description = "VM created by OpenTofu (multinode environment)"
  tags        = concat(var.vm_tags, [local.vm_nodes[count.index].role])

  on_boot         = var.on_boot
  stop_on_destroy = true

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node
    datastore_id = var.vm_datastore
    full         = true
    retries      = 3
  }

  cpu {
    cores = local.vm_nodes[count.index].cpu_cores
    type  = "host"
  }

  memory {
    dedicated = local.vm_nodes[count.index].memory_mb
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = format(
          "%s/%s",
          cidrhost(var.vm_ipv4_cidr, local.vm_ipv4_host_number + count.index),
          local.vm_ipv4_prefix,
        )
        gateway = var.gateway_ipv4
      }
    }

    user_account {
      username = "ubuntu"

      keys = [
        trimspace(file(pathexpand(var.ssh_public_key_path)))
      ]
    }
  }

  serial_device {
    device = "socket"
  }
}
