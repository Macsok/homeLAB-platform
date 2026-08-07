resource "proxmox_download_file" "ubuntu_noble" {
    content_type = "import"
    datastore_id = var.image_datastore
    node_name = var.proxmox_node

    url = var.ubuntu_image_url
    file_name = var.ubuntu_image_file_name

    upload_timeout = 3600
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "ubuntu_noble_template" {
    vm_id = var.template_vm_id
    name = var.template_name
    node_name = var.proxmox_node

    description = "Ubuntu Noble cloud-init template managed by OpenTofu"
    tags = ["opentofu", "homelab", "template", "ubuntu-noble"]

    template = true
    started = false
    on_boot = false

    cpu {
        cores = 2
        type = "host"
    }

    memory {
        dedicated = 2048
    }

    disk {
        datastore_id = var.vm_datastore
        import_from = proxmox_download_file.ubuntu_noble.id

        interface = "virtio0"
        size = var.template_disk_size
        iothread = true
        discard = "on"
    }

    network_device {
        bridge = var.network_bridge
        model = "virtio"
    }

    initialization {
        datastore_id = var.vm_datastore
    }

    serial_device {
        device = "socket"
    }
}
