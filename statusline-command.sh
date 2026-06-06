#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown model"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session=$(echo "$input" | jq -r '.session_name // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
cumul_in=0; cumul_out=0; total_cost="0"

# Sum tokens from a jsonl, deduplicating by message.id, with per-model pricing.
# Prints: input_tokens output_tokens cost
aggregate_jsonl() {
  jq -r 'select(.message.usage != null and .message.stop_reason != null) |
    [(.message.id // ""),
     (.message.model // ""),
     (.message.usage.input_tokens // 0),
     (.message.usage.output_tokens // 0),
     (.message.usage.cache_creation_input_tokens // 0),
     (.message.usage.cache_read_input_tokens // 0)] | @tsv' \
    "$1" 2>/dev/null |
  sort -t$'\t' -k1,1 -u |
  awk -F'\t' '
    {
      ti += $3 + $5 + $6; to += $4
      pi=3.00; po=15.00; pcw=3.75; pcr=0.30
      if ($2 ~ /haiku/) { pi=0.80; po=4.00; pcw=1.00; pcr=0.08 }
      cost += ($3*pi + $4*po + $5*pcw + $6*pcr) / 1000000
    }
    END { print ti+0, to+0, cost+0 }'
}

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  read -r i o c < <(aggregate_jsonl "$transcript_path")
  cumul_in=$((cumul_in + i)); cumul_out=$((cumul_out + o))
  total_cost=$(awk "BEGIN {printf \"%.4f\", $total_cost + $c}")

  subagent_dir="$(dirname "$transcript_path")/$(basename "$transcript_path" .jsonl)/subagents"
  if [ -d "$subagent_dir" ]; then
    for sa_file in "$subagent_dir"/*.jsonl; do
      [ -f "$sa_file" ] || continue
      read -r i o c < <(aggregate_jsonl "$sa_file")
      cumul_in=$((cumul_in + i)); cumul_out=$((cumul_out + o))
      total_cost=$(awk "BEGIN {printf \"%.4f\", $total_cost + $c}")
    done
  fi
fi

fmt_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n/1000000
    else if (n >= 1000) printf "%.0fK", n/1000
    else printf "%d", n
  }'
}

parts="$model"

if [ -n "$effort" ]; then
  parts="$parts | effort:$effort"
fi

if [ -n "$used_pct" ]; then
  parts="$(printf '%s | ctx:%s%%' "$parts" "$(printf '%.0f' "$used_pct")")"
fi

five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_hr" ]; then
  parts="$(printf '%s | 5h:%s%%' "$parts" "$(printf '%.0f' "$five_hr")")"
fi

if [ "$cumul_out" -gt 0 ] 2>/dev/null; then
  parts="$parts | in:$(fmt_tokens "$cumul_in") out:$(fmt_tokens "$cumul_out") | \$$total_cost"
fi

if [ -n "$session" ]; then
  parts="$parts | $session"
fi

printf '%s' "$parts"
