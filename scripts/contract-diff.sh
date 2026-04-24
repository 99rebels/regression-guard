#!/usr/bin/env bash
# contract-diff.sh — Check if function/API signatures changed between two git refs
# Usage: ./contract-diff.sh [before_ref] [after_ref]
# Defaults: before=HEAD~1, after=HEAD
# Example: ./contract-diff.sh HEAD~3 HEAD

set -euo pipefail

BEFORE="${1:-HEAD~1}"
AFTER="${2:-HEAD}"

echo "=== Contract Diff: $BEFORE → $AFTER ==="
echo ""

# Get list of changed files
CHANGED_FILES=$(git diff --name-only "$BEFORE" "$AFTER" -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.rs' '*.rb' '*.java' '*.php' 2>/dev/null || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "No source code files changed between $BEFORE and $AFTER."
  exit 0
fi

echo "Changed source files:"
echo "$CHANGED_FILES" | while read -r f; do echo "  → $f"; done
echo ""

SIGNATURE_CHANGES=""

for FILE in $CHANGED_FILES; do
  # Check if file exists in both refs
  BEFORE_CONTENT=$(git show "$BEFORE:$FILE" 2>/dev/null || echo "")
  AFTER_CONTENT=$(git show "$AFTER:$FILE" 2>/dev/null || echo "")

  if [ -z "$BEFORE_CONTENT" ]; then
    echo "📄 $FILE — NEW FILE (no previous version to compare)"
    continue
  fi

  if [ -z "$AFTER_CONTENT" ]; then
    echo "📄 $FILE — DELETED"
    # Check if anything imports this deleted file
    MODULE_NAME=$(basename "$FILE" | sed 's/\.[^.]*$//')
    IMPORTERS=$(grep -rl "$MODULE_NAME" . --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" 2>/dev/null | grep -v node_modules || true)
    if [ -n "$IMPORTERS" ]; then
      echo "  🔴 BROKEN IMPORTS:"
      echo "$IMPORTERS" | while read -r imp; do echo "    → $imp"; done
      SIGNATURE_CHANGES="$SIGNATURE_CHANGES"$'\n'"  🔴 $FILE deleted — imports broken in: $IMPORTERS"
    fi
    continue
  fi

  # Extract function/class/interface declarations from both versions
  case "$FILE" in
    *.ts|*.tsx|*.js|*.jsx)
      # Match: export function, export const, export class, interface, type
      BEFORE_SIGS=$(echo "$BEFORE_CONTENT" | grep -n -E "^\s*(export\s+)?(function|const|class|interface|type)\s+" || true)
      AFTER_SIGS=$(echo "$AFTER_CONTENT" | grep -n -E "^\s*(export\s+)?(function|const|class|interface|type)\s+" || true)
      ;;
    *.py)
      # Match: def, class, async def
      BEFORE_SIGS=$(echo "$BEFORE_CONTENT" | grep -n -E "^(def |class |async def )" || true)
      AFTER_SIGS=$(echo "$AFTER_CONTENT" | grep -n -E "^(def |class |async def )" || true)
      ;;
    *.go)
      # Match: func, type, interface
      BEFORE_SIGS=$(echo "$BEFORE_CONTENT" | grep -n -E "^(func |type |interface )" || true)
      AFTER_SIGS=$(echo "$AFTER_CONTENT" | grep -n -E "^(func |type |interface )" || true)
      ;;
    *)
      # Generic: look for function/class patterns
      BEFORE_SIGS=$(echo "$BEFORE_CONTENT" | grep -n -E "(function|def |class |interface |type )" || true)
      AFTER_SIGS=$(echo "$AFTER_CONTENT" | grep -n -E "(function|def |class |interface |type )" || true)
      ;;
  esac

  # Compare signatures
  if [ "$BEFORE_SIGS" != "$AFTER_SIGS" ]; then
    echo "📄 $FILE — SIGNATURE CHANGES DETECTED:"
    # Show what changed
    DIFF=$(diff <(echo "$BEFORE_SIGS") <(echo "$AFTER_SIGS") 2>/dev/null || true)
    if [ -n "$DIFF" ]; then
      echo "$DIFF" | while IFS= read -r line; do
        case "$line" in
          \<*) echo "  - ${line#< }" ;;
          \>*) echo "  + ${line#> }" ;;
          ---*) ;; # skip diff headers
          *) ;; # skip context
        esac
      done
      SIGNATURE_CHANGES="$SIGNATURE_CHANGES"$'\n'"  ⚠️ $FILE — signatures changed (see above)"
    fi
  else
    echo "📄 $FILE — No signature changes"
  fi
done

echo ""
echo "=== Summary ==="
if [ -n "$SIGNATURE_CHANGES" ]; then
  echo "Signature changes found:"
  echo "$SIGNATURE_CHANGES"
  echo ""
  echo "🔴 These changes may require Tier 3 verification (deep check)."
else
  echo "✅ No function signature or API surface changes detected."
fi
