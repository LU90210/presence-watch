#!/bin/zsh

set -euo pipefail

# Copy this file to your own alert script, make it executable, and point
# PRESENCE_WATCH_ALERT_HOOK at it when starting Presence Watch.
#
# The monitor passes these environment variables:
# - PRESENCE_WATCH_EVENT_JSON: one-line JSON event, including time/event/x/y/keyCode
# - PRESENCE_WATCH_LOG: full event log path
# - PRESENCE_WATCH_ALERT_FILE: latest alert JSON path

MESSAGE="Presence Watch alert: ${PRESENCE_WATCH_EVENT_JSON}"

echo "$MESSAGE"

# Example shapes only:
# openclaw send-message --target weixin --message "$MESSAGE"
# hermes send-wechat --to me --message "$MESSAGE"
