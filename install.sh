#!/bin/bash

set -e

echo "🔧 Installing fancy-tar..."

# Determine Homebrew prefix (macOS M1/M2 uses /opt/homebrew)
BREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/usr/local")

# Paths
BIN_DIR="$BREW_PREFIX/bin"
MAN_DIR="$BREW_PREFIX/share/man/man1"
BASH_COMPLETION_DIR="$BREW_PREFIX/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$BREW_PREFIX/share/zsh/site-functions"
chmod +x "$BIN_DIR/fancy-tar"
FISH_COMPLETION_DIR="$BREW_PREFIX/share/fish/vendor_completions.d"

# 1. Install main script
echo "📥 Installing script to $BIN_DIR"
install -Dm755 scripts/fancy_tar_progress.sh "$BIN_DIR/fancy-tar"

# 2. Install man page
echo "📘 Installing man page to $MAN_DIR"
mkdir -p "$MAN_DIR"
cp docs/fancy-tar.1 "$MAN_DIR/"
gzip -f "$MAN_DIR/fancy-tar.1"

# 3. Install completions
echo "🧠 Installing shell completions..."

mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$FISH_COMPLETION_DIR"

cp completions/fancy-tar.bash "$BASH_COMPLETION_DIR/fancy-tar"
cp completions/fancy-tar.zsh "$ZSH_COMPLETION_DIR/_fancy-tar"
cp completions/fancy-tar.fish "$FISH_COMPLETION_DIR/fancy-tar.fish"

echo "✅ fancy-tar installed!"
echo "💡 Try: fancy-tar -h or fancy-tar -<TAB> for autocompletion"
