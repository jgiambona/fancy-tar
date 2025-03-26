# 🎁 fancy-tar

**A smarter way to archive files with compression, progress bars, optional encryption, hashing, file previews, and more.**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 `tar` + `gzip` made human-friendly
- ⏱️ Progress and file count display
- 🌳 Tree view preview
- 🔐 Optional encryption: GPG (symmetric or asymmetric) or OpenSSL
- 🔑 Password prompts when needed
- 🧠 Smart recipient validation
- ✅ SHA256 verification
- ❌ Cleans up incomplete files on error
- 📂 Optionally open the output folder
- 🖥️ macOS/Linux notifications
- 🐚 Autocompletions for Bash, Zsh, Fish

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
| `-n`                      | No gzip compression (creates .tar)                                        |
| `-s`                      | Simulate slow processing                                                  |
| `-x`                      | Open output folder when done                                              |
| `-t`, `--tree`            | Show tree view before archiving                                           |
| `--no-recursion`          | Archive only top-level files                                              |
| `--hash`                  | Output SHA256 hash of final archive                                       |
| `--encrypt[=gpg|openssl]` | Encrypt archive using GPG or OpenSSL                                      |
| `--recipient <id>`        | GPG recipient (email or key ID)                                           |
| `--password <pass>`       | Password for symmetric encryption                                         |
| `-h`, `--help`            | Show help message                                                         |

---

## 🔐 Encryption Modes

### 🔑 Symmetric GPG (default)
If `--encrypt=gpg` is used without a `--recipient`, the script prompts for a password and encrypts symmetrically:
```bash
fancy-tar secure/ --encrypt=gpg
# ➜ Prompts for password and creates archive.tar.gz.gpg
```

### 🧾 GPG with Public Key
```bash
fancy-tar backup/ --encrypt=gpg --recipient=you@example.com
# ➜ archive.tar.gz.gpg
```

### 🔒 OpenSSL Encryption
```bash
fancy-tar data/ --encrypt=openssl --password=secret
# ➜ archive.tar.gz.enc
```

---

## ✅ Smart Features

- Automatically detects recipient format
- Fallback to password prompt if `--password` not given
- `.gpg` or `.enc` appended automatically
- SHA256 `.sha256` created after encryption
- Safe cleanup on failure

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
