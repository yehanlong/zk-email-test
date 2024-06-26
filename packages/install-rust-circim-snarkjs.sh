#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_rust() {
        # Use expect to automate interactive selection
        expect <<EOF
            spawn curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
            expect "1) Proceed with standard installation (default - just press enter)"
            send -- "1\r"
            expect eof
EOF
}

# Install Rust via rustup if not already installed
if ! command_exists rustup; then
    echo "Installing Rust via rustup..."
    # export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    install_rust
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

# Display circom help information
# echo "Checking circom installation..."
# circom --help