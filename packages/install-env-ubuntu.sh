#!/bin/bash

# 开始
set -e
set -x

# 安装nodeJs
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js is already installed."
fi

# 安装yarn
if ! command -v yarn &> /dev/null; then
    echo "Installing Yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update && sudo apt-get install yarn
    yarn config set registry https://registry.npm.taobao.org
else
    echo "Yarn is already installed."
fi

# 安装git
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt-get install -y git
    git config --global user.name "yehanlong"
    git config --global user.email "952292896@qq.com"
    ssh-keygen -t rsa -C "yehanlong"
else
    echo "Git is already installed."
fi

# 安装 Rust
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust via rustup..."
    echo '1' | sh -c "curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf"
    # . $HOME/.cargo/env
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Rust is already installed."
fi

# 安装 circom
if ! command -v circom &> /dev/null; then
    echo "Installing circom..."
    git clone https://github.com/iden3/circom.git
    cd circom
    cargo build --release
    cargo install --path circom
    cd ..
else
    echo "circom is already installed."
fi

# 安装 snarkjs
if ! command -v snarkjs &> /dev/null; then
    echo "Installing snarkjs..."
    npm install -g snarkjs
else
    echo "snarkjs is already installed."
fi

# 安装 ts-node
if ! command -v ts-node &> /dev/null; then
    echo "Installing ts-node..."
    npm install -g ts-node
else
    echo "ts-node is already installed."
fi

echo '=================================所有组件安装完成================================'

# 拉取 zk-email-test 项目
if [ ! -d "zk-email-test" ]; then
    echo "Cloning zk-email-test project..."
    git clone https://github.com/yehanlong/zk-email-test.git
    cd zk-email-test
    yarn install
    cd packages
    chmod +x *.sh
    cd ../..
else
    echo "zk-email-test project already exists."
fi

echo '=================================项目拉取完成================================'
