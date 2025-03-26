# 🎁 fancy-tar

**Smarter, secure, and friendlier `tar` with progress bars, encryption, hash checking, file tree, desktop notifications, and more.**

Created by [Jason Giambona](https://github.com/jgiambona) — because `tar czvf` deserves better.

---

## 🚀 Features

- 📦 Wraps `tar` + `gzip` with progress and time info
- 🌳 Tree-style file preview
- 🕒 Time elapsed and ETA
- 🔐 Optional encryption with GPG or OpenSSL
- 📑 SHA256 hash for integrity
- ❌ Deletes incomplete archives on failure
- 📂 Open archive location when done
- 🐚 Bash/Zsh/Fish autocompletion
- 🖥️ Desktop notifications

---

## 📥 Installation

```bash
brew tap jgiambona/fancy-tar
brew install fancy-tar
```

---

## 🧠 Usage

```bash
fancy-tar [options] <files...>
```

---

## 🧰 Options

| Option                    | Description                                                               |
|---------------------------|---------------------------------------------------------------------------|
| `-o <file>`               | Set output filename (default: archive.tar.gz)                             |
| `-n`                      | No gzip compression (create .tar instead)                                 |
| `-s`                      | Slow mode for testing                                                     |
| `-x`                      | Open folder after archiving                                               |
| `-t`, `--tree`            | Show file tree before archiving                                           |
| `--no-recursion`          | Archive only top-level files                                              |
| `--hash`                  | Generate a .sha256 hash file for the archive                              |
| `--encrypt[=gpg|openssl]` | Encrypt using GPG (default) or OpenSSL                                    |
| `--recipient <id>`        | Use GPG public key (email, fingerprint, or key ID)                         |
| `--password <pass>`       | Password for encryption (otherwise will prompt interactively)             |
| `-h`, `--help`            | Show help message                                                         |

---

## 💡 Examples

### Basic gzip archive
```bash
fancy-tar my-folder
```

### Tree-view before archiving
```bash
fancy-tar --tree my-folder
```

### No gzip (raw .tar)
```bash
fancy-tar -n -o logs.tar logs/
```

### SHA256 verification
```bash
fancy-tar --hash backup/
# Produces: archive.tar.gz and archive.tar.gz.sha256
```

---

## 🔐 Encryption

### Symmetric GPG (default)
```bash
fancy-tar --encrypt=gpg my-folder
# Prompts for password, creates archive.tar.gz.gpg
```

### With password:
```bash
fancy-tar --encrypt=gpg --password hunter2 my-folder
```

### GPG public key encryption
```bash
fancy-tar --encrypt=gpg --recipient jason@example.com my-folder
```

If the recipient is missing, it will:
- Show a friendly error
- Suggest available public keys

### OpenSSL AES encryption
```bash
fancy-tar --encrypt=openssl --password hunter2 secure-data/
# Creates: archive.tar.gz.enc
```

---

## ⚠️ Smart Behavior

- `.gpg` or `.enc` extensions are automatically added to encrypted archives
- `.sha256` hash is generated after encryption
- Temporary files are cleaned on any error

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
