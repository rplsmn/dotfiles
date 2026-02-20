Setup new machine with this:

# Install steps

## Install deps

```bash
sudo apt update 
sudo apt install curl
```

## Install GH 

To install:

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
```

## Authenticate 

```bash
gh auth login
```

## Install the LLM suite

```bash
gh repo clone rplsmn/shared-safe-config ~/<path/>shared-safe-config
bash ~/<path/>shared-safe-config/install.sh
```

Requires: Ubuntu LTS, git, curl, and [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated.

After pulling config changes, re-sync without reinstalling tools:

```bash
machine-sync
```

Syncing artifacts:

```bash
artifact-sync
```

# Cold Specs Library

Not all specs (skills, commands, agents) need to load in every LLM session. The **cold specs library** keeps all specs in cold storage and activates only what's relevant.

## Two flows

### Flow A: Machine sync (automatic)

Runs via `sync.sh` / `machine-sync`. Symlinks **core** specs from the cold library (`~/.local/share/llm-specs/`) into global tool directories (`~/.claude/`, `~/.copilot/`). Vibe gets direct copies in `sync.sh` (skills → `~/.vibe/skills/`, commands → `~/.vibe/prompts/`).

### Flow B: Repo init/update (manual)

Copies **non-core** specs into project-local directories (`.claude/` and `.github/`) so they're committed with the repo and visible to all tools.

## `specs-sync` CLI

```bash
# Machine sync (global dirs — core specs)
specs-sync sync                      # rebuild core symlinks in global dirs

# Repo init/update (project-local dirs)
specs-sync init                      # initialize project with matching specs
specs-sync update                    # refresh project specs from cold library
specs-sync activate <id> [id...]     # copy a spec into the project
specs-sync activate --global <id>    # symlink to global dirs instead
specs-sync deactivate <id> [id...]   # remove specs from project
specs-sync auto                      # auto-detect and copy missing specs
specs-sync reset                     # remove non-core specs from project

# Discovery
specs-sync status                    # show current activation state (default)
specs-sync list                      # list all available specs
specs-sync list --tag r              # filter by tag
specs-sync list --type command       # filter by type (skill, command, agent)
specs-sync search "code review"      # search by keyword
```

### Auto-detection

When you run `claude` or `copilot` in a git repo, `specs-sync auto --quiet` runs automatically. It checks for project marker files and copies matching specs into the project if they aren't already present:

| Marker files | Specs activated |
|---|---|
| `DESCRIPTION`, `NAMESPACE`, `*.Rproj`, `.R`/`.Rmd`/`.qmd` files | R skills |
| `.github/` directory | `solve-issue`, `solve-batch`, `triage-issues` |

Auto-detection is **additive-only** — it never removes specs or overwrites existing copies. Use `specs-sync reset` to return to core-only.

### Per-project manifests

Activation state is stored in the project root as `.specs-manifest.json`. When not in a git repo, the global manifest at `~/.local/share/llm-specs/global-manifest.json` is used.

## OpenCode

OpenCode is installed by `install.sh` but is **not** managed by `specs-sync`. It has its own configuration.

## Adding new specs

1. Create the spec in `skills/`, `commands/`, or `agents/`
2. Add an entry to `library.json` with `id`, `type`, `name`, `description`, `core`, `tags`, and optional `triggers`
3. Run `sync.sh` to update the cold library
