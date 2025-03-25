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
- 🐚 Optional autocompletion for Bash, Zsh, and Fish
- 🔧 Options for gzip, slow mode, shallow archiving, and more

---

## 📥 Installation

### 🧃 Option 1: Homebrew (Recommended for macOS/Linux)

```bash
brew tap jgiambona/fancy-tar
brew install fancy-tar
```

### 📦 Option 2: RPM Package (Fedora, RHEL, etc.)

Download the latest `.rpm` file from the [Releases](https://github.com/jgiambona/fancy-tar/releases) page:

```bash
sudo dnf install fancy-tar-<version>.noarch.rpm
```

### 🛠 Option 3: Manual Install

```bash
git clone https://github.com/jgiambona/fancy-tar.git
cd fancy-tar
chmod +x scripts/fancy_tar_progress.sh
sudo ./install.sh
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
| `--no-recursion`   | Do not include directory contents (shallow archive)     |
| `-t`, `--tree`      | Show file hierarchy before archiving                   |
| `-h, --help`       | Show help                                               |

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

```bash
fancy-tar my-folder
```

### Shallow archive (top-level only):

```bash
fancy-tar --no-recursion my-folder
```

### Custom output name:

```bash
fancy-tar -o backup-2025.tar.gz my-folder another-folder
```

---

## 🎯 Autocompletion

Completions for Bash, Zsh, and Fish are installed automatically by `install.sh` or Homebrew.

---

## 🔧 Dev & Build

Build a new release tarball and RPM:
```bash
./scripts/build.sh  # (or just tag a release via GitHub)
```

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)

---

## 🤘 Contributing

PRs welcome! Want to add ZIP support, multithreading, or self-extraction? Fork and go wild.

---

## ❤️ Acknowledgements

- [pv](https://www.ivarch.com/programs/pv.shtml) — terminal progress bar tool
- Everyone who got sick of watching `tar` do nothing quietly

