# 🎁 fancy-tar

**Smarter, secure, and friendlier `tar` with progress bars, encryption, hash checking, tree view, desktop notifications, and more.**

Created by [Jason Giambona](https://github.com/jgiambona) — for people who want `tar` but actually human-readable.

---

## 🚀 Features

- 📦 Wraps `tar` + `gzip` with a friendly UI
- 📊 Real-time progress display
- 🌳 Tree-style file preview
- 🕒 Time elapsed and ETA
- 🔐 Optional archive encryption (GPG or OpenSSL)
- 📑 SHA256 hash output for integrity checking
- 📂 Open archive location after saving
- 🖥️ Desktop notifications
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
fancy-tar [options] <file1> [file2 ...]
```

---

## 🧰 Options

| Option                    | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `-o <file>`               | Set output filename (default: archive.tar.gz)                               |
| `-n`                      | Create a `.tar` file (no gzip compression)                                  |
| `-s`                      | Enable slow mode (simulate compression)                                     |
| `-x`                      | Open output folder after archiving                                          |
| `-t`, `--tree`            | Show hierarchical view of files before archiving                            |
| `--no-recursion`          | Don’t include subdirectory contents                                         |
| `--hash`                  | Generate a `.sha256` hash file for the archive                              |
| `--encrypt[=gpg|openssl]` | Encrypt archive with `gpg` (default) or `openssl`                           |
| `--recipient <id>`        | Use GPG public key to encrypt archive (for GPG asymmetric encryption)        |
| `--password <pass>`       | Use provided password for encryption (otherwise prompted interactively)     |
| `-h`, `--help`            | Show this help message                                                      |

---

## 💡 Examples

### 📦 Create a simple gzip archive
```bash
fancy-tar my-folder
```

### 🌳 Show tree view before archiving
```bash
fancy-tar --tree my-folder
```

### 🐌 Simulate a slower backup (debug/test)
```bash
fancy-tar -s my-folder
```

### 🗃 Archive without gzip compression
```bash
fancy-tar -n -o raw.tar my-folder
```

### 📏 Output SHA256 hash file
```bash
fancy-tar --hash my-folder
# Creates archive.tar.gz and archive.tar.gz.sha256
```

---

## 🔐 Encryption Examples

### ✅ GPG symmetric encryption (password)
```bash
fancy-tar --encrypt=gpg my-folder
# You will be prompted for a password
```

Or specify the password:
```bash
fancy-tar --encrypt=gpg --password hunter2 my-folder
```

### ✅ GPG public key encryption
```bash
fancy-tar --encrypt=gpg --recipient jason@example.com my-folder
```

💡 The `--recipient` value can be an email, user ID, key ID, or fingerprint.  
If the key isn’t found, fancy-tar will suggest available keys and exit cleanly.

---

### ✅ OpenSSL password-based AES encryption
```bash
fancy-tar --encrypt=openssl my-folder
# You will be prompted for a password
```

Or pass it directly:
```bash
fancy-tar --encrypt=openssl --password hunter2 my-folder
```

This creates: `archive.tar.gz` encrypted using AES-256-CBC with salt.

---

## 🔐 What if you use both --encrypt and --password?

- `--encrypt=gpg` + `--password` → symmetric GPG encryption
- `--encrypt=gpg` + `--recipient` → public key encryption
- `--encrypt=openssl` → always password-based

If no `--password` is provided, the script will securely prompt for one (silent input).

---

## 🔑 Missing a recipient?

If GPG can’t find the specified recipient, you’ll see:
```
❌ No public key found for recipient: bob@example.com
```

And fancy-tar will list your available keys:
```
🔑 Available recipients:
Jason Giambona <jason@example.com>
```

To add a missing key:
```bash
gpg --import bob-public.asc
```

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
