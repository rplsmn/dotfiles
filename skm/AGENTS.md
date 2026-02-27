# AGENTS.md

This file provides guidance to LLMs working with code in this repository.

## What This Repo Is

SKM (Skill Kit Manager) is a CLI tool and library for managing reusable
[Agent Skills](https://agentskills.io/) across LLM-powered coding assistants.

It provides cold storage, three-layer activation (core → project → session),
and per-session isolation for skills and agents.

## Key Commands

```bash
bash install.sh    # One-time setup (jq, CLI, cold library, shell init)
skm sync           # Re-sync cold library + core symlinks
skm status         # Show what's active
skm list           # Browse available skills
```

No build system, test suite, or CI/CD. All scripts are pure Bash.

## Repository Map

```
skm/
├── bin/skm                # CLI (~1790 lines Bash, set -euo pipefail)
├── shell/skm-init.sh      # Shell functions sourced in .bashrc
├── skills/                # 65+ skills (SKILL.md + optional references/)
├── agents/                # Agent definitions (single .md files)
├── library.json           # Registry of all specs with metadata
├── install.sh             # One-time bootstrap
├── README.md              # Public documentation
├── LICENSE                # MIT
└── AGENTS.md              # This file
```

### Key Files

| File | Purpose |
|------|---------|
| `bin/skm` | Main CLI — all subcommands (sync, add, load, publish, etc.) |
| `shell/skm-init.sh` | Session lifecycle + tool wrappers (claude, copilot, opencode) |
| `library.json` | Registry with id, type, description, tags, core flag per spec |
| `install.sh` | Installs jq, copies CLI, writes config, syncs library |

## Architecture

### Three-Layer Activation

```
Layer 1 — Core (global, always available)
  skm sync → cold library (~/.local/share/skm/) → global symlinks

Layer 2 — Project (manifest-declared, loaded at session start)
  .agents/skm.json → shell wrapper reads → symlinks into staging dir

Layer 3 — Session (JIT, mid-session)
  skm load <id> / skm unload <id>
```

### Cold Library

`~/.local/share/skm/` mirrors the repo's `skills/` and `agents/` plus `library.json`.
Core specs (`"core": true`) are symlinked into global tool dirs by `skm sync`.

### Spec Types

| Type | Location | Format |
|------|----------|--------|
| Skills | `skills/<name>/SKILL.md` | Directory with entry point + optional `references/` |
| Agents | `agents/<name>.md` | Single markdown file |

### `skm` CLI Subcommands

| Command | Description |
|---------|-------------|
| `sync` | Rebuild core symlinks in global dirs |
| `clean [--project]` | Remove stale non-symlinks |
| `add <id>` | Add spec to project manifest |
| `remove <id>` | Remove spec from project manifest |
| `refresh` | Update project staging from cold library |
| `load <id>` | JIT-load spec into active session |
| `unload <id>` | Remove spec from active session |
| `loaded` | Show active session specs |
| `status` | Overview of core + project + session state |
| `init` | Create project directory structure |
| `list` | List specs with filters |
| `search <query>` | Keyword search |
| `generate-library` | Regenerate library.json from disk |
| `publish <id>` | Publish project-local spec as PR |
| `migrate` | Convert legacy setup to manifest-based |

### Shell Init (`shell/skm-init.sh`)

Defines `claude()`, `copilot()`, `opencode()` wrappers that:
1. Create per-session staging dir (`~/.cache/skm/<project>-<ts>-<pid>/`)
2. Populate from project manifest (`.agents/skm.json`)
3. Pass `--add-dir` to the tool
4. Clean up staging on exit

Artifact integration is optional — if `_artifact_ensure_dir` / `_artifact_commit_and_push`
are defined (e.g., by user's own bashrc), wrappers use them automatically.

## Conventions

- All shell scripts use `set -e` or `set -euo pipefail`
- `jq` is the sole runtime dependency
- Skill frontmatter follows the [Agent Skills spec](https://agentskills.io/specification)
- Commit style: conventional commits, WHY over WHAT
- Adding new specs: create in `skills/` or `agents/` → run `skm generate-library`

## Roadmap

The Bash CLI works but is ~1790 lines reaching its limits. A Rust rewrite is planned:
- Single static binary, structured CLI with `clap`
- Semantic versioning, lock files, registry support
- Plugin system for tool adapters
- See README.md for details
