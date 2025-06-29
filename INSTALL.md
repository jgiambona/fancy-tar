# Installation Guide

This guide provides multiple installation options for fancy-tar, from the simplest one-liner for beginners to advanced manual installation for power users.

## 🎯 Quick Start (Recommended for beginners)

### One-liner Installation
The easiest way to install fancy-tar on any system:

```bash
curl -fsSL https://raw.githubusercontent.com/jgiambona/fancy-tar/main/install-curl.sh | bash
```

This will:
- Detect your operating system
- Install essential dependencies automatically
- Install fancy-tar to your user directory (`~/.local/bin`)
- Add it to your PATH
- Work on macOS, Linux, and other Unix-like systems

### macOS Users
If you're on macOS, you have additional options:

```bash
curl -fsSL https://raw.githubusercontent.com/jgiambona/fancy-tar/main/install-macos.sh | bash
```

This provides a menu with options:
1. **Homebrew** (if you already have Homebrew installed)
2. **System-wide** (requires sudo)
3. **User directory** (no sudo required, no Xcode needed)
4. **Applications folder** (macOS-style installation)
5. **Standalone bundle** (portable installation)

**Note:** These installers work without requiring Xcode Command Line Tools or Homebrew installation.

## 📦 Package Manager Installation

### Homebrew (macOS)
If you already have Homebrew installed:

```bash
brew install jgiambona/fancy-tar/fancy-tar
```

### Debian/Ubuntu
```bash
# Download and install the Debian package
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.7.0/fancy-tar_1.7.0-1_all.deb
sudo dpkg -i fancy-tar_1.7.0-1_all.deb
sudo apt-get install -f  # Install dependencies if needed
```

### Fedora/RHEL
```bash
# Download and install the RPM package
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.7.0/fancy-tar-1.7.0-1.noarch.rpm
sudo rpm -i fancy-tar-1.7.0-1.noarch.rpm
```

## 🔧 Manual Installation

### Option 1: Interactive Installer
For users who want control over the installation process:

```bash
git clone https://github.com/jgiambona/fancy-tar.git
cd fancy-tar
./install.sh
```

This provides a menu-driven installation with dependency detection.

### Option 2: Quick Installer
For minimal user interaction:

```bash
git clone https://github.com/jgiambona/fancy-tar.git
cd fancy-tar
./quick-install.sh
```

### Option 3: Manual Installation
For advanced users who want complete control:

```bash
git clone https://github.com/jgiambona/fancy-tar.git
cd fancy-tar
chmod +x scripts/fancy_tar_progress.sh
sudo cp scripts/fancy_tar_progress.sh /usr/local/bin/fancy-tar
sudo ln -s /usr/local/bin/fancy-tar /usr/local/bin/fancytar
sudo ln -s /usr/local/bin/fancy-tar /usr/local/bin/ftar
```

## 📋 Installation Options Comparison

| Method | Ease | Requirements | Best For | Updates |
|--------|------|--------------|----------|---------|
| **One-liner** | ⭐⭐⭐⭐⭐ | curl | Beginners | Manual |
| **macOS installer** | ⭐⭐⭐⭐⭐ | macOS only | macOS users | Manual |
| **Homebrew** | ⭐⭐⭐⭐ | Homebrew | macOS users with Homebrew | `brew upgrade` |
| **Package managers** | ⭐⭐⭐⭐ | Package manager | Linux users | Package manager |
| **Interactive installer** | ⭐⭐⭐ | git, basic dependencies | Users who want control | Manual |
| **Manual** | ⭐⭐ | git, manual steps | Advanced users | Manual |

**Note:** The one-liner and macOS installer work without requiring Xcode, Homebrew, or other development tools.

## 🔍 Dependencies

### Required Dependencies
- `bash` - Shell interpreter
- `tar` - Archive creation
- `pv` - Progress bars

### Optional Dependencies
- `gzip` - Compression (usually pre-installed)
- `zip` - ZIP archive support
- `p7zip` - 7z archive support
- `gpg` - GPG encryption
- `openssl` - OpenSSL encryption
- `pigz` - Parallel gzip compression
- `pbzip2` - Parallel bzip2 compression
- `pxz` - Parallel xz compression

**Note:** The quick installers will automatically install essential dependencies for you.

## 🚀 After Installation

Once installed, you can use fancy-tar with any of these commands:
- `fancy-tar` (full name)
- `fancytar` (shorter alias)
- `ftar` (shortest alias)

### Test the Installation
```bash
fancy-tar -h  # Show help
fancy-tar --version  # Show version
```

### Shell Completions
If you installed via package managers or the interactive installer, shell completions should be automatically available. Press `TAB` after typing `fancy-tar -` to see available options.

## 🔧 Troubleshooting

### "Command not found" after installation
If you get "command not found" after installation:

1. **Restart your terminal** - The PATH changes may not be active in your current session
2. **Or run:** `source ~/.bashrc` (bash) or `source ~/.zshrc` (zsh)
3. **Check your PATH:** `echo $PATH | grep local`

### Permission denied errors
If you get permission errors:

1. **User directory installation:** Make sure `~/.local/bin` is in your PATH
2. **System installation:** Make sure you ran the installer with appropriate permissions
3. **Check file permissions:** `ls -la $(which fancy-tar)`

### Missing dependencies
If you get errors about missing tools:

1. **On macOS:** 
   - If you have Homebrew: `brew install pv gzip zip p7zip gnupg openssl`
   - If you don't have Homebrew: Install it first at https://brew.sh, then run the above command
   - Or continue without these tools - fancy-tar will work with basic features
2. **On Ubuntu/Debian:** `sudo apt-get install pv gzip zip p7zip-full gnupg openssl`
3. **On Fedora:** `sudo dnf install pv gzip zip p7zip gnupg openssl`

## 📚 Next Steps

After installation, check out:
- [Quickstart Guide](README.md#-quickstart) - Common usage examples
- [Usage Documentation](README.md#-usage) - Complete option reference
- [Examples](README.md#💡-examples) - Real-world usage patterns

## 🤝 Need Help?

If you encounter issues:
1. Check the [troubleshooting section](#-troubleshooting) above
2. Review the [main README](README.md) for detailed documentation
3. Open an issue on GitHub with details about your system and the error 