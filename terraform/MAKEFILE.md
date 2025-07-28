# 🚀 Terraform Environment & Workspace Management Tutorial

This tutorial walks you through managing multiple isolated environments (like `dev` and `uat`) using **Terraform Workspaces** and a **Makefile** to automate tasks.

---

## 🏗️ 1. Setup Workspace

Terraform workspaces allow you to reuse the same Terraform configuration across different environments by maintaining **separate state files**.

### ✅ Default Workspace

If not specified, the default workspace used is:

```makefile
WORKSPACE ?= dev
```

This means all Terraform commands will operate in the `dev` workspace unless overridden.

---

## 🧠 2. `terraform workspace` Commands via Makefile

### 🔧 List Workspaces

```bash
make workspace-list
```

### 🔁 Show Current Workspace

```bash
make workspace-show
```

### 🆕 Create a New Workspace

```bash
make workspace-create WORKSPACE=uat
```

### 🔀 Switch to an Existing Workspace

```bash
make workspace-select WORKSPACE=uat
```

### ❌ Delete a Workspace (must not be active)

```bash
make workspace-delete WORKSPACE=uat
```

---

## ✏️ 3. Update Variables

Variables like instance count, SSH key, and tfvars file can be overridden at runtime.

### 📦 Default Values

```makefile
INSTANCE_COUNT ?= 1
TFVARS         ?= terraform.tfvars
TF_VAR_SSH_KEY ?= $(shell cat id_ed25519.pub)
PROJECT_DIR    ?= .
WORKSPACE      ?= dev
```

### 🔧 Override Example

```bash
make apply INSTANCE_COUNT=2 TFVARS=uat.tfvars WORKSPACE=uat
```

---

## 🌍 4. Manage an Environment

### 🔐 Authenticate with GCP

```bash
make auth
```

Runs:

```bash
gcloud auth application-default login
```

---

### 🔄 Select or Auto-Create Workspace (during plan/apply/destroy)

All core Terraform operations automatically select or create the correct workspace before execution.

---

### 🧪 Plan Infrastructure

```bash
make plan
```

Executes:

```bash
terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)
terraform plan ...
```

---

### 🚀 Apply Infrastructure

```bash
make apply
```

Executes:

```bash
terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)
terraform apply -auto-approve ...
```

---

### 💥 Destroy Infrastructure

```bash
make destroy
```

Executes:

```bash
terraform destroy -auto-approve ...
```

---

## 🔙 5. Revert to Default Workspace

To go back to the base/default state:

```bash
make workspace-select WORKSPACE=default
```

---

## 🧰 6. Miscellaneous Helpers

### 📤 Output Commands

```bash
make public-ips
make internal-ips
make ssh-commands
```

Each selects the correct workspace and runs `terraform output`.

---

### 🖥️ SSH Shortcuts

#### SSH into the first instance:

```bash
make ssh
```

#### SSH into all instances:

```bash
make ssh-all
```

---

## 🔁 7. Regenerate SSH Keys

To regenerate the SSH key and update your `.tfvars`:

```bash
make regen-key
```

Runs:

```bash
./generate_ssh_key_and_update_tfvars.sh
```

---

## 📄 Makefile Summary

### Terraform Commands

| Task     | Command         |
| -------- | --------------- |
| Init     | `make init`     |
| Plan     | `make plan`     |
| Apply    | `make apply`    |
| Destroy  | `make destroy`  |
| Validate | `make validate` |
| Format   | `make format`   |

---

### Workspace Commands

| Task         | Command                               |
| ------------ | ------------------------------------- |
| List         | `make workspace-list`                 |
| Show Current | `make workspace-show`                 |
| Create       | `make workspace-create WORKSPACE=uat` |
| Select       | `make workspace-select WORKSPACE=uat` |
| Delete       | `make workspace-delete WORKSPACE=uat` |

---

### SSH and Output

| Task         | Command             |
| ------------ | ------------------- |
| SSH to first | `make ssh`          |
| SSH to all   | `make ssh-all`      |
| Public IPs   | `make public-ips`   |
| Internal IPs | `make internal-ips` |
| SSH Commands | `make ssh-commands` |

---

## ✅ Best Practices

* Always include `terraform.workspace` in resource names to avoid conflicts.
* Isolate state using workspaces, not directories, unless you require separate backends.
* Use `locals` like this for naming:

  ```hcl
  locals {
    workspace_suffix = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  }
  ```


