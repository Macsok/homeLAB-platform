# homeLAB Platform

Infrastructure-as-code experiments for a Proxmox-based home lab.

## Documentation

See [OpenTofu and Proxmox VE Setup](docs/OpenTofuSetup.md) for prerequisites, Proxmox preparation, configuration, deployment, troubleshooting, and cleanup instructions.

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

# Mock structure
homeLAB-platform/
├── README.md
├── Taskfile.yaml
├── Makefile
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
│
├── docs/
│   ├── architecture.md
│   ├── networking.md
│   ├── disaster-recovery.md
│   └── adr/
│
├── opentofu/
│   ├── modules/
│   │   ├── proxmox-vm/
│   │   ├── ubuntu-node/
│   │   └── talos-node/
│   │
│   └── environments/
│       ├── shared/
│       ├── kubeadm-dev/
│       ├── kubeadm-prod/
│       └── talos-dev/
│
├── ansible/
│   ├── inventories/
│   ├── group_vars/
│   ├── roles/
│   │   ├── common/
│   │   ├── users/
│   │   ├── ssh-hardening/
│   │   └── node-preparation/
│   └── playbooks/
│       ├── prepare-nodes.yml
│       └── validate-nodes.yml
│
├── kubespray/
│   ├── inventory/
│   └── patches/
│
├── talos/
│   ├── patches/
│   ├── schemas/
│   └── scripts/
│
├── packer/
│   └── ubuntu/
│
├── scripts/
│   ├── generate-ansible-inventory.py
│   ├── bootstrap-kubeadm.sh
│   ├── bootstrap-talos.sh
│   └── validate-cluster.sh
│
└── .github/
    └── workflows/
        ├── opentofu.yml
        ├── ansible.yml
        ├── talos.yml
        └── security.yml
