# dotfiles

A unified dotfiles repository managing configuration for RSS (NetNewsWire), tmux, Zed, and Zsh. All configs are version-controlled here; symlinks connect each config to its expected system location.

## Repository Structure

```
dotfiles/
├── rss/
│   ├── settings.opml          # NetNewsWire feed subscriptions (OPML)
│   └── install.sh             # Syncs live OPML and creates symlink
├── tmux/
│   ├── settings.conf          # tmux configuration
│   └── install.sh             # Creates symlink at ~/.config/tmux/tmux.conf
├── zed/
│   ├── settings.template.jsonc  # Zed settings with {{CONTEXT7_API_KEY}} placeholder (committed)
│   ├── settings.jsonc           # Generated settings with real key (gitignored, what Zed reads)
│   └── install.sh               # Generates settings.jsonc and creates symlink
├── zsh/
│   ├── settings.zsh           # Zsh config / .zshrc contents
│   └── install.sh             # Creates symlink at ~/.zshrc
├── install.sh                 # Root installer — runs all sub-installers
├── generate-settings.sh       # Pulls live configs into repo (for committing updates)
├── .gitleaks.toml             # gitleaks secret scanning config
└── .gitignore
```

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| git | Version control | `xcode-select --install` |
| gitleaks | Secret scanning before sync | `brew install gitleaks` |
| python3 | Secret redaction in generate-settings.sh | Included on macOS |
| NetNewsWire | RSS reader (optional) | Mac App Store |
| tmux | Terminal multiplexer (optional) | `brew install tmux` |
| Zed | Code editor (optional) | https://zed.dev |
| fnm | Node version manager (used in zsh config) | `brew install fnm` |

## Environment Variables

| Variable | Required | Purpose | Affects |
|----------|----------|---------|---------|
| `CONTEXT7_API_KEY` | Yes (for Zed) | Context7 MCP server API key | `zed/install.sh`, `install.sh` |

## Setup Instructions

### 1. Clone the repo

```bash
git clone https://github.com/shivenshekar/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

### 2. Set required environment variables

Add this to your shell profile (e.g. `~/.zshrc` or `~/.bashrc`) — or export it in your current session:

```bash
export CONTEXT7_API_KEY=ctx7sk-<your-key-here>
```

You can find your Context7 API key at https://context7.com.

### 3. Run the installer

```bash
./install.sh
```

This will:
- Copy the live NetNewsWire OPML subscriptions into `rss/settings.opml`
- Create a symlink: `~/.config/tmux/tmux.conf` -> `tmux/settings.conf`
- Generate `zed/settings.jsonc` with your real API key substituted in, then symlink `~/.config/zed/settings.json` -> `zed/settings.jsonc`
- Create a symlink: `~/.zshrc` -> `zsh/settings.zsh`

The installer is idempotent — safe to run multiple times.

### 4. Syncing changes back to the repo

After making changes to your live configs (e.g. editing `~/.zshrc` or adding RSS feeds in NetNewsWire), run:

```bash
./generate-settings.sh
```

This pulls the live configs back into the repo, with secrets redacted. Then commit and push.

## Zed API Key Handling

The Zed config uses a Context7 MCP server that requires an API key. This key must **never** be committed to the repo.

The system works as follows:

1. **Template** (`zed/settings.template.jsonc`) — committed to git, contains `"{{CONTEXT7_API_KEY}}"` as a placeholder.
2. **Generated file** (`zed/settings.jsonc`) — gitignored, contains your real API key, is what Zed actually reads.
3. **`zed/install.sh`** — substitutes the placeholder with `$CONTEXT7_API_KEY` and writes the generated file.

If you run `install.sh` without setting `CONTEXT7_API_KEY`, the script will fail with a clear error message before creating any files.

If you run `generate-settings.sh`, gitleaks scans your live Zed settings and replaces any detected secrets with `{{CONTEXT7_API_KEY}}` in the template before writing to the repo.

## Symlink Map

| Config | System path | Repo path |
|--------|-------------|-----------|
| NetNewsWire feeds | `~/Library/Containers/com.ranchero.NetNewsWire-Evergreen/.../Subscriptions.opml` | `rss/settings.opml` |
| tmux | `~/.config/tmux/tmux.conf` | `tmux/settings.conf` |
| Zed | `~/.config/zed/settings.json` | `zed/settings.jsonc` (generated, gitignored) |
| Zsh | `~/.zshrc` | `zsh/settings.zsh` |

## Adding New Configs

1. Create a new subdirectory: `mkdir mynewconfig/`
2. Copy your config file in and give it a descriptive name (e.g. `mynewconfig/settings.conf`).
3. Write `mynewconfig/install.sh` following the pattern in `tmux/install.sh`:
   - Define `REPO_FILE` and `LIVE_FILE`
   - Back up existing files, create the symlink with `ln -sfn`
4. Add a call to it in the root `install.sh` under a clearly labeled section.
5. Add a corresponding sync block in `generate-settings.sh` to pull live changes back.
6. If the config contains secrets, add the generated file to `.gitignore` and use a template pattern like the Zed config.

## Security Notes

- `zed/settings.jsonc` (the generated file with the real API key) is listed in `.gitignore` and will never be committed.
- `.gitleaks.toml` configures gitleaks to scan for the Context7 API key pattern. Run `gitleaks detect --source . --no-git` at any time to verify no secrets are present in committed files.
- The `generate-settings.sh` script runs gitleaks before writing the Zed template and redacts any detected secrets.
- `.env` files are also gitignored as an additional safeguard.
