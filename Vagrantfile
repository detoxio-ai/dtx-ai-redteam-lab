# Requires: vagrant plugin install vagrant-disksize
unless Vagrant.has_plugin?("vagrant-disksize")
  raise "Please install the vagrant-disksize plugin:\n  vagrant plugin install vagrant-disksize"
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64" # Ubuntu 20.04, non-LVM
  config.disksize.size = "20GB"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 8048
    vb.cpus   = 6
  end

  config.vm.provision "shell", inline: <<-SHELL
    #!/usr/bin/env bash -eux

    echo "=== Disk BEFORE Resize ==="
    lsblk
    df -h /

    apt-get update
    apt-get install -y cloud-guest-utils

    ROOT_PART=$(findmnt / -o SOURCE -n)
    DISK=$(lsblk -no pkname "$ROOT_PART")
    PART_NUM=$(echo "$ROOT_PART" | grep -o '[0-9]*$')
    growpart /dev/$DISK $PART_NUM || true
    resize2fs "$ROOT_PART"

    echo "=== Disk AFTER Resize ==="
    lsblk
    df -h /

    # Install Docker
    apt-get install -y \
      apt-transport-https ca-certificates curl gnupg lsb-release git
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/docker.gpg
    gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg /tmp/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant

    # Install ASDF
    su - vagrant -c '[ -d "$HOME/.asdf" ] || git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0'
    su - vagrant -c 'grep -qxF ". $HOME/.asdf/asdf.sh" ~/.bashrc || echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc'
    su - vagrant -c 'grep -qxF ". $HOME/.asdf/completions/asdf.bash" ~/.bashrc || echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc'

    # Install uv
    su - vagrant -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    su - vagrant -c 'grep -qxF "source $HOME/.local/bin/env" ~/.bashrc || echo "source $HOME/.local/bin/env" >> ~/.bashrc'

    # Python 3.12 with uv
    su - vagrant -c 'bash -lc "source $HOME/.local/bin/env && uv python install 3.12"'

    # Install Python tools with uv
    su - vagrant -c 'bash -lc "
      source \$HOME/.local/bin/env
      uv tool install \\"dtx[torch]\\"
      uv tool install \\"garak\\"
      uv tool install \\"textattack[tensorflow]\\"
      uv tool install \\"huggingface_hub[cli,torch]\\"
    "'
    # Install Node.js via ASDF (with retry and npm validation)
    su - vagrant -c 'bash -lc "
      . \$HOME/.asdf/asdf.sh

      if ! asdf plugin-list | grep -q nodejs; then
        echo Installing nodejs plugin...
        asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
      fi

      # Wait and retry if script is missing
      sleep 1
      KEY_SCRIPT=\$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring
      if [ ! -f \$KEY_SCRIPT ]; then
        echo Retry: removing and re-adding nodejs plugin...
        asdf plugin-remove nodejs
        asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
      fi

      echo Importing Node.js release keys...
      bash \$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring

      echo Installing Node.js LTS...
      asdf install nodejs lts
      asdf global nodejs lts

      echo Checking npm...
      if ! command -v npm >/dev/null; then
        echo ERROR: npm not found after Node.js install.
        exit 1
      fi

      echo Installing promptfoo...
      npm install -g promptfoo

      # Install Ollama
      curl -fsSL https://ollama.com/install.sh | sh

      # Add Ollama to PATH for the current session
      export PATH="$HOME/.ollama/bin:$PATH"

      # Start Ollama (it runs as a background daemon)
      systemctl enable ollama
      systemctl start ollama

      # Pull required models
      ollama pull smollm2 || true
      ollama pull qwen3:0.6b || true
      ollama pull llama-guard3:1b-q3_K_S || true

    "'

  SHELL
end

