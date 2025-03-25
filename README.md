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
- 🔧 Options for gzip, slow mode, and auto-opening folder

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

This will install:
- `fancy-tar` to `/usr/local/bin`
- Man page
- Autocompletion for Bash, Zsh, and Fish

---

## 🧠 Usage

```bash
fancy-tar [options] file1 [file2 ...]
```

### 🌶 Options:

| Option       | Description                                  |
|--------------|----------------------------------------------|
| `-o <file>`  | Output archive name (default: `archive.tar.gz`) |
| `-n`         | No gzip compression (create `.tar` only)     |
| `-s`         | Slow mode (simulate slow compression)        |
| `-x`         | Open output folder when done                 |
| `-h`         | Show help                                    |

---

## 💡 Examples

### Basic gzip archive:

```bash
fancy-tar my-folder
```

### Custom output name:

```bash
fancy-tar -o backup-2025.tar.gz my-folder another-folder
```

### Create a raw `.tar` (no gzip):

```bash
fancy-tar -n -o archive.tar somefile.txt
```

### Slow mode with desktop notification:

```bash
fancy-tar -s big-folder
```

---

## 🎯 Autocompletion

Bash, Zsh, and Fish completions are installed with `install.sh` or via Homebrew.  
If you installed manually and want to activate it yourself:

### Bash:
```bash
source /usr/local/share/bash-completion/completions/fancy-tar
```

### Zsh:
```bash
autoload -U compinit && compinit
source /usr/local/share/zsh/site-functions/_fancy-tar
```

### Fish:
```bash
source /usr/local/share/fish/vendor_completions.d/fancy-tar.fish
```

---

## 🔧 Dev & Build

Build a new release tarball and RPM:
```bash
./scripts/build.sh  # (or just tag a release via GitHub)
```

This project is CI/CD integrated with:
- GitHub Actions
- RPM auto-building
- Homebrew formula auto-updating via `homebrew-fancy-tar`

---

## 📜 License

MIT License © [Jason Giambona](https://github.com/jgiambona)

---

## 🤘 Contributing

PRs welcome! Want to add ZIP support, multithreading, or self-extraction? Open an issue or fork and go wild.

---

## ❤️ Acknowledgements

- [pv](https://www.ivarch.com/programs/pv.shtml) — terminal progress bar tool
- Everyone who got sick of watching `tar` do nothing quietly

