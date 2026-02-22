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

Not all specs (skills, agents) need to load in every LLM session. The **cold specs library** keeps all specs in cold storage and activates only what's relevant.

## Two flows

### Flow A: Machine sync (automatic)

Runs via `sync.sh` / `machine-sync`. Symlinks **core** specs from the cold library (`~/.local/share/llm-specs/`) into global tool directories (`~/.claude/`, `~/.copilot/`, `~/.agents/`, `~/.vibe/`).

### Flow B: Project-local (manual)

Copies specs into project-local directories (`.claude/` and `.github/`) via `specs-sync add`, updated via `specs-sync refresh`.

## `specs-sync` CLI

```bash
# Machine sync (global dirs — core specs via symlinks)
specs-sync sync                      # rebuild core symlinks in global dirs
specs-sync clean                     # remove stale non-symlink copies from global dirs

# Project (local dirs — copies)
specs-sync init                      # initialize project directory structure
specs-sync add <id> [id...]          # copy a spec from cold library into the project
specs-sync refresh                   # update project specs from cold library; auto-commit

# Discovery
specs-sync status                    # show core specs and project-local specs (default)
specs-sync list                      # list all available specs
specs-sync list --tag r              # filter by tag
specs-sync list --type skill         # filter by type (skill, agent)
specs-sync search "code review"      # search by keyword
```

## Adding new specs

1. Create the spec in `skills/` or `agents/`
2. Add an entry to `library.json` with `id`, `type`, `name`, `description`, `core`, `tags`, and optional `triggers`
3. Run `sync.sh` to update the cold library
