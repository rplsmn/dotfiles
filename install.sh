#!/bin/bash
# One-time machine setup — installs tools, keys, repos, then syncs configs.
# Prerequisites: Ubuntu LTS, git, curl, gh (installed and authenticated)
# Usage: curl -fsSL https://raw.githubusercontent.com/rplsmn/shared-safe-config/main/install.sh | bash
set -e

echo "==> One-time machine setup"

# --- Dependencies ---
if ! command -v jq &>/dev/null; then
  echo "==> Installing jq"
  sudo apt-get update -qq
  sudo apt-get install -y -qq jq
fi

# --- CLI tools ---
if ! command -v claude &>/dev/null; then
  echo "==> Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi

if ! gh copilot version &>/dev/null 2>&1; then
  echo "==> Installing GitHub Copilot CLI"
  curl -fsSL https://gh.io/copilot-install | bash
fi

if ! command -v vibe &>/dev/null; then
  echo "==> Installing Mistral Vibe"
  curl -LsSf https://mistral.ai/vibe/install.sh | bash
fi

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

# --- Config repo ---
REPO="$HOME/shared-safe-config"
if [ -d "$REPO" ]; then
  git -C "$REPO" pull --ff-only
else
  git clone https://github.com/rplsmn/shared-safe-config.git "$REPO"
fi

# --- Sync configs ---
bash "$REPO/sync.sh"
