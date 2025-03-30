# 🎁 fancy-tar

**Smarter archiving made simple. Create `.tar.gz`, `.zip`, or encrypted archives with progress bars, file tree previews, and SHA256 hashing. Now with 7z support!**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 Create `.tar.gz`, `.zip`, or `.7z` archives
- 🔐 Encrypt with GPG, OpenSSL, or 7z AES
- 🔑 Password confirmation (symmetric encryption)
- 📁 Tree view preview
- ✅ SHA256 hash generation (`--hash`)
- ⚠️ Security warning for ZIP encryption
- 🧹 Cleans up incomplete archives on failure
- 🧠 Recipient validation and GPG fallback
- 🐚 Shell completions for Bash, Zsh, Fish
- 🔢 `--version` support

---

## 🧰 Usage

```bash
fancy-tar [options] <files...>
```

---

## 🧠 Options

| Option                    | Description                                                               |
|---------------------------|---------------------------------------------------------------------------|
| `-o <file>`               | Set output archive filename                                               |
| `-n`                      | No gzip compression (create `.tar`)                                       |
| `-s`                      | Simulate slow mode                                                        |
| `-x`                      | Open output folder when done                                              |
| `-t`, `--tree`            | Show file structure preview                                               |
| `--no-recursion`          | Shallow archive (no subdirectories)                                       |
| `--hash`                  | Output SHA256 hash                                                        |
| `--zip`                   | Create a `.zip` archive (classic encryption)                              |
| `--encrypt=METHOD`        | Encryption method: `gpg`, `openssl`, or `7z`                              |
| `--recipient <id>`        | GPG recipient (email, fingerprint, or key ID)                             |
| `--password <pass>`       | Password for encryption (prompted if omitted)                             |
| `--version`               | Show current version                                                      |
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
# Prompts for password + confirmation
```

### OpenSSL
```bash
fancy-tar data/ --encrypt=openssl --password secret
```

### 7z (AES encrypted)
```bash
fancy-tar folder/ --encrypt=7z --password secret
```

---

## 📦 ZIP Archive Examples

```bash
fancy-tar logs/ --zip
fancy-tar logs/ --zip --password mypass
```

⚠️ ZIP Encryption Warning:
> Classic ZIP password protection is not secure.  
> Use GPG, OpenSSL, or 7z for secure encryption.

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
