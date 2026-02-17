Setup new machine with this:

```bash
gh repo clone rplsmn/shared-safe-config ~/shared-safe-config && bash ~/shared-safe-config/install.sh
```

Requires: Ubuntu LTS, git, curl, and [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated.

After pulling config changes, re-sync without reinstalling tools:

```bash
machine-sync-remote
```
