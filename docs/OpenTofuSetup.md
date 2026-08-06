# OpenTofu Installation and Proxmox Setup

This guide shows how to install OpenTofu on a bastion host and prepare Proxmox for infrastructure provisioning.

## 1. Install OpenTofu on the bastion host

At the time of writing, the stable OpenTofu line is 1.12. On Ubuntu, the recommended installation path is the official APT repository.

Run the following commands on the bastion host:

```bash
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg
```

Add the repository keys:

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

Add the APT repository:

```bash
echo \
  "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" \
  | sudo tee /etc/apt/sources.list.d/opentofu.list >/dev/null

sudo chmod a+r /etc/apt/sources.list.d/opentofu.list
```

Install OpenTofu:

```bash
sudo apt-get update
sudo apt-get install -y tofu
```

Verify the installation:

```bash
tofu version
```

You should see output similar to:

```text
OpenTofu v1.12.0
```

## 2. How OpenTofu talks to Proxmox

OpenTofu does not communicate with the Proxmox API directly. It uses a provider, for example `bpg/proxmox`:

```text
OpenTofu
  |
  +-- provider bpg/proxmox
             |
             +-- Proxmox API
```

The provider is downloaded automatically by:

```bash
tofu init
```

Do not install the provider manually. `tofu init` downloads providers and modules, creates the `.terraform` directory, and generates the dependency lock file.

Because the provider is in the `0.x` release line, pin it to a known working version in your configuration.

## 3. Create a Proxmox user and API token

Do not use the `root@pam` password directly in OpenTofu files. The recommended approach is to use an API token, especially for automation and CI/CD. A token can be revoked independently and limited with permissions.

### Initial setup

For the first iteration, create a dedicated user with broad permissions. Once provisioning works, reduce the role to the minimum required set.

In the Proxmox GUI, go to:

```text
Datacenter
└── Permissions
    └── Users
        └── Add
```

Create the user:

```text
User name: opentofu
Realm: Proxmox VE authentication server
```

The full username will be:

```text
opentofu@pve
```

Then assign a permission:

```text
Datacenter
└── Permissions
    └── Add
        └── User Permission
```

Start with:

```text
Path: /
User: opentofu@pve
Role: Administrator
Propagate: enabled
```

This is intentionally broad and is acceptable for a first test in a private homelab. Replace it with a custom role later.

Create an API token:

```text
Datacenter
└── Permissions
    └── API Tokens
        └── Add
```

Use these settings:

```text
User: opentofu@pve
Token ID: iac
Privilege Separation: disabled
```

Disabling privilege separation makes the token inherit the user's permissions.

Proxmox shows the token secret only once. Save the values in this format:

```text
Token ID:
opentofu@pve!iac

Secret:
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

The provider expects the combined token string:

```text
opentofu@pve!iac=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Do not store tokens or passwords directly in code or commit them to Git.

## 4. Prepare storage for cloud images

The OpenTofu workflow will download the official Ubuntu cloud image directly through the Proxmox API.

In the Proxmox GUI, open:

```text
Datacenter
└── Storage
    └── local
        └── Edit
```

In the Content field, enable:

```text
Import
```

Typical storage usage in this setup is:

```text
local
```

for the imported image, and:

```text
local-lvm
```

for the disk of the running VM.

The resource that imports the image requires the `Import` content type to be allowed on the target storage.

## 5. Prepare your bastion environment

Clone the repository and generate an SSH key if you do not already have one:

```bash
ssh-keygen -t ed25519 -C "homelab-opentofu"
```

You can accept the default location:

```text
~/.ssh/id_ed25519
```

Check the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Export the Proxmox API token for the current shell session:

```bash
export PROXMOX_VE_API_TOKEN='opentofu@pve!iac-opentofu=TU_WSTAW_SECRET'
```

If you prefer, store the token in a shell profile or secret manager instead of typing it manually each time.

## 6. Initialize your OpenTofu project

After the provider configuration and credentials are in place, run:

```bash
tofu init
```

Then validate the configuration with:

```bash
tofu plan
```

If the plan succeeds, you can proceed with VM and infrastructure definitions for Proxmox.