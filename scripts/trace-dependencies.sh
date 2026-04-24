#!/usr/bin/env bash
# trace-dependencies.sh — Find all callers/importers of a given module or function
# Usage: ./trace-dependencies.sh <file_or_function_pattern> [search_dir] [depth]
# Example: ./trace-dependencies.sh "src/utils/formatDate" . 2

set -euo pipefail

PATTERN="${1:?Usage: trace-dependencies.sh <pattern> [search_dir] [depth]}"
SEARCH_DIR="${2:-.}"
MAX_DEPTH="${3:-2}"

# Detect language from file extension
detect_import_pattern() {
  case "$1" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs)
      echo "import\|require"
      ;;
    *.py)
      echo "import\|from"
      ;;
    *.go)
      echo "import"
      ;;
    *.rs)
      echo "use "
      ;;
    *.rb)
      echo "require\|require_relative"
      ;;
    *)
      echo "import\|require\|include\|use"
      ;;
  esac
}

# Get the module name (strip extension and path prefix for matching)
MODULE_NAME=$(basename "$PATTERN" | sed 's/\.[^.]*$//')
FILE_EXT="${PATTERN##*.}"
IMPORT_KW=$(detect_import_pattern "$PATTERN")

echo "=== Dependency Trace: $PATTERN ==="
echo "Module name: $MODULE_NAME"
echo "Search dir: $SEARCH_DIR"
echo "Max depth: $MAX_DEPTH"
echo ""

CURRENT_LEVEL_FILES=""
PREV_FILES=""

# Level 1: direct importers
echo "--- Level 1: Direct callers/importers ---"
CURRENT_LEVEL_FILES=$(grep -rl "$MODULE_NAME\|$PATTERN" "$SEARCH_DIR" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" --include="*.rb" \
  --include="*.java" --include="*.php" \
  2>/dev/null | grep -v node_modules | grep -v '.git' | grep -v __pycache__ || true)

if [ -z "$CURRENT_LEVEL_FILES" ]; then
  echo "  No direct callers found."
else
  echo "$CURRENT_LEVEL_FILES" | while read -r f; do
    echo "  → $f"
  done
fi

# Deeper levels
LEVEL=2
PREV_FILES="$CURRENT_LEVEL_FILES"

while [ "$LEVEL" -le "$MAX_DEPTH" ]; do
  echo ""
  echo "--- Level $LEVEL: Transitive callers ---"

  NEXT_FILES=""
  for prev_file in $PREV_FILES; do
    [ ! -f "$prev_file" ] && continue
    prev_module=$(basename "$prev_file" | sed 's/\.[^.]*$//')
    found=$(grep -rl "$prev_module" "$SEARCH_DIR" \
      --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
      --include="*.py" --include="*.go" --include="*.rs" --include="*.rb" \
      2>/dev/null | grep -v node_modules | grep -v '.git' | grep -v __pycache__ || true)

    if [ -n "$found" ]; then
      echo "$found" | while read -r f; do
        echo "  → $f (via $prev_file)"
      done
      NEXT_FILES="$NEXT_FILES"$'\n'"$found"
    fi
  done

  if [ -z "$NEXT_FILES" ]; then
    echo "  No further callers found. Stopping trace."
    break
  fi

  PREV_FILES=$(echo "$NEXT_FILES" | sort -u)
  LEVEL=$((LEVEL + 1))
done

echo ""
echo "=== Trace complete ==="
