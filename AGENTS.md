# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A personal developer environment bootstrap for Ubuntu/WSL that provisions:
- CLI AI assistants (Claude Code, GitHub Copilot CLI, Mistral Vibe, OpenCode)
- Shell configuration (`.bashrc`, `.gitconfig`)
- A **Cold Specs Library** that manages reusable LLM skills, commands, and agents across tools and projects

## Key Commands

```bash
bash install.sh          # One-time machine setup (tools, SSH, bin scripts, then sync)
bash sync.sh             # Re-runnable: syncs configs, cold library, bin scripts to machine
machine-sync             # Pulls repo then runs sync.sh (installed to ~/.local/bin)
specs-sync <subcommand>  # Cold Specs Library CLI (see below)
```

There is no build system, test suite, linter, or CI/CD. All scripts are pure Bash.

## Architecture

### Cold Specs Library (Two-Flow System)

The central concept. Not all specs load in every LLM session — only relevant ones are activated.

**Flow A — Machine sync** (`sync.sh`): Core specs are **symlinked** from cold storage (`~/.local/share/llm-specs/`) into global tool directories (`~/.claude/`, `~/.copilot/`). Vibe gets direct copies.

**Flow B — Repo init/update** (`specs-sync`): Non-core specs are **copied** into project-local directories (`.claude/`, `.github/`) so they're committed with the repo.

### Spec Types

| Type | Location | Format |
|------|----------|--------|
| Skills | `skills/<name>/SKILL.md` | Directory with `SKILL.md` entry point + optional references |
| Commands | `commands/<name>.md` | Single markdown file |
| Agents | `agents/<name>.md` | Single markdown file |

### Core vs Non-Core

- **Core** (`"core": true` in `library.json`): Always symlinked globally via `sync.sh`
- **Non-core**: Activated per-project via triggers or `specs-sync activate`

### Trigger-Based Auto-Detection

Specs declare `triggers` in `library.json` with `files` and `extensions`. Shell wrappers for `claude`/`copilot` in `dot_bashrc` automatically run `specs-sync auto --quiet` before launching, which checks the project root for matching files and copies relevant specs.

Auto-detection is **additive-only** — never removes or overwrites existing project copies.

### `specs-sync` CLI (`bin/specs-sync`)

~1000 lines of Bash (`set -euo pipefail`). Key subcommands:
- `sync` — Rebuild core symlinks in global dirs
- `auto [--quiet]` — Auto-detect and activate based on project markers
- `activate <id> [--global]` — Copy to project or symlink globally
- `deactivate <id>` — Remove from project
- `init` / `update` / `reset` — Project lifecycle
- `list [--tag TAG] [--type TYPE]` / `search <query>` — Discovery
- `generate-library` — Regenerate `library.json` from disk contents (preserves existing metadata)

### Shell Wrappers (`dot_bashrc`)

`claude()`, `copilot()`, `opencode()` are wrapper functions that:
1. Ensure an artifacts directory exists for the current repo
2. Run `specs-sync auto --quiet`
3. Pass `--add-dir` for the artifacts directory
4. Auto-commit and push artifacts after the tool exits

### Per-Project State

- `.specs-manifest.json` in project roots tracks activated non-core specs
- `~/.local/share/llm-specs/global-manifest.json` when not in a git repo

## Key Files

| File | Purpose |
|------|---------|
| `library.json` | Registry of all specs with metadata, triggers, tags, core flag |
| `global-instructions.md` | Copied to `~/.claude/CLAUDE.md`, `~/.copilot/copilot-instructions.md`, `~/.vibe/prompts/cli.md` |
| `dot_bashrc` | Shell config with tool wrappers, PS1, artifact helpers |
| `dot_gitconfig` | Git aliases and config |
| `bin/specs-sync` | Cold Specs Library CLI |
| `bin/machine-sync` | Pull repo + run sync (install.sh patches the `REPO=` line via sed) |
| `bin/artifact-sync` | Clone/pull `rplsmn/llm-artifacts` to `~/.artifacts/` |
| `claude-code/claude-global-settings.json` | Global Claude Code settings (status line, experimental flags) |

## Conventions

- All shell scripts use `set -e` or `set -euo pipefail`
- `.gitattributes` enforces LF line endings (`* text=auto eol=lf`) for WSL/Windows compatibility
- `jq` is the sole runtime dependency (installed by `install.sh`)
- Skill frontmatter: only `name` and `description` fields; `description` must start with "Use when..." describing triggering conditions
- Command frontmatter: supports `description`, `disable-model-invocation`, `arguments`
- Adding new specs: create in `skills/`, `commands/`, or `agents/` → add entry to `library.json` → run `sync.sh`
- Commit style: conventional commits (`fix:`, `feat:`, `refactor:`, `chore:`), WHY over WHAT
