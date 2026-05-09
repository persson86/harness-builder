#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown model"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session=$(echo "$input" | jq -r '.session_name // empty')
in_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
out_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

parts=""

# Model
parts="$model"

# Effort (only when present)
if [ -n "$effort" ]; then
  parts="$parts | effort:$effort"
fi

# Context usage percentage (only after first message)
if [ -n "$used_pct" ]; then
  parts="$(printf '%s | ctx:%s%%' "$parts" "$(printf '%.0f' "$used_pct")")"
fi

# Tokens in/out and projected cost (only after first message)
if [ -n "$in_tokens" ] && [ -n "$out_tokens" ]; then
  parts="$parts | in:$in_tokens out:$out_tokens"
  cost=$(awk "BEGIN {
    printf \"%.4f\", ($in_tokens * 3.00 + $out_tokens * 15.00 + $cache_write * 3.75 + $cache_read * 0.30) / 1000000
  }")
  parts="$parts | \$$cost"
fi

# Session name (only when set)
if [ -n "$session" ]; then
  parts="$parts | $session"
fi

printf '%s' "$parts"
