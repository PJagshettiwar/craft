#!/usr/bin/env bash
# craft-doctor — deterministic CLAUDE.md verifier. No LLM, no network, ~1s.
#
# Answers one question: can this CLAUDE.md be trusted?
# Reports DRIFT only for things it can actually prove wrong. Everything it cannot
# check deterministically is UNCHECKED, never DRIFT — a false drift signal makes
# craft downgrade a good section to "hints" and is worse than no signal at all.
#
# Usage:  craft-doctor.sh [--file PATH] [--quiet] [--selftest]
# Exit:   0 = ran successfully (drift is reported, not fatal — warnings never block)
#         1 = could not run (no file, bad args)
#         2 = selftest failed
#
# Output is machine-parseable; ~9 copied preflight blocks read it.
#   DRIFT      <kind> <token> — <why>
#   UNCHECKED  <kind> <token> — <why>
#   STALE      <section> — verified <YYYY-MM>, older than <N> months
#   SUMMARY    drift=<n> unchecked=<n> stale=<n> lines=<n>/<max> sections_drifted=<a,b>

set -uo pipefail

FILE="CLAUDE.md"
QUIET=0
MAX_LINES=400
STALE_MONTHS=6

# Sections whose backticked tokens are checkable. Anything else is prose.
PATH_SECTIONS="## Reuse Map|## Architecture|## Do NOT|## Patterns"
CMD_SECTIONS="## Commands"
SYMBOL_SECTIONS="## Reuse Map|## Patterns"

while [ $# -gt 0 ]; do
  case "$1" in
    --file)     FILE="${2:-}"; shift 2 ;;
    --quiet)    QUIET=1; shift ;;
    --verbose)  VERBOSE=1; shift ;;
    --selftest) selftest=1; shift ;;
    -h|--help)  sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "craft-doctor: unknown arg '$1'" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------- extraction --
# Emits: <kind>\t<section>\t<token>
# kind ∈ path | cmd | symbol
#
# Rules (from the plan §2.6, kept narrow on purpose):
#   - fenced code blocks are skipped entirely — they hold examples, not claims
#   - a line with <!-- doctor:ignore --> is skipped
#   - only backticked tokens count; bare prose never does
#   - path  = contains "/", no spaces, not a URL / @scope package / glob
#   - cmd   = first word of a backticked token under ## Commands
#   - symbol= anything else in a checkable section — UNCHECKED without an LSP
extract() {
  awk -v paths="$PATH_SECTIONS" -v cmds="$CMD_SECTIONS" -v syms="$SYMBOL_SECTIONS" '
    /^```/          { fence = !fence; next }
    fence           { next }
    /doctor:ignore/ { next }
    /^## /          { section = $0; next }
    {
      line = $0
      while (match(line, /`[^`]+`/)) {
        tok = substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)

        if (section ~ cmds) {
          split(tok, w, " ")
          if (w[1] != "") print "cmd\t" section "\t" w[1]
          continue
        }
        if (tok ~ / /)     continue   # a phrase, not a token
        if (tok ~ /:\/\//) continue   # URL
        if (tok ~ /^@/)    continue   # @scope/package
        if (tok ~ /[*?]/)  continue   # glob

        # ONLY a slash means path. Everything else is a symbol claim we cannot
        # resolve without a language server, so it goes UNCHECKED.
        #
        # Tested against a real 283-line CLAUDE.md: the looser "contains / or ."
        # rule produced 12 DRIFT lines and 0 were real — `TableSchema.fromBean()`,
        # `MetricsInitializer.java`, `super.open(openContext)`. Since §2.3 downgrades
        # drifted sections to hints, that rule would have stripped a good
        # Architecture section out of every review. Over-reporting DRIFT is the one
        # failure mode that actively makes craft worse, so ambiguity → UNCHECKED.
        if (tok ~ /\//)                     { print "path\t"   section "\t" tok; continue }
        if (section ~ syms || section ~ paths) { print "symbol\t" section "\t" tok }
      }
    }
  ' "$1"
}

# ------------------------------------------------------------------ selftest --
if [ "${selftest:-0}" = 1 ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$tmp/src"; : > "$tmp/src/real.js"
  cat > "$tmp/CLAUDE.md" <<'EOF'
# Test
## Commands
- Test: `definitely-not-a-real-binary-xyz test`
- List: `ls -la`
## Reuse Map
- `src/real.js` — exists
- `src/gone.js` — does not exist
- `HttpClient.get` — a symbol, not a path
- ignore me `src/ignored.js` <!-- doctor:ignore -->
## Architecture
See `https://example.com/x` and `@scope/pkg` and `src/**/*.js` — none are checkable.
Call `Widget.build()` before `super.open(ctx)` — symbols, not files.
```
`src/in-a-fence.js` must be skipped
```
EOF
  cd "$tmp" || exit 2
  out="$("$OLDPWD/scripts/craft-doctor.sh" --file CLAUDE.md 2>&1)"
  fail=0
  check() { # description, pattern, expect(0=present,1=absent)
    if echo "$out" | grep -q "$2"; then got=0; else got=1; fi
    if [ "$got" != "$3" ]; then echo "SELFTEST FAIL: $1"; fail=1; fi
  }
  check "missing path flagged"        "DRIFT.*src/gone.js"        0
  check "existing path not flagged"   "DRIFT.*src/real.js"        1
  check "missing binary flagged"      "DRIFT.*definitely-not-a-real-binary-xyz" 0
  check "present binary not flagged"  "DRIFT.*cmd.*ls"            1
  check "fenced path skipped"         "in-a-fence.js"             1
  check "doctor:ignore respected"     "src/ignored.js"            1
  check "URL skipped"                 "example.com"               1
  check "@scope skipped"              "@scope/pkg"                1
  check "glob skipped"                "src/\*\*"                  1
  check "symbol unchecked not drift"  "DRIFT.*HttpClient"        1
  # Regression guard: dotted symbols must never be reported as missing paths.
  # A real 283-line CLAUDE.md produced 12 such false positives before this rule.
  check "dotted symbol is not a path" "DRIFT.*path.*HttpClient"   1
  check "method call is not a path"   "DRIFT.*Widget.build()"     1
  [ "$fail" = 0 ] && echo "SELFTEST PASS (12 checks)"
  exit "$fail"
fi

# ---------------------------------------------------------------------- main --
[ -f "$FILE" ] || { echo "SUMMARY drift=0 unchecked=0 stale=0 lines=0/$MAX_LINES no-file=$FILE"; exit 0; }

drift=0; unchecked=0; stale=0
drifted_sections=""
note() { [ "$QUIET" = 1 ] || echo "$1"; }
mark_section() {
  case ",$drifted_sections," in
    *",$1,"*) ;;
    *) drifted_sections="${drifted_sections:+$drifted_sections,}$1" ;;
  esac
}

# Serena decides whether symbols are checkable at all.
if [ -n "${CRAFT_SERENA:-}" ]; then HAS_LSP=1; else HAS_LSP=0; fi

while IFS="$(printf '\t')" read -r kind section token; do
  [ -n "${kind:-}" ] || continue
  short="$(echo "$section" | sed 's/^## //')"
  case "$kind" in
    path)
      if [ ! -e "$token" ]; then
        note "DRIFT      path $token — no such file or directory"
        drift=$((drift + 1)); mark_section "$short"
      fi
      ;;
    cmd)
      if ! command -v "$token" >/dev/null 2>&1; then
        note "DRIFT      cmd $token — not on PATH"
        drift=$((drift + 1)); mark_section "$short"
      fi
      ;;
    symbol)
      if [ "$HAS_LSP" = 0 ]; then
        # Counted always, printed only with --verbose: a real CLAUDE.md yields ~100
        # of these and they'd bury the DRIFT lines that actually need action.
        [ "${VERBOSE:-0}" = 1 ] && note "UNCHECKED  symbol $token — no language server"
        unchecked=$((unchecked + 1))
      fi
      # ponytail: LSP path deferred to wave 7 — needs Serena MCP, not a shell call.
      ;;
  esac
done <<EOF
$(extract "$FILE")
EOF

# Freshness. A section claiming to be verified in 2024 is a claim, and a checkable one.
now_months=$(( $(date +%Y) * 12 + $(date +%m) ))
while IFS= read -r line; do
  case "$line" in
    "## "*) cur="${line#\#\# }" ;;
  esac
  stamp="$(echo "$line" | sed -n 's/.*<!-- *verified: *\([0-9]\{4\}\)-\([0-9]\{2\}\).*/\1 \2/p')"
  if [ -n "$stamp" ]; then
    y="${stamp% *}"; m="${stamp#* }"
    age=$(( now_months - (10#$y * 12 + 10#$m) ))
    if [ "$age" -gt "$STALE_MONTHS" ]; then
      note "STALE      ${cur:-<top>} — verified $y-$m, ${age} months old"
      stale=$((stale + 1))
    fi
  fi
done < "$FILE"

lines=$(wc -l < "$FILE" | tr -d ' ')
[ "$lines" -le "$MAX_LINES" ] || note "DRIFT      size $FILE — $lines lines, over the $MAX_LINES ceiling"
[ "$lines" -le "$MAX_LINES" ] || drift=$((drift + 1))

echo "SUMMARY drift=$drift unchecked=$unchecked stale=$stale lines=$lines/$MAX_LINES sections_drifted=${drifted_sections:-none}"
exit 0
