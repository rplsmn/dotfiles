#!/bin/bash
# Minimal bootstrap — clone the repo and run setup.sh
# Usage: curl -fsSL https://raw.githubusercontent.com/rplsmn/shared-safe-config/main/install.sh | bash
set -e

REPO="$HOME/shared-safe-config"

if [ -d "$REPO" ]; then
  git -C "$REPO" pull --ff-only
else
  git clone https://github.com/rplsmn/shared-safe-config.git "$REPO"
fi

bash "$REPO/setup.sh"
