# 🎁 fancy-tar

**A smarter, prettier `tar` with progress bars, file info, ETA, and desktop notifications.**  
Built by [Jason Giambona](https://github.com/jgiambona) — because `tar czvf` deserves some ✨.

---

## 🚀 Features

- 📦 Wraps `tar` and `gzip` with a friendly UI
- 📊 Real-time progress bar using `pv`
- 📁 Shows current file, total files, and total archive size
- ⏱️ Estimated time remaining and total time elapsed
- 🖥️ Desktop notifications when complete (macOS and Linux)
- 🐚 Autocompletion for Bash, Zsh, and Fish
- 🔧 Options for gzip, slow mode, shallow archiving, tree view, hash output

---

## 📥 Installation

```bash
brew tap jgiambona/fancy-tar
brew install fancy-tar
```

---

## 🧠 Usage

```bash
fancy-tar [options] file1 [file2 ...]
```

### 🌶 Options:

| Option             | Description                                             |
|--------------------|---------------------------------------------------------|
| `-o <file>`        | Output archive name (default: `archive.tar.gz`)         |
| `-n`               | No gzip compression (create `.tar` only)                |
| `-s`               | Slow mode (simulate slow compression)                   |
| `-x`               | Open output folder when done                            |
| `-t`, `--tree`     | Show file hierarchy before archiving                    |
| `--no-recursion`   | Do not include directory contents (shallow archive)     |
| `--hash`           | Output SHA256 hash file alongside the archive           |
| `-h`, `--help`     | Show help                                               |

---

## 💡 Examples

### Basic gzip archive:

```bash
fancy-tar my-folder
```

### Tree-view before archiving:

```bash
fancy-tar --tree my-folder
```

### With accurate progress output and hash:

```bash
fancy-tar --hash my-folder
# ✅ Done! Archive created: archive.tar.gz
# 🔐 SHA256 hash saved to: archive.tar.gz.sha256
```

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)
