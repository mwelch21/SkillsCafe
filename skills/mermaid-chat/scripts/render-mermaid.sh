#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <image|ascii> <input.mmd> [output.png]" >&2
  exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || usage

mode=$1
input=$2

[[ -f "$input" ]] || { echo "Input not found: $input" >&2; exit 1; }

render_ascii() {
  local clean_input
  clean_input=$(mktemp "${TMPDIR:-/tmp}/mermaid-chat.XXXXXX.mmd")
  trap 'rm -f "$clean_input"' RETURN

  # mermaid-ascii currently interprets Mermaid styling directives as nodes.
  # Strip presentation-only statements while preserving semantic status labels.
  awk '!/^[[:space:]]*(classDef|class|style|linkStyle)[[:space:]]/' "$input" > "$clean_input"

  sed -i.bak -e 's/✓/[OK]/g' -e 's/✕/[X]/g' "$clean_input"
  rm -f "$clean_input.bak"
  mermaid-ascii -f "$clean_input" --ascii
}

case "$mode" in
  image)
    output=${3:-"${input%.*}.png"}
    command -v npx >/dev/null 2>&1 || {
      echo "PNG rendering requires Node.js with npx." >&2
      exit 1
    }
    npx -p @mermaid-js/mermaid-cli mmdc -i "$input" -o "$output" -b transparent
    echo "$output"
    ;;
  ascii)
    [[ $# -eq 2 ]] || usage
    command -v mermaid-ascii >/dev/null 2>&1 || {
      echo "Text rendering requires the mermaid-ascii executable." >&2
      exit 1
    }
    render_ascii
    ;;
  *)
    usage
    ;;
esac
