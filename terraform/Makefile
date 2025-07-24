INSTANCE_COUNT ?= 1
PROJECT_DIR    ?= .
TFVARS         ?= terraform.tfvars
TF_VAR_SSH_KEY ?= $(shell cat id_ed25519.pub)

# === Terraform Commands ===
init:
	terraform -chdir=$(PROJECT_DIR) init

plan:
	terraform -chdir=$(PROJECT_DIR) plan \
		-var="ssh_public_key=$(TF_VAR_SSH_KEY)" \
		-var="instance_count=$(INSTANCE_COUNT)" \
		-var-file=$(TFVARS)

apply:
	terraform -chdir=$(PROJECT_DIR) apply -auto-approve \
		-var="ssh_public_key=$(TF_VAR_SSH_KEY)" \
		-var="instance_count=$(INSTANCE_COUNT)" \
		-var-file=$(TFVARS)

destroy:
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
	@terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[]'

internal-ips:
	@terraform -chdir=$(PROJECT_DIR) output -json internal_ips | jq -r '.[]'

ssh-commands:
	@terraform -chdir=$(PROJECT_DIR) output -json ssh_commands | jq -r '.[]'

# === SSH shortcuts ===
ssh:
	@first_ip=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[0]'); \
	ssh -i id_ed25519 -o IdentitiesOnly=yes dtx@$$first_ip

ssh-all:
	@ips=$$(terraform -chdir=$(PROJECT_DIR) output -json public_ips | jq -r '.[]'); \
	for ip in $$ips; do \
		echo "Connecting to $$ip..."; \
		ssh -i id_ed25519 -o IdentitiesOnly=yes dtx@$$ip 'hostname && whoami'; \
	done

# === One-time auth ===
auth:
	gcloud auth application-default login

regen-key:
	./generate_ssh_key_and_update_tfvars.sh

