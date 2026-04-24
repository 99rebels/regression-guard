---
name: regression-guard
description: >
  Prevent AI coding agents from silently breaking your code. After every code change, the agent
  automatically classifies severity and runs a matching verification protocol — from a quick
  signature scan for trivial edits to a full dependency trace, behavioral contract check, and
  scope-creep detection for risky refactors. Passive, token-efficient, and works across Claude
  Code, OpenClaw, Cursor, Codex CLI, and Gemini CLI.
version: "1.5.0"
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

Regression Guard runs automatically after every code change. It classifies the risk, checks for breakage, and surfaces findings to the agent — so regressions get caught before the user ever sees them.

## When to Use

- "Did the AI break something?"
- "Check this change before I commit"
- "Run regression check"
- Any code change — it activates automatically, you don't ask

## How It Works

```
1. AI makes a code change
2. Regression Guard checkpoint runs
3. Findings surfaced to the agent
4. Agent uses its own judgment to fix or escalate
5. Agent returns work to user
```

This skill is a **checkpoint**, not a controller. It reveals problems. The agent decides what to do about them — whether to fix, escalate to the user, or proceed if the findings are acceptable.

### Where It Fits in the Flow

Regression Guard runs **after code changes, before testing**:

```
Code change → Regression Guard checkpoint → Fix findings → Run tests → Return to user
```

Tests verify the changed code works. Regression Guard verifies the change didn't break anything *else*. They're complementary — neither replaces the other.

## Three Tiers — Right-Sized Checking

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

**Clean Tier 1 — silent, no output to user:**
The agent runs the check, finds nothing, and proceeds. The user never sees Regression Guard.

**Tier 2 with finding:**

```
🛡️ Regression Guard — Standard Check
Modified: src/utils/formatDate.ts (18 lines, 1 file)

Callers traced: 3
  ✅ Dashboard.tsx — compatible
  ✅ Profile.tsx — compatible
  ⚠️ notifications.ts — default param changed

Tests: ✅ All 12 passed

Findings: 1 issue for agent review
→ notifications.ts uses default parameter that changed — verify or update
```

**Tier 3 catching scope creep:**

```
🛡️ Regression Guard — Deep Check
Modified: 5 files, 127 lines

Alignment Check:
  ✅ middleware/rateLimit.ts — rate limiter (requested)
  ⚠️ middleware/auth.ts — switched to JWT (NOT requested)
  ⚠️ services/session.ts — DELETED (NOT requested)

Findings: 2 issues for agent review
→ Auth system changed without request — revert or confirm with user
→ Session service deleted — 3 broken imports in logout.ts, api.ts, csrf.ts
```

See `references/output-templates.md` for full templates.

## Installation

Drop the `regression-guard/` folder into your agent's skill directory:

```
Claude Code:   .claude/skills/regression-guard/
OpenClaw:      skills/regression-guard/
Cursor:        .cursor/skills/regression-guard/
Codex CLI:     .codex/skills/regression-guard/
Gemini CLI:    .gemini/skills/regression-guard/
```

No dependencies. No configuration required. Works immediately.

### Helper Scripts (Optional)

Two bash scripts are included. The agent can use these as shortcuts, or follow the SKILL.md instructions manually. Both are optional.

**Dependency tracer** — find all callers of a function/module:
```
scripts/trace-dependencies.sh <filepath_or_function> [search_dir] [depth]
```

**Contract diff** — compare function signatures between two git refs:
```
scripts/contract-diff.sh [before_ref] [after_ref]
```

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

---

## The Protocol — What the Agent Follows

This section is for the agent. It contains the verification instructions.

### Design Philosophy

This skill is a **checkpoint**, not a controller. Its job is to reveal problems to you — the agent. You decide what to do with the findings.

- Use your own judgment on whether to fix, escalate, or proceed
- Use your own judgment on when you've checked enough
- Fix what you can, ask the user about what you can't
- Don't let these checks replace your existing debugging or testing workflow
- If tests exist in the project, run them AFTER this checkpoint, not instead of it

### When to Output to the User

- **Silent when clean** — if the checkpoint finds nothing, don't mention it
- **Output when findings exist** — surface what you found so the user knows what happened
- **Output after fixing** — if you fixed the findings, tell the user briefly what was caught and fixed
- **Escalate when unsure** — if you found something but aren't sure how to handle it, tell the user

Use plain text with these symbols: 🛡️ ✅ ⚠️ 🔴 →

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

**Tier 1** — ALL true: 1 file, <10 lines, no sig/type changes, no deletions. Note: for trivial edits (comments, whitespace, string values), shared-utility status does not force Tier 2. For code logic changes to shared utilities, escalate to Tier 2.
**Tier 2** — ANY true: 2-3 files, 10-50 lines, shared utility (code logic change), new dep, runtime config
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
- Alignment check — lightweight (list each modified file; for each: does this change serve the user's request? Flag anything that doesn't)
- Run existing tests (detect runner, execute, analyze failures as expected or unexpected)
  - If no test runner is detected: fall back to the strongest available static check (type checker, compiler, or linter). Mark result as PASS WITH WARNINGS and note the absence of tests.
  - For TypeScript projects with composite configs: run `tsc -b` or `tsc -p <config>` against the specific project. Root-level `tsc --noEmit` can silently pass due to project references.
- Orphan check (unused imports, broken imports)

**Tier 3 adds:**
- Transitive dependency trace (2nd order — callers of callers)
- Behavioral contract check (before vs after for each changed function)
- Alignment check — full (compare actual changes vs. original request, detailed scope creep analysis)
- Targeted test generation (3-5 edge-case tests for the change)

See `references/verification-protocol.md` for the complete step-by-step protocol with decision trees.

### Step 3: Handle Findings

After the verification, you have findings. What you do with them is up to you:

**If nothing found:** Continue. Don't mention the checkpoint to the user.

**If issues found:** Fix what you can using your own judgment. General guidance:
- If the change was user-requested and findings are downstream (callers, types) → prefer to fix
- If the change introduces unrequested behavior or deletions → escalate to the user before fixing

Then decide:
- Can I fix this confidently? → Fix it, re-verify, and tell the user what was caught
- Am I unsure? → Tell the user what you found and ask how to proceed
- Is this a design decision? → Tell the user and let them decide

**After fixing:** Re-run the verification to confirm your fix didn't introduce new issues. Use your judgment on how many passes is enough — but don't loop indefinitely.

### Rules

1. Never skip classification. A misclassified change is a missed regression.
2. Escalate, never downgrade. Tier 3 situations never get Tier 1 treatment.
3. Be honest about confidence. If you can't verify something, mark ⚠️, not ✅.
4. Don't over-alert. Clean changes get clean passes. Crying wolf trains users to ignore the guard.
5. Alignment check runs at Tier 2 (lightweight) and Tier 3 (full). Never skip it.
6. Test failures aren't always regressions. Distinguish expected vs unexpected.
7. This checkpoint complements testing — it doesn't replace it.
8. Work without git. Use memory and file reading if git is unavailable.
