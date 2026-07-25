## Context Preflight

Run FIRST, before anything else in this phase. No exceptions.

A senior engineer does not search their own brain — they already know the project, and they
know where their knowledge ends. This block is how you earn that. It is four bounded lookups.

```bash
# 1. Trust check — can CLAUDE.md be believed?
bash "${CRAFT_HOME:-$(dirname "$(readlink -f "$0" 2>/dev/null || echo .)")}/scripts/craft-doctor.sh"
```

If `CRAFT_HOME` is unset, look for `scripts/craft-doctor.sh` at the repo root, then at
`${CLAUDE_PLUGIN_ROOT}/scripts/craft-doctor.sh`. If you cannot find it, continue and set
`MODE` to include `no-doctor` — never block on the checker being absent.

Read its output:
- `DRIFT` on a section → that section is a **hint**, not a binding rule. Verify before relying.
- `UNCHECKED` → **not** drift. It means no language server was available to confirm symbols.
- `SUMMARY sections_drifted=...` → the list of sections you must treat with suspicion.

**2. Confirm the map.** CLAUDE.md is already in your session context — do NOT re-read it.
Quote the `## Reuse Map` and `## Patterns` entries relevant to *this* area of the code, or
state which of those sections are absent.

**3. Locate.** For the area this phase touches, resolve:

| What | With Serena | Without |
|---|---|---|
| owning module | `get_symbols_overview` | `Glob` the directory |
| nearest sibling implementation | `find_symbol` | `Grep` for the same shape nearby |
| direct callers | `find_referencing_symbols` | `Grep -w` the symbol name |
| tests that name it | references filtered to test paths | `Grep` the symbol under the test glob |
| recent history | — | `git log --oneline -n 3 -- <path>` |

A grep-derived test list is a good lead, not a proof. Say which you used.

**4. Declare.** Emit exactly this, then proceed:

```
CONTEXT: module=<m> siblings=<f> callers=<n> tests=<file,file> last-touched=<date, sha>
KNOWN:   <the one or two facts that will actually shape this work>
UNKNOWN: <what you could not determine, and what would resolve it>
MODE:    serena | grep-only  [+ no-map] [+ no-doctor] [+ no-git]
```

**`UNKNOWN:` may not be empty by default.** An author knows the edge of their knowledge; a
fresher assumes. Writing `UNKNOWN: none` is a claim — if it later proves wrong, that is a
process failure, not bad luck. This line is the anti-hallucination gate: it turns a silent
assumption into a visible one the user can correct in five seconds.

`CONTEXT:` must carry real numbers and a real SHA. You cannot produce those without running
the lookups, which is the point.

### Degenerate cases — state them, don't stall

| Situation | Do |
|---|---|
| no CLAUDE.md | `MODE` gets `no-map`; every convention claim becomes an `UNKNOWN` |
| no git, or a shallow CI clone | `last-touched=unavailable (shallow)`; skip history lookups |
| no `gh`, or a non-GitHub remote | skip PR-discussion lookups, note it |
| brand-new file | `last-touched=new`; siblings are still required |
| monorepo, area not yet identified | resolve the area first — that IS the preflight |

### Source hierarchy — code wins, always

When sources disagree, this order is binding:

```
1. The code            ground truth for WHAT IS
2. Git history         ground truth for WHY, and WHAT WAS ALREADY TRIED
3. The tests           the contract for WHAT MUST KEEP WORKING
4. CLAUDE.md           human intent — authoritative for CONVENTION, never for FACT
5. OpenSpec artifacts  intent for THIS change only
```

**Prose never overrides code.** If CLAUDE.md says a helper lives somewhere and it does not,
the code wins and the doc is wrong. This is what makes a stale doc survivable instead of
dangerous.

### History is memory — use it, bounded

An author remembers "we tried that in March and reverted it." You can derive it:

```bash
git log -S '<symbol>' --oneline            # commits that added or removed this
git log --diff-filter=D --oneline -- <p>   # what used to exist here
git log --follow -L :<symbol>:<file>       # this function's whole life
git blame -L <start>,<end> -- <file>       # who, when, and the commit message
```

Bounded always: `--oneline`, `-n 5`, region-scoped `-L`. Never unbounded `git log -p`.
On demand, triggered by a question — not loaded upfront.

**Reverts are findings.** If work reintroduces something a past commit deliberately removed —
message says revert, rollback, regression, fix — surface it with the SHA before proceeding.
