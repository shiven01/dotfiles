#!/usr/bin/env bash
# =============================================================================
# tmux config installer
# Links the dotfiles tmux config into ~/.config/tmux/tmux.conf.
# Safe to run multiple times (idempotent).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FILE="$SCRIPT_DIR/settings.conf"
LIVE_FILE="$HOME/.config/tmux/tmux.conf"
LIVE_DIR="$(dirname "$LIVE_FILE")"

mkdir -p "$LIVE_DIR"

if [[ -L "$LIVE_FILE" && "$(readlink "$LIVE_FILE")" == "$REPO_FILE" ]]; then
  echo "[tmux] Symlink already correct: $LIVE_FILE -> $REPO_FILE"
elif [[ -L "$LIVE_FILE" ]]; then
  echo "[tmux] Updating symlink: $LIVE_FILE -> $REPO_FILE"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
elif [[ -f "$LIVE_FILE" ]]; then
  echo "[tmux] Backing up existing file: $LIVE_FILE -> ${LIVE_FILE}.bak"
  mv "$LIVE_FILE" "${LIVE_FILE}.bak"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[tmux] Symlink created: $LIVE_FILE -> $REPO_FILE"
else
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[tmux] Symlink created: $LIVE_FILE -> $REPO_FILE"
fi
