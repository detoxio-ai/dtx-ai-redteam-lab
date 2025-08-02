INSTANCE_COUNT ?= 1
PROJECT_DIR    ?= .
TFVARS         ?= terraform.tfvars
TF_VAR_SSH_KEY ?= $(shell cat id_ed25519.pub)
WORKSPACE      ?= dev

# === Terraform Commands ===
init:
	terraform -chdir=$(PROJECT_DIR) init

plan:
	terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	terraform -chdir=$(PROJECT_DIR) plan \
		-var="ssh_public_key=$(TF_VAR_SSH_KEY)" \
		-var="instance_count=$(INSTANCE_COUNT)" \
		-var-file=$(TFVARS)

apply:
	terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	terraform -chdir=$(PROJECT_DIR) apply -auto-approve \
		-var="ssh_public_key=$(TF_VAR_SSH_KEY)" \
		-var="instance_count=$(INSTANCE_COUNT)" \
		-var-file=$(TFVARS)

destroy:
	terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	terraform -chdir=$(PROJECT_DIR) destroy -auto-approve \
		-var="ssh_public_key=$(TF_VAR_SSH_KEY)" \
		-var="instance_count=$(INSTANCE_COUNT)" \
		-var-file=$(TFVARS)

validate:
	terraform -chdir=$(PROJECT_DIR) validate

format:
	terraform -chdir=$(PROJECT_DIR) fmt

# === Output helpers ===
public-ips:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[]'

internal-ips:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@terraform -chdir=$(PROJECT_DIR) output -json internal_ips | jq -r '.[]'

ssh-commands:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@terraform -chdir=$(PROJECT_DIR) output -json ssh_commands | jq -r '.[]'

# === SSH shortcuts ===
ssh:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@first_ip=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[0]'); \
	ssh -i id_ed25519 -o IdentitiesOnly=yes dtx@$$first_ip

# === RDP over SSH ===
rdp-over-ssh:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@first_ip=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[0]'); \
	echo "Forwarding local port 3390 to remote RDP port 3389..."; \
	echo "Then connect your RDP client to localhost:3390"; \
	ssh -i id_ed25519 -o IdentitiesOnly=yes -L 3390:localhost:3389 dtx@$$first_ip

ssh-all:
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@ips=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[]'); \
	for ip in $$ips; do \
		echo "Connecting to $$ip..."; \
		ssh -i id_ed25519 -o IdentitiesOnly=yes dtx@$$ip 'hostname && whoami'; \
	done

# === Port Forwarding ===
port-forward:
ifndef PORT
	$(error ❌ Please provide PORT. Usage: make port-forward PORT=8000)
endif
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE) >/dev/null || terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)
	@first_ip=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[0]'); \
	echo "🔁 Forwarding remote port $$first_ip:$(PORT) to localhost:$(PORT)..."; \
	ssh -i id_ed25519 -o IdentitiesOnly=yes -N -L $(PORT):localhost:$(PORT) dtx@$$first_ip


# === Terraform Workspace Management ===
workspace-list:
	@terraform -chdir=$(PROJECT_DIR) workspace list

workspace-show:
	@terraform -chdir=$(PROJECT_DIR) workspace show

workspace-create:
ifndef WORKSPACE
	$(error Please provide WORKSPACE name. Usage: make workspace-create WORKSPACE=uat)
endif
	@terraform -chdir=$(PROJECT_DIR) workspace new $(WORKSPACE)

workspace-select:
ifndef WORKSPACE
	$(error Please provide WORKSPACE name. Usage: make workspace-select WORKSPACE=uat)
endif
	@terraform -chdir=$(PROJECT_DIR) workspace select $(WORKSPACE)

workspace-delete:
ifndef WORKSPACE
	$(error Please provide WORKSPACE name. Usage: make workspace-delete WORKSPACE=uat)
endif
	@terraform -chdir=$(PROJECT_DIR) workspace select default
	@terraform -chdir=$(PROJECT_DIR) workspace delete $(WORKSPACE)


# === One-time auth ===
auth:
	gcloud auth application-default login

regen-key:
	./generate_ssh_key_and_update_tfvars.sh
