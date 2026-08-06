resource "proxmox_download_file" "ubuntu_noble" {
    content_type = "import"
    datastore_id = var.image_datastore
    node_name = var.proxmox_node

    url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    file_name = "noble-server-cloudimg-amd64.qcow2"

    # Optional: Set a timeout for the download operation (in seconds)
    upload_timeout = 3600
    # Optional: Overwrite the file if it already exists in the datastore
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "test_vm" {
    vm_id = var.vm_id
    name = var.vm_name
    node_name = var.proxmox_node

    description = "VM created by OpenTofu"
    tags = ["opentofu", "homelab", "test"]

    stop_on_destroy = true

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
        size = 20
        iothread  = true
        discard = "on"
    }

    network_device {
        bridge = var.network_bridge
        model = "virtio"
    }

    initialization {
        datastore_id = var.vm_datastore

        ip_config {
            ipv4 {
                address = var.vm_ipv4_cidr
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