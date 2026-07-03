#!/bin/bash
input=$(cat)

IFS=$'\037' read -r model effort used_pct session transcript_path five_hr five_hr_reset <<EOF
$(printf '%s' "$input" | jq -r '[.model.display_name // "unknown model", .effort.level // "", .context_window.used_percentage // "", .session_name // "", .transcript_path // "", .rate_limits.five_hour.used_percentage // "", .rate_limits.five_hour.resets_at // ""] | join("\u001f")')
EOF
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
      if ($2 ~ /fable|mythos/) { pi=10.00; po=50.00; pcw=12.50; pcr=1.00 }
      else if ($2 ~ /haiku/) { pi=1.00; po=5.00; pcw=1.25; pcr=0.10 }
      else if ($2 ~ /opus/) { pi=5.00; po=25.00; pcw=6.25; pcr=0.50 }
      else if ($2 ~ /sonnet-5|sonnet_5|Sonnet 5/) { pi=2.00; po=10.00; pcw=2.50; pcr=0.20 }
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

reset_to_epoch() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
    return 0
  fi
  if date -u -d "$value" +%s >/dev/null 2>&1; then
    date -u -d "$value" +%s
    return 0
  fi
  if date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$value" +%s >/dev/null 2>&1; then
    date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$value" +%s
    return 0
  fi
  return 1
}

parts="$model"

if [ -n "$effort" ]; then
  parts="$parts | effort:$effort"
fi

if [ -n "$used_pct" ]; then
  parts="$(printf '%s | ctx:%s%%' "$parts" "$(printf '%.0f' "$used_pct")")"
fi

if [ -n "$five_hr" ]; then
  reset_label=""
  if [ -n "$five_hr_reset" ]; then
    now=$(date +%s)
    reset_epoch="$(reset_to_epoch "$five_hr_reset" 2>/dev/null || printf '')"
    remaining=$((reset_epoch - now))
    if [ "$remaining" -gt 0 ] 2>/dev/null; then
      h=$((remaining / 3600))
      m=$(( (remaining % 3600) / 60 ))
      if [ "$h" -gt 0 ]; then
        reset_label=" (${h}h${m}m)"
      else
        reset_label=" (${m}m)"
      fi
    fi
  fi
  parts="$(printf '%s | 5h:%s%%%s' "$parts" "$(printf '%.0f' "$five_hr")" "$reset_label")"
fi

if [ "$cumul_out" -gt 0 ] 2>/dev/null; then
  parts="$parts | in:$(fmt_tokens "$cumul_in") out:$(fmt_tokens "$cumul_out") | \$$total_cost"
fi

if [ -n "$session" ]; then
  parts="$parts | $session"
fi

printf '%s' "$parts"
