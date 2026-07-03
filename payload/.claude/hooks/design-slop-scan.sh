#!/usr/bin/env bash
#
# Deterministic design/text anti-slop scanner.
#
# This is a heuristic regex scanner, not a CSS or HTML parser. It is
# intentionally conservative and inherits the false-positive profile of raw text
# scans. Paragraph-opening uniformity is intentionally omitted; use the
# text-integrity-audit skill for that judgment.
#
set -u

JSON=0
STRICT=0
STRICT_TEXT=0
SELFTEST=0
CHANGED=0
PATHS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --json) JSON=1 ;;
    --strict) STRICT=1 ;;
    --strict-text) STRICT_TEXT=1 ;;
    --selftest) SELFTEST=1 ;;
    --changed) CHANGED=1 ;;
    -h|--help)
      sed -n '1,36p' "$0"
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

supported_path() {
  case "${1##*.}" in
    html|css|js|jsx|ts|tsx|astro|vue|svelte|md|txt) return 0 ;;
    HTML|CSS|JS|JSX|TS|TSX|ASTRO|VUE|SVELTE|MD|TXT) return 0 ;;
    *) return 1 ;;
  esac
}

collect_path_files() {
  local path="$1"
  if [[ -f "$path" ]]; then
    supported_path "$path" && FILES+=("$path")
  elif [[ -d "$path" ]]; then
    while IFS= read -r -d '' file; do
      supported_path "$file" && FILES+=("$file")
    done < <(
      find "$path" \
        \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name _archive -o -name coverage -o -name .venv -o -name venv -o -name vendor -o -name site-packages -o -name __pycache__ \) -prune \
        -o -type f -print0
    )
  fi
}

collect_changed_files() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'warning: --changed requested outside git repo; scanning requested paths\n' >&2
    return 1
  fi

  local file
  while IFS= read -r file; do
    [[ -n "$file" && -f "$file" ]] || continue
    supported_path "$file" && FILES+=("$file")
  done < <({ git diff --name-only HEAD -- 2>/dev/null; git ls-files -o --exclude-standard 2>/dev/null; } | sort -u)
  return 0
}

selftest() {
  local out json changed status scanner
  scanner="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
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
  if bash "$0" "$tmp/dirty.css" >/dev/null 2>&1; then
    printf 'selftest FAIL: gradient-text should fail\n' >&2
    return 1
  fi

  printf '.a{border-radius:24px}.b{border-radius:23px}.c{letter-spacing:-0.05em}.d{letter-spacing:-0.03em}.e{width:370px}.f{width:369px}' > "$tmp/numeric.css"
  out="$(bash "$0" "$tmp/numeric.css" 2>&1)"
  printf '%s\n' "$out" | grep -q 'soft-radius' || { printf 'selftest FAIL: border-radius numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'tight-letter-spacing' || { printf 'selftest FAIL: letter-spacing numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'large-fixed-width' || { printf 'selftest FAIL: width numeric rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q '23px' && { printf 'selftest FAIL: border-radius 23px should pass\n' >&2; return 1; }

  cat > "$tmp/no-alt.html" <<'HTML'
<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width"><title>Ok</title></head><body><img src="x.png"></body></html>
HTML
  if bash "$0" "$tmp/no-alt.html" >/dev/null 2>&1; then
    printf 'selftest FAIL: img without alt should fail\n' >&2
    return 1
  fi

  printf 'Texto limpo com travessão — apenas revisão.\n' > "$tmp/unicode.md"
  bash "$0" "$tmp/unicode.md" >/dev/null 2>&1 || { printf 'selftest FAIL: unicode punctuation should be P2 by default\n' >&2; return 1; }
  if bash "$0" --strict-text "$tmp/unicode.md" >/dev/null 2>&1; then
    printf 'selftest FAIL: --strict-text should fail unicode punctuation\n' >&2
    return 1
  fi

  printf 'Nesta seção vamos ver o método. Em resumo, é revolucionário, robusto, escalável e claro.\n' > "$tmp/accent.md"
  out="$(bash "$0" "$tmp/accent.md" 2>&1)"
  printf '%s\n' "$out" | grep -q 'advance-organizer' || { printf 'selftest FAIL: accented advance organizer missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'recap-reflex' || { printf 'selftest FAIL: accented recap reflex missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'unlock-language' || { printf 'selftest FAIL: accented unlock language missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q 'generic-quality-stack' || { printf 'selftest FAIL: accented quality stack missing\n' >&2; return 1; }

  yes 'um, dois, e tres' | head -n 5 > "$tmp/triads.md"
  out="$(bash "$0" "$tmp/triads.md" 2>&1)"
  printf '%s\n' "$out" | grep -q 'triadic-list-density' || { printf 'selftest FAIL: triadic rule missing\n' >&2; return 1; }
  printf '%s\n' "$out" | grep -q "$tmp/triads.md:1" || { printf 'selftest FAIL: triadic line should be first real triad\n' >&2; return 1; }

  printf 'body{color:#111}\n' > "$tmp/clean.css"
  bash "$0" "$tmp/clean.css" >/dev/null 2>&1 || { printf 'selftest FAIL: clean CSS should pass\n' >&2; return 1; }

  json="$(bash "$0" --json "$tmp/unicode.md" 2>&1)"
  printf '%s\n' "$json" | grep -q '"aggregates"' || { printf 'selftest FAIL: json aggregates missing\n' >&2; return 1; }

  if command -v git >/dev/null 2>&1; then
    mkdir "$tmp/repo"
    (cd "$tmp/repo" && git init -q && git config user.email a@example.com && git config user.name a &&
      printf 'body{color:#111}\n' > clean.css &&
      printf '.x{background:linear-gradient(90deg,purple,indigo)}\n' > dirty.css &&
      git add . && git commit -qm init &&
      printf '.x{background:linear-gradient(90deg,purple,indigo);background-clip:text}\n' > dirty.css &&
      printf '.y{border-radius:24px}\n' > untracked.css &&
      changed="$(bash "$scanner" --changed . 2>&1)" )
    status=$?
    [[ "$status" -eq 0 || "$status" -eq 1 ]] || { printf 'selftest FAIL: --changed execution failed\n' >&2; return 1; }
  fi

  printf 'selftest ok\n'
}

if [[ "$SELFTEST" -eq 1 ]]; then
  selftest
  exit $?
fi

if [[ "$CHANGED" -eq 1 ]]; then
  collect_changed_files || {
    for path in "${PATHS[@]}"; do collect_path_files "$path"; done
  }
else
  for path in "${PATHS[@]}"; do collect_path_files "$path"; done
fi

perl -Mutf8 -CSDA - "$JSON" "$STRICT" "$STRICT_TEXT" -- "${FILES[@]}" <<'PERL'
use strict;
use warnings;
use utf8;

my ($json_mode, $strict, $strict_text, $dash, @files) = @ARGV;
my @findings;
my $scanned = 0;
my $p1 = 0;
my $p2 = 0;
my $has_motion = 0;
my $has_reduced_motion = 0;
my ($first_motion_file, $first_motion_line) = ("", 1);

sub add_finding {
  my ($sev, $rule, $file, $line, $msg) = @_;
  $line ||= 1;
  push @findings, { severity => $sev, rule => $rule, file => $file, line => $line, message => $msg };
  if ($sev eq "P1") { $p1++ } else { $p2++ }
}

sub ext_of {
  my ($file) = @_;
  return "" unless $file =~ /\.([^.\/]+)$/;
  return lc $1;
}

sub is_design_ext {
  my ($ext) = @_;
  return $ext =~ /^(html|css|js|jsx|ts|tsx|astro|vue|svelte)$/;
}

sub is_text_ext {
  my ($ext) = @_;
  return $ext =~ /^(md|txt|html)$/;
}

sub read_file {
  my ($file) = @_;
  open my $fh, "<:encoding(UTF-8)", $file or return undef;
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}

sub line_at {
  my ($text, $offset) = @_;
  return 1 + (substr($text, 0, $offset) =~ tr/\n//);
}

sub first_line {
  my ($text, $re) = @_;
  my $pattern = "$re";
  $pattern =~ s/^\(\?\^?[a-z]*://;
  $pattern =~ s/\)$//;
  return undef unless $text =~ /$pattern/mi;
  return line_at($text, $-[0]);
}

sub scan_numeric_css {
  my ($file, $text) = @_;
  my @lines = split /\n/, $text, -1;
  for my $idx (0 .. $#lines) {
    my $line_no = $idx + 1;
    my $line = lc $lines[$idx];
    my @decls = split /[;}]/, $line;
    for my $decl (@decls) {
      if ($decl =~ /(^|[{\s])border-radius\s*:/) {
        if ($decl =~ /([0-9]+(?:\.[0-9]+)?)px/ && $1 >= 24 && $1 < 500) {
          add_finding("P2", "soft-radius", $file, $line_no, "border-radius >=24px should be reviewed against design tokens");
        }
      }
      if ($decl =~ /(^|[{\s])letter-spacing\s*:/) {
        if ($decl =~ /(-[0-9]+(?:\.[0-9]+)?)em/ && $1 < -0.04) {
          add_finding("P2", "tight-letter-spacing", $file, $line_no, "letter-spacing below -0.04em is fragile");
        }
        if ($decl =~ /(-[0-9]+(?:\.[0-9]+)?)px/ && $1 <= -1) {
          add_finding("P2", "tight-letter-spacing", $file, $line_no, "letter-spacing <= -1px is fragile");
        }
      }
      if ($decl =~ /(^|[{\s])width\s*:/) {
        add_finding("P2", "width-100vw", $file, $line_no, "width:100vw often causes horizontal overflow") if $decl =~ /100vw/;
        if ($decl =~ /([0-9]+(?:\.[0-9]+)?)px/ && $1 >= 370) {
          add_finding("P2", "large-fixed-width", $file, $line_no, "fixed width >=370px is risky on mobile");
        }
      }
      if ($decl =~ /(^|[{\s])border-(left|right)(-width)?\s*:/) {
        if ($decl =~ /([0-9]+(?:\.[0-9]+)?)px/ && $1 >= 2) {
          add_finding("P1", "side-accent-border", $file, $line_no, "side accent borders >=2px are blocked");
        }
      }
      if ($decl =~ /(^|[{\s])transition(-property)?\s*:/) {
        my $value = $decl;
        $value =~ s/^[^:]*://;
        add_finding("P2", "transition-all", $file, $line_no, "transition: all is too broad")
          if $value =~ /(^|[\s,])all($|[\s,])/;
        for my $part (split /,/, $value) {
          $part =~ s/^\s+|\s+$//g;
          my ($lead) = split /\s+/, $part;
          if (defined $lead && $lead =~ /^(width|height|min-width|max-width|min-height|max-height|margin|margin-left|margin-right|margin-top|margin-bottom|padding|padding-left|padding-right|padding-top|padding-bottom|inset|top|right|bottom|left)$/) {
            add_finding("P2", "layout-transition", $file, $line_no, "transitioning layout properties can cause jank");
          }
        }
      }
    }
  }
}

sub scan_html_document {
  my ($file, $text) = @_;
  return unless $text =~ /<!doctype\s+html|<html\b/i;
  return if $text =~ /\@dsCard\b/;

  add_finding("P1", "missing-viewport-meta", $file, 1, "complete HTML documents need a viewport meta tag")
    unless $text =~ /<meta\b[^>]*\bname\s*=\s*["']viewport["'][^>]*>/i;
  add_finding("P1", "missing-html-lang", $file, 1, "complete HTML documents need <html lang>")
    unless $text =~ /<html\b[^>]*\blang\s*=/i;
  add_finding("P1", "missing-title", $file, 1, "complete HTML documents need a non-empty title")
    unless $text =~ /<title\b[^>]*>\s*\S[\s\S]*?<\/title>/i;

  while ($text =~ /\bsrc\s*=\s*["']["']/gi) {
    add_finding("P1", "empty-src", $file, line_at($text, $-[0]), "empty src attributes are blocked");
  }
  while ($text =~ /<img\b([^>]*)>/gis) {
    my $attrs = $1;
    next if $attrs =~ /\balt\s*=/i;
    add_finding("P1", "image-missing-alt", $file, line_at($text, $-[0]), "<img> elements need alt attributes");
  }
}

sub scan_design_file {
  my ($file, $ext, $text) = @_;
  $has_reduced_motion = 1 if $text =~ /prefers-reduced-motion/i;
  if (my $line = first_line($text, qr/\@keyframes|(^|[^-])animation\s*:|transition\s*:/)) {
    $has_motion = 1;
    if ($first_motion_file eq "") {
      ($first_motion_file, $first_motion_line) = ($file, $line);
    }
  }

  if ($text =~ /background-clip\s*:\s*text|-webkit-background-clip\s*:\s*text/i && $text =~ /(linear|radial|conic)-gradient\s*\(/i) {
    add_finding("P1", "gradient-text", $file, 1, "gradient text is blocked by the design gate");
  }
  if (my $line = first_line($text, qr/font-size\s*:[^;}]*vw/)) {
    add_finding("P1", "font-size-vw", $file, $line, "font-size must not scale with viewport width");
  }
  if ($text =~ /outline\s*:\s*(none|0)([;}\s]|$)/i && $text !~ /:focus-visible|:focus[^{]*\{[^}]*(outline|box-shadow|border|background)/is) {
    add_finding("P1", "outline-none-without-focus", $file, first_line($text, qr/outline\s*:\s*(none|0)([;}\s]|$)/) || 1, "outline removal needs a visible focus remedy in the same file");
  }
  if ($text =~ /(linear|radial|conic)-gradient\s*\([^)]*(purple|violet|indigo)/i) {
    add_finding("P2", "purple-gradient", $file, first_line($text, qr/(purple|violet|indigo)/) || 1, "purple/violet/indigo gradients are common generated-design tells");
  }
  if (my $line = first_line($text, qr/backdrop-filter\s*:[^;}]*blur|backdrop-blur|glassmorphism/)) {
    add_finding("P2", "glassmorphism", $file, $line, "blurred glass effects need review");
  }

  scan_numeric_css($file, $text);

  while ($text =~ /img\s*:\s*hover\s*\{[^}]*transform/gis) {
    add_finding("P2", "image-hover-transform", $file, line_at($text, $-[0]), "hover transforms on images often feel templated");
  }
  if (my $line = first_line($text, qr/group-hover[^\s"']*(scale|rotate|translate)/)) {
    add_finding("P2", "group-hover-motion", $file, $line, "group-hover scale/rotate/translate needs visual review");
  }
  scan_html_document($file, $text) if $ext eq "html";
}

sub scan_text_file {
  my ($file, $text) = @_;
  return if $file =~ m{(^|/)payload/(CLAUDE|AGENTS)\.md$};

  if (my $line = first_line($text, qr/AI slop|anti-slop|AI-looking|generic AI/)) {
    add_finding("P1", "vague-generated-label", $file, $line, "vague generated-output labels are not useful evidence");
  }
  if (my $line = first_line($text, qr/^\s*(Certainly|Sure|Absolutely|Claro|Com certeza)[,! ]/)) {
    add_finding("P1", "acknowledgment-opener", $file, $line, "assistant acknowledgment openers should be removed");
  }
  if (my $line = first_line($text, qr/production-ready by construction|guaranteed results?|WCAG compliant by prompt|60fps guarantee/)) {
    add_finding("P1", "fake-finality", $file, $line, "unsupported finality or guarantees are blocked");
  }
  while ($text =~ /[—–→…“”‘’]/g) {
    add_finding("P2", "banned-unicode-punctuation", $file, line_at($text, $-[0]), "unicode punctuation is review-only by default; use --strict-text to fail it");
  }
  if (my $line = first_line($text, qr/in this section|we will explore|nesta seç[aã]o|nesta secao|vamos ver|vamos explorar/)) {
    add_finding("P2", "advance-organizer", $file, $line, "advance-organizer phrasing often reads generated");
  }
  if (my $line = first_line($text, qr/in conclusion|em conclus[aã]o|em resumo|recapitulando/)) {
    add_finding("P2", "recap-reflex", $file, $line, "generic recap phrasing needs review");
  }
  if (my $line = first_line($text, qr/[A-Za-zÀ-ÖØ-öø-ÿ0-9_-]+ is a concept that|[A-Za-zÀ-ÖØ-öø-ÿ0-9_-]+ [ée] um conceito que/)) {
    add_finding("P2", "definition-template", $file, $line, "definition-template sentence needs specificity");
  }
  if (my $line = first_line($text, qr/not just .* but|n[aã]o apenas .* mas|nao apenas .* mas/)) {
    add_finding("P2", "not-x-but-y", $file, $line, "not-X-but-Y contrast is often generic");
  }
  if (my $line = first_line($text, qr/unlock|unleash|elevate|game-changer|revolucion[aá]rio|revolucionario|transformador|transformative/)) {
    add_finding("P2", "unlock-language", $file, $line, "category-hype language needs review");
  }
  if (my $line = first_line($text, qr/clear, concise, and|robusto, escal[aá]vel e|robusto, escalavel e|robust, scalable, and/)) {
    add_finding("P2", "generic-quality-stack", $file, $line, "generic quality stacks need concrete proof");
  }

  my @words = ($text =~ /\p{L}+/g);
  my $threshold = int(@words / 250);
  $threshold = 3 if $threshold < 3;
  my $triads = 0;
  my $first_line;
  while ($text =~ /\b\p{L}+\b\s*,\s*\b\p{L}+\b\s*,?\s*(and|e)\s+\b\p{L}+\b/gui) {
    $triads++;
    $first_line ||= line_at($text, $-[0]);
  }
  if ($triads >= $threshold) {
    add_finding("P2", "triadic-list-density", $file, $first_line || 1, "triadic-list density $triads >= threshold $threshold");
  }
}

for my $file (@files) {
  next unless -f $file;
  my $ext = ext_of($file);
  my $design = is_design_ext($ext);
  my $text_file = is_text_ext($ext);
  next unless $design || $text_file;
  my $text = read_file($file);
  next unless defined $text;
  $scanned++;
  scan_design_file($file, $ext, $text) if $design;
  scan_text_file($file, $text) if $text_file;
}

if ($has_motion && !$has_reduced_motion) {
  add_finding("P2", "motion-without-reduced-motion", $first_motion_file, $first_motion_line, "motion exists but prefers-reduced-motion was not found in scanned design files");
}

my $should_fail = $p1 > 0 || ($strict && $p2 > 0);
if ($strict_text) {
  for my $f (@findings) {
    $should_fail = 1 if $f->{rule} eq "banned-unicode-punctuation";
  }
}

sub json_escape {
  my ($s) = @_;
  $s = "" unless defined $s;
  $s =~ s/\\/\\\\/g;
  $s =~ s/"/\\"/g;
  $s =~ s/\n/\\n/g;
  $s =~ s/\r/\\r/g;
  $s =~ s/\t/\\t/g;
  return $s;
}

my %groups;
for my $idx (0 .. $#findings) {
  my $f = $findings[$idx];
  my $key = join "\t", $f->{severity}, $f->{rule}, $f->{file}, $f->{message};
  push @{ $groups{$key} }, $f->{line};
}

if ($json_mode) {
  print '{"summary":{"scanned_files":' . $scanned . ',"p1":' . $p1 . ',"p2":' . $p2 . '},"findings":[';
  for my $i (0 .. $#findings) {
    print "," if $i;
    my $f = $findings[$i];
    print '{"severity":"' . json_escape($f->{severity}) . '","rule":"' . json_escape($f->{rule}) . '","file":"' . json_escape($f->{file}) . '","line":' . int($f->{line}) . ',"message":"' . json_escape($f->{message}) . '"}';
  }
  print '],"aggregates":[';
  my $first = 1;
  for my $key (sort keys %groups) {
    my ($sev, $rule, $file, $msg) = split /\t/, $key, 4;
    print "," unless $first;
    $first = 0;
    my @lines = @{ $groups{$key} };
    print '{"severity":"' . json_escape($sev) . '","rule":"' . json_escape($rule) . '","file":"' . json_escape($file) . '","count":' . scalar(@lines) . ',"sample_lines":[';
    for my $i (0 .. $#lines) {
      last if $i >= 3;
      print "," if $i;
      print int($lines[$i]);
    }
    print '],"message":"' . json_escape($msg) . '"}';
  }
  print "]}\n";
} else {
  for my $key (sort keys %groups) {
    my ($sev, $rule, $file, $msg) = split /\t/, $key, 4;
    my @lines = @{ $groups{$key} };
    my $limit = @lines < 3 ? scalar(@lines) : 3;
    my @sample = @lines[0 .. $limit - 1];
    my $line_label = join ",", @sample;
    my $suffix = "";
    if (@lines > 3) {
      my $more = @lines - 3;
      $suffix = " (... and $more more)";
    }
    print "$sev $file:$line_label $rule - $msg$suffix\n";
  }
  print "Scanned $scanned files -- $p1 P1 (fail), $p2 P2 (review)\n";
}

exit($should_fail ? 1 : 0);
PERL
