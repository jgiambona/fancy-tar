#!/bin/bash

set -e

echo "🔧 Installing fancy-tar..."

# Target install paths
BIN_DIR="/usr/local/bin"
MAN_DIR="/usr/local/share/man/man1"
BASH_COMPLETION_DIR="/usr/local/share/bash-completion/completions"
ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"
FISH_COMPLETION_DIR="/usr/local/share/fish/vendor_completions.d"

# 1. Install main script
echo "📥 Installing script to $BIN_DIR"
install -Dm755 scripts/fancy_tar_progress.sh "$BIN_DIR/fancy-tar"

# 2. Install man page
echo "📘 Installing man page to $MAN_DIR"
mkdir -p "$MAN_DIR"
cp docs/fancy-tar.1 "$MAN_DIR/"
gzip -f "$MAN_DIR/fancy-tar.1"

# 3. Install shell completions
echo "🧠 Installing shell completions..."

mkdir -p "$BASH_COMPLETION_DIR"
mkdir -p "$ZSH_COMPLETION_DIR"
mkdir -p "$FISH_COMPLETION_DIR"

cp completions/fancy-tar.bash "$BASH_COMPLETION_DIR/fancy-tar"
cp completions/fancy-tar.zsh "$ZSH_COMPLETION_DIR/_fancy-tar"
cp completions/fancy-tar.fish "$FISH_COMPLETION_DIR/fancy-tar.fish"

echo "✅ fancy-tar installed successfully!"
echo "You can now run: fancy-tar -h"

