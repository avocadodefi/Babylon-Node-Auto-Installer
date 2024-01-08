#!/bin/bash

# Display cool ASCII art header for "daniel00001"
cat << "EOF"
  .'|=|`.     .'|=|`.     .'| |   |   .'|   .'|=|_.'   .'|Discord .'|=|`.     .'|=|`.     .'|=|`.     .'|=|`.   `._    | 
.'  | |  `. .'  | |  `. .'  |\|   | .'  | .'  |  ___ .'  |      .'  | |  `. .'  | |  `. .'  | |  `. .'  | |  `.    |   | 
|   | |   | |   |=|   | |   | |   | |   | |   |=|_.' |   |      |   |/|   | |   |/|   | |   |/|   | |   |/|   |    |   | 
|   | |  .' |   | |   | |   | |  .' |   | |   |  ___ |   |  ___ `.  | |  .' `.  | |  .' `.  | |  .' `.  | |  .'    |   | 
|___|=|.'   |___| |___| |___| |.'   |___| |___|=|_.' |___|=|_.'   `.|=|.'     `.|=|.'     `.|=|.'     `.|=|.'      |___| 
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
sudo apt update && sudo apt upgrade -y

# Install necessary build tools
sudo apt -qy install curl git jq lz4 build-essential

# Install Go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.12.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' | sudo tee -a /etc/profile.d/gopath.sh

# Inform user about manual action required after the script
echo "Please run 'source /etc/profile.d/gopath.sh' or log out and log back in to apply the PATH update."

# Clone and build the Babylon binaries
cd $HOME
rm -rf babylon
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.7.2

# Build the binaries (to be executed after re-login or sourcing the profile)
echo "After ensuring the PATH is updated, run the following commands manually:"
echo "cd $HOME/babylon && make build"

# Prepare binaries for Cosmovisor (to be moved after building binaries)
echo "Create the directory $HOME/.babylond/cosmovisor/genesis/bin and move the 'babylond' binary there after building it."

# Create application symlinks (to be executed after binaries are moved)
echo "After moving the binaries, run:"
echo "sudo ln -s $HOME/.babylond/cosmovisor/genesis $HOME/.babylond/cosmovisor/current -f"
echo "sudo ln -s $HOME/.babylond/cosmovisor/current/bin/babylond /usr/local/bin/babylond -f"

# Install Cosmovisor
echo "Install Cosmovisor by running 'go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest' after the PATH is updated."

# Create and start the Babylon service
echo "After completing the above steps, create the Babylon service file at /etc/systemd/system/babylon.service and start the service."
