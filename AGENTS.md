# AGENTS.md

Guidance for LLM agents working in this repository.

## Goal

A **dead-simple personal dotfiles sync** for a single user across their own
Ubuntu/Debian (incl. WSL) machines. Centralise a small set of hand-tuned config
files so muscle-memory/preferences propagate between machines without manual
copy-paste. The remote `main` is the single source of truth.

This repo was previously an over-built machine-bootstrap tool that also
installed CLI AI assistants and their settings. **That is all gone** — a
separate tool (AKM) now owns LLM harness installs, skills, and instructions.
Do not reintroduce any of that here. If you find references to AKM, Claude Code
settings, Copilot, `install.sh`, `sync.sh`, or `machine-sync`, they are stale.

## Hard design constraints (do not "improve" past these)

- **Scope:** exactly three files today — `~/.gitconfig`, `~/.tmux.conf`, and a
  `~/.bashrc` snippet. Nothing else unless the user asks.
- **Ubuntu/Debian only.** No macOS/other-distro branches. `apt` is assumed.
- **Overwrite = truth.** Pull clobbers local files with no backups, on purpose.
- **No frameworks.** Pure bash + git + sed. `jq` is NOT a dependency (the old
  repo used it; the rework dropped it). No build/test/lint/CI exists.
- **Public repo.** Keep it publishable: no secrets. `user.email` in
  `files/gitconfig` must stay the GitHub noreply address, never a real personal
  email. SSH keys/config are intentionally excluded.
- **Simplicity over flexibility.** If a change adds config knobs, abstraction,
  or "just in case" handling, it's probably wrong for this repo.

## Layout

```
dotfiles/
├── bootstrap.sh            # fresh-machine entry (curl | bash): clone + install + pull
├── manifest.sh             # SINGLE SOURCE OF TRUTH for managed files; sourced by both cmds
├── bin/
│   ├── config-pull         # remote -> machine (apply truth, overwrite)
│   └── config-push         # machine -> remote (snapshot, diff, y/N, commit+push)
├── files/
│   ├── gitconfig           # -> ~/.gitconfig  (whole file)
│   ├── tmux.conf           # -> ~/.tmux.conf  (whole file)
│   └── bashrc.snippet      # -> ~/.bashrc     (marker block only)
├── README.md               # user-facing
├── AGENTS.md               # this file
├── CLAUDE.md               # points here
└── .gitignore              # defensive key/secret guard
```

## How it works

- **`manifest.sh`** defines `MANIFEST=("repo_path|dest|mode")` where mode is
  `copy` (whole file) or `block` (marker-delimited region). Both `config-pull`
  and `config-push` source it, so **adding a managed file is a one-line edit
  here** — never hardcode paths in the scripts.
- **On-machine repo location:** `${XDG_DATA_HOME:-$HOME/.local/share}/config-sync`.
  Commands install to `~/.local/bin`. Always resolve XDG via the
  `${XDG_*:-default}` idiom, never hardcode `~/.local/share`.
- **`config-pull`:** `git pull --ff-only`, apply each manifest entry, then
  reinstall both commands (self-update). `copy` = `cp`; `block` = strip the
  `config-sync` marker block (plus legacy markers) and re-append.
- **`config-push`:** copy live files into the repo (for `block`, extract only
  the marker region), `git add -A`, show the staged diff, prompt `y/N`, then
  commit + push. Never auto-commits without the prompt.
- **`.bashrc` marker:** `# >>> config-sync >>>` / `# <<< config-sync <<<`.
  `BASHRC_LEGACY_MARKERS` in the manifest lists old ids (`shared-safe-config`)
  that pull also strips, so old machines migrate cleanly. `files/bashrc.snippet`
  stores the block body WITHOUT the marker lines.

## Remote

`github.com/rplsmn/dotfiles` (public). Bootstrap clones over **HTTPS** (anon,
no creds on a fresh box); only `config-push` needs write auth, which the user
sets up separately (e.g. `gh`).

## When changing things

- Keep `bootstrap.sh`, `README.md`, and the raw URL in sync if the repo name or
  branch ever changes.
- Test scripts by dry-reasoning through both directions; there is no test suite.
- Match the existing terse, commented bash style.
