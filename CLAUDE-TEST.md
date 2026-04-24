# Regression Guard — Claude Code Test & Review

You are testing a new agent skill called **Regression Guard**. It's designed to prevent AI coding agents from silently breaking code by running verification checks after every code change.

## Setup

1. Read `SKILL.md` in this directory thoroughly
2. Also read `references/output-templates.md` and `references/verification-protocol.md`
3. Familiarize yourself with the three-tier system and the checkpoint philosophy

## Part 1: Functional Tests

Run these scenarios against a codebase. For each one, follow the skill's protocol exactly as written and report what happened.

### Test A: Tier 1 — Silent Check
Make a trivial change to any file (e.g., change a string value, add a comment).
- Did you run the classification step?
- Did you run self-interrogation?
- Did you output anything to the user, or stay silent?
- Was the protocol clear enough to follow without guessing?

### Test B: Tier 2 — Moderate Change
Make a moderate change (e.g., add error handling to a function, refactor logic within a function).
- Did classification correctly identify Tier 2?
- Did you trace callers?
- Did you run tests?
- Were the instructions for each step clear?
- Was the output format correct?

### Test C: Tier 3 — Risky Change
Make a risky change (e.g., change a function signature, delete a file, modify shared code).
- Did classification correctly identify Tier 3?
- Did you run self-interrogation with all 5 questions?
- Did the alignment check work? Did you catch scope creep if you went beyond the request?
- Was the transitive dependency trace useful?
- Did you decide how to handle findings on your own, or did the skill feel like it was telling you what to do?

### Test D: Edge Case — Scope Creep
Ask yourself to do something simple (e.g., "add a comment to this function") but deliberately also make an unrelated change (e.g., modify a different function's signature).
- Did the alignment check catch the unrelated change?
- Did the self-interrogation reveal it?

### Test E: Edge Case — File Deletion
Delete a file that other files import from.
- Did classification correctly trigger Tier 3?
- Did the caller trace find all broken imports?

## Part 2: Honest Review

After running the tests, answer these questions honestly. Be critical — we want to ship a good skill.

1. **Clarity:** Were the instructions clear enough to follow on the first read, or did you have to re-read sections? Which parts were confusing?

2. **Completeness:** Were there any situations where you didn't know what to do next? Any gaps in the protocol?

3. **Token efficiency:** Did the self-interrogation feel like wasted tokens on trivial changes, or was it useful? Would you prefer it only on Tier 2/3?

4. **The checkpoint philosophy:** Did it feel natural to use your own judgment on fixes, or did you want more specific instructions? Did the skill feel like it was helping you or getting in your way?

5. **Output format:** Were the templates clear? Would you actually output in that format, or would you naturally format it differently?

6. **Classification:** Did the tier classification feel right for each test? Any cases where you'd classify differently than the rules suggest?

7. **The "silent when clean" rule:** Did this feel right? Would you prefer to always mention the check, even when clean?

8. **Overall:** Would you recommend this skill to another developer? What's the one thing you'd change?

## Part 3: Weakest Model Test (if possible)

If you have access to a weaker model (Claude Haiku, GPT-4o-mini), run Test A and Test C with that model. Report:
- Could the weaker model follow the instructions?
- Did it skip any steps?
- Did it understand the classification?
- Did the self-interrogation produce useful answers?

This matters because the skill needs to work on the weakest model, not just the strongest.

## Output Format

For each test: brief summary of what happened and whether the skill worked as intended.

For the review: answer each question with a specific, honest response. Don't be polite — be useful.

For the weakest model test: describe what happened and whether the skill was effective.
