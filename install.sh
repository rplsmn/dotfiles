#!/bin/bash
# One-time machine setup — installs tools, keys, repos, then syncs configs.
# Prerequisites: Ubuntu LTS, git, curl, gh (installed and authenticated)
# Usage: gh repo clone rplsmn/shared-safe-config ~/shared-safe-config && bash ~/shared-safe-config/install.sh
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

if ! command -v copilot &>/dev/null 2>&1; then
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

# --- Config repo ---
REPO="$(cd "$(dirname "$0")" && pwd)"

# --- Install bin scripts ---
echo "==> Installing commands to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
cp "$REPO/bin/artifact-sync" "$HOME/.local/bin/"
sed "s|^REPO=.*|REPO=\"$REPO\"|" "$REPO/bin/machine-sync-remote" > "$HOME/.local/bin/machine-sync-remote"
chmod +x "$HOME/.local/bin/machine-sync-remote"
cp "$REPO/bin/specs" "$HOME/.local/bin/specs"
chmod +x "$HOME/.local/bin/specs"

# --- Artifacts repo ---
echo "==> Syncing artifacts"
artifact-sync

# --- Sync configs ---
bash "$REPO/sync.sh"
