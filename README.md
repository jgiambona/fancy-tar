# fancy-tar

**fancy-tar** is a smarter, friendlier tar tool with progress bars, tree views, encryption, ZIP support, and more.

### 📦 Features

- 🎯 Create `.tar`, `.tar.gz`, or `.zip` archives
- 🔐 GPG or OpenSSL encryption (symmetric or public key)
- 🔑 Password prompt with confirmation
- 🧠 Tree-style file preview with `--tree`
- 📂 Optional recursion control
- 🔍 SHA256 checksum generation (`--hash`)
- ✅ Self-testing with interactive password prompts (`--self-test`)
- 🔄 Desktop notifications and folder opening
- 🧹 Automatic cleanup of temporary files

### 🚀 Installation

Via Homebrew (macOS):

```bash
brew install jgiambona/fancy-tar/fancy-tar
```

Via RPM (Fedora/RHEL):

```bash
# Download the RPM package from the latest release
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.6.1/fancy-tar-1.6.1-1.noarch.rpm

# Verify package signature (optional but recommended)
curl -LO https://github.com/jgiambona/fancy-tar/releases/download/v1.6.1/fancy-tar-1.6.1-1.noarch.rpm.asc
gpg --verify fancy-tar-1.6.1-1.noarch.rpm.asc fancy-tar-1.6.1-1.noarch.rpm

# Install using rpm (Fedora/RHEL)
sudo rpm -i fancy-tar-1.6.1-1.noarch.rpm

# Or using dnf (Fedora)
sudo dnf install ./fancy-tar-1.6.1-1.noarch.rpm

# Or using yum (RHEL)
sudo yum install ./fancy-tar-1.6.1-1.noarch.rpm

# To upgrade an existing installation:
sudo rpm -U fancy-tar-1.6.1-1.noarch.rpm
# Or using dnf:
sudo dnf upgrade ./fancy-tar-1.6.1-1.noarch.rpm
# Or using yum:
sudo yum upgrade ./fancy-tar-1.6.1-1.noarch.rpm

# To uninstall:
sudo rpm -e fancy-tar
# Or using dnf:
sudo dnf remove fancy-tar
# Or using yum:
sudo yum remove fancy-tar

# Dependencies:
# - Required: pv, gnu-tar, coreutils
# - Optional: gpg (for GPG encryption), openssl (for OpenSSL encryption), p7zip (for ZIP support)
# These will be automatically installed by dnf/yum if missing

# Verify installation:
fancy-tar --version
fancy-tar --self-test

# Troubleshooting:
# 1. If installation fails with "package is already installed":
#    - Use upgrade command instead of install
#    - Or remove existing package first: sudo rpm -e fancy-tar
#
# 2. If dependencies are missing:
#    - Fedora: sudo dnf install pv gnu-tar coreutils
#    - RHEL: sudo yum install pv gnu-tar coreutils
#
# 3. If GPG verification fails:
#    - Import the key: curl -sSL https://github.com/jgiambona.gpg | gpg --import
#
# 4. If you get permission errors:
#    - Ensure you're using sudo
#    - Check file permissions: ls -l fancy-tar-1.6.1-1.noarch.rpm
```

Manual:

```bash
chmod +x scripts/fancy_tar_progress.sh
./install.sh
```

### 📚 Usage

```bash
fancy-tar [options] <files...>
```

#### Common Options

- `-o <file>`         Output name (default: `archive.tar.gz`)
- `-n`                No gzip compression (create .tar instead of .tar.gz)
- `-s`                Enable slow mode (simulate slower compression)
- `-x`                Open the output folder when done
- `--zip`             Create `.zip` archive
- `--encrypt=gpg`     GPG encrypt (`--recipient` or password prompt)
- `--encrypt=openssl` Encrypt with OpenSSL AES-256
- `--password`        Specify or prompt for password
- `--recipient <id>`  Recipient ID for GPG public key encryption
- `--hash`            Save SHA256 of archive
- `--tree`            Show hierarchical file layout before archiving
- `--no-recursion`    Don't recurse into subdirectories
- `--self-test`       Run internal test
- `--version`         Show version

### 🔒 Security Considerations

- **GPG Encryption**: Recommended for sensitive data. Supports both symmetric (password) and asymmetric (public key) encryption.
- **OpenSSL Encryption**: Strong AES-256 encryption with password protection.
- **ZIP Encryption**: Classic ZIP encryption is **not recommended** for sensitive data as it's easily broken with modern tools. Use GPG or OpenSSL instead.
- **Password Handling**: Passwords are never stored and are only used in memory during encryption.

### 🔍 Examples

```bash
# Create a basic tar.gz archive
fancy-tar myfiles/ -o backup.tar.gz

# Create a plain tar archive (no compression)
fancy-tar myfiles/ -n -o backup.tar

# Create a ZIP archive with encryption
fancy-tar sensitive/ --zip --encrypt=zip -o secure.zip

# Show file tree before archiving
fancy-tar project/ --tree -o project.tar.gz

# Create archive with hash verification
fancy-tar data/ --hash -o data.tar.gz

# Archive without compression
fancy-tar files/ -n -o files.tar

# Create GPG-encrypted archive with public key
fancy-tar secret/ --encrypt=gpg --recipient user@example.com -o secret.tar.gz

# Create OpenSSL-encrypted archive with password
fancy-tar private/ --encrypt=openssl --password -o private.tar.gz

# Create encrypted ZIP with password
fancy-tar secure/ --zip --encrypt=zip --password -o secure.zip

# Create archive without recursion
fancy-tar project/ --no-recursion -o project.tar.gz

# Create archive with all bells and whistles
fancy-tar important/ --tree --hash --encrypt=gpg --recipient user@example.com -o important.tar.gz

# Create archive and open output folder when done
fancy-tar myfiles/ -x -o backup.tar.gz

# Create archive with desktop notification
fancy-tar myfiles/ -o backup.tar.gz  # Notifications are enabled by default

# Create archive with slow mode (simulates slower compression)
fancy-tar largefiles/ -s -o slow.tar.gz

# Create archive with default name (archive.tar.gz)
fancy-tar myfiles/

# Create GPG-encrypted archive with multiple recipients
fancy-tar secret/ --encrypt=gpg --recipient user1@example.com --recipient user2@example.com -o secret.tar.gz
```

### 💡 Tips

- If no output file is specified, the archive will be created as `archive.tar.gz` (or `archive.zip` with `--zip`)
- Use `--tree` to preview the file structure before archiving
- The `-s` (slow mode) option is useful for testing or when you want to see the progress bar in action
- Desktop notifications are enabled by default and will show when the archive is complete
- Use `--hash` to generate SHA256 checksums for verifying archive integrity
- The `--no-recursion` option is useful for creating shallow archives of directories

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 🙏 Acknowledgments

- Inspired by the need for better progress reporting in tar operations
- Built with modern shell scripting best practices
- Thanks to all contributors and users!

