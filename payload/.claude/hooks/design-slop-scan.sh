#!/usr/bin/env bash
#
# Deterministic design/text anti-slop scanner.
#
# This is a heuristic regex/awk/perl scanner, not a CSS or HTML parser. It is
# intentionally conservative and inherits the false-positive profile of raw text
# scans. Paragraph-opening uniformity is intentionally omitted; use the
# text-integrity-audit skill for that judgment.
#
set -u

JSON=0
STRICT=0
STRICT_TEXT=0
SELFTEST=0
PATHS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --json) JSON=1 ;;
    --strict) STRICT=1 ;;
    --strict-text) STRICT_TEXT=1 ;;
    --selftest) SELFTEST=1 ;;
    -h|--help)
      sed -n '1,38p' "$0"
      exit 0
      ;;
    --) shift; break ;;
    -*) printf 'error: unknown flag: %s\n' "$1" >&2; exit 2 ;;
    *) PATHS+=("$1") ;;
  esac
  shift
done
while [[ "$#" -gt 0 ]]; do
  PATHS+=("$1")
  shift
done
[[ "${#PATHS[@]}" -gt 0 ]] || PATHS=(".")

FILES=()
FIND_SEV=()
FIND_RULE=()
FIND_FILE=()
FIND_LINE=()
FIND_MSG=()
SCANNED=0
P1=0
P2=0
HAS_REDUCED_MOTION=0
HAS_MOTION=0
FIRST_MOTION_FILE=""
FIRST_MOTION_LINE=1

add_finding() {
  local sev="$1" rule="$2" file="$3" line="$4" msg="$5"
  FIND_SEV+=("$sev")
  FIND_RULE+=("$rule")
  FIND_FILE+=("$file")
  FIND_LINE+=("${line:-1}")
  FIND_MSG+=("$msg")
  if [[ "$sev" == "P1" ]]; then
    P1=$((P1 + 1))
  else
    P2=$((P2 + 1))
  fi
}

lower_ext() {
  local name="$1" ext
  ext="${name##*.}"
  [[ "$ext" != "$name" ]] || { printf ''; return; }
  printf '%s' "$ext" | tr '[:upper:]' '[:lower:]'
}

is_design_ext() {
  case "$1" in
    html|css|js|jsx|ts|tsx|astro|vue|svelte) return 0 ;;
    *) return 1 ;;
  esac
}

is_text_ext() {
  case "$1" in
    md|txt|html) return 0 ;;
    *) return 1 ;;
  esac
}

first_line_matching() {
  local file="$1" pattern="$2"
  PATTERN="$pattern" perl -Mutf8 -MEncode=decode -CSDA -ne '
    BEGIN { $pat = decode("UTF-8", $ENV{"PATTERN"}); }
    if (/$pat/i) { print "$.\n"; exit }
  ' "$file" 2>/dev/null
}

grep_file_i() {
  local file="$1" pattern="$2"
  grep -Eiq "$pattern" "$file" 2>/dev/null
}

perl_file_has() {
  local file="$1" pattern="$2"
  perl -Mutf8 -CSDA -0777 -ne "exit(($pattern) ? 0 : 1)" "$file" 2>/dev/null
}

scan_numeric_css() {
  local file="$1"
  while IFS="$(printf '\t')" read -r rule line msg; do
    case "$rule" in
      side-accent-border) add_finding "P1" "$rule" "$file" "$line" "$msg" ;;
      *) add_finding "P2" "$rule" "$file" "$line" "$msg" ;;
    esac
  done < <(awk '
    function emit(rule, msg) { print rule "\t" NR "\t" msg }
    function px_value(text,   m) {
      if (match(text, /[0-9]+(\.[0-9]+)?px/)) return substr(text, RSTART, RLENGTH) + 0
      return -1
    }
    function em_value(text) {
      if (match(text, /-[0-9]+(\.[0-9]+)?em/)) return substr(text, RSTART, RLENGTH) + 0
      return 0
    }
    function negative_px_value(text) {
      if (match(text, /-[0-9]+(\.[0-9]+)?px/)) return substr(text, RSTART, RLENGTH) + 0
      return 0
    }
    function prop_decl(text, prop) {
      return text ~ ("(^|[{[:space:]])" prop "[[:space:]]*:")
    }
    {
      line = tolower($0)
      ndecl = split(line, decls, /[;}]/)
      for (d = 1; d <= ndecl; d++) {
        decl = decls[d]

        if (prop_decl(decl, "border-radius")) {
          val = px_value(decl)
          if (val >= 24 && val < 500) emit("soft-radius", "border-radius >=24px should be reviewed against design tokens")
        }

        if (prop_decl(decl, "letter-spacing")) {
          val = em_value(decl)
          if (val < -0.04) emit("tight-letter-spacing", "letter-spacing below -0.04em is fragile")
          val = negative_px_value(decl)
          if (val <= -1) emit("tight-letter-spacing", "letter-spacing <= -1px is fragile")
        }

        if (prop_decl(decl, "width")) {
          if (decl ~ /100vw/) emit("width-100vw", "width:100vw often causes horizontal overflow")
          val = px_value(decl)
          if (val >= 370) emit("large-fixed-width", "fixed width >=370px is risky on mobile")
        }

        if (decl ~ /(^|[{[:space:]])border-(left|right)(-width)?[[:space:]]*:/) {
          val = px_value(decl)
          if (val >= 2) emit("side-accent-border", "side accent borders >=2px are blocked")
        }

        if (decl ~ /(^|[{[:space:]])transition(-property)?[[:space:]]*:/) {
          sub(/^[^:]*:/, "", decl)
          if (decl ~ /(^|[[:space:],])all($|[[:space:],])/) {
            emit("transition-all", "transition: all is too broad")
          }
          n = split(decl, parts, ",")
          for (i = 1; i <= n; i++) {
            prop = parts[i]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", prop)
            split(prop, words, /[[:space:]]+/)
            lead = words[1]
            if (lead ~ /^(width|height|min-width|max-width|min-height|max-height|margin|margin-left|margin-right|margin-top|margin-bottom|padding|padding-left|padding-right|padding-top|padding-bottom|inset|top|right|bottom|left)$/) {
              emit("layout-transition", "transitioning layout properties can cause jank")
            }
          }
        }
      }
    }
  ' "$file")
}

scan_html_document() {
  local file="$1" line
  perl_file_has "$file" 'm/(<!doctype\s+html|<html\b)/i' || return 0
  perl_file_has "$file" 'm/\@dsCard\b/' && return 0

  if ! perl_file_has "$file" 'm/<meta\b[^>]*\bname\s*=\s*["'\'']viewport["'\''][^>]*>/i'; then
    add_finding "P1" "missing-viewport-meta" "$file" 1 "complete HTML documents need a viewport meta tag"
  fi
  if ! perl_file_has "$file" 'm/<html\b[^>]*\blang\s*=/i'; then
    add_finding "P1" "missing-html-lang" "$file" 1 "complete HTML documents need <html lang>"
  fi
  if ! perl_file_has "$file" 'm/<title\b[^>]*>\s*\S[\s\S]*?<\/title>/i'; then
    add_finding "P1" "missing-title" "$file" 1 "complete HTML documents need a non-empty title"
  fi

  while IFS=: read -r line _; do
    [[ -n "$line" ]] || continue
    add_finding "P1" "empty-src" "$file" "$line" "empty src attributes are blocked"
  done < <(grep -Ein '\bsrc[[:space:]]*=[[:space:]]*["'\'']["'\'']' "$file" 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    add_finding "P1" "image-missing-alt" "$file" "$line" "<img> elements need alt attributes"
  done < <(perl -Mutf8 -CSDA -0777 -ne '
    while (/<img\b([^>]*)>/gis) {
      my $attrs = $1;
      next if $attrs =~ /\balt\s*=/i;
      my $before = substr($_, 0, $-[0]);
      my $line = 1 + ($before =~ tr/\n//);
      print "$line\n";
    }
  ' "$file" 2>/dev/null)
}

scan_design_file() {
  local file="$1" ext="$2" line

  if grep_file_i "$file" 'prefers-reduced-motion'; then
    HAS_REDUCED_MOTION=1
  fi
  line="$(first_line_matching "$file" '(@keyframes|(^|[^-])animation[[:space:]]*:|transition[[:space:]]*:)')"
  if [[ -n "$line" ]]; then
    HAS_MOTION=1
    if [[ -z "$FIRST_MOTION_FILE" ]]; then
      FIRST_MOTION_FILE="$file"
      FIRST_MOTION_LINE="$line"
    fi
  fi

  if grep_file_i "$file" 'background-clip[[:space:]]*:[[:space:]]*text|-webkit-background-clip[[:space:]]*:[[:space:]]*text' &&
     grep_file_i "$file" '(linear|radial|conic)-gradient[[:space:]]*\('; then
    add_finding "P1" "gradient-text" "$file" 1 "gradient text is blocked by the design gate"
  fi

  line="$(first_line_matching "$file" 'font-size[[:space:]]*:[^;}]*vw')"
  [[ -z "$line" ]] || add_finding "P1" "font-size-vw" "$file" "$line" "font-size must not scale with viewport width"

  if grep_file_i "$file" 'outline[[:space:]]*:[[:space:]]*(none|0)([;}[:space:]]|$)' &&
     ! perl_file_has "$file" 'm/:focus-visible|:focus[^{]*\{[^}]*(outline|box-shadow|border|background)/is'; then
    line="$(first_line_matching "$file" 'outline[[:space:]]*:[[:space:]]*(none|0)([;}[:space:]]|$)')"
    add_finding "P1" "outline-none-without-focus" "$file" "${line:-1}" "outline removal needs a visible focus remedy in the same file"
  fi

  if grep_file_i "$file" '(linear|radial|conic)-gradient[[:space:]]*\([^)]*(purple|violet|indigo)'; then
    line="$(first_line_matching "$file" '(purple|violet|indigo)')"
    add_finding "P2" "purple-gradient" "$file" "${line:-1}" "purple/violet/indigo gradients are common generated-design tells"
  fi

  line="$(first_line_matching "$file" '(backdrop-filter[[:space:]]*:[^;}]*blur|backdrop-blur|glassmorphism)')"
  [[ -z "$line" ]] || add_finding "P2" "glassmorphism" "$file" "$line" "blurred glass effects need review"

  scan_numeric_css "$file"

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    add_finding "P2" "image-hover-transform" "$file" "$line" "hover transforms on images often feel templated"
  done < <(perl -Mutf8 -CSDA -0777 -ne '
    while (/img\s*:\s*hover\s*\{[^}]*transform/gsii) {
      my $before = substr($_, 0, $-[0]);
      my $line = 1 + ($before =~ tr/\n//);
      print "$line\n";
    }
  ' "$file" 2>/dev/null)

  line="$(first_line_matching "$file" 'group-hover[^[:space:]"'\'']*(scale|rotate|translate)')"
  [[ -z "$line" ]] || add_finding "P2" "group-hover-motion" "$file" "$line" "group-hover scale/rotate/translate needs visual review"

  if [[ "$ext" == "html" ]]; then
    scan_html_document "$file"
  fi
}

scan_text_file() {
  local file="$1" line

  line="$(first_line_matching "$file" '(AI slop|anti-slop|AI-looking|generic AI)')"
  [[ -z "$line" ]] || add_finding "P1" "vague-generated-label" "$file" "$line" "vague generated-output labels are not useful evidence"

  line="$(first_line_matching "$file" '^[[:space:]]*(Certainly|Sure|Absolutely|Claro|Com certeza)[,! ]')"
  [[ -z "$line" ]] || add_finding "P1" "acknowledgment-opener" "$file" "$line" "assistant acknowledgment openers should be removed"

  line="$(first_line_matching "$file" '(production-ready by construction|guaranteed results?|WCAG compliant by prompt|60fps guarantee)')"
  [[ -z "$line" ]] || add_finding "P1" "fake-finality" "$file" "$line" "unsupported finality or guarantees are blocked"

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    add_finding "P2" "banned-unicode-punctuation" "$file" "$line" "unicode punctuation is review-only by default; use --strict-text to fail it"
  done < <(perl -Mutf8 -CSDA -ne '
    if (/[—–→…“”‘’]/) { print "$.\n" }
  ' "$file" 2>/dev/null)

  line="$(first_line_matching "$file" '(in this section|we will explore|nesta seç[aã]o|nesta secao|vamos ver|vamos explorar)')"
  [[ -z "$line" ]] || add_finding "P2" "advance-organizer" "$file" "$line" "advance-organizer phrasing often reads generated"

  line="$(first_line_matching "$file" '(in conclusion|em conclus[aã]o|em resumo|recapitulando)')"
  [[ -z "$line" ]] || add_finding "P2" "recap-reflex" "$file" "$line" "generic recap phrasing needs review"

  line="$(first_line_matching "$file" '([A-Za-zÀ-ÖØ-öø-ÿ0-9_-]+ is a concept that|[A-Za-zÀ-ÖØ-öø-ÿ0-9_-]+ [ée] um conceito que)')"
  [[ -z "$line" ]] || add_finding "P2" "definition-template" "$file" "$line" "definition-template sentence needs specificity"

  line="$(first_line_matching "$file" '(not just .* but|n[aã]o apenas .* mas|nao apenas .* mas)')"
  [[ -z "$line" ]] || add_finding "P2" "not-x-but-y" "$file" "$line" "not-X-but-Y contrast is often generic"

  line="$(first_line_matching "$file" '(unlock|unleash|elevate|game-changer|revolucion[aá]rio|revolucionario|transformador|transformative)')"
  [[ -z "$line" ]] || add_finding "P2" "unlock-language" "$file" "$line" "category-hype language needs review"

  line="$(first_line_matching "$file" '(clear, concise, and|robusto, escal[aá]vel e|robusto, escalavel e|robust, scalable, and)')"
  [[ -z "$line" ]] || add_finding "P2" "generic-quality-stack" "$file" "$line" "generic quality stacks need concrete proof"

  while IFS="$(printf '\t')" read -r line triads threshold; do
    [[ -n "$line" ]] || continue
    add_finding "P2" "triadic-list-density" "$file" "$line" "triadic-list density $triads >= threshold $threshold"
  done < <(perl -Mutf8 -CSDA -0777 -ne '
    my $text = $_;
    my @words = ($text =~ /\p{L}+/g);
    my $threshold = int(@words / 250);
    $threshold = 3 if $threshold < 3;
    my $triads = 0;
    while ($text =~ /\b\p{L}+\b\s*,\s*\b\p{L}+\b\s*,?\s*(and|e)\s+\b\p{L}+\b/gui) {
      $triads++;
    }
    if ($triads >= $threshold) { print "1\t$triads\t$threshold\n" }
  ' "$file" 2>/dev/null)
}

collect_files() {
  local path="$1"
  if [[ -f "$path" ]]; then
    FILES+=("$path")
  elif [[ -d "$path" ]]; then
    while IFS= read -r -d '' file; do
      FILES+=("$file")
    done < <(
      find "$path" \
        \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name _archive -o -name coverage -o -name .venv -o -name venv -o -name vendor -o -name site-packages -o -name __pycache__ \) -prune \
        -o -type f -print0
    )
  fi
}

json_escape() {
  perl -Mutf8 -CS -pe 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g'
}

print_results() {
  local i count should_fail=0
  [[ "$P1" -gt 0 ]] && should_fail=1
  [[ "$STRICT" -eq 1 && "$P2" -gt 0 ]] && should_fail=1
  if [[ "$STRICT_TEXT" -eq 1 ]]; then
    count="${#FIND_RULE[@]}"
    i=0
    while [[ "$i" -lt "$count" ]]; do
      [[ "${FIND_RULE[$i]}" != "banned-unicode-punctuation" ]] || should_fail=1
      i=$((i + 1))
    done
  fi

  if [[ "$JSON" -eq 1 ]]; then
    printf '{"summary":{"scanned_files":%s,"p1":%s,"p2":%s},"findings":[' "$SCANNED" "$P1" "$P2"
    count="${#FIND_SEV[@]}"
    i=0
    while [[ "$i" -lt "$count" ]]; do
      [[ "$i" -eq 0 ]] || printf ','
      printf '{"severity":"%s","rule":"%s","file":"%s","line":%s,"message":"%s"}' \
        "$(printf '%s' "${FIND_SEV[$i]}" | json_escape)" \
        "$(printf '%s' "${FIND_RULE[$i]}" | json_escape)" \
        "$(printf '%s' "${FIND_FILE[$i]}" | json_escape)" \
        "${FIND_LINE[$i]}" \
        "$(printf '%s' "${FIND_MSG[$i]}" | json_escape)"
      i=$((i + 1))
    done
    printf ']}\n'
  else
    count="${#FIND_SEV[@]}"
    i=0
    while [[ "$i" -lt "$count" ]]; do
      printf '%s %s:%s %s - %s\n' "${FIND_SEV[$i]}" "${FIND_FILE[$i]}" "${FIND_LINE[$i]}" "${FIND_RULE[$i]}" "${FIND_MSG[$i]}"
      i=$((i + 1))
    done
    printf 'Scanned %s files -- %s P1 (fail), %s P2 (review)\n' "$SCANNED" "$P1" "$P2"
  fi

  if [[ "$should_fail" -eq 1 ]]; then
    return 1
  fi
  return 0
}

run_scan() {
  local path file ext design text
  for path in "${PATHS[@]}"; do
    collect_files "$path"
  done

  for file in "${FILES[@]}"; do
    [[ -f "$file" ]] || continue
    ext="$(lower_ext "$file")"
    design=1
    text=1
    is_design_ext "$ext" && design=0
    is_text_ext "$ext" && text=0
    [[ "$design" -eq 0 || "$text" -eq 0 ]] || continue
    SCANNED=$((SCANNED + 1))
    [[ "$design" -ne 0 ]] || scan_design_file "$file" "$ext"
    [[ "$text" -ne 0 ]] || scan_text_file "$file"
  done

  if [[ "$HAS_MOTION" -eq 1 && "$HAS_REDUCED_MOTION" -eq 0 ]]; then
    add_finding "P2" "motion-without-reduced-motion" "$FIRST_MOTION_FILE" "$FIRST_MOTION_LINE" "motion exists but prefers-reduced-motion was not found in scanned design files"
  fi

  print_results
}

selftest() {
  local out status
  SELFTEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/design-slop-scan.XXXXXX")" || exit 1
  trap 'rm -rf "${SELFTEST_TMP:-}"' EXIT
  local tmp="$SELFTEST_TMP"

  cat > "$tmp/dirty.css" <<'CSS'
.title {
  background: linear-gradient(90deg, red, blue);
  background-clip: text;
  color: transparent;
}
CSS
  if "$0" "$tmp/dirty.css" >/dev/null 2>&1; then
    printf 'selftest FAIL: gradient-text should fail\n' >&2
    return 1
  fi

  printf '.a{border-radius:24px}.b{border-radius:23px}.c{letter-spacing:-0.05em}.d{letter-spacing:-0.03em}.e{width:370px}.f{width:369px}' > "$tmp/numeric.css"
  out="$("$0" "$tmp/numeric.css" 2>&1)"
  printf '%s\n' "$out" | grep -q 'soft-radius' || { printf 'selftest FAIL: border-radius numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'tight-letter-spacing' || { printf 'selftest FAIL: letter-spacing numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'large-fixed-width' || { printf 'selftest FAIL: width numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q '23px' && { printf 'selftest FAIL: border-radius 23px should pass\n' >&2; return 1; }

  cat > "$tmp/no-alt.html" <<'HTML'
<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width"><title>Ok</title></head><body><img src="x.png"></body></html>
HTML
  if "$0" "$tmp/no-alt.html" >/dev/null 2>&1; then
    printf 'selftest FAIL: img without alt should fail\n' >&2
    return 1
  fi

  printf 'Texto limpo com travessão — apenas revisão.\n' > "$tmp/unicode.md"
  "$0" "$tmp/unicode.md" >/dev/null 2>&1 || { printf 'selftest FAIL: unicode punctuation should be P2 by default\n' >&2; return 1; }
  if "$0" --strict-text "$tmp/unicode.md" >/dev/null 2>&1; then
    printf 'selftest FAIL: --strict-text should fail unicode punctuation\n' >&2
    return 1
  fi

  printf 'Nesta seção vamos ver o método. Em resumo, é revolucionário, robusto, escalável e claro.\n' > "$tmp/accent.md"
  out="$("$0" "$tmp/accent.md" 2>&1)"
  printf '%s\n' "$out" | grep -q 'advance-organizer' || { printf 'selftest FAIL: accented advance organizer missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'recap-reflex' || { printf 'selftest FAIL: accented recap reflex missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'unlock-language' || { printf 'selftest FAIL: accented unlock language missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'generic-quality-stack' || { printf 'selftest FAIL: accented quality stack missing\n' >&2; return 1; }

  printf 'body{color:#111}\n' > "$tmp/clean.css"
  "$0" "$tmp/clean.css" >/dev/null 2>&1 || { printf 'selftest FAIL: clean CSS should pass\n' >&2; return 1; }

  printf 'selftest ok\n'
}

if [[ "$SELFTEST" -eq 1 ]]; then
  selftest
else
  run_scan
fi
