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

# --- Install specs-sync CLI (bootstrap — must happen before specs sync) ---
echo "==> Installing specs-sync CLI"
mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/bin/specs-sync" "$HOME/.local/bin/specs-sync"
chmod +x "$HOME/.local/bin/specs-sync"

# --- LLM specs library (cold storage) ---
echo "==> Syncing specs to library"
LIBRARY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llm-specs"
mkdir -p "$LIBRARY_DIR"
cp -r "$REPO_DIR/skills" "$LIBRARY_DIR/"
cp -r "$REPO_DIR/commands" "$LIBRARY_DIR/"
cp -r "$REPO_DIR/agents" "$LIBRARY_DIR/"
cp "$REPO_DIR/library.json" "$LIBRARY_DIR/"

# Initialize global manifest if it doesn't exist
if [ ! -f "$LIBRARY_DIR/global-manifest.json" ]; then
  echo '{"activated":[]}' > "$LIBRARY_DIR/global-manifest.json"
fi

# --- Activate core specs + rebuild symlinks (Claude + Copilot only) ---
echo "==> Activating core specs (global symlinks)"
"$HOME/.local/bin/specs-sync" sync --quiet

# --- Vibe distribution (direct copies — Vibe has its own layout) ---
echo "==> Syncing Vibe specs"
mkdir -p "$HOME/.vibe/skills" "$HOME/.vibe/prompts" "$HOME/.vibe/agents"
cp -r "$REPO_DIR/skills"/* "$HOME/.vibe/skills/" 2>/dev/null || true
cp "$REPO_DIR/commands"/*.md "$HOME/.vibe/prompts/" 2>/dev/null || true
cp "$REPO_DIR/agents"/*.md "$HOME/.vibe/agents/" 2>/dev/null || true

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
sed "s|^REPO=.*|REPO=\"$REPO_DIR\"|" "$REPO_DIR/bin/machine-sync" > "$HOME/.local/bin/machine-sync"
chmod +x "$HOME/.local/bin/machine-sync"

echo "==> Done! Open a new terminal or run: source ~/.bashrc"
