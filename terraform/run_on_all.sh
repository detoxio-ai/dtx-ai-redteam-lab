#!/bin/bash

# === Configuration ===
SSH_USER="dtx"                  # or ec2-user, dtx, etc.
SSH_KEY="./id_ed25519"        # path to your private SSH key
COMMAND="uptime"                   # command to run on each server
PROJECT_DIR="./"

# === Get list of public IPs from Terraform output ===
IP_LIST=$(terraform -chdir=$PROJECT_DIR -json public_ips | jq -r '.[]')

# === Iterate and run command ===
for ip in $IP_LIST; do
  echo "Running on $ip..."
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o IdentitiesOnly=yes "$SSH_USER@$ip" "$COMMAND"
done

