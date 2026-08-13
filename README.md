# dotfiles

Dead-simple config sync for my Ubuntu/Debian machines. One user (me), one truth
(this repo's `main`). No frameworks, no secrets — just git, bash, sed.

Manages three files:

| Repo file            | Lands at        | How            |
|----------------------|-----------------|----------------|
| `files/gitconfig`    | `~/.gitconfig`  | whole file     |
| `files/tmux.conf`    | `~/.tmux.conf`  | whole file     |
| `files/bashrc.snippet` | `~/.bashrc`   | marker block   |

## New machine

```bash
curl -fsSL https://raw.githubusercontent.com/rplsmn/dotfiles/main/bootstrap.sh | bash
```

Clones this repo to `~/.local/share/config-sync`, installs the two commands
below into `~/.local/bin`, and applies every config.

## Daily use

- **`config-pull`** — pull the latest truth from the remote and apply it here
  (overwrites the managed files; no backups).
- **`config-push`** — snapshot this machine's live configs, show you the diff,
  and after a `y/N` greenlight, commit + push so every other machine can pull it.

Typical flow: tweak `~/.tmux.conf` on machine A → `config-push` → on machine B
run `config-pull`.

## Notes

- **Overwrite model:** latest remote `main` is always the truth. `config-pull`
  clobbers local copies. That's the point — it frees you from tracking which
  tweak made it to which machine.
- **`.bashrc`** is only partially owned: your snippet lives between
  `# >>> config-sync >>>` / `# <<< config-sync <<<` markers; the rest of the
  file (stock Ubuntu content) is left alone per machine.
- **SSH config is intentionally not managed** — done by hand for now.
- **Adding a file:** add one line to `manifest.sh`; both commands pick it up.
