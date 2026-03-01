#!/bin/bash
# Sync configs from repo to machine. Safe to re-run anytime.
# Usage: bash ~/shared-safe-config/sync.sh
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Syncing configs from $REPO_DIR"

# --- Shell config (append, idempotent via marker block) ---
echo "==> Syncing bashrc"
MARKER_START="# >>> shared-safe-config >>>"
MARKER_END="# <<< shared-safe-config <<<"
if [ -f "$HOME/.bashrc" ]; then
  sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOME/.bashrc"
fi
{
  echo "$MARKER_START"
  cat "$REPO_DIR/dot_bashrc"
  echo "$MARKER_END"
} >> "$HOME/.bashrc"

# --- Git config ---
echo "==> Syncing gitconfig"
cp "$REPO_DIR/dot_gitconfig" "$HOME/.gitconfig"

# --- LLM tool configs ---
echo "==> Syncing LLM tool configs"
mkdir -p "$HOME/.claude" "$HOME/.copilot"

# --- Claude Code ---
echo "==> Syncing Claude Code config"
cp "$REPO_DIR/claude-code/claude-statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
if [ -f "$HOME/.claude/settings.json" ]; then
  jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" "$REPO_DIR/claude-code/claude-global-settings.json" > "$HOME/.claude/settings.json.tmp"
  mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
else
  cp "$REPO_DIR/claude-code/claude-global-settings.json" "$HOME/.claude/settings.json"
fi

# --- Copilot CLI ---
echo "==> Syncing Copilot CLI config"
cp "$REPO_DIR/copilot-cli/copilot-commit-message-instructions.md" "$HOME/.copilot/"
cp "$REPO_DIR/copilot-cli/copilot-statusline.sh" "$HOME/.copilot/copilot-statusline.sh"
chmod +x "$HOME/.copilot/copilot-statusline.sh"
if [ -f "$HOME/.copilot/config.json" ]; then
  jq -s '.[0] * .[1]' "$HOME/.copilot/config.json" "$REPO_DIR/copilot-cli/config.json" > "$HOME/.copilot/config.json.tmp"
  mv "$HOME/.copilot/config.json.tmp" "$HOME/.copilot/config.json"
else
  cp "$REPO_DIR/copilot-cli/config.json" "$HOME/.copilot/config.json"
fi

# --- Bin scripts ---
echo "==> Syncing machine-sync to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
sed "s|^REPO=.*|REPO=\"$REPO_DIR\"|" "$REPO_DIR/bin/machine-sync" > "$HOME/.local/bin/machine-sync"
chmod +x "$HOME/.local/bin/machine-sync"

echo "==> Done! Open a new terminal or run: source ~/.bashrc"
