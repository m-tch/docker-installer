#!/bin/bash

# Detect OS
OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')

echo "Detected OS: $OS"
sleep 1

install_docker() {
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | bash
    sudo usermod -aG docker $USER
    echo "Docker installed successfully!"
}

install_docker_compose() {
    echo "Installing Docker Compose..."
    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep $(uname -s)-$(uname -m) | cut -d '"' -f 4)
    sudo curl -L "$LATEST_COMPOSE" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully!"
}

case "$OS" in
    ubuntu|debian)
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg lsb-release
        install_docker
        install_docker_compose
        ;;
    centos|rhel)
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl enable --now docker
        install_docker_compose
        ;;
    fedora)
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl enable --now docker
        install_docker_compose
        ;;
    arch)
        sudo pacman -Sy --noconfirm docker docker-compose
        sudo systemctl enable --now docker
        ;;
    opensuse*)
        sudo zypper install -y docker docker-compose
        sudo systemctl enable --now docker
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Installation complete. You may need to restart your session for Docker group changes to apply."
