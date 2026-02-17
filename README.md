Setup new machine with this:

```bash
curl -fsSL https://raw.githubusercontent.com/rplsmn/shared-safe-config/main/install.sh | bash
```

Requires: Ubuntu LTS, git, curl, and [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated.

After pulling config changes, re-sync without reinstalling tools:

```bash
bash ~/shared-safe-config/sync.sh
```
