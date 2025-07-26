#!/usr/bin/env bash
set -euxo pipefail

USER="${username}"

# Create user if not exists
if ! id -u "$USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USER"
fi

# Add to sudo group
usermod -aG sudo "$USER"

# Setup authorized key
mkdir -p /home/$USER/.ssh
echo "${ssh_public_key}" > /home/$USER/.ssh/authorized_keys
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh

# Add passwordless sudo privileges
echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
chmod 440 /etc/sudoers.d/90-$USER

# Harden SSH
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd



# === Base Packages ===
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git \
  sudo

# === Docker Installation ===
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/docker.gpg
gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg /tmp/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker "$USER"

# === Install ASDF ===
sudo -u $USER git clone https://github.com/asdf-vm/asdf.git "/home/$USER/.asdf" --branch v0.14.0
sudo -u $USER bash -c 'echo ". \$HOME/.asdf/asdf.sh" >> ~/.bashrc'
sudo -u $USER bash -c 'echo ". \$HOME/.asdf/completions/asdf.bash" >> ~/.bashrc'

# === Install uv ===
sudo -u $USER bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
sudo -u $USER bash -c 'echo "source \$HOME/.local/bin/env" >> ~/.bashrc'

# === Python via uv ===
sudo -u $USER bash -c 'bash -lc "source \$HOME/.local/bin/env && uv python install 3.12"'

# === Python Tools via uv ===
sudo -u $USER bash -c 'bash -lc "
  source \$HOME/.local/bin/env
  uv tool install \"dtx[torch]\"
  uv tool install \"garak\"
  uv tool install \"textattack[tensorflow]\"
  uv tool install \"huggingface_hub[cli,torch]\"
"'

# === Node.js via ASDF + promptfoo ===
sudo -u $USER bash -c 'bash -lc "
  . \$HOME/.asdf/asdf.sh
  asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
  bash \$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring
  asdf install nodejs lts
  asdf global nodejs lts
  npm install -g promptfoo
"'

# === Install Ollama ===
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable ollama
systemctl start ollama

# === Pull Ollama Models ===
ollama pull smollm2 || true
ollama pull qwen3:0.6b || true
ollama pull llama-guard3:1b-q3_K_S || true

# === Update PATH and .bashrc ===
cat >> ~/.bashrc <<'EOF'

# === User environment setup ===

# ASDF
export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"

# uv
export PATH="$HOME/.local/bin:$PATH"
source "$HOME/.local/bin/env" 2>/dev/null || true

# npm global bin (optional)
export PATH="$HOME/.npm-global/bin:$PATH"

# ollama (optional)
export PATH="$HOME/.ollama/bin:$PATH"

EOF

# === Write Generic Secrets ===
SECRETS_DIR="/home/$USER/.secrets"
mkdir -p "$SECRETS_DIR"

%{ for key, value in secrets_json ~}
cat <<EOF > "$SECRETS_DIR/${key}.txt"
${value}
EOF
%{ endfor ~}

chown -R $USER:$USER "/home/$USER/dtx"
chmod 700 "$SECRETS_DIR"
chmod 600 "$SECRETS_DIR"/*.txt


# === Run install scripts ===
if [ -f "/home/$USER/install-dtx-demo-lab.sh" ]; then
  chmod +x "/home/$USER/install-dtx-demo-lab.sh"
  sudo -u "$USER" bash "/home/$USER/install-dtx-demo-lab.sh" || true
fi

if [ -f "/home/$USER/install-pentagi.sh" ]; then
  chmod +x "/home/$USER/install-pentagi.sh"
  sudo -u "$USER" bash "/home/$USER/install-pentagi.sh" || true
fi
