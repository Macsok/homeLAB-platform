# OpenTofu and Proxmox VE Setup

> [!NOTE]
> This guide is about setting up single VM, other documentations exapand on this topis and extensions.

This guide explains how to prepare a bastion host and a Proxmox VE cluster, then use the OpenTofu configuration in this repository to provision an Ubuntu 24.04 VM.

The configuration is located in `opentofu/environments/kubeadm-dev`. This guide targets:

- OpenTofu 1.12.x
- `bpg/proxmox` provider 0.111.1
- Proxmox VE 9.x

The pinned provider offers limited support for Proxmox VE 8.x and does not support 7.x. Review the provider compatibility notes before using a different Proxmox release.

## Prerequisites

Before you begin, make sure that you have:

- A Debian- or Ubuntu-based bastion host with access to the Proxmox API
- Administrator access to Proxmox for the initial user, token, and storage setup
- The Proxmox API endpoint, node name, datastore names, and network bridge name
- An unused VM ID and static IPv4 address
- Internet access from the Proxmox node to `cloud-images.ubuntu.com`
- A local clone of this repository

## 1. Install OpenTofu on the bastion host

The current stable OpenTofu release series is 1.12.x. Install it from the official APT repository.

Install the required tools:

```bash
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg
```

Add the repository signing keys:

```bash
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://get.opentofu.org/opentofu.gpg \
  | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null

curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
  | sudo gpg --no-tty --batch --dearmor \
  -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null

sudo chmod a+r \
  /etc/apt/keyrings/opentofu.gpg \
  /etc/apt/keyrings/opentofu-repo.gpg
```

Add the OpenTofu package repository:

```bash
echo \
  "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" \
  | sudo tee /etc/apt/sources.list.d/opentofu.list >/dev/null

sudo chmod a+r /etc/apt/sources.list.d/opentofu.list
```

Install and verify OpenTofu:

```bash
sudo apt-get update
sudo apt-get install -y tofu
tofu version
```

The output should report OpenTofu 1.12.x. The exact patch version and platform may differ.

## 2. Understand the provider workflow

OpenTofu uses the `bpg/proxmox` provider to communicate with the Proxmox API:

```text
OpenTofu
  |
  +-- provider bpg/proxmox
             |
             +-- Proxmox API
```

Do not install the provider manually. `tofu init` downloads the version pinned in `versions.tf`, creates the local `.terraform` directory, and creates or updates `.terraform.lock.hcl`.

The `.terraform` directory must not be committed. Commit `.terraform.lock.hcl`; it records the selected provider version and trusted package checksums for repeatable installation.

## 3. Create a Proxmox user and API token

Use a dedicated API token instead of storing the `root@pam` password in the OpenTofu configuration.

### Create a role and user

The following role is a practical baseline for the resources currently defined in this repository. Run these commands in a shell on a Proxmox VE 9.x node:

```bash
pveum role add OpenTofuProvisioner -privs \
  "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.AccessNetwork Sys.Audit VM.Allocate VM.Audit VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.PowerMgmt"

pveum user add opentofu@pve --comment "OpenTofu automation"
pveum acl modify / -user opentofu@pve -role OpenTofuProvisioner
```

Assigning the role at `/` is convenient for a small homelab. For stricter isolation, split the ACLs across the relevant VM, storage, node, and SDN paths. Available privileges and API permission checks can differ between Proxmox releases, so verify the required permissions in the API viewer for the installed version.

The equivalent GUI locations are `Datacenter > Permissions > Roles` and `Datacenter > Permissions > Users`. Add the user permission at `/` with propagation enabled.

### Create the token

Create a token named `iac` with privilege separation enabled, then assign the same role to the token:

```bash
pveum user token add opentofu@pve iac -privsep 1
pveum acl modify / -token 'opentofu@pve!iac' -role OpenTofuProvisioner

pveum user permissions opentofu@pve
pveum user token permissions opentofu@pve iac
```

In the GUI, use `Datacenter > Permissions > API Tokens > Add` with these values:

```text
User: opentofu@pve
Token ID: iac
Privilege Separation: enabled
```

Then add an API token permission at `/`, select `OpenTofuProvisioner`, and enable propagation. With privilege separation enabled, the token's effective permissions are the intersection of its ACLs and the user's ACLs.

Proxmox displays the token secret only once. Store it in a password manager or secret manager. The provider expects the token in this format:

```text
<user>@<realm>!<token-id>=<token-secret>
```

For this guide, the complete value looks like this:

```text
opentofu@pve!iac=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Do not add the `PVEAPIToken=` HTTP authorization prefix to the environment variable value.

Never commit the token, a password, or a populated secrets file to Git.

## 4. Enable image imports in Proxmox

The configuration downloads the current Ubuntu 24.04 Noble cloud image directly to Proxmox by using its download URL API.

In the Proxmox GUI:

1. Open `Datacenter > Storage`.
2. Select the datastore configured as `image_datastore` (`local` by default).
3. Select **Edit**.
4. Enable the **Import** content type.
5. Save the change.

The image datastore must support file imports. Also confirm that `vm_datastore` accepts **Disk image** content.

The default storage layout used by this repository is:

| Purpose | Variable | Default value |
| --- | --- | --- |
| Downloaded cloud image | `image_datastore` | `local` |
| VM disk and cloud-init data | `vm_datastore` | `local-lvm` |

The resource uses the mutable `noble/current` image URL. The provider can detect an upstream size change and download the newer image during a later run. For fully reproducible builds, replace the URL with a dated release URL and configure its checksum.

The resource also sets `overwrite_unmanaged = true`. If a file named `noble-server-cloudimg-amd64.qcow2` already exists outside OpenTofu, it can be replaced. Confirm that the filename is not used by another workflow before applying the configuration.

## 5. Create the VM access key

Generate a dedicated SSH key on the bastion host. The following path matches `terraform.tfvars.example` and overrides the generic `~/.ssh/id_ed25519.pub` variable default:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/opentofu_vm_access \
  -C "homelab-opentofu"
```

Confirm that the public key exists:

```bash
cat ~/.ssh/opentofu_vm_access.pub
```

OpenTofu adds this public key to the `ubuntu` account in the new VM. It is not used to authenticate the provider to the Proxmox API.

## 6. Configure the environment

From the repository root, move to the root module:

```bash
cd opentofu/environments/kubeadm-dev
```

Create your local variable file from the tracked example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` is ignored by Git and must be created separately in each checkout. Review and replace every example value before creating a plan. The `example.com` hostname and `192.0.2.0/24` addresses are reserved documentation placeholders and will not work in your network.

| Variable | Description |
| --- | --- |
| `proxmox_endpoint` | Proxmox API base URL, for example `https://pve.example.com:8006/`; do not append `/api2/json` |
| `proxmox_insecure` | Set to `true` only when the API uses a self-signed certificate that the bastion host does not trust |
| `proxmox_node` | Exact Proxmox node name |
| `image_datastore` | Datastore with the **Import** content type enabled |
| `vm_datastore` | Datastore for the VM disk and cloud-init data |
| `network_bridge` | Existing bridge or SDN VNet connected to the target network |
| `vm_id` | Unused VM ID in the Proxmox cluster |
| `vm_name` | Name of the VM |
| `vm_ipv4_cidr` | Unused static IPv4 address in CIDR notation |
| `gateway_ipv4` | Gateway for the VM network |
| `ssh_public_key_path` | Path to the public key generated in the previous step |

Do not put the API token in `terraform.tfvars`. Export it for the current shell session instead:

```bash
export PROXMOX_VE_API_TOKEN='opentofu@pve!iac=REPLACE_WITH_TOKEN_SECRET'
```

Single quotes prevent Bash from interpreting the `!` character. For repeated or automated use, inject this environment variable from a secret manager.

## 7. Initialize, validate, and apply

Run all OpenTofu commands from `opentofu/environments/kubeadm-dev`.

Initialize the working directory:

```bash
tofu init
```

Validate the configuration:

```bash
tofu validate
```

Create and review a saved plan:

```bash
tofu plan -out=kubeadm-dev.tfplan
tofu show kubeadm-dev.tfplan
```

For a fresh environment, the plan should propose one downloaded image and one VM. Apply only the plan that you reviewed:

```bash
tofu apply kubeadm-dev.tfplan
```

Display the resulting connection details:

```bash
tofu output
tofu output -raw ssh_command
```

Use the displayed command to connect to the VM after cloud-init and networking are ready.

When you finish all OpenTofu operations for the current session, remove the token from the shell environment:

```bash
unset PROXMOX_VE_API_TOKEN
```

Export the token again before any later `plan`, `apply`, or `destroy` operation.

## 8. State and secret handling

This root module currently uses the local backend, so OpenTofu stores state in `terraform.tfstate` in the working directory. State and plan files can contain sensitive data.

- Do not commit `terraform.tfstate`, plan files, credentials, or API responses.
- Back up the state before changing the OpenTofu or provider version.
- Configure a remote backend with locking before multiple people or CI jobs manage the same environment.
- Do not run two applies against the same state at the same time.

The repository's `.gitignore` excludes local state, plan files, and `terraform.tfvars`, but this does not replace proper secret management.

## 9. Destroy the test environment

Create and review a destroy plan before removing the VM and downloaded image:

```bash
export PROXMOX_VE_API_TOKEN='opentofu@pve!iac=REPLACE_WITH_TOKEN_SECRET'
```

```bash
tofu plan -destroy -out=destroy.tfplan
tofu show destroy.tfplan
tofu apply destroy.tfplan
```

Destroying infrastructure is irreversible. Confirm that the plan targets only the resources managed by this root module.

Remove the token from the shell when the destroy operation finishes:

```bash
unset PROXMOX_VE_API_TOKEN
```

## Troubleshooting

### `401 Unauthorized` or `403 Permission check failed`

- Confirm that the token has the exact `user@realm!token-id=secret` format.
- Confirm that the user is enabled and its ACL applies to the required path.
- With privilege separation enabled, confirm that both the user and token have the required ACLs.
- Review the pinned provider's privilege documentation because available privileges differ between Proxmox VE versions.

### TLS certificate errors

For a temporary private-lab setup, set `proxmox_insecure = true`. The preferred fix is to trust the Proxmox certificate authority or install a certificate issued by a trusted CA, then set the value to `false`.

### Image import errors

- Confirm that **Import** is enabled on `image_datastore`.
- Confirm that the Proxmox node can reach `cloud-images.ubuntu.com` over HTTPS.
- On Proxmox VE 9.x, confirm that the API user and token have `Datastore.AllocateTemplate` on the image datastore and `Sys.Audit` plus `Sys.AccessNetwork` on the node.
- If the API reports that `Sys.Modify` is required, check the installed Proxmox API viewer before granting it because this is a broader privilege used by some older Proxmox/provider combinations.

### Node, datastore, bridge, or VM ID errors

Check the corresponding value in `terraform.tfvars`. Names must match Proxmox exactly, and the VM ID must be unused across the cluster.

### SSH connection errors

Confirm that the VM address is reachable from the bastion host, the configured bridge is attached to the correct network, and `ssh_public_key_path` points to the public key rather than the private key. The cloud image may also need a short time to complete cloud-init after the VM starts.

## References

- [OpenTofu 1.12 documentation](https://opentofu.org/docs/v1.12/)
- [Installing OpenTofu on Debian and Ubuntu](https://opentofu.org/docs/intro/install/deb/)
- [`tofu init` command](https://opentofu.org/docs/cli/commands/init/)
- [`bpg/proxmox` 0.111.1 provider documentation](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs)
- [`proxmox_download_file` permissions and behavior](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/download_file)
- [Proxmox VE user management](https://pve.proxmox.com/pve-docs/chapter-pveum.html)
- [Proxmox VE API viewer](https://pve.proxmox.com/pve-docs/api-viewer/)
