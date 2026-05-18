#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE_FILE="$SCRIPT_DIR/presence-watch-skill/SKILL.md"

detect_openclaw_home() {
  if [[ -n "${OPENCLAW_HOME:-}" ]]; then
    print -r -- "$OPENCLAW_HOME"
    return
  fi

  local candidate
  for candidate in "$HOME/.openclaw" "$HOME/.jvs/.openclaw"; do
    if [[ -d "$candidate" ]]; then
      print -r -- "$candidate"
      return
    fi
  done

  print -r -- "$HOME/.openclaw"
}

detect_skills_root() {
  if [[ -n "${OPENCLAW_SKILLS_DIR:-}" ]]; then
    print -r -- "$OPENCLAW_SKILLS_DIR"
    return
  fi

  local openclaw_home
  openclaw_home="$(detect_openclaw_home)"

  local candidate
  for candidate in \
    "$HOME/.agents/skills" \
    "$openclaw_home/skills" \
    "$openclaw_home/workspace/.agents/skills" \
    "$openclaw_home/workspace.default/.agents/skills" \
    "$openclaw_home/workspace/skills"; do
    if [[ -d "$candidate" ]]; then
      print -r -- "$candidate"
      return
    fi
  done

  print -r -- "$HOME/.agents/skills"
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

echo "Installed OpenClaw skill to $TARGET_FILE"
echo "If OpenClaw is already running, restart it or start a new session so it reloads skills."
echo "Set OPENCLAW_SKILLS_DIR=/path/to/skills if your OpenClaw uses a custom skill directory."
