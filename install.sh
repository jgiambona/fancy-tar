#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to install dependencies based on OS
install_dependencies() {
    local os="$1"
    local missing_deps=()
    
    print_status "Checking dependencies..."
    
    # Core dependencies (required)
    if ! command_exists tar; then
        missing_deps+=("tar")
    fi
    
    if ! command_exists pv; then
        missing_deps+=("pv")
    fi
    
    # Optional but recommended dependencies
    if ! command_exists gzip; then
        missing_deps+=("gzip")
    fi
    
    if ! command_exists zip; then
        missing_deps+=("zip")
    fi
    
    if ! command_exists 7z; then
        missing_deps+=("p7zip")
    fi
    
    if ! command_exists gpg; then
        missing_deps+=("gnupg")
    fi
    
    if ! command_exists openssl; then
        missing_deps+=("openssl")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All dependencies are already installed!"
        return 0
    fi
    
    print_warning "Missing dependencies: ${missing_deps[*]}"
    echo
    echo "Would you like to install missing dependencies automatically? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_warning "Skipping dependency installation. Some features may not work."
        return 0
    fi
    
    case "$os" in
        "debian")
            print_status "Installing dependencies using apt..."
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
            ;;
        "fedora")
            print_status "Installing dependencies using dnf..."
            sudo dnf install -y "${missing_deps[@]}"
            ;;
        "rhel")
            print_status "Installing dependencies using yum..."
            sudo yum install -y "${missing_deps[@]}"
            ;;
        "arch")
            print_status "Installing dependencies using pacman..."
            sudo pacman -S --noconfirm "${missing_deps[@]}"
            ;;
        "macos")
            install_macos_dependencies "${missing_deps[@]}"
            ;;
        *)
            print_error "Automatic dependency installation not supported for this OS."
            print_warning "Please install the following manually: ${missing_deps[*]}"
            return 1
            ;;
    esac
    
    print_success "Dependencies installed successfully!"
}

# Function to install dependencies on macOS
install_macos_dependencies() {
    local missing_deps=("$@")
    
    # Check if Homebrew is available
    if command_exists brew; then
        print_status "Installing dependencies using Homebrew..."
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
}

# Function to install fancy-tar
install_fancy_tar() {
    local install_method="$1"
    
    case "$install_method" in
        "homebrew")
            print_status "Installing via Homebrew..."
            brew install jgiambona/fancy-tar/fancy-tar
            ;;
        "system")
            print_status "Installing to system directories..."
            install_to_system
            ;;
        "user")
            print_status "Installing to user directory..."
            install_to_user
            ;;
        "local")
            print_status "Installing to current directory..."
            install_to_local
            ;;
        *)
            print_error "Invalid installation method: $install_method"
            return 1
            ;;
    esac
}

# Function to install to system directories
install_to_system() {
# Determine Homebrew prefix (macOS M1/M2 uses /opt/homebrew)
    local BREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/usr/local")

# Paths
    local BIN_DIR="$BREW_PREFIX/bin"
    local MAN_DIR="$BREW_PREFIX/share/man/man1"
    local BASH_COMPLETION_DIR="$BREW_PREFIX/share/bash-completion/completions"
    local ZSH_COMPLETION_DIR="$BREW_PREFIX/share/zsh/site-functions"
    local FISH_COMPLETION_DIR="$BREW_PREFIX/share/fish/vendor_completions.d"
    
    # 1. Install main script
    print_status "Installing script to $BIN_DIR"
    sudo install -Dm755 scripts/fancy_tar_progress.sh "$BIN_DIR/fancy-tar"
    
    # Create symbolic links for aliases
    print_status "Creating command aliases..."
    sudo ln -sf "$BIN_DIR/fancy-tar" "$BIN_DIR/fancytar"
    sudo ln -sf "$BIN_DIR/fancy-tar" "$BIN_DIR/ftar"
    
    # 2. Install man page
    print_status "Installing man page to $MAN_DIR"
    sudo mkdir -p "$MAN_DIR"
    sudo cp docs/fancy-tar.1 "$MAN_DIR/"
    sudo gzip -f "$MAN_DIR/fancy-tar.1"
    
    # 3. Install completions
    print_status "Installing shell completions..."
    sudo mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$FISH_COMPLETION_DIR"
    
    sudo cp completions/fancy-tar.bash "$BASH_COMPLETION_DIR/fancy-tar"
    sudo cp completions/fancy-tar.zsh "$ZSH_COMPLETION_DIR/_fancy-tar"
    sudo cp completions/fancy-tar.fish "$FISH_COMPLETION_DIR/fancy-tar.fish"
}

# Function to install to user directory
install_to_user() {
    local USER_BIN="$HOME/.local/bin"
    local USER_MAN="$HOME/.local/share/man/man1"
    local USER_BASH_COMPLETION="$HOME/.local/share/bash-completion/completions"
    local USER_ZSH_COMPLETION="$HOME/.local/share/zsh/site-functions"
    local USER_FISH_COMPLETION="$HOME/.local/share/fish/vendor_completions.d"
    
    # Create directories
    mkdir -p "$USER_BIN" "$USER_MAN" "$USER_BASH_COMPLETION" "$USER_ZSH_COMPLETION" "$USER_FISH_COMPLETION"

# 1. Install main script
    print_status "Installing script to $USER_BIN"
    install -Dm755 scripts/fancy_tar_progress.sh "$USER_BIN/fancy-tar"

# Create symbolic links for aliases
    print_status "Creating command aliases..."
    ln -sf "$USER_BIN/fancy-tar" "$USER_BIN/fancytar"
    ln -sf "$USER_BIN/fancy-tar" "$USER_BIN/ftar"

# 2. Install man page
    print_status "Installing man page to $USER_MAN"
    cp docs/fancy-tar.1 "$USER_MAN/"
    gzip -f "$USER_MAN/fancy-tar.1"

# 3. Install completions
    print_status "Installing shell completions..."
    cp completions/fancy-tar.bash "$USER_BASH_COMPLETION/fancy-tar"
    cp completions/fancy-tar.zsh "$USER_ZSH_COMPLETION/_fancy-tar"
    cp completions/fancy-tar.fish "$USER_FISH_COMPLETION/fancy-tar.fish"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
        print_warning "Adding $USER_BIN to PATH..."
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.zshrc"
        print_success "PATH updated. Please restart your terminal or run: source ~/.bashrc"
    fi
}

# Function to install to local directory
install_to_local() {
    local LOCAL_BIN="./bin"
    
    # Create bin directory
    mkdir -p "$LOCAL_BIN"
    
    # Install main script
    print_status "Installing script to $LOCAL_BIN"
    install -Dm755 scripts/fancy_tar_progress.sh "$LOCAL_BIN/fancy-tar"
    
    # Create symbolic links for aliases
    print_status "Creating command aliases..."
    ln -sf "$LOCAL_BIN/fancy-tar" "$LOCAL_BIN/fancytar"
    ln -sf "$LOCAL_BIN/fancy-tar" "$LOCAL_BIN/ftar"
    
    print_success "fancy-tar installed to $LOCAL_BIN"
    print_warning "To use fancy-tar, run: ./bin/fancy-tar"
    print_warning "Or add $LOCAL_BIN to your PATH"
}

# Main installation function
main() {
    echo "🎯 fancy-tar Installer"
    echo "======================"
    echo
    
    # Detect OS
    local os=$(detect_os)
    print_status "Detected OS: $os"
    
    # Install dependencies
    install_dependencies "$os"
    
    # Choose installation method
    echo
    echo "Choose installation method:"
    echo "1) Homebrew (recommended for macOS)"
    echo "2) System-wide (requires sudo)"
    echo "3) User directory (~/.local/bin)"
    echo "4) Local directory (./bin)"
    echo "5) Skip installation"
    echo
    read -p "Enter your choice (1-5): " choice
    
    case "$choice" in
        1)
            if [[ "$os" == "macos" ]]; then
                if command_exists brew; then
                    install_fancy_tar "homebrew"
                else
                    print_error "Homebrew not found. Please choose a different installation method."
                    print_warning "To use Homebrew, install it first: https://brew.sh"
                    exit 1
                fi
            else
                print_error "Homebrew installation is only available on macOS"
                exit 1
            fi
            ;;
        2)
            install_fancy_tar "system"
            ;;
        3)
            install_fancy_tar "user"
            ;;
        4)
            install_fancy_tar "local"
            ;;
        5)
            print_warning "Installation skipped"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo
    print_success "fancy-tar installed successfully!"
    echo
echo "💡 Try: fancy-tar -h or fancy-tar -<TAB> for autocompletion"
echo "💡 You can also use: fancytar or ftar"
    echo
    echo "📚 Documentation: https://github.com/jgiambona/fancy-tar"
}

# Run main function
main "$@"
