#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
}

echo -e "${GREEN}Starting Docker and Docker Compose installation...${NC}"

# Detect OS and architecture
OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
OS_VERSION_ID=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)
USER_NAME=$(whoami)

echo "Detected OS: $OS_ID $OS_VERSION_ID, Architecture: $ARCH, User: $USER_NAME"

sleep 1

install_docker() {
    echo -e "${GREEN}Installing Docker...${NC}"

    case "$OS_ID" in
        ubuntu|debian|raspbian)
            ( 
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release

                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$OS_ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg

                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_ID \
                  $(lsb_release -cs) stable" | \
                  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ) & spinner
            ;;
        centos|rhel)
            (
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl enable --now docker
            ) & spinner
            ;;
        fedora)
            (
                sudo dnf install -y dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl enable --now docker
            ) & spinner
            ;;
        arch)
            (
                sudo pacman -Sy --noconfirm docker
                sudo systemctl enable --now docker
            ) & spinner
            ;;
        *)
            echo "Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    sudo usermod -aG docker "$USER_NAME" || true

    echo -e "\n${GREEN}Docker installed successfully!${NC}"
    echo "You may need to log out and log back in for group changes to take effect."
}

install_docker_compose() {
    echo -e "${GREEN}Installing Docker Compose...${NC}"

    (
        COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

        if [[ -z "$COMPOSE_LATEST" ]]; then
            echo "Failed to fetch latest Docker Compose version."
            exit 1
        fi

        DESTINATION=/usr/local/bin/docker-compose

        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o "$DESTINATION"
        sudo chmod +x "$DESTINATION"
    ) & spinner

    echo -e "\n${GREEN}Docker Compose installed successfully!${NC}"
}

# Main
install_docker
install_docker_compose

echo -e "${GREEN}Installation complete!${NC}"
echo "Please log out and log back in to apply Docker group membership."
