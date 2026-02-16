# Setup script for a new machine

# Check if SSH key is setup
# Checks if github cli (gh) is installed and setup
# Adds dot_bashrc to ~/.bashrc and source it
# Replaces .gitconfig with the contents of dot_gitconfig
# Clones git@github.com/rplsmn/llm-artifacts to ~/.artifacts
# Creates ~/.claude, ~/.copilot, ~/.vibe
# copies {agents/, commands/, skills/} to the root of each
# copies global-instructions.md to ~/.claude/CLAUDE.md, ~/.copilot/copilot-instructions.md and ~/.vibe/prompts/cli.md
# Add claude-code/claude-statusline.sh to ~/.claude and add the content of claude-code/claude-global-settings.json to ~/.claude/settings.json
