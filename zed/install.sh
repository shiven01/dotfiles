#!/usr/bin/env bash
# =============================================================================
# Zed config installer
# 1. Generates the live settings.jsonc by substituting {{CONTEXT7_API_KEY}}
#    from the CONTEXT7_API_KEY environment variable, then symlinks it into place.
# 2. Symlinks keymap.json directly (no secrets — no template needed).
# Safe to run multiple times (idempotent).
#
# Requires:
#   CONTEXT7_API_KEY  — your Context7 API key (set in ~/.zshrc or .env)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_DIR="$HOME/.config/zed"

# --- Validate required env vars ---
if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
  echo "[zed] ERROR: CONTEXT7_API_KEY is not set." >&2
  echo "[zed]   Export it before running: export CONTEXT7_API_KEY=ctx7sk-..." >&2
  exit 1
fi

mkdir -p "$LIVE_DIR"

# --- Generate settings from template ---
TEMPLATE="$SCRIPT_DIR/settings.template.jsonc"
GENERATED="$SCRIPT_DIR/settings.jsonc"
LIVE_SETTINGS="$LIVE_DIR/settings.json"

echo "[zed] Generating settings from template..."
sed "s/{{CONTEXT7_API_KEY}}/$CONTEXT7_API_KEY/g" "$TEMPLATE" > "$GENERATED"
echo "[zed] Settings written to: $GENERATED"

if [[ -L "$LIVE_SETTINGS" && "$(readlink "$LIVE_SETTINGS")" == "$GENERATED" ]]; then
  echo "[zed] Symlink already correct: $LIVE_SETTINGS -> $GENERATED"
elif [[ -L "$LIVE_SETTINGS" ]]; then
  echo "[zed] Updating symlink: $LIVE_SETTINGS -> $GENERATED"
  ln -sfn "$GENERATED" "$LIVE_SETTINGS"
elif [[ -f "$LIVE_SETTINGS" ]]; then
  echo "[zed] Backing up existing file: $LIVE_SETTINGS -> ${LIVE_SETTINGS}.bak"
  mv "$LIVE_SETTINGS" "${LIVE_SETTINGS}.bak"
  ln -sfn "$GENERATED" "$LIVE_SETTINGS"
  echo "[zed] Symlink created: $LIVE_SETTINGS -> $GENERATED"
else
  ln -sfn "$GENERATED" "$LIVE_SETTINGS"
  echo "[zed] Symlink created: $LIVE_SETTINGS -> $GENERATED"
fi

# --- Symlink keymap.json ---
REPO_KEYMAP="$SCRIPT_DIR/keymap.json"
LIVE_KEYMAP="$LIVE_DIR/keymap.json"

if [[ -L "$LIVE_KEYMAP" && "$(readlink "$LIVE_KEYMAP")" == "$REPO_KEYMAP" ]]; then
  echo "[zed] Symlink already correct: $LIVE_KEYMAP -> $REPO_KEYMAP"
elif [[ -L "$LIVE_KEYMAP" ]]; then
  echo "[zed] Updating symlink: $LIVE_KEYMAP -> $REPO_KEYMAP"
  ln -sfn "$REPO_KEYMAP" "$LIVE_KEYMAP"
elif [[ -f "$LIVE_KEYMAP" ]]; then
  echo "[zed] Backing up existing file: $LIVE_KEYMAP -> ${LIVE_KEYMAP}.bak"
  mv "$LIVE_KEYMAP" "${LIVE_KEYMAP}.bak"
  ln -sfn "$REPO_KEYMAP" "$LIVE_KEYMAP"
  echo "[zed] Symlink created: $LIVE_KEYMAP -> $REPO_KEYMAP"
else
  ln -sfn "$REPO_KEYMAP" "$LIVE_KEYMAP"
  echo "[zed] Symlink created: $LIVE_KEYMAP -> $REPO_KEYMAP"
fi
