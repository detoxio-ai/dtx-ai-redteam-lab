# Requires: vagrant plugin install vagrant-disksize
unless Vagrant.has_plugin?("vagrant-disksize")
  raise "Please install the vagrant-disksize plugin:\n  vagrant plugin install vagrant-disksize"
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64" # Ubuntu 20.04, non-LVM
  config.disksize.size = "20GB"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus   = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    #!/usr/bin/env bash -eux

    echo "=== Disk BEFORE Resize ==="
    lsblk
    df -h /

    # Resize root partition to full 20GB
    apt-get update
    apt-get install -y cloud-guest-utils
    ROOT_PART=$(findmnt / -o SOURCE -n)
    DISK=$(lsblk -no pkname "$ROOT_PART")
    PART_NUM=$(echo "$ROOT_PART" | grep -o '[0-9]*$')
    growpart /dev/$DISK $PART_NUM
    resize2fs "$ROOT_PART"

    echo "=== Disk AFTER Resize ==="
    lsblk
    df -h /

    # Install Docker
    apt-get install -y \
      apt-transport-https ca-certificates curl gnupg lsb-release git
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant

    # Install ASDF for vagrant user
    su - vagrant -c '[ -d "$HOME/.asdf" ] || git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0'
    su - vagrant -c 'grep -qxF ". $HOME/.asdf/asdf.sh" ~/.bashrc || echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc'
    su - vagrant -c 'grep -qxF ". $HOME/.asdf/completions/asdf.bash" ~/.bashrc || echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc'

    # Install uv CLI
    su - vagrant -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    su - vagrant -c 'grep -qxF "source $HOME/.local/bin/env" ~/.bashrc || echo "source $HOME/.local/bin/env" >> ~/.bashrc'

    # Install Python 3.12 with uv
    su - vagrant -c 'bash -lc "source $HOME/.local/bin/env && uv python install 3.12"'

    # Install dtx[torch] with uv (under Python 3.12)
    su - vagrant -c 'bash -lc "source $HOME/.local/bin/env && uv tool install \\"dtx[torch]\\""'
  SHELL
end

