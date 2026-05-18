# Presence Watch

Presence Watch is a tiny macOS activity monitor for short "I am stepping away"
moments. It listens for keyboard, mouse, and trackpad input, records the first
event, and can optionally notify you through a Hermes Agent Weixin/WeChat setup.

It does not lock the Mac, identify a person, take photos, record audio, or stop
running programs.

## Features

- Keyboard, mouse, and trackpad activity detection
- One clean watch session per start; old runtime logs are overwritten
- Optional Hermes Agent Weixin/WeChat alert on first detected input
- Optional custom alert hook for OpenClaw or other agents
- Hermes and OpenClaw skill installers for natural-language control
- Optional remote display sleep command via `pmset displaysleepnow`
- Local state kept under `.presence-watch/`

## Requirements

- macOS
- Swift command-line tools
- Accessibility/Input Monitoring permission for the terminal or service that
  starts the watcher
- Optional: Hermes Agent with Weixin/WeChat configured for proactive alerts
- Optional: Hermes or OpenClaw with terminal access for natural-language control

If Swift says the Xcode license has not been accepted, run:

```sh
sudo xcodebuild -license
```

## Manual Usage

```sh
./presence-watch-control.sh start
./presence-watch-control.sh status
./presence-watch-control.sh logs
./presence-watch-control.sh stop
```

To sleep only the display:

```sh
./presence-watch-control.sh sleep-display
```

## Agent Skill Setup

Install the bundled Hermes skill:

```sh
./install-hermes-skill.sh
```

Then restart your Hermes gateway or clear any existing session prompt cache so
Hermes sees the new skill instructions.

Install the bundled OpenClaw-compatible skill:

```sh
./install-openclaw-skill.sh
```

The OpenClaw installer defaults to the common personal skill directory
`$HOME/.agents/skills`. If your OpenClaw uses a custom skill directory, run:

```sh
OPENCLAW_SKILLS_DIR=/path/to/skills ./install-openclaw-skill.sh
```

Restart OpenClaw or start a new session after installation so it reloads skills.

Natural-language examples for Hermes or OpenClaw:

```text
开启电脑监控
有人动我电脑吗
我回来了
确认息屏
```

For display sleep, consider using an explicit phrase such as `确认息屏` to avoid
accidental trigger from casual discussion.

## Copy-Paste Agent Install Prompts

Replace `REPO_URL` with this repository's Git URL, then paste the matching block
into Hermes or OpenClaw.

Hermes:

```text
请在这台 macOS 上安装 Presence Watch，并把它注册成 Hermes skill。不要读取、上传或打印 .env、token、日志里的敏感内容。

执行：

REPO_URL="https://github.com/<owner>/presence-watch.git"
INSTALL_DIR="$HOME/presence-watch"
if [ -d "$INSTALL_DIR/.git" ]; then
  cd "$INSTALL_DIR" && git pull --ff-only
else
  git clone "$REPO_URL" "$INSTALL_DIR" && cd "$INSTALL_DIR"
fi
chmod +x *.sh
./install-hermes-skill.sh
./presence-watch-control.sh status

完成后告诉我安装路径、skill 路径和 status 输出。如果 Swift 要求接受 Xcode license，提示我运行 sudo xcodebuild -license；如果 macOS 权限不足，提示我给运行 Hermes 的终端或进程开启 Accessibility 和 Input Monitoring。
```

OpenClaw:

```text
请在这台 macOS 上安装 Presence Watch，并把它注册成 OpenClaw 可用的 skill。不要读取、上传或打印 .env、token、日志里的敏感内容。

执行：

REPO_URL="https://github.com/<owner>/presence-watch.git"
INSTALL_DIR="$HOME/presence-watch"
if [ -d "$INSTALL_DIR/.git" ]; then
  cd "$INSTALL_DIR" && git pull --ff-only
else
  git clone "$REPO_URL" "$INSTALL_DIR" && cd "$INSTALL_DIR"
fi
chmod +x *.sh
./install-openclaw-skill.sh
./presence-watch-control.sh status

如果 OpenClaw 的 skill 目录不是默认目录，改用 OPENCLAW_SKILLS_DIR=/path/to/skills ./install-openclaw-skill.sh。完成后告诉我安装路径、skill 路径和 status 输出。如果 Swift 要求接受 Xcode license，提示我运行 sudo xcodebuild -license；如果 macOS 权限不足，提示我给运行 OpenClaw 的终端或进程开启 Accessibility 和 Input Monitoring。
```

## Weixin/WeChat Alerts

`presence-watch-control.sh start` automatically uses `hermes-presence-alert.sh`
when it is executable. The alert script expects Hermes Agent to be installed
under:

```text
$HOME/.hermes/hermes-agent
```

You can override paths with:

```sh
HERMES_HOME=/path/to/.hermes
HERMES_AGENT=/path/to/hermes-agent
HERMES_PYTHON=/path/to/python
```

The alert script sends through Hermes' `send_message` tool with target `weixin`,
so your Hermes environment should define the Weixin credentials and home channel
it normally uses.

For OpenClaw or another agent, provide your own executable alert script and start
with:

```sh
PRESENCE_WATCH_ALERT_HOOK=/path/to/alert-hook.sh ./presence-watch-control.sh start
```

The hook receives these environment variables:

```text
PRESENCE_WATCH_EVENT_JSON
PRESENCE_WATCH_LOG
PRESENCE_WATCH_ALERT_FILE
```

See `presence-watch-alert-hook.example.sh` for a minimal custom hook template.

## State Files

Runtime files are written to `.presence-watch/` and are ignored by Git:

```text
.presence-watch/pid
.presence-watch/alert.json
.presence-watch/presence-watch.log
.presence-watch/alert-send.log
.presence-watch/stdout.log
.presence-watch/stderr.log
```

Each `start` clears the previous session's logs and alert state.

## Security Notes

This tool is a lightweight local activity detector, not a security boundary. It
can tell you that input happened; it cannot prove who touched the machine or
prevent someone from using it.

Do not commit your Hermes `.env`, Weixin tokens, logs, or runtime state.
