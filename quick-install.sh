#!/bin/bash

# fancy-tar Quick Installer
# Run this script to install fancy-tar with minimal user interaction

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "debian"
        elif command -v dnf >/dev/null 2>&1; then
            echo "fedora"
        elif command -v yum >/dev/null 2>&1; then
            echo "rhel"
        elif command -v pacman >/dev/null 2>&1; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install minimal dependencies
install_minimal_deps() {
    local os="$1"
    
    # Only install absolutely essential dependencies
    local missing_deps=()
    
    if ! command_exists tar; then
        missing_deps+=("tar")
    fi
    
    if ! command_exists pv; then
        missing_deps+=("pv")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "Essential dependencies are available"
        return 0
    fi
    
    print_warning "Installing essential dependencies: ${missing_deps[*]}"
    
    case "$os" in
        "debian")
            sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
            ;;
        "fedora")
            sudo dnf install -y "${missing_deps[@]}"
            ;;
        "rhel")
            sudo yum install -y "${missing_deps[@]}"
            ;;
        "arch")
            sudo pacman -S --noconfirm "${missing_deps[@]}"
            ;;
        "macos")
            if command_exists brew; then
                brew install "${missing_deps[@]}"
            else
                print_warning "Homebrew not found. Some features may not work optimally."
                print_warning "To install missing dependencies manually:"
                print_warning "  - Install Homebrew: https://brew.sh"
                print_warning "  - Then run: brew install ${missing_deps[*]}"
                print_warning "  - Or install Xcode Command Line Tools and use Homebrew"
                print_warning ""
                print_warning "Continuing with basic installation (some features may be limited)..."
                return 0  # Continue without the dependencies
            fi
            ;;
        *)
            print_warning "Please install manually: ${missing_deps[*]}"
            return 1
            ;;
    esac
}

# Function to install fancy-tar to user directory
install_to_user() {
    local USER_BIN="$HOME/.local/bin"
    local USER_MAN="$HOME/.local/share/man/man1"
    
    # Create directories
    mkdir -p "$USER_BIN" "$USER_MAN"
    
    # Install main script
    print_status "Installing fancy-tar to $USER_BIN"
    install -Dm755 scripts/fancy_tar_progress.sh "$USER_BIN/fancy-tar"
    
    # Create aliases
    ln -sf "$USER_BIN/fancy-tar" "$USER_BIN/fancytar"
    ln -sf "$USER_BIN/fancy-tar" "$USER_BIN/ftar"
    
    # Install man page
    cp docs/fancy-tar.1 "$USER_MAN/"
    gzip -f "$USER_MAN/fancy-tar.1"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
        print_warning "Adding $USER_BIN to PATH..."
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.zshrc"
        print_success "PATH updated. Please restart your terminal or run: source ~/.bashrc"
    fi
}

# Main installation
main() {
    echo "🎯 fancy-tar Quick Installer"
    echo "============================"
    echo
    
    # Detect OS
    local os=$(detect_os)
    print_status "Detected OS: $os"
    
    # Install minimal dependencies
    install_minimal_deps "$os"
    
    # Install to user directory (no sudo required)
    install_to_user
    
    echo
    print_success "fancy-tar installed successfully!"
    echo
    echo "💡 Try: fancy-tar -h"
    echo "💡 You can also use: fancytar or ftar"
    echo
    echo "📚 Documentation: https://github.com/jgiambona/fancy-tar"
}

# Run main function
main "$@" 