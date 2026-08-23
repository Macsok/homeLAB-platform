# Kubernetes with kubeadm and Ansible

This repository provisions three Ubuntu 24.04 virtual machines with OpenTofu and then bootstraps a Kubernetes cluster with Ansible:

- one control-plane and stacked etcd node,
- two worker nodes,
- containerd as the container runtime,
- Calico as the CNI plugin,
- optionally, MetalLB in Layer 2 mode for `LoadBalancer` services.

This is a development and home-lab topology. The Kubernetes API and etcd are unavailable while the single control-plane node is down.

## 1. Provision the virtual machines

Follow [OpenTofuMultiNode.md](OpenTofuMultiNode.md) and apply the `kubeadm-multinode` environment.

If you intend to install MetalLB, reserve an unused address range outside DHCP and set it in `terraform.tfvars`:

```hcl
metallb_address_pool = "192.168.10.70-192.168.10.79"
```

The base cluster does not use this range when MetalLB is disabled. Do not enable MetalLB with the example range until it has been excluded from the router's DHCP pool and checked for address conflicts.

OpenTofu exposes an `ansible_inventory` output containing the actual machine names and addresses. Export it from the repository root:

```bash
tofu -chdir=opentofu/environments/kubeadm-multinode output -raw ansible_inventory \
  > ansible/inventories/hosts.yml
```

The generated file is ignored by Git because it belongs to a specific deployment.

The three VMs must be able to communicate with each other on the private network. The simplest Proxmox firewall policy is to allow all traffic between members of this cluster while limiting SSH and Kubernetes API access from other networks. When MetalLB is enabled, its speakers also communicate between nodes on TCP and UDP port 7946. The nodes need outbound HTTPS access to `pkgs.k8s.io`, `registry.k8s.io`, and GitHub's raw content host to download Kubernetes packages, images, and pinned resource manifests.

## 2. Install Ansible on the bastion host

Run Ansible from the Linux or WSL bastion that can reach the VM network:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r ansible/requirements.txt
```

If you are reinstalling cluster refresh authorized hosts:
```bash
ssh-keygen -R 192.168.10.61
ssh-keygen -R 192.168.10.62
ssh-keygen -R 192.168.10.63
```

Connect to each machine once to verify access and record its SSH host key. For the example addresses:

```bash
ssh -i ~/.ssh/opentofu_vm_access ubuntu@192.168.10.61 true
ssh -i ~/.ssh/opentofu_vm_access ubuntu@192.168.10.62 true
ssh -i ~/.ssh/opentofu_vm_access ubuntu@192.168.10.63 true
```

## 3. Check the inventory and connectivity

```bash
cd ansible
ansible-inventory --graph
ansible all -m ping --private-key ~/.ssh/opentofu_vm_access
```

The inventory must contain exactly one host in `control_plane` and the remaining hosts in `workers`.

## 4. Create the cluster

Create the base cluster without MetalLB:

```bash
ansible-playbook playbooks/cluster.yml --private-key ~/.ssh/opentofu_vm_access
```

To create or reconcile the cluster with MetalLB, enable the optional component for that run:

```bash
ansible-playbook playbooks/cluster.yml --private-key ~/.ssh/opentofu_vm_access \
  -e metallb_enabled=true
```

The default is `metallb_enabled: false` in `ansible/inventories/group_vars/all.yml`. You can change it there for persistent enablement, but the extra variable keeps the base configuration unchanged. Enabling MetalLB later is also supported: re-run the same playbook with `-e metallb_enabled=true`.

The playbook performs the following operations:

1. Waits for cloud-init and configures hostnames.
2. Disables swap and configures the required kernel modules and sysctls.
3. Installs containerd and enables its systemd cgroup driver.
4. Adds the versioned Kubernetes package repository and installs held kubelet, kubeadm, and kubectl packages.
5. Runs `kubeadm init` on the control-plane node.
6. Installs the pinned Calico manifest.
7. Creates a short-lived join token only if a worker has not joined yet.
8. Runs `kubeadm join` on new workers and waits for the nodes and CoreDNS to become ready.
9. When `metallb_enabled` is true, installs pinned MetalLB components and configures the reserved Layer 2 address pool.

Re-running the playbook reconciles host configuration and Calico, as well as MetalLB when it is enabled. It skips `kubeadm init` when `/etc/kubernetes/admin.conf` exists and skips workers that already have `/etc/kubernetes/kubelet.conf`.

Setting `metallb_enabled` back to false only skips MetalLB management; it does not uninstall an existing MetalLB deployment.

## 5. Use the cluster

The playbook copies the administrator kubeconfig to `ansible/artifacts/admin.conf`. From the `ansible` directory:

```bash
export KUBECONFIG="$PWD/artifacts/admin.conf"
kubectl get nodes -o wide
kubectl get pods --all-namespaces
# Only when MetalLB was enabled:
kubectl get pods --namespace metallb-system
```

The API address in this kubeconfig is a private VM address. The client therefore needs routing to the VM network.

The playbook intentionally does not install an Ingress controller, a default StorageClass, or a provider-specific CSI driver. Add those components after the base cluster is healthy according to the storage and service exposure required by the home-lab environment.

## Configuration and upgrades

Cluster settings are stored in `ansible/inventories/group_vars/all.yml`. The Pod CIDR (`10.244.0.0/16`) and Service CIDR (`10.96.0.0/12`) deliberately do not overlap the example VM network (`192.168.10.0/24`). The deployment-specific MetalLB pool comes from OpenTofu through the generated inventory and is used only when `metallb_enabled` is true.

Kubernetes packages are held after installation. Upgrading Kubernetes requires the normal kubeadm upgrade sequence and should not be done by merely changing `kubernetes_minor_version` and re-running this playbook.

The Calico and MetalLB versions are pinned. Review their release notes before changing `calico_version` or `metallb_version`.
