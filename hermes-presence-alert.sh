#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_AGENT="${HERMES_AGENT:-$HERMES_HOME/hermes-agent}"
HERMES_PYTHON="${HERMES_PYTHON:-$HERMES_AGENT/venv/bin/python3}"
SEND_LOG="${PRESENCE_WATCH_ALERT_SEND_LOG:-$SCRIPT_DIR/.presence-watch/alert-send.log}"

if [[ -f "$HERMES_HOME/.env" ]]; then
  set +u
  set -a
  source "$HERMES_HOME/.env"
  set +a
  set -u
fi

mkdir -p "$(dirname "$SEND_LOG")"

cd "$HERMES_AGENT"

"$HERMES_PYTHON" - <<'PY' >> "$SEND_LOG" 2>&1
import json
import os
import sys
from datetime import datetime

from tools.send_message_tool import send_message_tool

raw_event = os.environ.get("PRESENCE_WATCH_EVENT_JSON", "{}")
log_path = os.environ.get("PRESENCE_WATCH_LOG", "")

try:
    event = json.loads(raw_event)
except Exception:
    event = {"raw": raw_event}

event_time = event.get("time") or datetime.now().isoformat(timespec="seconds")
event_name = event.get("event") or "unknown"
x = event.get("x")
y = event.get("y")
count = event.get("count")

position = f" ({x}, {y})" if x is not None and y is not None else ""
count_text = f" #{count}" if count is not None else ""

message = (
    "⚠️ 电脑监控警告：检测到键盘/鼠标/触控板活动\n"
    f"时间：{event_time}\n"
    f"事件：{event_name}{count_text}{position}\n"
    "如果不是你本人操作，可以回复「远程息屏」或「远程熄屏」。\n"
)
if log_path:
    message += f"日志：{log_path}"

result_raw = send_message_tool({
    "action": "send",
    "target": "weixin",
    "message": message,
}) if os.environ.get("PRESENCE_WATCH_DRY_RUN") != "1" else json.dumps({
    "success": True,
    "dry_run": True,
    "message": message,
})
print(datetime.now().isoformat(timespec="seconds"), result_raw)

try:
    result = json.loads(result_raw)
except Exception:
    result = {}

if result.get("error"):
    sys.exit(1)
PY
