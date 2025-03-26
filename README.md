# 🎁 fancy-tar

**The friendliest tar wrapper with compression, encryption, hashing, tree view, and now... ZIP support!**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 Friendly interface for `tar` + `gzip`
- ⏱️ Progress bars and file count
- 🌳 Tree view preview
- 🔐 Encrypt with GPG, OpenSSL, or ZIP password
- ⚠️ Warns about weak classic ZIP encryption
- ✅ SHA256 hashing
- ❌ Cleans up broken files on error
- 🖥️ Notifications (macOS/Linux)
- 📂 Option to open folder after archiving
- 🐚 Shell completions for Bash, Zsh, Fish

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
| `-o <file>`               | Output filename (default: archive.tar.gz or archive.zip)                  |
| `-n`                      | Disable gzip compression (.tar only)                                      |
| `-s`                      | Simulate slow compression                                                 |
| `-x`                      | Open folder after archiving                                               |
| `-t`, `--tree`            | Show file tree preview                                                    |
| `--no-recursion`          | Archive top-level files only                                              |
| `--hash`                  | Output SHA256 checksum                                                    |
| `--encrypt[=gpg|openssl]` | Encrypt tar archive using GPG/OpenSSL                                     |
| `--recipient <id>`        | GPG recipient for encryption                                              |
| `--password <pass>`       | Password for symmetric or zip encryption                                  |
| `--zip`                   | Create `.zip` archive (uses classic ZIP encryption if password given)     |
| `-h`, `--help`            | Show help                                                                 |

---

## 📦 ZIP Archives

### Create a ZIP file
```bash
fancy-tar myfolder --zip
# ➜ archive.zip
```

### Create a password-protected ZIP file
```bash
fancy-tar myfolder --zip --password hunter2
```

### ⚠️ ZIP Encryption Warning

```
🔐 Warning: Classic ZIP encryption is insecure.
   • Easily broken with modern tools
   • No integrity/authentication protection
💡 Use --encrypt=gpg or --encrypt=openssl for stronger encryption.
```

---

## 🔐 Tar-Based Encryption

### GPG (symmetric or recipient-based)
```bash
fancy-tar data/ --encrypt=gpg
fancy-tar data/ --encrypt=gpg --recipient=you@example.com
```

### OpenSSL AES
```bash
fancy-tar data/ --encrypt=openssl --password=secret
```

---

## ✅ Smart Behaviors

- Archive type inferred from `--zip`
- Secure encryption fallback
- Auto-prompts for passwords
- Validates recipients
- Warns about weak crypto
- Only final file is hashed

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
