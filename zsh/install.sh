#!/usr/bin/env bash
# =============================================================================
# Zsh config installer
# Links the dotfiles zsh config into ~/.zshrc.
# Safe to run multiple times (idempotent).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FILE="$SCRIPT_DIR/settings.zsh"
LIVE_FILE="$HOME/.zshrc"

if [[ -L "$LIVE_FILE" && "$(readlink "$LIVE_FILE")" == "$REPO_FILE" ]]; then
  echo "[zsh] Symlink already correct: $LIVE_FILE -> $REPO_FILE"
elif [[ -L "$LIVE_FILE" ]]; then
  echo "[zsh] Updating symlink: $LIVE_FILE -> $REPO_FILE"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
elif [[ -f "$LIVE_FILE" ]]; then
  echo "[zsh] Backing up existing file: $LIVE_FILE -> ${LIVE_FILE}.bak"
  mv "$LIVE_FILE" "${LIVE_FILE}.bak"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[zsh] Symlink created: $LIVE_FILE -> $REPO_FILE"
else
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[zsh] Symlink created: $LIVE_FILE -> $REPO_FILE"
fi
