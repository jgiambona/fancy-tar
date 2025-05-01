# 🎯 fancy-tar

**fancy-tar** is a smarter, friendlier tar tool with progress bars, tree views, encryption, ZIP support, and more. It's a simple bash script wrapper around existing tools, making it easy to audit and trust - no need to rely on unknown authors or complex binaries. It saves you time by providing a user-friendly interface to common operations that people want but often can't be bothered looking up or remembering the complicated commands for.

<div align="center">

[![Version](https://img.shields.io/badge/version-1.7.3-blue.svg)](https://github.com/jgiambona/fancy-tar/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-89E051.svg)](https://www.gnu.org/software/bash/)

</div>

## ✨ Features

- 🎯 Create `.tar`, `.tar.gz`, `.zip`, or `.7z` archives
- 🔐 GPG, OpenSSL, or 7z encryption (symmetric or public key)
  - GPG encrypted files have `.gpg` extension
  - OpenSSL encrypted files have `.enc` extension
  - 7z archives use built-in AES-256 encryption
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

### Via Debian Package (Debian/Ubuntu)

```bash
# Download the Debian package from the latest release
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.7.0/fancy-tar_1.7.0-1_all.deb

# Install using dpkg
sudo dpkg -i fancy-tar_1.7.0-1_all.deb

# Install dependencies if needed
sudo apt-get install -f
```

### Via RPM (Fedora/RHEL)

```bash
# Download the RPM package from the latest release
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.7.0/fancy-tar-1.7.0-1.noarch.rpm

# Verify package signature (optional but recommended)
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.7.0/fancy-tar-1.7.0-1.noarch.rpm.asc
gpg --verify fancy-tar-1.7.0-1.noarch.rpm.asc fancy-tar-1.7.0-1.noarch.rpm

# Install using rpm (Fedora/RHEL)
sudo rpm -i fancy-tar-1.7.0-1.noarch.rpm

# Or using dnf (Fedora)
sudo dnf install ./fancy-tar-1.7.0-1.noarch.rpm

# Or using yum (RHEL)
sudo yum install ./fancy-tar-1.7.0-1.noarch.rpm
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
   sudo ln -s /usr/local/bin/fancy-tar /usr/local/bin/fancytar
   sudo ln -s /usr/local/bin/fancy-tar /usr/local/bin/ftar
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
  - `pigz` (for parallel gzip compression)
  - `pbzip2` (for parallel bzip2 compression)
  - `pxz` (for parallel xz compression)

## 📚 Usage

```bash
fancy-tar [options] <files/directories>
# or
fancytar [options] <files/directories>
# or
ftar [options] <files/directories>
```

### Common Options

- `-o, --output <file>`    Specify output file name
- `-n`                     Create uncompressed tar archive
- `-s`                     Use slower but better compression
- `-x`                     Open the output folder when done
- `-t, --tree`            Show hierarchical file structure before archiving
- `--no-recurse`          Do not include directory contents (shallow archive)
- `--hash`                Output SHA256 hash file alongside the archive
- `--encrypt[=method]`    Encrypt archive with gpg (default) or openssl
- `--recipient <id>`      Recipient ID for GPG public key encryption
- `--password <pass>`     Password to use for encryption (if supported)
- `--verify`              Verify the archive after creation
- `--split-size=<size>`   Split the archive into smaller parts (e.g., 100M, 1G)
- `--zip`                 Create a .zip archive (with optional password)
- `--7z`                  Create a .7z archive (with optional password)
- `--compression=<0-9>`   Set compression level for 7z archives (0=store, 9=ultra)
- `--use=<tool>`          Force specific compression tool (gzip, bzip2, xz, etc.)
- `--print-filename`      Output only the final archive filename (for scripting)

### Compression Methods

The tool automatically uses parallel compression tools when available:
- gzip → pigz (parallel gzip)
- bzip2 → pbzip2 (parallel bzip2)
- xz → pxz (parallel xz)

You can force a specific compression tool using the `--use` option:
```bash
# Force using gzip instead of pigz
fancy-tar --use=gzip -o archive.tar.gz files/

# Force using bzip2 instead of pbzip2
fancy-tar --use=bzip2 -o archive.tar.bz2 files/

# Force using xz instead of pxz
fancy-tar --use=xz -o archive.tar.xz files/
```

## 🔒 Security Features

- **Password Handling:**
  - 🔐 Interactive password prompts are masked
  - 🔒 Terminal settings are properly restored
  - 🚫 No password storage or logging

- **Encryption Options:**
  - 🔐 GPG (recommended for sensitive data)
    - Supports both symmetric (password) and asymmetric (public key) encryption
    - Uses AES-256 for symmetric encryption
  - 🔒 OpenSSL (strong AES-256 encryption)
    - Uses PBKDF2 for key derivation
    - Includes salt for better security
  - 🔐 7z (strong encryption)
    - Uses AES-256 encryption when password is provided
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

# Create archive with timestamp in filename
fancy-tar database.sql -o "database-$(date +%Y%m%d-%H%M).tar.gz"

# Get just the filename for use in scripts or pipes
fancy-tar myfiles/ -o "backup-$(date +%Y%m%d).tar.gz" --print-filename | xargs some_other_command

# Show file tree before archiving
fancy-tar project/ --tree -o project.tar.gz

# Create archive with hash verification
fancy-tar data/ --hash -o data.tar.gz

# Capture output filename for use in other scripts
output_file=$(fancy-tar myfiles/ -o backup.tar.gz)
echo "Created archive: $output_file"
# Use the filename in another command
some_other_command "$output_file"
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
fancy-tar sensitive/ --zip --password -o secure.zip
```

### Split Archives
```bash
# Create a split tar.gz archive
fancy-tar huge_folder/ --split-size=100M -o split.tar.gz

# Create a split 7z archive
fancy-tar huge_folder/ --7z --split-size=1G -o split.7z

# Create a split ZIP archive
fancy-tar huge_folder/ --zip --split-size=500M -o split.zip
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for better progress reporting in tar operations
- Built with modern shell scripting best practices
- Thanks to all contributors and users!

## Test Scripts

The project includes several test scripts to ensure functionality and reliability:

- `tests/test_compression.sh`: Basic compression tests
  - Tests basic archive creation with different formats (tar.gz, tar.bz2, tar.xz)
  - Verifies archive integrity
  - Checks compression level handling
  - Tests basic encryption functionality

- `tests/test_advanced.sh`: Comprehensive feature tests
  - Tests parallel compression tools (pigz, pbzip2, pxz)
  - Tests multiple encryption methods (GPG, OpenSSL, 7z)
  - Tests error handling and edge cases
  - Tests special cases (special characters, symlinks, hard links, permissions)
  - Tests performance with large files and many small files

- `tests/test_man.sh`: Documentation tests
  - Verifies man page formatting
  - Checks for documentation completeness
  - Ensures all options are properly documented

To run all tests locally:
```bash
# Make test scripts executable
chmod +x tests/*.sh

# Run basic compression tests
./tests/test_compression.sh

# Run advanced feature tests
./tests/test_advanced.sh

# Run man page tests
./tests/test_man.sh
```

