#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${1:-./skills}"

TARGETS=(
  "$HOME/.trae-cn/skills"
  "$HOME/.trae/skills"
  "$HOME/.codex/skills"
  "$HOME/.claude/skills"
  "$HOME/.factory/skills"
  "$HOME/.agents/skills"
)

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "skills dir not found: $SKILLS_DIR" >&2
  exit 1
fi

for t in "${TARGETS[@]}"; do
  mkdir -p "$t"
done

shopt -s nullglob
for d in "$SKILLS_DIR"/*/; do
  name="$(basename "${d%/}")"
  src="$(cd "$(dirname "$d")" && pwd)/$name"

  for t in "${TARGETS[@]}"; do
    dst="$t/$name"
    if [[ -e "$dst" || -L "$dst" ]]; then
      rm -rf "$dst"
    fi
    ln -s "$src" "$dst"
  done
done
