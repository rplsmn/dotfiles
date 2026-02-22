# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A personal developer environment bootstrap for Ubuntu/WSL that provisions:
- CLI AI assistants (Claude Code, GitHub Copilot CLI, Mistral Vibe, OpenCode)
- Shell configuration (`.bashrc`, `.gitconfig`)
- A **Cold Specs Library** that manages reusable LLM skills and agents across tools and projects

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

**Flow A — Machine sync** (`sync.sh`): Core specs are **symlinked** from cold storage (`~/.local/share/llm-specs/`) into global tool directories (`~/.claude/`, `~/.copilot/`, `~/.agents/`, `~/.vibe/`).

**Flow B — Repo init/refresh** (`specs-sync`): Specs are **copied** into project-local directories (`.claude/`, `.github/`) via `specs-sync add` and updated via `specs-sync refresh`.

### Spec Types

| Type | Location | Format |
|------|----------|--------|
| Skills | `skills/<name>/SKILL.md` | Directory with `SKILL.md` entry point + optional companions |
| Agents | `agents/<name>.md` | Single markdown file |

### Core vs Non-Core

- **Core** (`"core": true` in `library.json`): Always symlinked globally via `sync.sh`
- **Non-core**: Added per-project via `specs-sync add`

### `specs-sync` CLI (`bin/specs-sync`)

Bash CLI (`set -euo pipefail`). Key subcommands:
- `sync` — Rebuild core symlinks in global dirs (`~/.claude`, `~/.copilot`, `~/.agents`, `~/.vibe`)
- `clean` — Remove non-symlinks from global dirs (stale manual copies)
- `add <id>` — Copy a spec from cold library into the project
- `refresh` — Scan project dirs, update matching specs from cold library, auto-commit
- `init` — Create project directory structure
- `list [--tag TAG] [--type TYPE]` / `search <query>` — Discovery
- `generate-library` — Regenerate `library.json` from disk contents (preserves existing metadata)

### Shell Wrappers (`dot_bashrc`)

`claude()`, `copilot()`, `opencode()` are wrapper functions that:
1. Ensure an artifacts directory exists for the current repo
2. Run `specs-sync refresh --quiet`
3. Pass `--add-dir` for the artifacts directory
4. Auto-commit and push artifacts after the tool exits

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
- Adding new specs: create in `skills/` or `agents/` → add entry to `library.json` → run `sync.sh`
- Commit style: conventional commits (`fix:`, `feat:`, `refactor:`, `chore:`), WHY over WHAT
