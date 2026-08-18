# Kubernetes with kubeadm and Ansible

This repository provisions three Ubuntu 24.04 virtual machines with OpenTofu and then bootstraps a Kubernetes cluster with Ansible:

- one control-plane and stacked etcd node,
- two worker nodes,
- containerd as the container runtime,
- Calico as the CNI plugin.

This is a development and home-lab topology. The Kubernetes API and etcd are unavailable while the single control-plane node is down.

## 1. Provision the virtual machines

Follow [OpenTofuMultiNode.md](OpenTofuMultiNode.md) and apply the `kubeadm-multinode` environment.

OpenTofu exposes an `ansible_inventory` output containing the actual machine names and addresses. Export it from the repository root:

```bash
tofu -chdir=opentofu/environments/kubeadm-multinode output -raw ansible_inventory \
  > ansible/inventories/hosts.yml
```

The generated file is ignored by Git because it belongs to a specific deployment.

The three VMs must be able to communicate with each other on the private network. The simplest Proxmox firewall policy is to allow all traffic between members of this cluster while limiting SSH and Kubernetes API access from other networks. The nodes also need outbound HTTPS access to `pkgs.k8s.io`, `registry.k8s.io`, and GitHub's raw content host to download Kubernetes packages, images, and the pinned Calico manifest.

## 2. Install Ansible on the bastion host

Run Ansible from the Linux or WSL bastion that can reach the VM network:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r ansible/requirements.txt
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

```bash
ansible-playbook playbooks/cluster.yml \
  --private-key ~/.ssh/opentofu_vm_access
```

The playbook performs the following operations:

1. Waits for cloud-init and configures hostnames.
2. Disables swap and configures the required kernel modules and sysctls.
3. Installs containerd and enables its systemd cgroup driver.
4. Adds the versioned Kubernetes package repository and installs held kubelet, kubeadm, and kubectl packages.
5. Runs `kubeadm init` on the control-plane node.
6. Installs the pinned Calico manifest.
7. Creates a short-lived join token only if a worker has not joined yet.
8. Runs `kubeadm join` on new workers and waits for the nodes and CoreDNS to become ready.

Re-running the playbook reconciles host configuration and Calico. It skips `kubeadm init` when `/etc/kubernetes/admin.conf` exists and skips workers that already have `/etc/kubernetes/kubelet.conf`.

## 5. Use the cluster

The playbook copies the administrator kubeconfig to `ansible/artifacts/admin.conf`. From the `ansible` directory:

```bash
export KUBECONFIG="$PWD/artifacts/admin.conf"
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

The API address in this kubeconfig is a private VM address. The client therefore needs routing to the VM network.

The playbook intentionally does not install an Ingress controller, a default StorageClass, MetalLB, or a provider-specific CSI driver. Add those components after the base cluster is healthy according to the storage and service exposure required by the home-lab environment.

## Configuration and upgrades

Cluster settings are stored in `ansible/inventories/group_vars/all.yml`. The Pod CIDR (`10.244.0.0/16`) and Service CIDR (`10.96.0.0/12`) deliberately do not overlap the example VM network (`192.168.10.0/24`).

Kubernetes packages are held after installation. Upgrading Kubernetes requires the normal kubeadm upgrade sequence and should not be done by merely changing `kubernetes_minor_version` and re-running this playbook.

The Calico version is pinned. Review its release notes before changing `calico_version`.
