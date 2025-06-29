#!/bin/bash

# fancy-tar macOS Installer
# Provides multiple installation options for macOS users

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies via Homebrew
install_dependencies_brew() {
    local missing_deps=()
    
    # Check for essential dependencies
    if ! command_exists pv; then
        missing_deps+=("pv")
    fi
    
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
    
    print_status "Installing dependencies: ${missing_deps[*]}"
    brew install "${missing_deps[@]}"
    print_success "Dependencies installed successfully!"
}

# Function to check dependencies without Homebrew
check_dependencies_no_brew() {
    local missing_deps=()
    
    # Check for essential dependencies
    if ! command_exists pv; then
        missing_deps+=("pv")
    fi
    
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
        print_success "All dependencies are already available!"
        return 0
    fi
    
    print_warning "Some optional dependencies are missing: ${missing_deps[*]}"
    print_warning "fancy-tar will work with basic features, but some advanced features may be limited."
    print_warning ""
    print_warning "To install these dependencies later:"
    print_warning "  - Install Homebrew: https://brew.sh"
    print_warning "  - Then run: brew install ${missing_deps[*]}"
    print_warning ""
    print_warning "Continuing with basic installation..."
    return 0
}

# Function to install fancy-tar via Homebrew
install_via_homebrew() {
    print_status "Installing fancy-tar via Homebrew..."
    brew install jgiambona/fancy-tar/fancy-tar
    print_success "fancy-tar installed via Homebrew!"
}

# Function to install to system directories
install_to_system() {
    local BREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/usr/local")
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

# Function to install to Applications folder
install_to_applications() {
    local APP_DIR="$HOME/Applications/fancy-tar"
    local BIN_DIR="$APP_DIR/bin"
    
    # Create application directory
    mkdir -p "$BIN_DIR"
    
    # Install main script
    print_status "Installing script to $BIN_DIR"
    install -Dm755 scripts/fancy_tar_progress.sh "$BIN_DIR/fancy-tar"
    
    # Create aliases
    ln -sf "$BIN_DIR/fancy-tar" "$BIN_DIR/fancytar"
    ln -sf "$BIN_DIR/fancy-tar" "$BIN_DIR/ftar"
    
    # Create a simple launcher script
    cat > "$APP_DIR/launch-fancy-tar.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./bin/fancy-tar "$@"
EOF
    chmod +x "$APP_DIR/launch-fancy-tar.command"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_warning "Adding $BIN_DIR to PATH..."
        echo "export PATH=\"\$HOME/Applications/fancy-tar/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/Applications/fancy-tar/bin:\$PATH\"" >> "$HOME/.zshrc"
        print_success "PATH updated. Please restart your terminal or run: source ~/.bashrc"
    fi
    
    print_success "fancy-tar installed to $APP_DIR"
    print_warning "You can also double-click launch-fancy-tar.command to run fancy-tar"
}

# Function to create a standalone bundle
create_standalone_bundle() {
    local BUNDLE_DIR="./fancy-tar-standalone"
    
    print_status "Creating standalone bundle..."
    
    # Create bundle directory
    rm -rf "$BUNDLE_DIR"
    mkdir -p "$BUNDLE_DIR"
    
    # Copy script
    cp scripts/fancy_tar_progress.sh "$BUNDLE_DIR/fancy-tar"
    chmod +x "$BUNDLE_DIR/fancy-tar"
    
    # Create aliases
    ln -sf "fancy-tar" "$BUNDLE_DIR/fancytar"
    ln -sf "fancy-tar" "$BUNDLE_DIR/ftar"
    
    # Copy documentation
    cp README.md "$BUNDLE_DIR/"
    cp docs/fancy-tar.1 "$BUNDLE_DIR/"
    
    # Create usage instructions
    cat > "$BUNDLE_DIR/USAGE.txt" << 'EOF'
fancy-tar Standalone Bundle
==========================

This bundle contains a standalone version of fancy-tar that doesn't require installation.

Usage:
  ./fancy-tar [options] <files/directories>
  ./fancytar [options] <files/directories>
  ./ftar [options] <files/directories>

Examples:
  ./fancy-tar -h                    # Show help
  ./fancy-tar document.pdf          # Create archive
  ./fancy-tar --zip folder/         # Create ZIP archive
  ./fancy-tar --encrypt secret.txt  # Create encrypted archive

For more information, see README.md
EOF
    
    print_success "Standalone bundle created at $BUNDLE_DIR"
    print_warning "You can copy this folder anywhere and run fancy-tar directly"
}

# Main installation function
main() {
    echo "🎯 fancy-tar macOS Installer"
    echo "============================"
    echo
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This installer is for macOS only"
        exit 1
    fi
    
    # Choose installation method
    echo "Choose installation method:"
    echo "1) Homebrew (recommended if you have Homebrew installed)"
    echo "2) System-wide (requires sudo)"
    echo "3) User directory (~/.local/bin - no sudo required)"
    echo "4) Applications folder (~/Applications/fancy-tar)"
    echo "5) Create standalone bundle (./fancy-tar-standalone)"
    echo "6) Skip installation"
    echo
    read -p "Enter your choice (1-6): " choice
    
    case "$choice" in
        1)
            if command_exists brew; then
                install_dependencies_brew
                install_via_homebrew
            else
                print_error "Homebrew not found. Please choose a different installation method."
                print_warning "To use Homebrew, install it first: https://brew.sh"
                exit 1
            fi
            ;;
        2)
            if command_exists brew; then
                install_dependencies_brew
            else
                check_dependencies_no_brew
            fi
            install_to_system
            ;;
        3)
            check_dependencies_no_brew
            install_to_user
            ;;
        4)
            check_dependencies_no_brew
            install_to_applications
            ;;
        5)
            check_dependencies_no_brew
            create_standalone_bundle
            ;;
        6)
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