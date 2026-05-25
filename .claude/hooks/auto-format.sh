#!/usr/bin/env bash
# Auto-format files on Edit/Write based on language.
# Reads file path from hook payload via jq.

FILE=$(jq -r '.tool_input.file_path' 2>/dev/null)
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

EXT="${FILE##*.}"

case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|css|scss|less|html|json|yaml|yml|md|mdx|graphql|vue|svelte)
    npx prettier --write "$FILE" 2>/dev/null
    ;;
  py|pyi)
    command -v ruff >/dev/null 2>&1 && ruff format "$FILE" 2>/dev/null && ruff check --fix "$FILE" 2>/dev/null
    ;;
  go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE" 2>/dev/null
    ;;
  rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$FILE" 2>/dev/null
    ;;
  java)
    command -v google-java-format >/dev/null 2>&1 && google-java-format -i "$FILE" 2>/dev/null
    ;;
  kt|kts)
    command -v ktlint >/dev/null 2>&1 && ktlint -F "$FILE" 2>/dev/null
    ;;
  c|h|cpp|hpp|cc|cxx|hxx)
    command -v clang-format >/dev/null 2>&1 && clang-format -i "$FILE" 2>/dev/null
    ;;
esac

exit 0
