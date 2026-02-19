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
machine-sync-remote
```

Syncing artifacts:

```bash
artifact-sync
```

# Cold Specs Library

Not all specs (skills, commands, agents) need to load in every LLM session. The **cold specs library** keeps all specs in cold storage and activates only what's relevant via symlinks.

## How it works

1. `sync.sh` copies all specs to `~/.local/share/llm-specs/` (the cold library)
2. Core specs (debugging, TDD, verification, planning, etc.) are always active
3. Other specs activate on demand — manually or auto-detected from project type
4. Active specs are symlinked into tool directories (`~/.claude/`, `~/.copilot/`, `~/.vibe/`)
5. Shell wrappers auto-detect project type on each `claude`/`copilot` launch

## `specs` CLI

```bash
specs                           # show current activation status (default)
specs list                      # list all available specs
specs list --tag r              # filter by tag
specs list --type command       # filter by type (skill, command, agent)
specs search "code review"      # search by keyword across names, descriptions, tags
specs activate <id> [id...]     # activate specs for current project
specs deactivate <id> [id...]   # deactivate specs
specs auto                      # auto-detect project type and activate matching specs
specs auto --dry-run            # preview what would be activated
specs sync                      # rebuild symlinks from manifest (repair tool)
specs reset                     # return to core-only (remove all non-core activations)
```

### Auto-detection

When you run `claude` or `copilot` in a git repo, `specs auto --quiet` runs automatically. It checks for project marker files:

| Marker files | Specs activated |
|---|---|
| `DESCRIPTION`, `NAMESPACE`, `*.Rproj`, `.R`/`.Rmd`/`.qmd` files | All 6 R skills |
| `.github/` directory | `solve-issue`, `triage-issues` |

Auto-detection is **additive-only** — it never removes existing symlinks. Use `specs reset` to return to core-only.

### Per-project manifests

Activation state is stored per-project in `~/.artifacts/<project>/.specs-manifest.json`. When not in a git repo, the global manifest at `~/.local/share/llm-specs/global-manifest.json` is used.

## Adding new specs

1. Create the spec in `skills/`, `commands/`, or `agents/`
2. Add an entry to `library.json` with `id`, `type`, `name`, `description`, `core`, `tags`, and optional `triggers`
3. Run `sync.sh` to update the cold library
