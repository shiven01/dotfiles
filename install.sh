#!/usr/bin/env bash
# =============================================================================
# dotfiles — root installer
# Runs each config's install.sh to generate settings and create symlinks.
# Safe to run multiple times (idempotent).
#
# Required environment variables:
#   CONTEXT7_API_KEY  — Context7 API key used in Zed settings
#
# Usage:
#   export CONTEXT7_API_KEY=ctx7sk-...
#   ./install.sh
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Validate required environment variables ---
required_vars=("CONTEXT7_API_KEY")
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required environment variable '$var' is not set." >&2
    echo "  Export it before running: export $var=<value>" >&2
    exit 1
  fi
done

echo "=== dotfiles installer ==="
echo "DOTFILES_DIR: $DOTFILES_DIR"
echo ""

# === RSS Feeds ===
echo "--- [rss] ---"
bash "$DOTFILES_DIR/rss/install.sh"
echo ""

# === tmux ===
echo "--- [tmux] ---"
bash "$DOTFILES_DIR/tmux/install.sh"
echo ""

# === Zed ===
echo "--- [zed] ---"
bash "$DOTFILES_DIR/zed/install.sh"
echo ""

# === Zsh ===
echo "--- [zsh] ---"
bash "$DOTFILES_DIR/zsh/install.sh"
echo ""

echo "=== All configs installed successfully ==="
