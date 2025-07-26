#!/bin/bash
set -e

TFVARS_FILE="terraform.tfvars"
ENV_FILE=".env"

# Ensure secrets_json block exists
if ! grep -q '^secrets_json *= *{' "$TFVARS_FILE"; then
  echo -e "\nsecrets_json = {\n}" >> "$TFVARS_FILE"
fi

# Track how many were added
new_count=0

# Read .env and append missing keys
while IFS='=' read -r key value; do
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)

  [[ -z "$key" || "$key" == \#* ]] && continue

  # Check for key (exact match inside secrets_json)
  if awk "/secrets_json *= *\\{/ {in_block=1} in_block && /^ *\\\"$key\\\"[[:space:]]*= / {found=1} /^}/ {in_block=0} END {exit !found}" "$TFVARS_FILE"; then
    continue  # key already exists
  fi

  # Insert above closing brace of secrets_json
  sed -i "/^ *} *$/i \  \"$key\" = \"$value\"" "$TFVARS_FILE"
  ((new_count++))

done < "$ENV_FILE"

echo "✅ Added $new_count new secret(s) to terraform.tfvars."

