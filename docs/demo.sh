#!/bin/bash

# Function to clean up demo files
cleanup() {
    cd - > /dev/null
    rm -rf "$DEMO_DIR"
    rm -f demo*.tar.gz demo*.tar.bz2 demo*.tar.xz demo*.7z demo*.zip
}

# Ensure cleanup happens even on script exit
trap cleanup EXIT

# Create a temporary directory for our demo
DEMO_DIR=$(mktemp -d)
cd "$DEMO_DIR"

# Create some sample files and directories
mkdir -p project/{src,tests,docs}
echo "Sample source code" > project/src/main.py
echo "Test code" > project/tests/test.py
echo "Documentation" > project/docs/README.md

# Set up a clean environment
export PS1="user@demo \$ "
export HOME="/home/user"

# Function to run a command and wait for user input
run_cmd() {
    echo -e "\n$ $1"
    eval "$1"
    echo -e "\nPress Enter to continue..."
    read
}

# Clear screen and start demo
clear
echo "Welcome to fancy-tar demo!"
echo "Press Enter to begin..."
read

# Basic archive creation
run_cmd "fancy-tar project/ -o demo.tar.gz"

# Tree view
run_cmd "fancy-tar project/ --tree -o demo2.tar.gz"

# Hash verification
run_cmd "fancy-tar project/ --hash -o demo3.tar.gz"

# GPG encryption
run_cmd "fancy-tar project/ --encrypt=gpg -o demo4.tar.gz"

# Clean up
cleanup 