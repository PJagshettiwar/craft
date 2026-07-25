#!/usr/bin/env bash
# check-doctrine — proves the copied Superpowers doctrine is actually present in craft.
#
# This is the mechanical half of the copy gate (plan §5.3). It proves a string is
# PRESENT in a file. It cannot prove the string sits somewhere the model reads before
# acting — that is what the behavioural scenarios in §5.3 step 2 are for. Passing this
# is necessary, not sufficient, and it does not authorise the Wave 2b deletion on its own.
#
# Usage:  check-doctrine.sh              verify craft files contain the doctrine
#         check-doctrine.sh --sources    verify the literals still match Superpowers 5.0.7
# Exit:   0 all present · 1 something missing

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SP="${SUPERPOWERS_HOME:-$HOME/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7}"

# target-in-craft | source-skill | verbatim literal
#
# Every literal below is anti-rationalisation text: its job is to foreclose a specific
# excuse the model is about to generate. Paraphrase kills it, so it is checked exactly.
manifest() {
  cat <<'EOF'
doctrine/tdd.md|test-driven-development|NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
doctrine/tdd.md|test-driven-development|Violating the letter of the rules is violating the spirit of the rules.
doctrine/tdd.md|test-driven-development|**MANDATORY. Never skip.**
doctrine/tdd.md|test-driven-development|Thinking "skip TDD just this once"? Stop. That's rationalization.
doctrine/tdd.md|test-driven-development|Write code before the test? Delete it. Start over.
doctrine/tdd.md|test-driven-development|Red Flags - STOP and Start Over
doctrine/tdd.md|test-driven-development|Common Rationalizations
doctrine/debugging.md|systematic-debugging|NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
doctrine/debugging.md|systematic-debugging|ALWAYS find root cause before attempting fixes. Symptom fixes are failure.
doctrine/debugging.md|systematic-debugging|If ≥ 3: STOP and question the architecture
doctrine/debugging.md|systematic-debugging|Common Rationalizations
doctrine/verification.md|verification-before-completion|NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
doctrine/verification.md|verification-before-completion|Skip any step = lying, not verifying
doctrine/verification.md|verification-before-completion|Evidence before claims, always.
doctrine/verification.md|verification-before-completion|Rationalization Prevention
commands/craft-explore.md|brainstorming|This Is Too Simple To Need A Design
commands/craft-explore.md|brainstorming|Every project goes through this process.
EOF
}

pass=0; fail=0
mode="${1:-craft}"

while IFS='|' read -r target skill literal; do
  [ -n "$target" ] || continue

  if [ "$mode" = "--sources" ]; then
    file="$SP/skills/$skill/SKILL.md"
    label="source $skill"
  else
    file="$target"
    label="$target"
  fi

  if [ ! -f "$file" ]; then
    printf 'MISSING FILE  %-34s (%s)\n' "$label" "${literal:0:40}..."
    fail=$((fail + 1))
    continue
  fi

  if grep -qF -- "$literal" "$file"; then
    pass=$((pass + 1))
  else
    printf 'MISSING TEXT  %-34s "%s"\n' "$label" "$literal"
    fail=$((fail + 1))
  fi
done <<EOF
$(manifest)
EOF

if [ "$mode" = "--sources" ]; then
  echo "SOURCES  present=$pass missing=$fail  (Superpowers at $SP)"
  [ "$fail" -eq 0 ] || echo "  → the manifest no longer matches upstream; fix the literals before copying."
else
  echo "DOCTRINE present=$pass missing=$fail"
  [ "$fail" -eq 0 ] || echo "  → craft does not yet carry this doctrine. Expected until waves 1-2 land."
fi

[ "$fail" -eq 0 ]
