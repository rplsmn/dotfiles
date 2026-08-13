# Single source of truth for what config-sync manages.
# Sourced (not executed) by bin/config-pull and bin/config-push.
#
# To manage a new file: add one line to MANIFEST below. Both directions
# (pull = apply to machine, push = snapshot from machine) pick it up.

# Marker id wrapping the bashrc snippet block. Legacy ids are also stripped
# on apply so old machines migrate cleanly.
BASHRC_MARKER="config-sync"
BASHRC_LEGACY_MARKERS=("shared-safe-config")

# Managed files: "repo_relative_path|destination|mode"
#   copy  -> overwrite the destination file wholesale
#   block -> replace only the marker-delimited block inside the destination
MANIFEST=(
  "files/gitconfig|$HOME/.gitconfig|copy"
  "files/tmux.conf|$HOME/.tmux.conf|copy"
  "files/bashrc.snippet|$HOME/.bashrc|block"
)
