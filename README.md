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
