#!/bin/bash

# Detect OS
OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)
USER_NAME=$(whoami)

echo "Detected OS: $OS, Architecture: $ARCH, User: $USER_NAME"
sleep 1

install_docker() {
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | bash
    sudo usermod -aG docker "$USER_NAME"
    echo "Docker installed successfully!"
    echo "You may need to log out and log back in for group changes to take effect."
}

install_docker_compose() {
    echo "Installing Docker Compose..."
    
    # Determine appropriate Docker Compose binary
    if [[ "$ARCH" == "x86_64" ]]; then
        COMPOSE_URL=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep $(uname -s)-$(uname -m) | cut -d '"' -f 4)
    elif [[ "$ARCH" == "armv7l" ]]; then
        COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-armv7"
    elif [[ "$ARCH" == "aarch64" ]]; then
        COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64"
    else
        echo "Unsupported architecture for Docker Compose."
        exit 1
    fi

    sudo curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully!"
}

case "$OS" in
    ubuntu|debian|raspbian)
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
        sudo usermod -aG docker "$USER_NAME"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Installation complete. Log out and log back in for Docker group changes to take effect."
