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

# --- LLM tool directories ---
echo "==> Syncing LLM tool configs"
mkdir -p "$HOME/.claude" "$HOME/.copilot" "$HOME/.vibe/prompts"

for dir in "$HOME/.claude" "$HOME/.copilot" "$HOME/.vibe"; do
  cp -r "$REPO_DIR/agents" "$dir/"
  cp -r "$REPO_DIR/commands" "$dir/"
  cp -r "$REPO_DIR/skills" "$dir/"
done

# --- Global instructions ---
cp "$REPO_DIR/global-instructions.md" "$HOME/.claude/CLAUDE.md"
cp "$REPO_DIR/global-instructions.md" "$HOME/.copilot/copilot-instructions.md"
cp "$REPO_DIR/global-instructions.md" "$HOME/.vibe/prompts/cli.md"

# --- Claude Code specifics ---
echo "==> Syncing Claude Code config"
cp "$REPO_DIR/claude-code/claude-statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
if [ -f "$HOME/.claude/settings.json" ]; then
  jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" "$REPO_DIR/claude-code/claude-global-settings.json" > "$HOME/.claude/settings.json.tmp"
  mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
else
  cp "$REPO_DIR/claude-code/claude-global-settings.json" "$HOME/.claude/settings.json"
fi

# --- Bin scripts ---
echo "==> Syncing commands to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/bin/artifact-sync" "$HOME/.local/bin/"
cp "$REPO_DIR/bin/machine-sync-remote" "$HOME/.local/bin/"

echo "==> Done! Open a new terminal or run: source ~/.bashrc"
