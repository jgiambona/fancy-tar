# 🎁 fancy-tar

**Smarter archiving with compression, encryption, progress bars, hashing, and now a version flag + improved password handling!**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 Gzip or ZIP archiving with tar-like syntax
- 🔐 Encrypt with GPG or OpenSSL
- 🔑 Password prompts with confirmation
- 📁 Tree view preview
- ✅ SHA256 verification
- 🧼 Cleans up on failure
- 🧠 Smart recipient validation
- ⚠️ Classic ZIP encryption warning
- 📂 Optionally open the output folder
- 🐚 Completions for Bash, Zsh, Fish
- 🔢 `--version` flag support

---

## 🧠 Usage

```bash
fancy-tar [options] <files...>
```

---

## 🧰 Options

| Option                    | Description                                                               |
|---------------------------|---------------------------------------------------------------------------|
| `-o <file>`               | Set output archive filename                                               |
| `-n`                      | No gzip compression (create .tar)                                         |
| `-s`                      | Simulate slower archiving                                                 |
| `-x`                      | Open folder after archiving                                               |
| `-t`, `--tree`            | Show tree view preview                                                    |
| `--no-recursion`          | Shallow archive (top-level files only)                                    |
| `--hash`                  | Create `.sha256` checksum of final file                                   |
| `--zip`                   | Create a `.zip` archive (uses classic ZIP encryption)                     |
| `--encrypt[=gpg|openssl]` | Encrypt using GPG (default) or OpenSSL                                    |
| `--recipient <id>`        | GPG public key ID/email                                                   |
| `--password <pass>`       | Password for encryption (or will prompt + confirm)                        |
| `--version`               | Show version number and exit                                              |
| `-h`, `--help`            | Show help                                                                 |

---

## 🔐 Encryption Examples

### GPG (asymmetric)
```bash
fancy-tar secure/ --encrypt=gpg --recipient you@example.com
```

### GPG (symmetric)
```bash
fancy-tar secure/ --encrypt=gpg
# Prompts for password and confirmation
```

### OpenSSL
```bash
fancy-tar secure/ --encrypt=openssl --password hunter2
```

---

## 📦 ZIP Archives

```bash
fancy-tar folder/ --zip
fancy-tar folder/ --zip --password hunter2
```

### ⚠️ ZIP Encryption Warning
```
🔐 Warning: Classic ZIP encryption is insecure.
   • Easily broken with modern tools
   • Not suitable for confidential data
💡 Use GPG or OpenSSL for better security.
```

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
