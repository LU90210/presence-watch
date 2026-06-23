#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE_FILE="$SCRIPT_DIR/presence-watch-skill/SKILL.md"

# Claude Code keeps personal skills under ~/.claude/skills (override with
# CLAUDE_SKILLS_DIR). Some setups vendor skills under ~/.agents/skills and
# symlink them into ~/.claude/skills; installing straight to ~/.claude/skills
# works for both.
detect_skills_root() {
  if [[ -n "${CLAUDE_SKILLS_DIR:-}" ]]; then
    print -r -- "$CLAUDE_SKILLS_DIR"
    return
  fi
  print -r -- "$HOME/.claude/skills"
}

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Missing skill template: $SOURCE_FILE" >&2
  exit 1
fi

TARGET_ROOT="$(detect_skills_root)"
TARGET_DIR="$TARGET_ROOT/presence-watch"
TARGET_FILE="$TARGET_DIR/SKILL.md"

mkdir -p "$TARGET_DIR"

escaped_dir="${SCRIPT_DIR//\\/\\\\}"
escaped_dir="${escaped_dir//&/\\&}"
escaped_dir="${escaped_dir//#/\\#}"

sed "s#__PRESENCE_WATCH_DIR__#$escaped_dir#g" "$SOURCE_FILE" > "$TARGET_FILE"

echo "Installed Claude Code skill to $TARGET_FILE"
echo "Start a new Claude Code session so it picks up the skill."
echo "Set CLAUDE_SKILLS_DIR=/path/to/skills to install elsewhere."
