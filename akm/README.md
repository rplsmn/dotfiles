# AKM — Agent Kit Manager

A CLI tool and library for managing reusable [Agent Skills](https://agentskills.io/) across LLM-powered coding assistants (Claude Code, GitHub Copilot CLI, OpenCode, and more).

AKM provides **cold storage**, **three-layer activation**, and **session isolation** for skills and agents — so your LLM tools load exactly the right context for each project and session.

## Features

- **Cold library** — A single source of truth at `~/.local/share/akm/`, decoupled from any project
- **Three-layer activation** — Core (global), project (manifest), and session (JIT) loading
- **Session isolation** — Per-session staging dirs prevent collisions between parallel sessions
- **Code/skills separation** — Project manifests declare skill IDs only; no spec content committed to project repos
- **Multi-tool support** — Works with Claude Code, GitHub Copilot CLI, OpenCode, and more
- **60+ skills included** — Development workflows, code review, TDD, planning, debugging, and more

## Prerequisites

- **jq** — Install with your package manager (e.g., `sudo apt-get install jq`, `brew install jq`)
- **git** — For cloning and repo detection

## Quick Start

```bash
# Clone and install
git clone https://github.com/<org>/akm ~/akm
bash ~/akm/install.sh    # installs CLI, syncs library, wires ~/.bashrc

# Open a new terminal (or source ~/.bashrc), then:
akm status
```

## How It Works

### Three-Layer Activation

```
Layer 1 — Core (global, always available)
  akm sync → cold library (~/.local/share/akm/)
           → symlinks into ~/.claude/, ~/.copilot/, ~/.agents/

Layer 2 — Project (declared in manifest, loaded at session start)
  .agents/akm.json lists skill/agent IDs
  → shell wrapper reads manifest → symlinks into staging dir

Layer 3 — Session (JIT, mid-session)
  akm load <id>   → adds to active staging dir
  akm unload <id> → removes from staging dir
```

### Shell Wrappers

When you source `akm-init.sh` (done automatically by `install.sh`), it provides wrapper functions for `claude`, `copilot`, and `opencode` that automatically:
1. Create a per-session staging directory
2. Populate it from the project manifest (`.agents/akm.json`)
3. Pass the staging dir to the tool via `--add-dir`
4. Clean up on exit

## CLI Reference

```
akm <subcommand> [options] [arguments]

Global:
  sync            Rebuild core spec symlinks in global dirs
  clean           Remove stale specs from global or project dirs
    --project       Clean project dirs instead of global
    --migrate       (with --project) Migrate legacy copies to manifest first
    --dry-run       Show what would happen without making changes
  status          Show core, session, manifest, and available specs (default)

Project:
  init            Initialize project dirs and manifest stub
  add <id>        Add spec ID(s) to project manifest (.agents/akm.json)
  remove <id>     Remove spec ID(s) from project manifest

Session:
  load <id>       Symlink spec into active staging dir (JIT loading)
  unload <id>     Remove spec from active staging dir
  loaded          Show specs loaded in active session

Publishing:
  publish <id>    Publish a local spec to the source repo as a PR
    --dry-run       Show what would happen without making changes
    --force         Overwrite if spec already exists in source repo

Discovery:
  list            List all specs in the library (--tag TAG, --type skill|agent)
  search <query>  Search specs by keyword
  libgen          Auto-generate library.json from disk contents
  help            Show help
```

## Included Skills

AKM ships with 63 skills covering:

| Category | Skills |
|----------|--------|
| **Development workflow** | brainstorming, writing-plans, executing-plans, test-driven-development, verification-before-completion |
| **Code quality** | critical-code-reviewer, requesting-code-review, receiving-code-review, systematic-debugging |
| **Git & collaboration** | git-commit, finishing-a-development-branch, using-git-worktrees, pr-create, solve-issue, triage-issues |
| **Multi-agent** | planning-team, implementing-team, dispatching-parallel-agents, subagent-driven-development, solve-batch |
| **Writing & docs** | technical-writer, editor, content-creator, adr-writing |
| **Domain-specific** | R packages, Shiny, Quarto, Rust, Vitest, Supabase, and more |

See `akm list` for the full inventory with descriptions.

## Skill Format

Skills follow the [Agent Skills specification](https://agentskills.io/specification):

```
skills/<name>/
├── SKILL.md           # Entry point (YAML frontmatter + instructions)
└── references/        # Optional supporting files
```

The YAML frontmatter requires `name` and `description` (starting with "Use when...").

## Project Manifests

Declare which skills a project uses in `.agents/akm.json`:

```json
{
  "skills": ["test-driven-development", "systematic-debugging"],
  "agents": ["code-reviewer"]
}
```

These are loaded automatically when you start a session via the shell wrappers.

## Machine Layout

```
~/.local/bin/akm                    # CLI tool
~/.local/share/akm/                 # Cold library (source of truth)
  ├── skills/                       # All skills
  ├── agents/                       # All agents
  ├── library.json                  # Registry
  └── shell/akm-init.sh            # Shell init script
~/.config/akm/config                # REPO= path to source repo
~/.cache/akm/                       # Ephemeral session staging dirs
```

## Third-Party Attributions

Some included skills were created by or derived from third-party authors:

- Skills by **Garrick Aden-Buie** (@gadenbuie): `cran-extrachecks`, `testing-r-packages`, `lifecycle`, `cli` — MIT License
- **Mickaël Canouil** (@mcanouil): `quarto-authoring` — MIT License
- **Anthony Fu** (@antfu): `vitest` — generated from [vitest-dev/vitest](https://github.com/vitest-dev/vitest)
- R language skills derived from **Sarah Johnson** (@sj-io): `metaprogramming-rlang`, `developing-packages-r`, `writing-tidyverse-r`, `customizing-vectors-r`, `designing-oop-r`, `optimizing-r`
- Skills with Apache 2.0 license: `webapp-testing`, `frontend-design`, `skill-creator`, `canvas-design`, `algorithmic-art`, `internal-comms`

See individual skill directories for full license terms.

## License

MIT — see [LICENSE](LICENSE).

## Related Projects

- [Agent Skills Specification](https://agentskills.io/) — The open standard for portable AI coding skills
- [`npx skills`](https://github.com/vercel-labs/skills) — Discover and import skills from GitHub (complementary to AKM)
