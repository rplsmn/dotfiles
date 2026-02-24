# AGENTS.md

This file provides guidance to LLMs working inside CLI tools when working with code in this repository.

## What This Repo Is

A personal LLM skill/agent management system and developer environment bootstrap for Ubuntu/WSL. The core purpose is managing reusable [Agent Skills](https://agentskills.io/) (following the open SKILLS spec) and agent instructions across multiple CLI-based AI tools and projects.

It also provisions:
- CLI AI assistants (Claude Code, GitHub Copilot CLI, Mistral Vibe, OpenCode)
- Shell configuration (`.bashrc`, `.gitconfig`) — legacy from when this was a machine-sync repo; may be extracted later

### What Makes This Different

The closest comparable tool is [`npx skills`](https://github.com/vercel-labs/skills) (Vercel), which excels at finding, importing, and updating skills from GitHub repos. This project adds capabilities that `npx skills` does not have:

- **Cold storage** — A local library (`~/.local/share/llm-specs/`) that acts as a single source of truth, decoupled from any project or tool directory
- **Three-layer activation** — Core (global symlinks), project (manifest-declared IDs), and session (JIT load/unload) — each layer adds without polluting the others
- **Session isolation** — Per-session staging directories (`~/.cache/llm-skills/<session-id>/`) prevent collisions between parallel sessions and subagents
- **Code/skills separation** — Project manifests (`.agents/specs-sync.json`) declare skill IDs only; no spec content is committed to project repos
- **Artifact management** — Auto-commit/push of LLM session outputs to a shared artifacts repo

## Key Commands

```bash
bash install.sh          # One-time machine setup (tools, SSH, bin scripts, then sync)
bash sync.sh             # Re-runnable: syncs configs, cold library, bin scripts to machine
machine-sync             # Pulls repo then runs sync.sh (installed to ~/.local/bin)
specs-sync <subcommand>  # Cold Specs Library CLI (see below)
```

There is no build system, test suite, linter, or CI/CD. All scripts are pure Bash.

## Repository Map

```
shared-safe-config/
├── skills/                          # 69 skills (SKILL.md + optional references/)
│   ├── git-commit/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── test-driven-development/SKILL.md
│   ├── planning-team/SKILL.md
│   ├── implementing-team/SKILL.md
│   └── ...
├── agents/                          # Agent instructions (single .md files)
│   └── code-reviewer.md
├── bin/
│   ├── specs-sync                   # Cold Specs Library CLI (~1760 lines Bash)
│   ├── machine-sync                 # Pull repo + run sync.sh
│   └── artifact-sync                # Clone/pull artifacts repo to ~/.artifacts/
├── claude-code/
│   ├── claude-global-settings.json  # Global Claude Code settings
│   └── claude-statusline.sh         # Status line script
├── copilot-cli/
│   └── copilot-commit-message-instructions.md
├── library.json                     # Registry of all specs (~950 lines)
├── global-instructions.md           # Shared LLM instructions for all tools
├── install.sh                       # One-time bootstrap
├── sync.sh                          # Re-runnable config sync
├── dot_bashrc                       # Shell config: tool wrappers, session lifecycle
├── dot_gitconfig                    # Git aliases and config
├── AGENTS.md                        # This file
└── CLAUDE.md                        # Points to AGENTS.md
```

### Key Files

| File | Purpose |
|------|---------|
| `library.json` | Registry of all specs with metadata (id, type, description, tags, core flag) |
| `global-instructions.md` | Copied to `~/.claude/CLAUDE.md`, `~/.copilot/copilot-instructions.md`, `~/.vibe/prompts/cli.md` |
| `dot_bashrc` | Shell config: PS1, artifact helpers, session lifecycle, tool wrappers |
| `dot_gitconfig` | Git aliases and config (legacy, may be extracted) |
| `bin/specs-sync` | Cold Specs Library CLI — the main tool in this repo |
| `bin/machine-sync` | Pull repo + run sync (install.sh patches the `REPO=` line via sed) |
| `bin/artifact-sync` | Clone/pull `rplsmn/llm-artifacts` to `~/.artifacts/` |

## Architecture

### Three-Layer Skill Activation

Skills don't load in every LLM session — they activate through three layers that converge in a per-session staging directory.

```
Layer 1 — Core (global, always available)
  sync.sh → cold library (~/.local/share/llm-specs/)
          → symlinks into ~/.claude/, ~/.copilot/, ~/.agents/, ~/.vibe/

Layer 2 — Project (declared in manifest, loaded at session start)
  .agents/specs-sync.json lists skill/agent IDs
  → shell wrapper reads manifest → symlinks into staging dir

Layer 3 — Task (JIT, mid-session)
  specs-sync load <id>   → adds to active staging dir
  specs-sync unload <id> → removes from staging dir
```

**Session staging directory**: `~/.cache/llm-skills/<project>-<timestamp>-<pid>/`
Created by shell wrappers (`claude()`, `copilot()`, `opencode()`), passed to the tool via `--add-dir`, destroyed on exit.

### Cold Library

The cold library at `~/.local/share/llm-specs/` mirrors the repo's `skills/` and `agents/` directories plus `library.json`. It is the single source of truth on each machine.

- **Core specs** (`"core": true` in `library.json`): Symlinked into global tool dirs by `specs-sync sync`
- **Non-core specs**: Available for project-level or JIT activation but not globally loaded

### Spec Types

| Type | Repo Location | Format | Spec Standard |
|------|---------------|--------|---------------|
| Skills | `skills/<name>/SKILL.md` | Directory with `SKILL.md` entry point + optional `references/`, `scripts/`, `assets/` | [Agent Skills spec](https://agentskills.io/specification) |
| Agents | `agents/<name>.md` | Single markdown file | Custom (no standard yet) |

### `specs-sync` CLI (`bin/specs-sync`)

Bash CLI (`set -euo pipefail`). Subcommands:

| Command | Description |
|---------|-------------|
| `sync` | Rebuild core symlinks in global dirs |
| `clean [--project]` | Remove stale non-symlinks from global dirs (or project dir with `--project`) |
| `add <id>` | Add spec ID to project manifest (`.agents/specs-sync.json`) |
| `remove <id>` | Remove spec ID from project manifest |
| `refresh [--quiet]` | Update project staging from cold library, auto-commit if changed |
| `load <id>` | JIT-load a spec into the active session staging dir |
| `unload <id>` | Remove a spec from the active session staging dir |
| `loaded` | Show specs in the active session (with provenance: `[manifest]` vs `[loaded]`) |
| `status` | Show core specs + project manifest + session state |
| `init` | Create project directory structure (`.agents/`, `.claude/`, `.github/`) |
| `list [--tag TAG] [--type TYPE]` | List specs with optional filters |
| `search <query>` | Keyword search across specs |
| `generate-library` | Regenerate `library.json` from disk contents (preserves existing metadata) |
| `publish <id> [--dry-run] [--force]` | Publish a project-local spec to the source repo as a PR |
| `migrate` | Convert legacy `.claude/skills/` copies to manifest-based setup |

### Shell Wrappers (`dot_bashrc`)

`claude()`, `copilot()`, `opencode()` are wrapper functions that:
1. Ensure an artifacts directory exists for the current repo (`~/.artifacts/<repo>/`)
2. Start a session: create staging dir, populate from project manifest
3. Pass `--add-dir` for both artifacts and staging directories
4. On exit: destroy staging dir, auto-commit and push artifacts

### Artifact System

LLM session outputs (plans, research, session notes) are stored in `~/.artifacts/<repo-name>/` — a separate git repo (`rplsmn/llm-artifacts`) that is auto-synced.

```
~/.artifacts/<repo>/
├── plans/       # Implementation plans, architecture decisions
├── research/    # Technology evaluations, deep research
├── sessions/    # Session summaries and handoff notes
└── archive/     # Completed/superseded items
```

### Machine Layout (After Install)

```
~/.local/bin/
├── specs-sync                   # CLI tool
├── machine-sync                 # Repo pull + sync
└── artifact-sync                # Artifacts repo sync

~/.local/share/llm-specs/        # Cold library (source of truth)
├── skills/                      # All skills from repo
├── agents/                      # All agents from repo
└── library.json                 # Spec registry

~/.config/llm-specs/config       # REPO= path to source repo

~/.claude/                       # Global Claude Code dir
├── CLAUDE.md                    # From global-instructions.md
├── skills/                      # Core skill symlinks → cold library
├── agents/                      # Core agent symlinks → cold library
└── settings.json                # Merged with claude-global-settings.json

~/.cache/llm-skills/             # Ephemeral session staging dirs
└── <project>-<ts>-<pid>/        # One per active session
    ├── .claude/skills/           # Symlinks for this session
    ├── .copilot/skills/
    └── .agents/skills/
```

## Conventions

- All shell scripts use `set -e` or `set -euo pipefail`
- `.gitattributes` enforces LF line endings (`* text=auto eol=lf`) for WSL/Windows compatibility
- `jq` is the sole runtime dependency (installed by `install.sh`)
- Skill frontmatter follows the [Agent Skills spec](https://agentskills.io/specification): `name` and `description` are required; `description` should start with "Use when..." describing triggering conditions
- Adding new specs: create in `skills/` or `agents/` → run `specs-sync generate-library` → run `sync.sh`
- Commit style: conventional commits (`fix:`, `feat:`, `refactor:`, `chore:`), WHY over WHAT

## Roadmap

### Current State

The system works but is a ~1760-line Bash script reaching its limits. Recent work (Feb 2026) added session-scoped staging directories (#10), the publish flow (#11), and project-level clean (#14). Open issues:

- **#12 — CLI Rewrite RFC**: Rewrite `specs-sync` in Rust as a proper CLI with package manager capabilities (semantic versioning, lock files, registry support, self-update). This is the main planned effort.
- **#5 — Cleanup**: One-time removal of renamed binaries on existing machines.

### Planned: Rust CLI Rewrite

The Bash implementation has no structured error handling, no types, no tests, and brittle complex flows (git operations in `publish`). A Rust rewrite would provide:

- Single static binary, ~1ms startup (critical since it runs at every session start)
- Structured CLI with `clap`, shell completions, proper error types
- Semantic versioning for specs, lock files per project
- Plugin system for tool adapters (Claude, Copilot, Cursor, etc.) instead of hardcoded dirs
- Registry support for sharing/discovering community specs
- Unit tests and CI/CD

**Migration path**: Phase 1 (feature parity drop-in) → Phase 2 (versioning, lock files, diff) → Phase 3 (registry) → Phase 4 (absorb install.sh/sync.sh, self-update).

### Relationship to `npx skills`

[`npx skills`](https://github.com/vercel-labs/skills) is the ecosystem's package manager for finding and importing skills from GitHub. It does discovery and installation well. This project focuses on what happens after import: cold storage, layered activation, session isolation, and code/skills separation. The two are complementary — a future version could use `npx skills` (or its protocol) for discovery/import while keeping the cold library and hot-load system.
