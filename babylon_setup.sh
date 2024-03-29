#!/bin/bash

echo "Starting the Babylon Node Auto-Installer..."

# Display ASCII "daniel00001"
cat << "EOF"
    __                __         __  ______  ______  ______  ______  ____   
.--|  |.---.-..-----.|__|.-----.|  ||      ||      ||      ||      ||_   |  
|  _  ||  _  ||     ||  ||  -__||  ||  --  ||  --  ||  --  ||  --  | _|  |_ 
|_____||___._||__|__||__||_____||__||______||______||______||______||______|
                                                                            
EOF

# Ask the user for their moniker name
read -p "Enter your moniker (node name): " MONIKER
if [[ -z "$MONIKER" ]]; then
    echo "No moniker name provided. Exiting..."
    exit 1
fi

# Update and upgrade the system packages
sudo apt update && sudo apt upgrade -y

# Install necessary build tools
sudo apt -qy install curl git jq lz4 build-essential

# Install Go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.12.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/gopath.sh
source /etc/profile.d/gopath.sh
echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile
source $HOME/.profile

# Confirm Go installation
if ! command -v go &> /dev/null; then
    echo "Go could not be installed correctly. Exiting..."
    exit 1
fi

echo "Go installed successfully. Proceeding with Babylon setup..."

# Clone and build the Babylon binaries
cd $HOME
rm -rf babylon
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.7.2
if ! make build; then
    echo "Failed to build Babylon. Exiting..."
    exit 1
fi

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.babylond/cosmovisor/genesis/bin
mv build/babylond $HOME/.babylond/cosmovisor/genesis/bin/

# Create application symlinks
sudo ln -s $HOME/.babylond/cosmovisor/genesis $HOME/.babylond/cosmovisor/current -f
sudo ln -s $HOME/.babylond/cosmovisor/current/bin/babylond /usr/local/bin/babylond -f

# Install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# Initialize the node
babylond config chain-id bbn-test-2
babylond config keyring-backend test
babylond config node tcp://localhost:16457
babylond init "$MONIKER" --chain-id bbn-test-2

# Download Genesis and Addrbook
echo "Downloading Genesis file..."
curl -Ls https://snapshots.kjnodes.com/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
echo "Downloading Addrbook file..."
curl -Ls https://snapshots.kjnodes.com/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

# Configure node settings
sed -i -e "s|^seeds =.*|seeds = \"3f472746f46493309650e5a033076689996c8881@babylon-testnet.rpc.kjnodes.com:16459\"|" $HOME/.babylond/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml
sed -i -e 's|^pruning *=.*|pruning = "custom"|' -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' -e 's|^pruning-interval *=.*|pruning-interval = "19"|' $HOME/.babylond/config/app.toml

# Create and start the Babylon service
sudo tee /etc/systemd/system/babylon.service > /dev/null << EOF
[Unit]
Description=babylon node service
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
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

sudo systemctl daemon-reload
sudo systemctl enable babylon.service
sudo systemctl start babylon.service

# Offer the user an option to check the node logs
while true; do
    read -p "Do you want to check the node logs? (yes/no): " yn
    case $yn in
        [Yy]* ) sudo journalctl -u babylon.service -f --no-hostname -o cat; break;;
        [Nn]* ) echo "Exiting log viewer."; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Babylon Node setup completed successfully."
