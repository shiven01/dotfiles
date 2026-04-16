#!/usr/bin/env bash
# =============================================================================
# RSS Feeds config installer
# Copies the live NetNewsWire OPML subscriptions file into the dotfiles repo,
# then creates a symlink from the repo file to the live location.
# Safe to run multiple times (idempotent).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FILE="$SCRIPT_DIR/settings.opml"
LIVE_FILE="$HOME/Library/Containers/com.ranchero.NetNewsWire-Evergreen/Data/Library/Application Support/NetNewsWire/Accounts/OnMyMac/Subscriptions.opml"

# === Sync live → repo ===
if [[ -f "$LIVE_FILE" ]]; then
  cp "$LIVE_FILE" "$REPO_FILE"
  echo "[rss] Synced subscriptions to: $REPO_FILE"
else
  echo "[rss] WARNING: Live OPML file not found at: $LIVE_FILE" >&2
  echo "[rss]   NetNewsWire may not be installed, or has never synced." >&2
fi

# === Create symlink: live location → repo file ===
LIVE_DIR="$(dirname "$LIVE_FILE")"
if [[ ! -d "$LIVE_DIR" ]]; then
  echo "[rss] Skipping symlink — live directory does not exist: $LIVE_DIR" >&2
  exit 0
fi

if [[ -L "$LIVE_FILE" ]]; then
  echo "[rss] Symlink already exists: $LIVE_FILE -> $(readlink "$LIVE_FILE")"
elif [[ -f "$LIVE_FILE" ]]; then
  echo "[rss] Backing up existing file: $LIVE_FILE -> ${LIVE_FILE}.bak"
  mv "$LIVE_FILE" "${LIVE_FILE}.bak"
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[rss] Symlink created: $LIVE_FILE -> $REPO_FILE"
else
  ln -sfn "$REPO_FILE" "$LIVE_FILE"
  echo "[rss] Symlink created: $LIVE_FILE -> $REPO_FILE"
fi
