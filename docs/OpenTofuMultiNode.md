# OpenTofu Multi-Node

Requirements, Proxmox preparation, and OpenTofu configuration are described in [OpenTofuSetup.md](OpenTofuSetup.md). Before deployment, create `terraform.tfvars` from the example file and adjust its values.

First, deploy the source VM template from `opentofu/environments/kubeadm-template`. Set `template_vm_id` and `template_node` in the multi-node `terraform.tfvars` to match the created template.

```bash
cd opentofu/environments/kubeadm-multinode
cp terraform.tfvars.example terraform.tfvars
export PROXMOX_VE_API_TOKEN='opentofu@pve!iac=REPLACE_WITH_TOKEN_SECRET'

tofu init
tofu validate
tofu plan -out=kubeadm-multinode.tfplan
tofu apply kubeadm-multinode.tfplan
tofu output

unset PROXMOX_VE_API_TOKEN
```

The configuration clones the specified template and creates three virtual machines:

- one `control-plane` node with 4 CPU cores and 4096 MB of RAM,
- two `worker` nodes, each with 2 CPU cores and 2048 MB of RAM.

The machines receive three consecutive VM IDs and IPv4 addresses, starting with the `vm_id` and `vm_ipv4_cidr` values from `terraform.tfvars`. Common tags are defined by `vm_tags`, while the role tag is added automatically.

The environment also exposes an `ansible_inventory` output. After the machines are ready, continue with [Kubernetes with kubeadm and Ansible](KubeadmAnsible.md) to generate the inventory and bootstrap the cluster.
