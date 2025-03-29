# 🎁 fancy-tar

**Smarter archiving made simple. Create `.tar.gz`, `.zip`, or encrypted archives with progress bars, password prompts, file tree previews, and hashing.**

Created by [Jason Giambona](https://github.com/jgiambona)

---

## 🚀 Features

- 📦 Gzip or ZIP archiving with tar-like syntax
- 🔐 GPG or OpenSSL encryption with optional recipient or password
- 🔑 Password confirmation to avoid typos
- 📁 Tree view preview
- ✅ SHA256 hash generation (`--hash`)
- ⚠️ Security warning for classic ZIP encryption
- 🧹 Cleans up incomplete archives on error
- 🧠 Validates recipients, default to symmetric GPG
- 🐚 Shell completions for Bash, Zsh, Fish
- 🔢 `--version` support

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
| `-n`                      | No gzip compression (create `.tar`)                                       |
| `-s`                      | Simulate slow mode (for fun or testing)                                   |
| `-x`                      | Open output folder when done                                              |
| `-t`, `--tree`            | Show file structure preview                                               |
| `--no-recursion`          | Shallow archive (no subdirectories)                                       |
| `--hash`                  | Output SHA256 hash alongside archive                                      |
| `--encrypt[=gpg|openssl]` | Encrypt archive with GPG or OpenSSL                                       |
| `--recipient <id>`        | GPG recipient (email, fingerprint, or key ID)                             |
| `--password <pass>`       | Password for encryption (or interactively prompted)                       |
| `--zip`                   | Create a `.zip` archive (classic ZIP encryption with password support)    |
| `--version`               | Print current version                                                     |
| `-h`, `--help`            | Show help                                                                 |

---

## 🔐 Encryption Examples

### GPG (recipient-based public key)
```bash
fancy-tar secure/ --encrypt=gpg --recipient your@email.com
```

### GPG (symmetric encryption)
```bash
fancy-tar secrets/ --encrypt=gpg
# Will prompt for password + confirmation
```

### OpenSSL
```bash
fancy-tar private/ --encrypt=openssl --password mypass
```

---

## 📦 ZIP Archives

```bash
fancy-tar reports/ --zip
fancy-tar reports/ --zip --password secret
fancy-tar reports/ --zip --encrypt --password secret
```

⚠️ Classic ZIP encryption is not secure:
- Can be cracked easily
- Not authenticated
💡 Use `--encrypt=gpg` or `--encrypt=openssl` for strong encryption.

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
