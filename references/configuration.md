# Configuration Reference

Regression Guard works without any configuration. Place `.regression-guard.json` in your project root to customize.

## Full Schema

```json
{
  "alwaysTier3": ["src/middleware/*", "src/api/*"],
  "neverCheck": ["*.css", "*.scss", "*.stories.*"],
  "skipTests": false,
  "maxDependencyDepth": 2,
  "customTestCommand": "pnpm test --reporter=verbose"
}
```

## Fields

**alwaysTier3** (string array, optional)
Glob patterns that always trigger deep checks, regardless of change size.
Use for critical paths where even small changes need full verification.
Default: none

**neverCheck** (string array, optional)
File patterns to skip entirely.
Use for stylesheets, static assets, generated files.
Default: none

**skipTests** (boolean, optional)
Set to true to skip test execution. Only static analysis runs.
Useful for large projects where running tests is slow.
Default: false

**maxDependencyDepth** (number, optional)
How deep to trace callers. 1 = direct callers only. 2 = callers of callers (default).
Higher values catch more cascading risks but cost more tokens.
Default: 2

**customTestCommand** (string, optional)
Override the auto-detected test command.
Auto-detection supports: jest, vitest, mocha, pytest, go test, cargo test.
Use this for custom runners or when you want specific flags.
Default: auto-detect from project files

## Cross-Agent Compatibility

Regression Guard works across all major AI coding agents:

**Claude Code / Codex CLI / Gemini CLI:**
Full protocol — terminal access, git, test runners, file reading all available.

**Cursor:**
Run verification after accepting changes. May need to use terminal panel for test execution.

**OpenClaw:**
Full protocol — all tools available.

**Agents without terminal access:**
Run classification + signature scan + alignment check. Skip test execution and dependency scripts — do manual file reading instead.
