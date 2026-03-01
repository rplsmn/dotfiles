#!/bin/bash
# Copilot CLI status line script
# Receives session JSON on stdin, outputs a formatted status line
# Enable with STATUS_LINE feature flag + status_line config in ~/.copilot/config.json

set -euo pipefail

INPUT=$(cat)

# --- Extract values from JSON ---
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // "unknown"')
PERCENT_USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.total_output_tokens // 0')
CACHE_READ=$(echo "$INPUT" | jq -r '.context_window.total_cache_read_tokens // 0')
CACHE_WRITE=$(echo "$INPUT" | jq -r '.context_window.total_cache_write_tokens // 0')

# --- Format percentage ---
PERCENT_USED=$(printf "%.0f" "$PERCENT_USED")

# --- Estimate cost from tokens and model pricing (USD per 1M tokens) ---
case "$MODEL_ID" in
  claude-opus-4.6|claude-opus-4.5)
    IN_PRICE=15; OUT_PRICE=75; CR_PRICE=1.5; CW_PRICE=18.75 ;;
  claude-sonnet-4.6|claude-sonnet-4.5|claude-sonnet-4)
    IN_PRICE=3; OUT_PRICE=15; CR_PRICE=0.3; CW_PRICE=3.75 ;;
  claude-haiku-4.5|claude-haiku-4)
    IN_PRICE=0.80; OUT_PRICE=4; CR_PRICE=0.08; CW_PRICE=1 ;;
  gpt-5.1-codex*|gpt-5.2-codex*|gpt-5.3-codex*)
    IN_PRICE=2.50; OUT_PRICE=10; CR_PRICE=0.25; CW_PRICE=2.50 ;;
  gpt-5*)
    IN_PRICE=5; OUT_PRICE=15; CR_PRICE=1.25; CW_PRICE=5 ;;
  gemini*)
    IN_PRICE=1.25; OUT_PRICE=10; CR_PRICE=0.31; CW_PRICE=1.25 ;;
  *)
    IN_PRICE=3; OUT_PRICE=15; CR_PRICE=0.3; CW_PRICE=3.75 ;;
esac

COST_USD=$(echo "scale=6; ($INPUT_TOKENS * $IN_PRICE + $OUTPUT_TOKENS * $OUT_PRICE + $CACHE_READ * $CR_PRICE + $CACHE_WRITE * $CW_PRICE) / 1000000" | bc -l)

if (( $(echo "$COST_USD < 0.01" | bc -l) )); then
  COST_DISPLAY=$(printf "%.4f" "$COST_USD")
else
  COST_DISPLAY=$(printf "%.2f" "$COST_USD")
fi

# --- Build status line (context + cost only, CLI shows dir/branch/model already) ---
echo "📊 ${PERCENT_USED}% ctx · 💰 \$${COST_DISPLAY}"
