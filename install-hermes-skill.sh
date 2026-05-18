#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
TARGET_DIR="$HERMES_HOME/skills/presence-watch"
TARGET_FILE="$TARGET_DIR/SKILL.md"
SOURCE_FILE="$SCRIPT_DIR/presence-watch-skill/SKILL.md"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Missing skill template: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

escaped_dir="${SCRIPT_DIR//\\/\\\\}"
escaped_dir="${escaped_dir//&/\\&}"
escaped_dir="${escaped_dir//#/\\#}"

sed "s#__PRESENCE_WATCH_DIR__#$escaped_dir#g" "$SOURCE_FILE" > "$TARGET_FILE"

rm -f "$HERMES_HOME/.skills_prompt_snapshot.json" 2>/dev/null || true

echo "Installed Hermes skill to $TARGET_FILE"
echo "Restart Hermes gateway or clear the current session prompt if it has cached old instructions."
