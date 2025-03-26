# 🎁 fancy-tar

**Smarter, safer, and more secure archiving with progress bars, encryption, hash verification, file tree previews, desktop notifications, and more.**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 Simple interface over `tar` + `gzip`
- 🧾 Show file count, total size, and progress
- 🌳 Tree view before archiving
- 🔐 Encryption via GPG or OpenSSL (symmetric or asymmetric)
- 🔑 Password prompt fallback
- 🛡️ Recipient validation with key suggestions
- ✅ SHA256 hashing of the final archive
- ❌ Cleans up incomplete files if an error occurs
- 🖥️ Desktop notifications on macOS/Linux
- 📂 Optionally open the output folder
- 🐚 Autocompletion for Bash, Zsh, Fish

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
| `--no-recursion`          | Shallow archive (top-level only)                                          |
| `--hash`                  | Output SHA256 `.sha256` hash file                                         |
| `--encrypt[=gpg|openssl]` | Encrypt using GPG (default) or OpenSSL                                    |
| `--recipient <id>`        | GPG public key ID/email for encryption                                    |
| `--password <pass>`       | Password for symmetric encryption                                         |
| `-h`, `--help`            | Show help                                                                 |

---

## 🔐 Encryption

### GPG (asymmetric) with public key:
```bash
fancy-tar secure/ --encrypt=gpg --recipient=jason@example.com
# ➜ Output: archive.tar.gz.gpg
```

### GPG (symmetric) with prompt:
```bash
fancy-tar mydata/ --encrypt=gpg
# Prompts for password, saves archive.tar.gz.gpg
```

### OpenSSL with password:
```bash
fancy-tar mydata/ --encrypt=openssl --password hunter2
# ➜ Output: archive.tar.gz.enc
```

---

## 🛡️ Smart Behavior

- Detects missing recipient and shows available keys
- Supports both `--flag=value` and `--flag value` forms
- Encrypts the final archive file, not a renamed placeholder
- Only saves `.gpg` or `.enc` file if encryption succeeds
- Cleans up unencrypted files after encryption
- Hash is generated after all encryption is done

---

## ✅ Example

```bash
fancy-tar logs/ --hash --encrypt=gpg --recipient=jason@example.com
```

Produces:
- `archive.tar.gz.gpg`
- `archive.tar.gz.gpg.sha256`

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
