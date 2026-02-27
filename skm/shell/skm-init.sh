#!/bin/bash
# skm-init.sh — Source this file in your .bashrc to enable SKM session lifecycle
# and LLM tool wrappers (claude, copilot, opencode).
#
# Usage:
#   # In your .bashrc (or sourced automatically by install.sh):
#   source ~/.local/share/skm/shell/skm-init.sh

# --- Tool helpers ---

_in_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

_project_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

_skm_repo_name() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || true
}

# --- Session lifecycle ---

# Create symlinks for a spec in the session staging directory.
# Skills = directory symlinks, Agents = file symlinks.
_skm_create_session_symlink() {
  local id="$1"
  local staging="$2"
  local library_dir="${XDG_DATA_HOME:-$HOME/.local/share}/skm"
  local library_json="$library_dir/library.json"

  if [[ ! -f "$library_json" ]]; then
    echo "Warning: library.json not found at $library_json" >&2
    return 1
  fi

  local type
  type="$(jq -r --arg id "$id" '.specs[] | select(.id == $id) | .type' "$library_json")"

  if [[ -z "$type" ]]; then
    echo "Warning: spec '$id' not found in library" >&2
    return 1
  fi

  local subdir source_path
  case "$type" in
    skill)
      subdir="skills"
      source_path="$library_dir/skills/$id"
      ;;
    agent)
      subdir="agents"
      source_path="$library_dir/agents/${id}.md"
      ;;
    *)
      echo "Warning: unknown type '$type' for spec '$id'" >&2
      return 1
      ;;
  esac

  if [[ ! -e "$source_path" ]]; then
    echo "Warning: source not found for '$id' at $source_path" >&2
    return 1
  fi

  # Symlink into each tool subdirectory within the staging dir
  local tool_dir
  for tool_dir in .claude .copilot .agents; do
    local target_dir="$staging/$tool_dir/$subdir"
    if [[ "$type" == "skill" ]]; then
      ln -sfn "$source_path" "$target_dir/$id"
    else
      ln -sf "$source_path" "$target_dir/${id}.md"
    fi
  done
}

# Create a per-session staging directory and populate it from the project manifest.
# Exports SKM_SESSION. Prints the staging dir path to stdout.
# Returns 1 if not in a git repo (caller should skip staging).
_skm_session_start() {
  local project_root
  project_root="$(_project_root)"
  if [[ -z "$project_root" ]]; then
    return 1
  fi

  local project_name
  project_name="$(_skm_repo_name)"
  local session_id="${project_name:-anon}-$(date +%s)-$$"
  local staging="$HOME/.cache/skm/$session_id"

  # Create staging directory structure for all tool dirs
  local tool_dir
  for tool_dir in .claude .copilot .agents; do
    mkdir -p "$staging/$tool_dir"/{skills,agents}
  done

  # Layer 2: load specs from project manifest
  local manifest="$project_root/.agents/skm.json"

  if [[ -f "$manifest" ]] && command -v jq &>/dev/null; then
    local id
    # Load skills from manifest
    while IFS= read -r id; do
      if [[ -n "$id" ]]; then
        _skm_create_session_symlink "$id" "$staging" || true
      fi
    done < <(jq -r '.skills // [] | .[]' "$manifest" 2>/dev/null)

    # Load agents from manifest
    while IFS= read -r id; do
      if [[ -n "$id" ]]; then
        _skm_create_session_symlink "$id" "$staging" || true
      fi
    done < <(jq -r '.agents // [] | .[]' "$manifest" 2>/dev/null)
  fi

  export SKM_SESSION="$staging"
}

# Remove the session staging directory and unset the env var.
_skm_session_end() {
  if [[ -n "${SKM_SESSION:-}" && -d "$SKM_SESSION" ]]; then
    rm -rf "$SKM_SESSION"
  fi
  unset SKM_SESSION
}

# --- Tool wrappers ---
# These wrap LLM CLI tools to automatically:
#   1. Set up a per-session skills staging directory
#   2. Clean up on exit

_skm_wrap_tool() {
  local tool="$1"; shift
  local extra_args=()
  if _in_git_repo; then
    _skm_session_start && extra_args+=(--add-dir "$SKM_SESSION")
  fi

  command "$tool" "${extra_args[@]}" "$@"
  local exit_code=$?

  _skm_session_end
  return $exit_code
}

claude()   { _skm_wrap_tool claude   "$@"; }
copilot()  { _skm_wrap_tool copilot  "$@"; }
opencode() { _skm_wrap_tool opencode "$@"; }
