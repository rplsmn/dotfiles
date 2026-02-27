#!/bin/bash
# AKM (Agent Kit Manager) — One-time setup
# Installs the akm CLI, syncs the cold library, and wires shell integration.
#
# Prerequisites: jq (see README for install instructions)
#
# Usage:
#   git clone https://github.com/<org>/akm ~/akm
#   bash ~/akm/install.sh
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "==> Installing AKM from $REPO"

# --- Check dependencies ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  echo "Install it first:  sudo apt-get install jq  (or see README)" >&2
  exit 1
fi

# --- Install CLI ---
echo "==> Installing akm CLI to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
cp "$REPO/bin/akm" "$HOME/.local/bin/akm"
chmod +x "$HOME/.local/bin/akm"

# Ensure ~/.local/bin is on PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  echo "⚠  Add to your shell profile:  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# --- Config file (persistent repo path) ---
echo "==> Writing AKM config"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/akm"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config" <<EOF
REPO="$REPO"
EOF

# --- LLM tool directories ---
echo "==> Creating LLM tool directories"
mkdir -p "$HOME/.claude" "$HOME/.copilot" "$HOME/.agents" "$HOME/.vibe/prompts"

# --- Cold library + core symlinks ---
echo "==> Syncing cold library"
akm sync --quiet

# --- Shell init (idempotent marker block in .bashrc) ---
echo "==> Wiring shell integration"
SHELL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/akm/shell"
mkdir -p "$SHELL_DIR"
cp "$REPO/shell/akm-init.sh" "$SHELL_DIR/akm-init.sh"

AKM_MARKER_START="# >>> akm >>>"
AKM_MARKER_END="# <<< akm <<<"
AKM_INIT_PATH="\${XDG_DATA_HOME:-\$HOME/.local/share}/akm/shell/akm-init.sh"

if [ -f "$HOME/.bashrc" ]; then
  sed -i "/$AKM_MARKER_START/,/$AKM_MARKER_END/d" "$HOME/.bashrc"
fi
{
  echo "$AKM_MARKER_START"
  echo "[ -f \"$AKM_INIT_PATH\" ] && source \"$AKM_INIT_PATH\""
  echo "$AKM_MARKER_END"
} >> "$HOME/.bashrc"

echo ""
echo "==> AKM installed! Open a new terminal or run: source ~/.bashrc"
