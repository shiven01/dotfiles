#!/usr/bin/env bash
# =============================================================================
# Zed config installer
# Generates the live settings.jsonc by substituting {{CONTEXT7_API_KEY}} from
# the CONTEXT7_API_KEY environment variable, then symlinks it into place.
# Safe to run multiple times (idempotent).
#
# Requires:
#   CONTEXT7_API_KEY  — your Context7 API key (set in ~/.zshrc or .env)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/settings.template.jsonc"
GENERATED="$SCRIPT_DIR/settings.jsonc"
LIVE_FILE="$HOME/.config/zed/settings.json"
LIVE_DIR="$(dirname "$LIVE_FILE")"

# --- Validate required env vars ---
if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
  echo "[zed] ERROR: CONTEXT7_API_KEY is not set." >&2
  echo "[zed]   Export it before running: export CONTEXT7_API_KEY=ctx7sk-..." >&2
  exit 1
fi

# --- Generate settings from template ---
echo "[zed] Generating settings from template..."
sed "s/{{CONTEXT7_API_KEY}}/$CONTEXT7_API_KEY/g" "$TEMPLATE" > "$GENERATED"
echo "[zed] Settings written to: $GENERATED"

# --- Create symlink: ~/.config/zed/settings.json → generated file ---
mkdir -p "$LIVE_DIR"

if [[ -L "$LIVE_FILE" && "$(readlink "$LIVE_FILE")" == "$GENERATED" ]]; then
  echo "[zed] Symlink already correct: $LIVE_FILE -> $GENERATED"
elif [[ -L "$LIVE_FILE" ]]; then
  echo "[zed] Updating symlink: $LIVE_FILE -> $GENERATED"
  ln -sfn "$GENERATED" "$LIVE_FILE"
elif [[ -f "$LIVE_FILE" ]]; then
  echo "[zed] Backing up existing file: $LIVE_FILE -> ${LIVE_FILE}.bak"
  mv "$LIVE_FILE" "${LIVE_FILE}.bak"
  ln -sfn "$GENERATED" "$LIVE_FILE"
  echo "[zed] Symlink created: $LIVE_FILE -> $GENERATED"
else
  ln -sfn "$GENERATED" "$LIVE_FILE"
  echo "[zed] Symlink created: $LIVE_FILE -> $GENERATED"
fi
