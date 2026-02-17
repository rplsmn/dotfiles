#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Setting up machine from $REPO_DIR"

# --- SSH key ---
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "==> Generating SSH key"
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "$(gh api user -q .login)@$(hostname)"
  eval "$(ssh-agent -s)"
  ssh-add "$HOME/.ssh/id_ed25519"
  gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname)"
  echo "==> SSH key registered with GitHub"
else
  echo "==> SSH key already exists, skipping"
fi

# --- Artifacts repo ---
if [ ! -d "$HOME/.artifacts" ]; then
  echo "==> Cloning llm-artifacts"
  gh repo clone rplsmn/llm-artifacts "$HOME/.artifacts"
else
  echo "==> Artifacts repo exists, pulling latest"
  git -C "$HOME/.artifacts" pull --ff-only || true
fi

# --- Shell config (append, idempotent via marker block) ---
echo "==> Installing bashrc additions"
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
echo "==> Installing gitconfig"
cp "$REPO_DIR/dot_gitconfig" "$HOME/.gitconfig"

# --- LLM tool directories ---
echo "==> Setting up LLM tool directories"
mkdir -p "$HOME/.claude" "$HOME/.copilot" "$HOME/.vibe/prompts"

for dir in "$HOME/.claude" "$HOME/.copilot" "$HOME/.vibe"; do
  cp -r "$REPO_DIR/agents" "$dir/"
  cp -r "$REPO_DIR/commands" "$dir/"
  cp -r "$REPO_DIR/skills" "$dir/"
done

# --- Global instructions ---
echo "==> Installing global instructions"
cp "$REPO_DIR/global-instructions.md" "$HOME/.claude/CLAUDE.md"
cp "$REPO_DIR/global-instructions.md" "$HOME/.copilot/copilot-instructions.md"
cp "$REPO_DIR/global-instructions.md" "$HOME/.vibe/prompts/cli.md"

# --- Claude Code specifics ---
echo "==> Installing Claude Code config"
cp "$REPO_DIR/claude-code/claude-statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
cp "$REPO_DIR/claude-code/claude-global-settings.json" "$HOME/.claude/settings.json"

echo ""
echo "==> Done! Open a new terminal or run: source ~/.bashrc"
