---
name: regression-guard
description: >
  Prevent AI coding agents from silently breaking your code. After every code change, the agent
  automatically classifies severity and runs a matching verification protocol — from a quick
  signature scan for trivial edits to a full dependency trace, behavioral contract check, and
  scope-creep detection for risky refactors. Passive, token-efficient, and works across Claude
  Code, OpenClaw, Cursor, Codex CLI, and Gemini CLI.
version: "1.2.0"
tags:
  - code-quality
  - regression
  - testing
  - code-review
  - developer-tools
---

# Regression Guard

**Catch what your AI agent broke — before it becomes your problem.**

AI coding agents introduce regressions at alarming rates. The SWE-CI benchmark (March 2026) found most models break previously working code in 3 out of 4 tasks. Developers spend 38% of their week debugging AI-generated bugs they didn't write.

Regression Guard runs automatically after every code change. It classifies the risk, checks for breakage, and reports to you — so you never ship silent regressions.

## When to Use

- "Did the AI break something?"
- "Check this change before I commit"
- "Run regression check"
- Any code change — it activates automatically, you don't ask

## How It Works

```
1. AI makes a code change
2. Regression Guard classifies the change severity
3. Runs the matching verification tier
4. Reports findings to you
```

### Three Tiers — Right-Sized Verification

```
🟢 Tier 1 — Light Check (trivial changes)
   1 file, <10 lines, no signature changes
   Checks: signature scan + import integrity
   Token cost: ~200-300

🟡 Tier 2 — Standard Check (moderate changes)
   2-3 files, 10-50 lines, or shared utility touched
   Checks: caller trace + test suite + orphan check
   Token cost: ~1,000-2,000

🔴 Tier 3 — Deep Check (risky changes)
   >3 files, >50 lines, or signature/API changes
   Checks: transitive trace + behavioral contract + alignment + test generation
   Token cost: ~3,000-5,000
```

Most changes are Tier 1 (80%+). Average token overhead per session: ~500 tokens.

### Self-Interrogation — Every Time

Before mechanical checks, the agent answers honestly:
- "What did I actually change?"
- "Did I go beyond what was asked?"

This catches things scripts can't — like behavioral changes that keep the same signature but return different values.

See `references/verification-protocol.md` for the full step-by-step protocol.

## What It Checks

```
✅ Signature changes     — did function inputs/outputs change?
✅ Import integrity       — are all imports valid and used?
✅ Caller compatibility   — do callers still work with the change?
✅ Test suite             — do existing tests still pass?
✅ Scope creep            — did the AI change more than requested?
✅ Behavioral contract    — did the function's behavior change?
✅ Transitive deps        — what uses the code that uses the code?
✅ Dynamic imports        — are there callers grep can't find?
```

## Output Examples

**Clean Tier 1 pass:**

```
🛡️ Regression Guard — Light Check
Modified: src/components/Button.tsx (2 lines)
✅ No signature changes
✅ Imports intact
Result: PASS
```

**Tier 2 with warning:**

```
🛡️ Regression Guard — Standard Check
Modified: src/utils/formatDate.ts (18 lines, 1 file)

Callers traced: 3
  ✅ Dashboard.tsx — compatible
  ✅ Profile.tsx — compatible
  ⚠️ notifications.ts — default param changed

Tests: ✅ All 12 passed

Result: PASS WITH WARNINGS
→ Review: src/api/notifications.ts (default parameter change)
```

**Tier 3 catching scope creep:**

```
🛡️ Regression Guard — Deep Check
Modified: 5 files, 127 lines

Alignment Check:
  ✅ middleware/rateLimit.ts — rate limiter (requested)
  ⚠️ middleware/auth.ts — switched to JWT (NOT requested)
  ⚠️ services/session.ts — DELETED (NOT requested)

═════════════════════════════
VERDICT: FAIL
═════════════════════════════
1. Session service deleted — 3 broken imports
→ Revert auth.ts and session.ts. Only add rate limiting.
```

See `references/output-templates.md` for full Tier 3 output format and all templates.

## Installation

Drop the `regression-guard/` folder into your agent's skill directory:

```
Claude Code:   .claude/skills/regression-guard/
OpenClaw:      ~/.openclaw/workspace/skills/regression-guard/
Cursor:        .cursor/skills/regression-guard/
Codex CLI:     .codex/skills/regression-guard/
Gemini CLI:    .gemini/skills/regression-guard/
```

No dependencies. No configuration required. Works immediately.

### Helper Scripts (Optional)

Two bash scripts are included for faster/more thorough checks. The agent can use these as shortcuts, or follow the SKILL.md instructions manually with grep and git. Both are optional.

**Dependency tracer** — find all callers of a function/module, up to N levels deep:
```
scripts/trace-dependencies.sh <filepath_or_function> [search_dir] [depth]
```
Use instead of manual grep for caller tracing. Handles multiple languages (JS/TS, Python, Go, Rust, Ruby).

**Contract diff** — compare function signatures between two git refs:
```
scripts/contract-diff.sh [before_ref] [after_ref]
```
Use instead of manual git diff for signature scanning. Detects broken imports from deleted files.

## Configuration (Optional)

Place `.regression-guard.json` in your project root:

```json
{
  "alwaysTier3": ["src/middleware/*", "src/api/*"],
  "neverCheck": ["*.css", "*.scss"],
  "skipTests": false,
  "maxDependencyDepth": 2,
  "customTestCommand": "pnpm test"
}
```

See `references/configuration.md` for full config reference.

## The Protocol — What the Agent Follows

This section is for the agent. It contains the complete verification instructions.

### Activation Rules

This skill activates **automatically after any code modification**. Do not wait to be asked.

**Skip for:**
- Documentation-only changes (README, docs/, *.md)
- Editor/tooling config (.editorconfig, .prettierrc, .eslintrc)
- Test-file-only changes (*.test.*, *.spec.*, __tests__/*)
- Changes made by the human directly

**Check:** Runtime configs (.env, config.json, database.json)

### Step 1: Classify

Answer these questions:
1. How many source files modified?
2. How many total lines changed?
3. Any function signature changes?
4. Any type/interface changes?
5. Any shared utilities touched (imported by 3+ files)?
6. Any files deleted or renamed?

**Tier 1** — ALL true: 1 file, <10 lines, no sig/type/shared changes, no deletions
**Tier 2** — ANY true: 2-3 files, 10-50 lines, shared utility, new dep, runtime config
**Tier 3** — ANY true: >3 files, >50 lines, sig change, type change, deletion, API change, schema change, scope creep

**Escalation rule:** Tier 1 scan finds signature change → immediately escalate to Tier 3.

### Step 1.5: Self-Interrogation (all tiers)

**All tiers:**
1. What did I actually change? (be specific)
2. Did I change anything beyond what was asked?

**Tier 2/3 also:**
3. What did the user ask me to do?
4. Which changes affect code other code depends on?
5. What could break that I haven't verified?

Rules: Do not give yourself the benefit of the doubt. Be specific. Do NOT skip mechanical checks because self-interrogation was clean.

### Step 2: Verification Protocol

**Tier 1 checks:**
- Signature scan (git diff or memory comparison — check params, returns, exports)
- Import integrity (verify new imports exist, removed imports aren't still used)

**Tier 2 adds:**
- Caller trace (search function NAME across all files, not just imports; check dynamic import() patterns)
- Run existing tests (detect runner, execute, analyze failures as expected or unexpected)
- Orphan check (unused imports, broken imports)

**Tier 3 adds:**
- Transitive dependency trace (2nd order — callers of callers)
- Behavioral contract check (before vs after for each changed function)
- Alignment check — CRITICAL (compare actual changes vs. original request, flag scope creep)
- Targeted test generation (3-5 edge-case tests for the change)

See `references/verification-protocol.md` for the complete step-by-step protocol with decision trees.

### Step 3: Output

**Style rules — follow exactly:**
- Plain text, no markdown code blocks in the report
- Symbols: 🛡️ ✅ ⚠️ 🔴 → ══
- File paths: forward slashes, relative to root
- Verdict: exactly PASS, PASS WITH WARNINGS, or FAIL
- Every ⚠️ or 🔴 must have a → action
- Output AFTER the code change, as part of your response

**Line limits:** Tier 1: max 5. Tier 2: max 15. Tier 3: max 40.

See `references/output-templates.md` for locked templates for each tier.

### Rules

1. Never skip classification. A misclassified change is a missed regression.
2. Escalate, never downgrade. Tier 3 situations never get Tier 1 treatment.
3. Be honest about confidence. If you can't verify something, mark ⚠️, not ✅.
4. Don't over-alert. Clean changes get clean passes. Crying wolf trains users to ignore the guard.
5. Alignment check is non-negotiable in Tier 3.
6. Test failures aren't always regressions. Distinguish expected vs unexpected.
7. Keep it concise. The user is mid-workflow.
8. Work without git. Use memory and file reading if git is unavailable.
