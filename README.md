# 🎯 fancy-tar

**fancy-tar** is a smarter, friendlier tar tool with progress bars, tree views, encryption, ZIP support, and more. It's a simple bash script wrapper around existing tools, making it easy to audit and trust - no need to rely on unknown authors or complex binaries. It saves you time by providing a user-friendly interface to common operations that people want but often can't be bothered looking up or remembering the complicated commands for.

<div align="center">

[![Version](https://img.shields.io/badge/version-1.7.5-blue.svg)](https://github.com/jgiambona/fancy-tar/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-89E051.svg)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/platform-linux-lightgrey.svg)](https://www.kernel.org/)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

</div>

## 📑 Table of Contents

- [Installation](#-installation)
- [Usage](#-usage)
- [Option Compatibility by Compression Method](#option-compatibility-by-compression-method)
- [Quickstart](#quickstart)
- [Compression Methods](#compression-methods)
- [Security Features](#-security-features)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Test Scripts](#test-scripts)

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
- 📑 **Split archive support:** Prints a summary of all split parts, checks for missing/empty parts, provides reassembly instructions, and handles errors and user prompts for existing parts.

## Why Use fancy-tar?
- No need to remember complex tar/zip/7z commands
- Automatic progress bars and file counts
- Safer, friendlier encryption and password handling
- Smart defaults and parallel compression for speed
- Unified interface for multiple archive formats

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
- `-x`, `--open-after`         Open the output folder when done (now supported on macOS and Linux)
- `-t, --tree`            Show hierarchical file structure before archiving
- `--no-recurse`          Do not include directory contents (shallow archive)
- `--hash`                Output SHA256 hash file alongside the archive
- `--encrypt[=method]`    Encrypt archive with gpg (default) or openssl
- `--recipient <id>`      Recipient ID for GPG public key encryption
- `--password <pass>`     Password to use for encryption (if supported)
- `--verify`              Verify the archive after creation (skipped for split archives; see below)
- `--split-size=<size>`   Split the archive into smaller parts (e.g., 100M, 1G). Prints a summary of all parts and reassembly instructions.
- `--zip`                 Create a .zip archive (with optional password)
- `--7z`                  Create a .7z archive (with optional password)
- `--compression=<0-9>`   Set compression level for 7z archives (0=store, 9=ultra)
- `--use=<tool>`          Force specific compression tool (gzip, pigz, bzip2, pbzip2, lbzip2, xz, pxz)
- `--print-filename`      Output only the final archive filename (for scripting)

**Tip:** If you do not specify <kbd>--zip</kbd> or <kbd>--7z</kbd>, the default output is a tar archive (with gzip compression if available).

### Option Compatibility by Compression Method

**Note:** If neither <kbd>--zip</kbd> nor <kbd>--7z</kbd> is specified, the default is tar/tar.gz (with parallel tools if available).

Some options are only available with certain compression methods. The table below summarizes which options can be used with each method:

| Option                        | tar/tar.gz | zip  | 7z   |
|-------------------------------|:----------:|:----:|:----:|
| <a name="opt-output"></a><kbd>-o</kbd>, <kbd>--output</kbd>                |    ✔️      | ✔️   | ✔️   |
| <a name="opt-n"></a><kbd>-n</kbd> (no compression)         |    ✔️      | ❌   | ❌   |
| <a name="opt-s"></a><kbd>-s</kbd> (slower/better compression) | ✔️      | ❌   | ❌   |
| <a name="opt-x"></a><kbd>-x</kbd>, <kbd>--open-after</kbd> (open after)             |    ✔️      | ✔️   | ✔️   |
| <a name="opt-tree"></a><kbd>-t</kbd>, <kbd>--tree</kbd>                  |    ✔️      | ✔️   | ✔️   |
| <a name="opt-no-recurse"></a><kbd>--no-recurse</kbd>                |    ✔️      | ✔️   | ✔️   |
| <a name="opt-hash"></a><kbd>--hash</kbd>                      |    ✔️      | ✔️   | ✔️   |
| <a name="opt-encrypt"></a><kbd>--encrypt[=gpg\|openssl]</kbd>     |    ✔️      | ❌   | ❌   |
| <a name="opt-encrypt7z"></a><kbd>--encrypt</kbd> (7z/zip password) |    ❌      | ✔️   | ✔️   |
| <a name="opt-recipient"></a><kbd>--recipient</kbd>                 |    ✔️      | ❌   | ❌   |
| <a name="opt-password"></a><kbd>--password</kbd>¹                  |    ✔️      | ✔️   | ✔️   |
| <a name="opt-verify"></a><kbd>--verify</kbd>                    |    ✔️      | ✔️   | ✔️   |
| <a name="opt-split-size"></a><kbd>--split-size</kbd>                |    ✔️      | ✔️   | ✔️   |
| <a name="opt-zip"></a><kbd>--zip</kbd>                       |    ❌      | ✔️   | ❌   |
| <a name="opt-7z"></a><kbd>--7z</kbd>                        |    ❌      | ❌   | ✔️   |
| <a name="opt-compression"></a><kbd>--compression=&lt;0-9&gt;</kbd>         |    ❌      | ❌   | ✔️   |
| <a name="opt-use"></a><kbd>--use=&lt;tool&gt;</kbd>                |    ✔️²      | ❌   | ❌   |
| <a name="opt-print-filename"></a><kbd>--print-filename</kbd>            |    ✔️      | ✔️   | ✔️   |

✔️ = Supported  ❌ = Not Supported

¹ <kbd>--password</kbd> for tar/tar.gz is only used with <kbd>--encrypt=gpg</kbd> or <kbd>--encrypt=openssl</kbd>.

² <kbd>--use</kbd> valid choices: <kbd>gzip</kbd>, <kbd>pigz</kbd>, <kbd>bzip2</kbd>, <kbd>pbzip2</kbd>, <kbd>lbzip2</kbd>, <kbd>xz</kbd>, <kbd>pxz</kbd> (tar/tar.gz only).

³ <kbd>--encrypt</kbd> for 7z uses 7z's built-in AES-256 encryption (not GPG/OpenSSL). For zip, it uses classic zip password protection. For tar/tar.gz, it uses GPG or OpenSSL as specified.

See the [Examples](#💡-examples) section below for usage patterns with each compression method.

### Quickstart

| Task                                 | Example Command |
|--------------------------------------|-----------------|
| Create tar.gz                        | [`fancy-tar folder/ -o archive.tar.gz`](#quickstart) |
| Create zip                           | [`fancy-tar --zip folder/ -o archive.zip`](#quickstart) |
| Create 7z                            | [`fancy-tar --7z folder/ -o archive.7z`](#quickstart) |
| Encrypt with GPG                     | [`fancy-tar --encrypt=gpg folder/ -o secret.tar.gz`](#quickstart) |
| Encrypt with OpenSSL                 | [`fancy-tar --encrypt=openssl --password folder/ -o secret.tar.gz`](#quickstart) |
| Encrypt ZIP with password            | [`fancy-tar --zip --password folder/ -o secure.zip`](#quickstart) |
| Encrypt 7z with password             | [`fancy-tar --7z --password folder/ -o secure.7z`](#quickstart) |
| Split tar.gz archive                 | [`fancy-tar --split-size=100M folder/ -o split.tar.gz`](#quickstart) |
| Split zip archive                    | [`fancy-tar --zip --split-size=500M folder/ -o split.zip`](#quickstart) |
| Split 7z archive                     | [`fancy-tar --7z --split-size=1G folder/ -o split.7z`](#quickstart) |
| Show file tree before archiving      | [`fancy-tar --tree folder/ -o archive.tar.gz`](#quickstart) |
| Verify archive after creation        | [`fancy-tar --verify folder/ -o archive.tar.gz`](#quickstart) |
| **Open output folder after creation**| [`fancy-tar -x folder/ -o archive.tar.gz`](#quickstart) |
| **Open output folder after creation (long option)**| [`fancy-tar --open-after folder/ -o archive.tar.gz`](#quickstart) |

### Compression Methods

The tool automatically uses parallel compression tools when available:
- gzip → pigz (parallel gzip)
- bzip2 → pbzip2 (parallel bzip2)
- xz → pxz (parallel xz)

**Tip:** Parallel tools like <kbd>pigz</kbd>, <kbd>pbzip2</kbd>, and <kbd>pxz</kbd> can significantly speed up compression on multi-core systems.

You can force a specific compression tool using the <a href="#opt-use"><kbd>--use</kbd></a> option:
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
    - Uses AES-256 encryption when <kbd>--encrypt</kbd> or <kbd>--password</kbd> is provided with <kbd>--7z</kbd>
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
  - ⚠️ **ZIP encryption (not recommended for sensitive data)**
    - **Uses classic ZIP password protection**
    - **Easily broken with modern tools**
    - **No integrity or authenticity protection**

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

When you use the `--split-size` option, fancy-tar will split the archive into multiple parts of the specified size. After creation, the script:
- Prints a summary of all split parts, including their sizes
- Warns if any part is missing or empty
- Skips verification (integrity check) for split archives, since verification must be done after reassembly
- Provides clear instructions for reassembling and verifying the archive
- Prompts if split parts already exist, allowing you to overwrite, rename, or cancel
- Cleans up all split parts if the operation fails

**Example output:**
```
✅ Split archive created successfully. Parts:
   split.tar.gz (50.0MB)
   split.tar.gz.ab (50.0MB)
   split.tar.gz.ac (50.0MB)
   split.tar.gz.ad (empty!)
⚠️  Warning: split.tar.gz.ad is empty!
⚠️  Warning: Some split parts are missing or empty. Archive may be incomplete.

To reassemble and verify your split archive:
   cat split.tar.gz* > combined.tar.gz
   gzip -t combined.tar.gz   # or   tar -tf combined.tar.gz
```
For 7z split archives:
```
To reassemble and extract:
   7z x split.7z.001
   (Make sure all .7z.0* parts are present in the same directory)
```

**Note:** Verification (`--verify`) is skipped for split archives. You must reassemble all parts before verifying integrity.

**Required tools:**
- `split` (for tar-based split archives)
- `7z` (for 7z split archives)
- `zip` (for zip split archives)

If any required tool is missing, the script will print an actionable error message.

**User prompts:**
- If split parts matching the output name already exist, you will be prompted to overwrite, rename, or cancel.

**Error handling:**
- If the split operation fails, all split parts are cleaned up to avoid confusion.

**Example usage:**
```bash
fancy-tar huge_folder/ --split-size=100M -o split.tar.gz
# Output will include a summary of parts and reassembly instructions
```

## Hashing and Integrity Verification

When using the `--hash` option, fancy-tar generates a SHA256 hash file (e.g., `archive.7z.sha256`) **after all other steps, including encryption**. This means the hash is for the final archive file, which may be encrypted if you used `--encrypt`.

**Why is this the default and recommended behavior?**
- The hash allows anyone to verify the integrity of the file they received or downloaded, regardless of whether it is encrypted or not.
- This is the standard practice for public distribution: users can check the hash to ensure the file (encrypted or not) has not been tampered with or corrupted.
- If you need to verify the contents of the archive after decryption, you can generate and keep a hash of the unencrypted file for your own internal use, but this is not typically distributed.

**Summary:**
- The `.sha256` file always matches the final output file (post-encryption, if used).
- This ensures users can verify the file they actually have, which is the most secure and expected workflow for distribution.

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

### Platform Support for Folder Opening

- The `-x`/`--open-after` option opens the folder containing the output archive after creation.
- On **macOS**: uses the `open` command.
- On **Linux**: uses the `xdg-open` command.
- On other platforms, this feature may not be available.

