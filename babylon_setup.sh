#!/bin/bash

# Display cool ASCII art header for "daniel00001"
cat << "EOF"
  [Your ASCII Art Here]
EOF

# Ask the user for their moniker name
read -p "Enter your moniker name: " MONIKER

# Check if MONIKER was provided
if [[ -z "$MONIKER" ]]; then
    echo "No moniker name provided. Exiting..."
    exit 1
fi

echo "Setting up your Babylon node with moniker $MONIKER..."

# Update and upgrade the system packages
sudo apt clean
sudo apt update && sudo apt upgrade -y

# Install necessary build tools
sudo apt -qy install curl git jq lz4 build-essential

# Install Go and update PATH
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.12.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/gopath.sh
source /etc/profile.d/gopath.sh
export PATH=$PATH:/usr/local/go/bin

# Check if Go is correctly installed
if ! command -v go &> /dev/null; then
    echo "Go could not be installed correctly. Exiting..."
    exit 1
fi

# Clone and build the Babylon binaries
cd $HOME
rm -rf babylon
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.7.2

# Build the binaries and check if build was successful
if ! make build; then
    echo "Failed to build Babylon. Exiting..."
    exit 1
fi

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.babylond/cosmovisor/genesis/bin
mv build/babylond $HOME/.babylond/cosmovisor/genesis/bin/
if [ ! -f "$HOME/.babylond/cosmovisor/genesis/bin/babylond" ]; then
    echo "Babylon binary not found. Exiting..."
    exit 1
fi

# Create application symlinks
sudo ln -s $HOME/.babylond/cosmovisor/genesis $HOME/.babylond/cosmovisor/current -f
sudo ln -s $HOME/.babylond/cosmovisor/current/bin/babylond /usr/local/bin/babylond -f

# Install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# Check if Cosmovisor is installed
if ! command -v cosmovisor &> /dev/null; then
    echo "Cosmovisor could not be installed correctly. Exiting..."
    exit 1
fi

# Create and start the Babylon service
sudo tee /etc/systemd/system/babylon.service > /dev/null << EOF
[Unit]
Description=babylon node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.babylond"
Environment="DAEMON_NAME=babylond"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.babylond/cosmovisor/current/bin"
[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable babylon.service

echo "Babylon Node setup completed successfully."
