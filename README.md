# homeLAB Platform

Infrastructure-as-code experiments for a Proxmox-based home lab.

## Documentation

See [OpenTofu and Proxmox VE Setup](docs/OpenTofuSetup.md) for prerequisites, Proxmox preparation, configuration, deployment, troubleshooting, and cleanup instructions.

For the three-node Kubernetes environment, see [OpenTofu Multi-Node](docs/OpenTofuMultiNode.md) followed by [Kubernetes with kubeadm and Ansible](docs/KubeadmAnsible.md).

## Kubernetes automation structure

```text
## AI-assisted pull request feedback

Authorized repository collaborators can comment on a pull request with:

- `@claude review` to request actionable review findings.
- `@claude suggest` to request exact code suggestions and a proposed commit plan.

Add text after either trigger to narrow the scope, for example:
`@claude suggest focus on OpenTofu lifecycle safety`.

Both modes are read-only. They can post inline comments and top-level feedback,
but cannot edit files, create commits, push, approve, or merge. Shared agent
behavior is defined in [AGENTS.md](AGENTS.md); Claude Code loads it through
[CLAUDE.md](CLAUDE.md).

## Kubernetes automation structure

```text
homeLAB-platform/
├── opentofu/environments/
│   ├── kubeadm-template/       # Ubuntu 24.04 Proxmox template
│   └── kubeadm-multinode/      # control-plane and worker VMs
├── ansible/
│   ├── inventories/            # generated inventory and cluster variables
│   ├── roles/
│   │   ├── kubernetes_node/       # OS, containerd, kubelet and kubeadm
│   │   ├── control_plane/         # kubeadm init and kubeconfig
│   │   └── kubernetes_resources/  # Calico and MetalLB bootstrap resources
│   └── playbooks/cluster.yml   # cluster orchestration and worker joins
└── docs/
    ├── OpenTofuMultiNode.md
    └── KubeadmAnsible.md
```
