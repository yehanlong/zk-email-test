#!/bin/bash

cd ../../

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# install_rust() {
#         # Use expect to automate interactive selection
#         expect <<EOF
#             spawn curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
#             expect "1) Proceed with standard installation (default - just press enter)"
#             send -- "1\r"
#             expect eof
# EOF
# }

# Install expect if not already installed
# if ! command_exists expect; then
#     echo "Installing expect..."
#     sudo apt-get update
#     sudo apt-get install -y expect
# else
#     echo "expect is already installed."
# fi

# Install Rust via rustup if not already installed
if ! command_exists rustup; then
    echo "Installing Rust via rustup..."
    # export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
    source $HOME/.cargo/env
else
    echo "Rust is already installed."
fi

# Check if circom is already installed
if ! command_exists circom; then
    # Clone circom repository and build
    echo "Cloning and installing circom..."
    git clone https://github.com/iden3/circom.git
    cd circom
    cargo build --release
    # Install circom binary
    cargo install --path circom
    cd ..
else
    echo "circom is already installed."
fi

# Check if snarkjs is already installed
if ! command_exists snarkjs; then
    # Install snarkjs via npm
    echo "Installing snarkjs..."
    npm install -g snarkjs
else
    echo "snarkjs is already installed."
fi

# Check if ts-node is already installed
if ! command_exists ts-node; then
    # Install ts-node via npm
    echo "Installing ts-node..."
    npm install -g ts-node
else
    echo "ts-node is already installed."
fi

# Display circom help information
# echo "Checking circom installation..."
# circom --help