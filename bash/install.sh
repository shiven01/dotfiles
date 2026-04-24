#!/usr/bin/env bash
# =============================================================================
# Bash / Terminal.app config installer
# Links the dotfiles Terminal.app plist into ~/Library/Preferences.
# Safe to run multiple times (idempotent).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FILE="$SCRIPT_DIR/settings.plist"
LIVE_FILE="$HOME/Library/Preferences/com.apple.Terminal.plist"

if [[ -L "$LIVE_FILE" && "$(readlink "$LIVE_FILE")" == "$REPO_FILE" ]]; then
  echo "[bash] Symlink already correct: $LIVE_FILE -> $REPO_FILE"
elif [[ -L "$LIVE_FILE" ]]; then
  echo "[bash] Updating symlink: $LIVE_FILE -> $REPO_FILE"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
elif [[ -f "$LIVE_FILE" ]]; then
  echo "[bash] Backing up existing file: $LIVE_FILE -> ${LIVE_FILE}.bak"
  mv "$LIVE_FILE" "${LIVE_FILE}.bak"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[bash] Symlink created: $LIVE_FILE -> $REPO_FILE"
else
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[bash] Symlink created: $LIVE_FILE -> $REPO_FILE"
fi
