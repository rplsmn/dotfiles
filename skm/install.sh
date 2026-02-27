#!/bin/bash
# SKM (Skill Kit Manager) — One-time setup
# Installs the skm CLI, syncs the cold library, and wires shell integration.
#
# Prerequisites: jq (see README for install instructions)
#
# Usage:
#   git clone https://github.com/<org>/skm ~/skm
#   bash ~/skm/install.sh
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "==> Installing SKM from $REPO"

# --- Check dependencies ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  echo "Install it first:  sudo apt-get install jq  (or see README)" >&2
  exit 1
fi

# --- Install CLI ---
echo "==> Installing skm CLI to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
cp "$REPO/bin/skm" "$HOME/.local/bin/skm"
chmod +x "$HOME/.local/bin/skm"

# Ensure ~/.local/bin is on PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  echo "⚠  Add to your shell profile:  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# --- Config file (persistent repo path) ---
echo "==> Writing SKM config"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/skm"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config" <<EOF
REPO="$REPO"
EOF

# --- LLM tool directories ---
echo "==> Creating LLM tool directories"
mkdir -p "$HOME/.claude" "$HOME/.copilot" "$HOME/.agents" "$HOME/.vibe/prompts"

# --- Cold library + core symlinks ---
echo "==> Syncing cold library"
skm sync --quiet

# --- Shell init (idempotent marker block in .bashrc) ---
echo "==> Wiring shell integration"
SHELL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/skm/shell"
mkdir -p "$SHELL_DIR"
cp "$REPO/shell/skm-init.sh" "$SHELL_DIR/skm-init.sh"

SKM_MARKER_START="# >>> skm >>>"
SKM_MARKER_END="# <<< skm <<<"
SKM_INIT_PATH="\${XDG_DATA_HOME:-\$HOME/.local/share}/skm/shell/skm-init.sh"

if [ -f "$HOME/.bashrc" ]; then
  sed -i "/$SKM_MARKER_START/,/$SKM_MARKER_END/d" "$HOME/.bashrc"
fi
{
  echo "$SKM_MARKER_START"
  echo "[ -f \"$SKM_INIT_PATH\" ] && source \"$SKM_INIT_PATH\""
  echo "$SKM_MARKER_END"
} >> "$HOME/.bashrc"

echo ""
echo "==> SKM installed! Open a new terminal or run: source ~/.bashrc"
