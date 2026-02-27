#!/bin/bash
# SKM (Skill Kit Manager) — One-time setup
# Installs the skm CLI and syncs the cold library.
#
# Usage:
#   git clone https://github.com/<org>/skm ~/skm
#   bash ~/skm/install.sh
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "==> Installing SKM from $REPO"

# --- Dependencies ---
if ! command -v jq &>/dev/null; then
  echo "==> Installing jq"
  sudo apt-get update -qq
  sudo apt-get install -y -qq jq
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

# --- Shell init ---
echo "==> Installing shell init script"
SHELL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/skm/shell"
mkdir -p "$SHELL_DIR"
cp "$REPO/shell/skm-init.sh" "$SHELL_DIR/skm-init.sh"

echo ""
echo "==> SKM installed!"
echo ""
echo "Add this to your ~/.bashrc (after any artifact helpers, before PS1):"
echo ""
echo "  source \"\${XDG_DATA_HOME:-\$HOME/.local/share}/skm/shell/skm-init.sh\""
echo ""
echo "Then: source ~/.bashrc"
