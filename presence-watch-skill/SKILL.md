---
name: presence-watch
description: MUST use for natural-language requests to monitor whether someone touched the user's Mac keyboard/trackpad/mouse while they are away, send alerts, or remotely sleep the display. Chinese triggers include 开启电脑监控, 启动电脑监控, 电脑监控, 帮我看着电脑, 我去厕所, 我离开一下, 我回来了, ok了, 关闭电脑监控, 电脑监控状态, 有人动我电脑吗, 远程息屏, 远程熄屏, 息屏, 熄屏, 让电脑黑屏.
version: 1.0.0
metadata:
  tags: [macos, security, monitoring, weixin, wechat, presence]
  hermes:
    requires_toolsets: [terminal]
    related_skills: []
  openclaw:
    requires_toolsets: [terminal]
---

# Presence Watch

Use this skill immediately when the user uses natural language to control laptop
presence monitoring. Do not ask the user to choose between monitoring methods.
This user's intended meaning for `开启电脑监控` is specifically: start the local
keyboard/mouse/trackpad monitor created at
`__PRESENCE_WATCH_DIR__`.

## Safety Model

This is a lightweight activity detector. It records local input activity; it
does not identify a person, take photos, record audio, or prevent someone from
using the computer. The `sleep-display` command only sleeps the display; it does
not shut down the Mac or stop running programs.

## Commands

Run these through the terminal tool exactly as written.

Start monitoring:

```sh
cd __PRESENCE_WATCH_DIR__ && ./presence-watch-control.sh start
```

Stop monitoring:

```sh
cd __PRESENCE_WATCH_DIR__ && ./presence-watch-control.sh stop
```

Check status:

```sh
cd __PRESENCE_WATCH_DIR__ && ./presence-watch-control.sh status
```

Show logs:

```sh
cd __PRESENCE_WATCH_DIR__ && ./presence-watch-control.sh logs
```

Sleep the display remotely:

```sh
cd __PRESENCE_WATCH_DIR__ && ./presence-watch-control.sh sleep-display
```

For display sleep requests, call the command immediately. Do not refuse by
saying remote hardware control is unavailable, and do not ask the user to run
`pmset` manually. This is an already-authorized local command and it works even
when monitoring is not currently running.

## Intent Mapping

- If the user says `开启电脑监控`, `启动电脑监控`, `我去厕所`, `我要离开一下`,
  `帮我看着电脑`, or similar: start monitoring.
- If the user says `我回来了`, `ok了`, `可以关了`, `关闭电脑监控`, or similar:
  stop monitoring.
- If the user asks `电脑监控状态`, `有人动我电脑吗`, `监控怎么样了`, or similar:
  check status. If `alert=present`, tell the user an input event was detected
  and include the event line.
- If the user asks for details/logs: show logs.
- If the user says `远程息屏`, `远程熄屏`, `息屏`, `熄屏`, `让电脑黑屏`, `把屏幕关掉`, or similar:
  sleep the display.

## Response Style

Keep replies short and operational.

After start succeeds, say that monitoring is on. If the Hermes alert hook or a
custom `PRESENCE_WATCH_ALERT_HOOK` is configured, say that an automatic warning
will be sent if keyboard/mouse/trackpad activity is detected.

After stop succeeds, say that monitoring is off.

If start fails, report the command output directly and mention the most likely
fix:

- Xcode license: run `sudo xcodebuild -license`
- macOS permissions: grant Accessibility and Input Monitoring to the terminal or
  process running Hermes.

## Alert Files

The control script writes state here:

```text
__PRESENCE_WATCH_DIR__/.presence-watch/pid
__PRESENCE_WATCH_DIR__/.presence-watch/alert.json
__PRESENCE_WATCH_DIR__/.presence-watch/presence-watch.log
__PRESENCE_WATCH_DIR__/.presence-watch/alert-send.log
```

`alert.json` exists only after input is detected in the current monitoring
session. `alert-send.log` records whether the proactive WeChat alert was sent.
