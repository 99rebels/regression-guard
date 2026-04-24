# Output Templates — Locked Format

Follow these templates exactly. Do not improvise, rearrange, or add sections.

## Symbols

```
🛡️  Report header
✅   Check passed
⚠️   Warning (needs attention)
🔴   Critical (regression detected)
→    Recommended action
══   Verdict separator (Tier 3 only)
```

## Formatting Rules

- Plain text only — no markdown code blocks around the report
- No bold, italic, or heading formatting within the report
- File paths: forward slashes, relative to project root
- Line counts: whole numbers only
- Verdict: exactly one of three — PASS, PASS WITH WARNINGS, or FAIL
- Every ⚠️ or 🔴 must have a → action on the next line
- Blank lines between sections for readability
- Output AFTER completing the code change, as part of your response to the user

## Tier 1 Template

🛡️ Regression Guard — Light Check
Modified: [filepath] ([N] lines)
✅ [check name] — [brief result]
✅ [check name] — [brief result]
Result: PASS

Escalation template (if Tier 1 scan finds a signature change):

🛡️ Regression Guard — Light Check → Escalated to Deep Check
Modified: [filepath] ([N] lines)
🔴 [reason for escalation]
→ Running Tier 3 protocol...
[output Tier 3 format]

## Tier 2 Template

🛡️ Regression Guard — Standard Check
Modified: [filepath(s)] ([N] lines, [N] files)

Self-interrogation:
  Asked: [original request]
  Beyond scope: [yes/no — details if yes]
  Unverified: [what might break]

Callers traced: [N]
  ✅ [filepath] — [status]
  ⚠️ [filepath] — [issue]

Alignment:
  ✅ [filepath] — [change] (requested)
  ⚠️ [filepath] — [change] (NOT requested)

Tests: [runner] — [summary]
  ✅ All [N] tests passed
  — or —
  ❌ [N] tests failed: [brief reason]
  — or —
  ⚠️ No test runner — [static check used] (PASS WITH WARNINGS)

Imports:
  ✅ No issues
  — or —
  ⚠️ [issue description]

Result: PASS / PASS WITH WARNINGS / FAIL
→ [action if not clean pass]

## Tier 3 Template

🛡️ Regression Guard — Deep Check
Modified: [N] files, [N] lines

Self-interrogation:
  Asked: [original request]
  Changed: [files and modifications]
  Beyond scope: [yes/no — details if yes]
  Unverified: [what hasn't been confirmed]

Dependency Trace:
  Direct callers ([N]):
    ✅ [filepath] — [status]
    ⚠️ [filepath] — [issue]
  2nd order ([N]):
    ✅ [filepath] — [status]
    ⚠️ [filepath] — [issue]

Behavioral Contract:
  [function]: [before → after]
  ⚠️ [breaking change or behavioral difference]

Alignment Check:
  ✅ [filepath] — [change] (requested)
  ⚠️ [filepath] — [change] (NOT requested)

Scope Creep: [detected / not detected]
  [details if detected]

Tests:
  Existing: [N] → ✅ / ❌ [summary]
  Generated: [N] → ✅ / ❌ [summary]

VERDICT: PASS / PASS WITH WARNINGS / FAIL
[If FAIL or WARNING: numbered list of issues, each with → fix]

Note: For clean passes (VERDICT: PASS), compress output. Skip empty sections. The ══ separator is optional on clean passes.
