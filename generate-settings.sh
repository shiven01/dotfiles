#!/usr/bin/env bash
# =============================================================================
# dotfiles — centralized generate-settings script
#
# Pulls the live config from each tool's real location into the dotfiles repo,
# so the repo always reflects what is actually running on the system.
#
# Each section reads from a symlink that points at the live config file,
# copies it into the repo, and redacts secrets where needed.
#
# Required environment variables (only for Zed):
#   CONTEXT7_API_KEY  — not needed here; used at install time, not sync time
#
# Usage:
#   ./generate-settings.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== generate-settings: syncing live configs into dotfiles repo ==="
echo ""

# =============================================================================
# === RSS CONFIG ===
# Syncs NetNewsWire OPML subscriptions from the live location.
# Live file: ~/Library/Containers/com.ranchero.NetNewsWire-Evergreen/Data/
#            Library/Application Support/NetNewsWire/Accounts/OnMyMac/Subscriptions.opml
# =============================================================================
echo "--- [rss] ---"

RSS_LIVE="$HOME/Library/Containers/com.ranchero.NetNewsWire-Evergreen/Data/Library/Application Support/NetNewsWire/Accounts/OnMyMac/Subscriptions.opml"
RSS_OUTPUT="$SCRIPT_DIR/rss/settings.opml"

if [[ -f "$RSS_LIVE" ]]; then
  cp "$RSS_LIVE" "$RSS_OUTPUT"
  echo "[rss] Done. Settings written to: $RSS_OUTPUT"
else
  echo "[rss] WARNING: Live OPML file not found: $RSS_LIVE" >&2
  echo "[rss]   NetNewsWire may not be installed or has not synced yet." >&2
fi
echo ""

# =============================================================================
# === TMUX CONFIG ===
# Syncs ~/.config/tmux/tmux.conf into the repo.
# Live file: ~/.config/tmux/tmux.conf
# =============================================================================
echo "--- [tmux] ---"

TMUX_LIVE="$HOME/.config/tmux/tmux.conf"
TMUX_OUTPUT="$SCRIPT_DIR/tmux/settings.conf"

if [[ -f "$TMUX_LIVE" ]]; then
  cp "$TMUX_LIVE" "$TMUX_OUTPUT"
  echo "[tmux] Done. Settings written to: $TMUX_OUTPUT"
else
  echo "[tmux] WARNING: Live tmux config not found: $TMUX_LIVE" >&2
fi
echo ""

# =============================================================================
# === ZED CONFIG ===
# Syncs ~/.config/zed/settings.json into the repo, redacting any secrets.
# Also syncs ~/.config/zed/keymap.json directly (no secrets).
#
# The template file (settings.template.jsonc) is what gets committed.
# The generated file (settings.jsonc) is in .gitignore and is what Zed reads.
#
# Secret handling:
#   - gitleaks scans the live file for secrets
#   - Any found secrets are replaced with {{CONTEXT7_API_KEY}} in the template
#   - The template is safe to commit; the generated file is not
#
# Requires: gitleaks (brew install gitleaks)
# =============================================================================
echo "--- [zed] ---"

ZED_LIVE="$HOME/.config/zed/settings.json"
ZED_TEMPLATE="$SCRIPT_DIR/zed/settings.template.jsonc"
ZED_KEYMAP_LIVE="$HOME/.config/zed/keymap.json"
ZED_KEYMAP_OUTPUT="$SCRIPT_DIR/zed/keymap.json"

if [[ ! -f "$ZED_LIVE" ]]; then
  echo "[zed] WARNING: Live Zed settings not found: $ZED_LIVE" >&2
else
  if ! command -v gitleaks &>/dev/null; then
    echo "[zed] ERROR: gitleaks is not installed. Install with: brew install gitleaks" >&2
    echo "[zed]   Skipping Zed config sync to avoid committing secrets." >&2
  else
    TMPDIR_WORK="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_WORK"' EXIT

    TEMP_SETTINGS="$TMPDIR_WORK/settings.json"
    REPORT_FILE="$TMPDIR_WORK/gitleaks-report.json"

    cp "$ZED_LIVE" "$TEMP_SETTINGS"

    echo "[zed] Running gitleaks scan..."
    gitleaks_exit=0
    gitleaks detect \
      --no-git \
      --source "$TMPDIR_WORK" \
      --report-format json \
      --report-path "$REPORT_FILE" \
      2>/dev/null \
      || gitleaks_exit=$?

    if [[ $gitleaks_exit -ge 2 ]]; then
      echo "[zed] ERROR: gitleaks encountered an unexpected error (exit $gitleaks_exit)." >&2
      exit 1
    fi

    if [[ -f "$REPORT_FILE" && -s "$REPORT_FILE" ]]; then
      echo "[zed] Secrets found — redacting and writing template..."
      python3 - "$TEMP_SETTINGS" "$REPORT_FILE" "$ZED_TEMPLATE" <<'PYEOF'
import json, sys, re

settings_path = sys.argv[1]
report_path   = sys.argv[2]
output_path   = sys.argv[3]

with open(settings_path, "r", encoding="utf-8") as f:
    content = f.read()

with open(report_path, "r", encoding="utf-8") as f:
    findings = json.load(f)

count = 0
for finding in findings:
    secret = finding.get("Secret", "")
    rule_id = finding.get("RuleID", "unknown")
    if secret and secret in content:
        # Use a descriptive placeholder based on the rule
        placeholder = "{{CONTEXT7_API_KEY}}" if "context7" in rule_id.lower() or "ctx7" in secret.lower() else "{{REDACTED}}"
        content = content.replace(f'"{secret}"', f'"{placeholder}"')
        count += 1
        print(f"  Redacted secret matching rule '{rule_id}' -> {placeholder}")

if count == 0:
    print("  No secrets found to redact.")

with open(output_path, "w", encoding="utf-8") as f:
    f.write(content)
PYEOF
      echo "[zed] Template written to: $ZED_TEMPLATE"
    else
      echo "[zed] No secrets detected. Copying as template..."
      cp "$TEMP_SETTINGS" "$ZED_TEMPLATE"
      echo "[zed] Template written to: $ZED_TEMPLATE"
    fi

    trap - EXIT
    rm -rf "$TMPDIR_WORK"
  fi
fi

if [[ -f "$ZED_KEYMAP_LIVE" ]]; then
  cp "$ZED_KEYMAP_LIVE" "$ZED_KEYMAP_OUTPUT"
  echo "[zed] Keymap written to: $ZED_KEYMAP_OUTPUT"
else
  echo "[zed] WARNING: Live Zed keymap not found: $ZED_KEYMAP_LIVE" >&2
fi
echo ""

# =============================================================================
# === ZSH CONFIG ===
# Syncs ~/.zshrc into the repo.
# Live file: ~/.zshrc
# =============================================================================
echo "--- [zsh] ---"

ZSH_LIVE="$HOME/.zshrc"
ZSH_OUTPUT="$SCRIPT_DIR/zsh/settings.zsh"

if [[ -f "$ZSH_LIVE" ]]; then
  cp "$ZSH_LIVE" "$ZSH_OUTPUT"
  echo "[zsh] Done. Settings written to: $ZSH_OUTPUT"
else
  echo "[zsh] WARNING: ~/.zshrc not found." >&2
fi
echo ""

echo "=== generate-settings complete ==="
