#!/bin/bash
set -e
echo "🔧 Installing fancy-tar..."
BREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/usr/local")
BIN_DIR="$BREW_PREFIX/bin"
MAN_DIR="$BREW_PREFIX/share/man/man1"
BASH_COMPLETION_DIR="$BREW_PREFIX/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$BREW_PREFIX/share/zsh/site-functions"
FISH_COMPLETION_DIR="$BREW_PREFIX/share/fish/vendor_completions.d"
install -Dm755 scripts/fancy_tar_progress.sh "$BIN_DIR/fancy-tar"
chmod +x "$BIN_DIR/fancy-tar"
mkdir -p "$MAN_DIR"
cp docs/fancy-tar.1 "$MAN_DIR/"
gzip -f "$MAN_DIR/fancy-tar.1"
mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$FISH_COMPLETION_DIR"
cp completions/fancy-tar.bash "$BASH_COMPLETION_DIR/fancy-tar"
cp completions/fancy-tar.zsh "$ZSH_COMPLETION_DIR/_fancy-tar"
cp completions/fancy-tar.fish "$FISH_COMPLETION_DIR/fancy-tar.fish"
echo "✅ fancy-tar installed!"
