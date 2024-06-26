#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PARENT_DIR="$(dirname "$SCRIPT_DIR")"

OUTPUT_DIR="$PARENT_DIR/rapidsnark_test"

mkdir -p "$OUTPUT_DIR"

cd "$OUTPUT_DIR" || { echo "Failed to change directory to $OUTPUT_DIR"; exit 1; }

if ! command -v git &> /dev/null; then
    echo "Git not found. Installing git..."
    if [ -f /etc/redhat-release ]; then
        sudo yum install -y git
    elif [ -f /etc/lsb-release ]; then
        sudo apt-get install -y git
    elif [ "$(uname)" == "Darwin" ]; then
        brew install git
    else
        echo "Unsupported OS for automatic git installation. Please install git manually."
        exit 1
    fi

    git config --global user.name ""
    git config --global user.email ""
    ssh-keygen -t rsa -b 4096 -C ""
    echo "Add the following SSH key to your git settings:"
    cat ~/.ssh/id_rsa.pub
else
    echo "Git is already installed."
fi

install_dependencies() {
    if [ -f /etc/redhat-release ]; then
        echo "Installing dependencies for CentOS..."
        dependencies=("gcc" "gcc-c++" "cmake" "gmp-devel" "libsodium" "libsodium-devel" "nasm" "curl" "m4")
        for dep in "${dependencies[@]}"; do
            if ! rpm -q $dep &> /dev/null; then
                sudo yum install -y $dep
            else
                echo "$dep is already installed."
            fi
        done
    elif [ -f /etc/lsb-release ]; then
        echo "Installing dependencies for Ubuntu..."
        dependencies=("build-essential" "cmake" "libgmp-dev" "libsodium-dev" "nasm" "curl" "m4")
        for dep in "${dependencies[@]}"; do
            if ! dpkg -l | grep -q $dep; then
                sudo apt-get install -y $dep
            else
                echo "$dep is already installed."
            fi
        done
    elif [ "$(uname)" == "Darwin" ]; then
        echo "Installing dependencies for MacOS..."
        dependencies=("gcc" "cmake" "gmp" "libsodium" "nasm" "curl" "m4")
        for dep in "${dependencies[@]}"; do
            if ! brew list $dep &> /dev/null; then
                brew install $dep
            else
                echo "$dep is already installed."
            fi
        done
    else
        echo "Unsupported OS for automatic dependency installation. Please install dependencies manually."
        exit 1
    fi
}

install_dependencies

if [ ! -d "rapidsnark" ]; then
    git clone https://github.com/iden3/rapidsnark.git
    cd rapidsnark || { echo "Failed to change directory to rapidsnark"; exit 1; }
    git submodule init
    git submodule update
else
    echo "rapidsnark is already present."
    cd rapidsnark || { echo "Failed to change directory to rapidsnark"; exit 1; }
fi

ARCH=$(uname -m)
OS=$(uname)

case "$OS" in
    "Darwin")
        case "$ARCH" in
            "x86_64")
                ./build_gmp.sh host
                mkdir -p build_prover && cd build_prover
                cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
                make -j4 && make install
                ;;
            "arm64")
                ./build_gmp.sh macos_arm64
                mkdir -p build_prover_macos_arm64 && cd build_prover_macos_arm64
                cmake .. -DTARGET_PLATFORM=macos_arm64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
                make -j4 && make install
                ;;
            *)
                echo "Unsupported architecture for MacOS."
                exit 1
                ;;
        esac
        ;;
    "Linux")
        case "$ARCH" in
            "x86_64")
                ./build_gmp.sh host
                mkdir -p build_prover && cd build_prover
                cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
                make -j4 && make install
                ;;
            "arm64")
                ./build_gmp.sh host
                mkdir -p build_prover && cd build_prover
                cmake .. -DTARGET_PLATFORM=arm64_host -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
                make -j4 && make install
                ;;
            "aarch64")
                ./build_gmp.sh host
                mkdir -p build_prover && cd build_prover
                cmake .. -DTARGET_PLATFORM=aarch64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
                make -j4 && make install
                ;;
            *)
                echo "Unsupported architecture for Linux."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unsupported OS."
        exit 1
        ;;
esac

echo "rapidsnark installation completed."
