#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
DIR_NAME=$(basename "$CURRENT_DIR")
MODEL=$(echo "$input" | jq -r '.model.display_name')
PERCENT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Format percentage to 1 decimal place
PERCENT_USED=$(printf "%.1f" "$PERCENT_USED")

# Format cost to show more precision for small amounts
if (( $(echo "$COST_USD < 0.01" | bc -l) )); then
    COST_DISPLAY=$(printf "%.4f" "$COST_USD")
else
    COST_DISPLAY=$(printf "%.2f" "$COST_USD")
fi

# Get git branch if in a git repo (change to current directory first)
GIT_BRANCH=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" ($BRANCH)"
    fi
fi

# Build status line with ANSI colors
# \033[36m = cyan, \033[32m = green, \033[33m = yellow, \033[35m = magenta, \033[0m = reset
echo -e "\033[36m${DIR_NAME}\033[0m\033[32m${GIT_BRANCH}\033[0m - \033[33m${MODEL}\033[0m - \033[35m${PERCENT_USED}%\033[0m - \033[36m\$${COST_DISPLAY}\033[0m"
