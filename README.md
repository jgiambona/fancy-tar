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

Via Homebrew:

```bash
brew install jgiambona/fancy-tar/fancy-tar
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
- `--zip`             Create `.zip` archive
- `--encrypt=gpg`     GPG encrypt (`--recipient` or password prompt)
- `--encrypt=openssl` Encrypt with OpenSSL AES-256
- `--password`        Specify or prompt for password
- `--hash`            Save SHA256 of archive
- `--tree`            Show hierarchical file layout before archiving
- `--no-recursion`    Don't recurse into subdirectories
- `--self-test`       Run internal test
- `--version`         Show version

