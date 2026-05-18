#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")"

LOG_PATH="${1:-$PWD/presence-watch.log}"

echo "Starting Presence Watch..."
echo "Log: $LOG_PATH"
echo "Stop with Ctrl-C when you return."
echo

exec /usr/bin/env swift ./presence-watch.swift --log "$LOG_PATH"
