# AGENTS.md

This file provides guidance to LLMs working with code in this repository.

## What This Repo Is

A personal developer environment bootstrap for Ubuntu/WSL. The core purpose is
managing multiple CLI-based AI tools and projects, and a global gitconfig.

It also provisions:

- CLI AI assistants (Claude Code, GitHub Copilot CLI, Mistral Vibe, OpenCode)
  with their settings
- Git configuration (`.gitconfig`)

## Key Commands

```bash
bash install.sh          # One-time machine setup (tools, SSH, bin scripts, then sync)
bash sync.sh             # Re-runnable: syncs configs + bin scripts to machine
machine-sync             # Pulls repo then runs sync.sh (installed to ~/.local/bin)
```

There is no build system, test suite, linter, or CI/CD. All scripts are pure Bash.

## Repository Map

```
shared-safe-config/
├── bin/
│   └── machine-sync                 # Pull repo + run sync.sh
├── claude-code/       # Manage settings specific to Claude Code
│   ├── claude-global-settings.json  # Global Claude Code settings
│   └── claude-statusline.sh         # Status line script
├── copilot-cli/       # Manage settings specific to Copilot CLI
│   └── copilot-commit-message-instructions.md
├── install.sh                       # One-time bootstrap
├── sync.sh                          # Re-runnable config sync
├── dot_bashrc                       # PS1 with git branch (injected into ~/.bashrc)
├── dot_gitconfig                    # Git aliases and config
├── AGENTS.md                        # This file
└── CLAUDE.md                        # Points to AGENTS.md
```

### Key Files

| File | Purpose |
|------|---------|
| `dot_bashrc` | PS1 prompt with git branch display |
| `dot_gitconfig` | Git aliases and config |
| `bin/machine-sync` | Pull repo + run sync (install.sh patches the `REPO=` line via sed) |

## Architecture

### Machine Layout (After Install)

```
~/.local/bin/
└── machine-sync                 # Repo pull + sync

~/.claude/                       # Global Claude Code dir
├── statusline.sh
└── settings.json                # Merged with claude-global-settings.json

~/.copilot/
└── copilot-commit-message-instructions.md
```

## Conventions

- All shell scripts use `set -e` or `set -euo pipefail`
- `.gitattributes` enforces LF line endings (`* text=auto eol=lf`) for WSL/Windows compatibility
- `jq` is the sole runtime dependency (installed by `install.sh`)
