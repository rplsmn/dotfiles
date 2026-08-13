#!/usr/bin/env bash
# bootstrap.sh: one-shot setup for a fresh Ubuntu/Debian machine.
#   curl -fsSL https://raw.githubusercontent.com/rplsmn/dotfiles/main/bootstrap.sh | bash
# Clones the repo, installs the config-pull/config-push commands, and applies
# every managed config immediately.
set -euo pipefail

REPO="${XDG_DATA_HOME:-$HOME/.local/share}/config-sync"
REMOTE="https://github.com/rplsmn/dotfiles.git"
BIN="$HOME/.local/bin"

echo "==> Bootstrapping dotfiles"

if ! command -v git >/dev/null 2>&1; then
  echo "==> Installing git"
  sudo apt-get update -qq && sudo apt-get install -y -qq git
fi

if [ -d "$REPO/.git" ]; then
  echo "==> Repo already present at $REPO, updating"
  git -C "$REPO" pull --ff-only
else
  echo "==> Cloning into $REPO"
  mkdir -p "$(dirname "$REPO")"
  git clone --quiet "$REMOTE" "$REPO"
fi

echo "==> Installing commands to $BIN"
mkdir -p "$BIN"
install -m 0755 "$REPO/bin/config-pull" "$BIN/config-pull"
install -m 0755 "$REPO/bin/config-push" "$BIN/config-push"

echo "==> Applying configs"
"$BIN/config-pull"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    echo
    echo "!! $BIN is not on your PATH. Add it so config-pull/config-push work:"
    echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
    ;;
esac

echo "==> Bootstrap complete."
