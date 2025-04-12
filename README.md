# 🎯 fancy-tar

**fancy-tar** is a smarter, friendlier tar tool with progress bars, tree views, encryption, ZIP support, and more.

<div align="center">

[![Version](https://img.shields.io/badge/version-1.6.4-blue.svg)](https://github.com/jgiambona/fancy-tar/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-89E051.svg)](https://www.gnu.org/software/bash/)

</div>

## ✨ Features

- 🎯 Create `.tar`, `.tar.gz`, `.zip`, or `.7z` archives
- 🔐 GPG, OpenSSL, or 7z encryption (symmetric or public key)
- 🔑 Secure password handling with masking and validation
- 🧠 Tree-style file preview with `--tree`
- 📂 Optional recursion control
- 🔍 SHA256 checksum generation (`--hash`)
- ✅ Self-testing with interactive password prompts (`--self-test`)
- 🔄 Desktop notifications and folder opening
- 🧹 Automatic cleanup of temporary files

## 🚀 Installation

### Via Homebrew (macOS)

```bash
brew install jgiambona/fancy-tar/fancy-tar
```

### Via RPM (Fedora/RHEL)

```bash
# Download the RPM package from the latest release
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.6.3/fancy-tar-1.6.3-1.noarch.rpm

# Verify package signature (optional but recommended)
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.6.3/fancy-tar-1.6.3-1.noarch.rpm.asc
gpg --verify fancy-tar-1.6.3-1.noarch.rpm.asc fancy-tar-1.6.3-1.noarch.rpm

# Install using rpm (Fedora/RHEL)
sudo rpm -i fancy-tar-1.6.3-1.noarch.rpm

# Or using dnf (Fedora)
sudo dnf install ./fancy-tar-1.6.3-1.noarch.rpm

# Or using yum (RHEL)
sudo yum install ./fancy-tar-1.6.3-1.noarch.rpm
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jgiambona/fancy-tar.git
   cd fancy-tar
   ```

2. Make the script executable:
   ```bash
   chmod +x scripts/fancy_tar_progress.sh
   ```

3. Install to make it globally accessible:
   ```bash
   # Option 1: Using the install script
   ./install.sh

   # Option 2: Manual installation
   sudo cp scripts/fancy_tar_progress.sh /usr/local/bin/fancy-tar
   sudo chmod +x /usr/local/bin/fancy-tar
   ```

4. Add shell completions (optional but recommended):
   ```bash
   # For bash
   sudo cp completions/fancy-tar.bash /etc/bash_completion.d/fancy-tar

   # For zsh
   sudo cp completions/fancy-tar.zsh /usr/local/share/zsh/site-functions/_fancy-tar

   # For fish
   sudo cp completions/fancy-tar.fish /usr/local/share/fish/vendor_completions.d/fancy-tar.fish
   ```

5. Install man page:
   ```bash
   sudo cp docs/fancy-tar.1 /usr/local/share/man/man1/
   sudo gzip /usr/local/share/man/man1/fancy-tar.1
   ```

### Dependencies

- **Required:**
  - `bash`
  - `pv` (for progress bars)
  - `gnu-tar`
  - `coreutils`

- **Optional:**
  - `gpg` (for GPG encryption)
  - `openssl` (for OpenSSL encryption)
  - `p7zip` (for ZIP and 7z support)

## 📚 Usage

```bash
fancy-tar [options] <files...>
```

### Common Options

| Option | Description |
|--------|-------------|
| `-o <file>` | Output name (default: `archive.tar.gz`) |
| `-n` | No gzip compression (create .tar) |
| `-s` | Enable slow mode (simulate slower compression) |
| `-x` | Open the output folder when done |
| `--zip` | Create `.zip` archive |
| `--7z` | Create `.7z` archive |
| `--compression=<0-9>` | Set 7z compression level (0=store, 9=ultra) |
| `--encrypt=gpg` | GPG encrypt (`--recipient` or password prompt) |
| `--encrypt=openssl` | Encrypt with OpenSSL AES-256 |
| `--password` | Specify or prompt for password |
| `--recipient <id>` | Recipient ID for GPG public key encryption |
| `--hash` | Save SHA256 of archive |
| `--tree` | Show hierarchical file layout |
| `--no-recursion` | Don't recurse into subdirectories |
| `--self-test` | Run internal test |
| `--version` | Show version |

## 🔒 Security Features

- **Password Handling:**
  - 🔐 Interactive password prompts are masked
  - 🔒 Terminal settings are properly restored
  - 📏 Password strength validation in interactive mode
  - 🚫 No password storage or logging

- **Encryption Options:**
  - 🔐 GPG (recommended for sensitive data)
    - Supports both symmetric (password) and asymmetric (public key) encryption
    - Uses AES-256 for symmetric encryption
  - 🔒 OpenSSL (strong AES-256 encryption)
    - Uses PBKDF2 for key derivation
    - Includes salt for better security
  - 🔐 7z (strong encryption)
    - Uses AES-256 encryption
    - Encrypts both file contents and headers
    - Supports solid compression
    - Uses maximum compression by default
    - Can be extracted with any 7z-compatible tool
    - Configurable compression level (0-9)
      - 0: Store (no compression)
      - 1: Fastest
      - 5: Normal (default)
      - 9: Ultra (very slow)
      - ⚠️ High levels (8-9) can be extremely slow
  - ⚠️ ZIP encryption (not recommended for sensitive data)
    - Uses classic ZIP password protection
    - Easily broken with modern tools
    - No integrity or authenticity protection

## 💡 Examples

### Basic Usage
```bash
# Create a basic tar.gz archive
fancy-tar myfiles/ -o backup.tar.gz

# Create a plain tar archive (no compression)
fancy-tar myfiles/ -n -o backup.tar

# Show file tree before archiving
fancy-tar project/ --tree -o project.tar.gz

# Create archive with hash verification
fancy-tar data/ --hash -o data.tar.gz
```

### 7z Archives
```bash
# Create a 7z archive with encryption and maximum compression
fancy-tar sensitive/ --7z --password --compression=9 -o secure.7z

# Create a 7z archive with fast compression
fancy-tar largefiles/ --7z --compression=1 -o fast.7z

# Create a split 7z archive
fancy-tar hugefiles/ --7z --split-size=100M -o split.7z

# Create and verify a 7z archive
fancy-tar important/ --7z --verify -o verified.7z
```

### Encryption
```bash
# Create GPG-encrypted archive with public key
fancy-tar secret/ --encrypt=gpg --recipient user@example.com -o secret.tar.gz

# Create OpenSSL-encrypted archive with password
fancy-tar private/ --encrypt=openssl --password -o private.tar.gz

# Create a ZIP archive with encryption
fancy-tar sensitive/ --zip --encrypt=zip -o secure.zip
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for better progress reporting in tar operations
- Built with modern shell scripting best practices
- Thanks to all contributors and users!

