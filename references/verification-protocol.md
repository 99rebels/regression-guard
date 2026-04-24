# Verification Protocol — Detailed Design

This is the core of Regression Guard. The agent follows this protocol automatically after any code change.

---

## Step 0: Classification (runs before any tier)

The agent classifies the change to pick the right tier. This is the first thing it does after completing a code modification.

### Classification Decision Tree

```
START → Count modified files
  │
  ├─ 1 file AND <10 lines changed?
  │   ├─ Any exported function signature changed? → TIER 3
  │   ├─ Any type definition changed? → TIER 3
  │   ├─ Any public API surface changed? → TIER 3
  │   └─ None of the above → TIER 1
  │
  ├─ 2-3 files OR 10-50 lines changed?
  │   ├─ Any function signature changed? → TIER 3
  │   ├─ Any shared utility or middleware touched? → TIER 2 (or TIER 3 if also signature change)
  │   ├─ Any config/DB schema changed? → TIER 3
  │   └─ None of the above → TIER 2
  │
  └─ >3 files OR >50 lines changed?
      └─ → TIER 3 (always)
```

### Classification Signals (what counts as what)

**Function signature change:**
- Parameter names, types, or count changed
- Return type changed
- Function renamed
- Function added/removed from exports
- Default parameter values changed

**Public API surface change:**
- Exported constants or types changed
- Endpoint routes changed
- Event names or payload shapes changed
- Environment variable names changed
- Config file structure changed

**Shared utility touched:**
- Files imported by 3+ other files
- Middleware, interceptors, hooks
- Base classes or shared interfaces
- Utility/helper modules
- Database models or ORM schemas

### Edge Cases
- **Delete a file?** → Always Tier 3 (need to verify nothing imports it)
- **Move/rename a file?** → Tier 3 (all imports need updating)
- **Change a config file?** → Tier 2 minimum (check what reads it)
- **Add a new dependency?** → Tier 2 (check for conflicts with existing deps)
- **Change a test file?** → Tier 1 (tests don't have callers)

---

## 🟢 Tier 1: Light Check

**Purpose:** Confirm that a trivial change didn't accidentally alter something important.

**Steps:**

1. **Signature scan** — Check if any exported function signatures in the modified file differ from the pre-change version. If the agent has access to git: `git diff HEAD -- <file> | grep -E "(export|function|const|class|interface|type)"`. If no git: compare the changed function against the agent's memory of the original.

2. **Import integrity** — Verify no imports were accidentally added, removed, or altered (other than the intended change).

3. **Verdict** — If steps 1-2 are clean, report: `✅ Light check passed — no interface changes detected.`

**Output format:**
```
🛡️ Regression Guard — Light Check
Modified: src/components/Button.tsx (4 lines)
✅ No signature changes detected
✅ Imports intact
Result: PASS
```

---

## 🟡 Tier 2: Standard Check

**Purpose:** Verify that moderate changes don't break direct callers and that tests still pass.

**Steps:**

1. **All Tier 1 checks** (signature scan + import integrity)

2. **Direct caller trace** — Identify all files that import or call the modified functions/modules. For each caller:
   - Does the call still match the current signature?
   - Are there any type mismatches?
   - Flag any callers in test files separately (less risky)

3. **Test execution** — Run the project's existing test suite (or relevant subset):
   - Detect the test runner (npm test, pytest, go test, cargo test, etc.)
   - Run tests for the affected module(s)
   - If tests fail: analyze whether the failure is expected (intentional behavior change) or unexpected (regression)

4. **Orphan check** — Were any imports added that don't correspond to actual usage? Were any removed that are still needed?

5. **Verdict** — Summarize findings.

**Output format:**
```
🛡️ Regression Guard — Standard Check
Modified: src/utils/formatDate.ts (23 lines, 1 file)

Callers traced:
  ✅ src/pages/Dashboard.tsx — compatible
  ✅ src/pages/Profile.tsx — compatible  
  ⚠️ src/api/notifications.ts — uses default parameter that changed, verify manually

Tests: src/utils/formatDate.test.ts
  ✅ All 12 tests passed

Imports:
  ✅ No orphaned imports detected

Result: PASS with 1 manual check needed
→ Review: src/api/notifications.ts (default parameter change)
```

---

## 🔴 Tier 3: Deep Check

**Purpose:** Comprehensive verification for risky changes — the full regression prevention protocol.

**Steps:**

1. **All Tier 1 + Tier 2 checks**

2. **Full dependency trace** — Beyond direct callers, trace the transitive dependency graph:
   - Direct callers of changed functions
   - Callers of callers (second-order)
   - Any module that imports types/interfaces from the changed files
   - Any configuration that references the changed module
   - Stop at 2nd order to keep token cost bounded

3. **Behavioral contract check** — For each function whose signature or behavior changed:
   - Document what the function DID before (pre-change contract)
   - Document what the function DOES now (post-change contract)
   - Flag any behavioral differences that aren't explained by the original request
   - Check: did the agent change MORE than what was asked?

4. **Alignment check** — Compare the actual changes against the user's original request:
   - List every file modified
   - For each modification: does it serve the stated goal?
   - Flag any "bonus" changes the agent made without being asked
   - This catches scope creep — the #1 source of unexpected regressions

5. **Targeted test generation** — If the agent has test-writing capability:
   - Generate tests specifically for the changed functions/behaviors
   - Focus on edge cases around the change (boundary values, error states)
   - Run the generated tests
   - If tests fail: the change itself may be wrong, not just its callers

6. **Impact summary** — Compile a confidence report

**Output format:**
```
🛡️ Regression Guard — Deep Check
Modified: src/middleware/auth.ts (67 lines, 4 files)

Dependency Trace:
  Direct callers (5):
    ✅ src/routes/user.ts — compatible
    ✅ src/routes/admin.ts — compatible  
    ⚠️ src/routes/api.ts — passes userId as string, now expects number
    ✅ src/services/session.ts — compatible
    ✅ src/services/token.ts — compatible
  2nd-order (2):
    ✅ src/routes/api.ts imports from src/services/session.ts (already flagged above)
    ✅ No other transitive risks

Behavioral Contract:
  Function: authenticate(req, res, next)
  Before: accepted userId as string | number
  After: accepts userId as number only
  ⚠️ BREAKING: removed string type from userId parameter
  Alignment: Original request was to "add rate limiting to auth middleware"
  ⚠️ SCOPE CREEP: userId type change was NOT part of the original request

Alignment Check:
  ✅ src/middleware/auth.ts — rate limiting added (requested)
  ✅ src/middleware/rateLimit.ts — new file (requested)
  ⚠️ src/types/user.ts — userId type narrowed (NOT requested)
  ⚠️ src/routes/api.ts — updated to pass number (NOT requested)

Targeted Tests:
  Generated: 3 new tests for authenticate()
  ✅ All passed

Verdict:
Result: FAIL — 2 regression risks detected
1. src/routes/api.ts passes string userId — type mismatch (BREAKING)
2. Scope creep: userId type narrowing was not requested

Recommended actions:
1. Revert the userId type change in src/types/user.ts unless intentional
2. If intentional, audit ALL callers of authenticate() for string usage
3. Review src/routes/api.ts for the userId cast
```

---

## Design Decisions & Rationale

### Why these specific tiers?
- **Tier 1** catches the most common AI mistake: accidentally changing something while doing something else (e.g., fixing a typo but nudging a function signature)
- **Tier 2** catches the medium-risk case: the change is correct but its callers might not be updated
- **Tier 3** catches the dangerous case: the AI went beyond what was asked and changed things it shouldn't have

### Why "alignment check" in Tier 3?
This is the most creative and highest-value feature. The #1 source of AI regressions isn't bad code — it's **the AI solving a different problem than the one you asked it to solve**. Detecting scope creep is genuinely novel.

### Why stop at 2nd-order dependency trace?
Third-order traces get exponentially expensive in tokens and rarely surface real risks. 2nd-order catches 95%+ of actual regression paths.

### Token budget estimates
- Tier 1: ~200-300 tokens (classification + quick scan)
- Tier 2: ~1,000-2,000 tokens (trace + test run output)
- Tier 3: ~3,000-5,000 tokens (full protocol)
- Most changes are Tier 1 — average token overhead per coding session: ~500 tokens
- One caught regression saves 3+ deployment cycles — net positive on tokens

### Language-agnostic approach
The protocol is designed around universal concepts (functions, imports, callers, signatures, types). Implementation helpers (scripts) will detect the project language and adapt:
- Python: `grep -r "import\|from"`, `pytest`
- JavaScript/TypeScript: `grep -r "import\|require"`, `npm test`
- Go: `grep -r "import"`, `go test`
- Rust: `grep -r "use "`, `cargo test`
- Generic fallback: file-level search patterns
