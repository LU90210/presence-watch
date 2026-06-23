#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")"

STATE_DIR="$PWD/.presence-watch"
PID_FILE="$STATE_DIR/pid"
LOG_FILE="$STATE_DIR/presence-watch.log"
ALERT_FILE="$STATE_DIR/alert.json"
OUT_FILE="$STATE_DIR/stdout.log"
ERR_FILE="$STATE_DIR/stderr.log"
DEFAULT_HOOK_FILE="$PWD/hermes-presence-alert.sh"
HOOK_FILE="${PRESENCE_WATCH_ALERT_HOOK:-$DEFAULT_HOOK_FILE}"

mkdir -p "$STATE_DIR"

is_running() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(cat "$PID_FILE")"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

start_watch() {
  if is_running; then
    echo "Presence Watch already running. pid=$(cat "$PID_FILE")"
    return 0
  fi

  rm -f "$ALERT_FILE"
  : > "$LOG_FILE"
  : > "$STATE_DIR/alert-send.log"
  : > "$OUT_FILE"
  : > "$ERR_FILE"

  local hook_command=""
  if [[ -n "${PRESENCE_WATCH_ALERT_HOOK:-}" && ! -x "$HOOK_FILE" ]]; then
    echo "Configured alert hook is not executable: $HOOK_FILE" >&2
    return 1
  fi

  if [[ -x "$HOOK_FILE" ]]; then
    hook_command="$HOOK_FILE"
  fi

  if [[ -n "$hook_command" ]]; then
    nohup /usr/bin/env swift ./presence-watch.swift \
      --log "$LOG_FILE" \
      --alert-file "$ALERT_FILE" \
      --on-alert "$hook_command" \
      --silent \
      > "$OUT_FILE" 2> "$ERR_FILE" &
  else
    nohup /usr/bin/env swift ./presence-watch.swift \
      --log "$LOG_FILE" \
      --alert-file "$ALERT_FILE" \
      --silent \
      > "$OUT_FILE" 2> "$ERR_FILE" &
  fi

  echo "$!" > "$PID_FILE"
  sleep 1

  if ! is_running; then
    rm -f "$PID_FILE"
    echo "Presence Watch failed to stay running."
    echo "== stdout =="
    cat "$OUT_FILE" 2>/dev/null || true
    echo "== stderr =="
    cat "$ERR_FILE" 2>/dev/null || true
    return 1
  fi

  echo "Presence Watch started. pid=$(cat "$PID_FILE")"
  echo "log=$LOG_FILE"
  echo "alert_file=$ALERT_FILE"
}

stop_watch() {
  if ! is_running; then
    rm -f "$PID_FILE"
    echo "Presence Watch is not running."
    return 0
  fi

  local pid
  pid="$(cat "$PID_FILE")"
  kill "$pid"
  rm -f "$PID_FILE"
  echo "Presence Watch stopped. pid=$pid"
}

status_watch() {
  if is_running; then
    echo "running pid=$(cat "$PID_FILE")"
  else
    echo "stopped"
  fi

  if [[ -f "$ALERT_FILE" ]]; then
    echo "alert=present"
    cat "$ALERT_FILE"
  else
    echo "alert=none"
  fi
}

logs_watch() {
  echo "== stdout =="
  tail -n 40 "$OUT_FILE" 2>/dev/null || true
  echo "== stderr =="
  tail -n 40 "$ERR_FILE" 2>/dev/null || true
  echo "== events =="
  tail -n 40 "$LOG_FILE" 2>/dev/null || true
  echo "== alert send =="
  tail -n 40 "$STATE_DIR/alert-send.log" 2>/dev/null || true
}

sleep_display() {
  /usr/bin/pmset displaysleepnow
  echo "Display sleep requested."
}

case "${1:-status}" in
  start)
    start_watch
    ;;
  stop)
    stop_watch
    ;;
  status)
    status_watch
    ;;
  logs)
    logs_watch
    ;;
  sleep-display)
    sleep_display
    ;;
  *)
    echo "Usage: $0 start|stop|status|logs|sleep-display"
    exit 2
    ;;
esac
