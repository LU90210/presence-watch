#!/usr/bin/env swift

import Cocoa
import ApplicationServices
import Foundation

struct Options {
    var logPath: String = FileManager.default.currentDirectoryPath + "/presence-watch.log"
    var alertFilePath: String?
    var onAlertCommand: String?
    var alarm = true
    var alertInterval: TimeInterval = 3
}

func usage() {
    print("""
    Usage: ./presence-watch.swift [--log PATH] [--alert-file PATH] [--on-alert COMMAND] [--silent]

    Monitors keyboard and trackpad/mouse activity until you stop it with Ctrl-C.
    If any input is detected, it records the event and alerts you.
    """)
}

func parseOptions() -> Options {
    var options = Options()
    var args = CommandLine.arguments.dropFirst().makeIterator()

    while let arg = args.next() {
        switch arg {
        case "--log":
            guard let path = args.next() else {
                usage()
                exit(2)
            }
            options.logPath = path
        case "--alert-file":
            guard let path = args.next() else {
                usage()
                exit(2)
            }
            options.alertFilePath = path
        case "--on-alert":
            guard let command = args.next() else {
                usage()
                exit(2)
            }
            options.onAlertCommand = command
        case "--silent":
            options.alarm = false
        case "--alert-interval":
            guard let value = args.next(), let seconds = TimeInterval(value) else {
                usage()
                exit(2)
            }
            options.alertInterval = seconds
        case "-h", "--help":
            usage()
            exit(0)
        default:
            print("Unknown argument: \(arg)")
            usage()
            exit(2)
        }
    }

    return options
}

let options = parseOptions()
let formatter = ISO8601DateFormatter()
let logURL = URL(fileURLWithPath: options.logPath)
let alertFileURL = options.alertFilePath.map { URL(fileURLWithPath: $0) }
let eventNames: [CGEventType: String] = [
    .keyDown: "keyDown",
    .keyUp: "keyUp",
    .flagsChanged: "flagsChanged",
    .leftMouseDown: "leftMouseDown",
    .leftMouseUp: "leftMouseUp",
    .rightMouseDown: "rightMouseDown",
    .rightMouseUp: "rightMouseUp",
    .mouseMoved: "mouseMoved",
    .leftMouseDragged: "leftMouseDragged",
    .rightMouseDragged: "rightMouseDragged",
    .scrollWheel: "scrollWheel",
    .otherMouseDown: "otherMouseDown",
    .otherMouseUp: "otherMouseUp",
    .otherMouseDragged: "otherMouseDragged",
    .tapDisabledByTimeout: "tapDisabledByTimeout",
    .tapDisabledByUserInput: "tapDisabledByUserInput"
]

final class MonitorState {
    var triggered = false
    var eventCount = 0
    var lastAlertTime: Date?
}

let state = MonitorState()

func appendLog(_ line: String) {
    let data = Data((line + "\n").utf8)

    if FileManager.default.fileExists(atPath: logURL.path) {
        if let handle = try? FileHandle(forWritingTo: logURL) {
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
            try? handle.close()
        }
    } else {
        try? data.write(to: logURL, options: .atomic)
    }
}

func writeAlertFile(_ line: String) {
    guard let alertFileURL else { return }
    try? Data((line + "\n").utf8).write(to: alertFileURL, options: .atomic)
}

func appleScriptString(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

func alertOnce(eventName: String) {
    guard options.alarm else { return }

    NSSound.beep()

    let message = "Input detected: \(eventName)"
    let command = """
    display notification \(appleScriptString(message)) with title "Presence Watch"
    """

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", command]
    try? task.run()
}

func runAlertHook(eventJSON: String) {
    guard let command = options.onAlertCommand, !command.isEmpty else { return }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.arguments = ["-lc", command]

    var environment = ProcessInfo.processInfo.environment
    environment["PRESENCE_WATCH_EVENT_JSON"] = eventJSON
    environment["PRESENCE_WATCH_LOG"] = logURL.path
    if let alertFileURL {
        environment["PRESENCE_WATCH_ALERT_FILE"] = alertFileURL.path
    }
    task.environment = environment

    try? task.run()
}

let mask =
    CGEventMask(1 << CGEventType.keyDown.rawValue) |
    CGEventMask(1 << CGEventType.keyUp.rawValue) |
    CGEventMask(1 << CGEventType.flagsChanged.rawValue) |
    CGEventMask(1 << CGEventType.leftMouseDown.rawValue) |
    CGEventMask(1 << CGEventType.leftMouseUp.rawValue) |
    CGEventMask(1 << CGEventType.rightMouseDown.rawValue) |
    CGEventMask(1 << CGEventType.rightMouseUp.rawValue) |
    CGEventMask(1 << CGEventType.mouseMoved.rawValue) |
    CGEventMask(1 << CGEventType.leftMouseDragged.rawValue) |
    CGEventMask(1 << CGEventType.rightMouseDragged.rawValue) |
    CGEventMask(1 << CGEventType.scrollWheel.rawValue) |
    CGEventMask(1 << CGEventType.otherMouseDown.rawValue) |
    CGEventMask(1 << CGEventType.otherMouseUp.rawValue) |
    CGEventMask(1 << CGEventType.otherMouseDragged.rawValue)

let callback: CGEventTapCallBack = { proxy, type, event, refcon in
    let state = Unmanaged<MonitorState>.fromOpaque(refcon!).takeUnretainedValue()

    state.eventCount += 1

    let name = eventNames[type] ?? "event-\(type.rawValue)"
    let point = event.location
    let timestamp = formatter.string(from: Date())
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let line = """
    {"time":"\(timestamp)","event":"\(name)","x":\(Int(point.x)),"y":\(Int(point.y)),"keyCode":\(keyCode),"count":\(state.eventCount)}
    """

    appendLog(line)

    let now = Date()
    let shouldAlert: Bool
    if !state.triggered {
        state.triggered = true
        shouldAlert = true
    } else if let last = state.lastAlertTime,
              now.timeIntervalSince(last) >= options.alertInterval {
        shouldAlert = true
    } else {
        shouldAlert = false
    }

    if shouldAlert {
        state.lastAlertTime = now
        writeAlertFile(line)
        runAlertHook(eventJSON: line)
        print("\nInput detected at \(timestamp): \(name) (#\(state.eventCount))")
        print("Log: \(logURL.path)")
        alertOnce(eventName: name)
    } else {
        print("Input #\(state.eventCount): \(name) at \(timestamp)")
    }

    return Unmanaged.passUnretained(event)
}

let statePointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(state).toOpaque())

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: mask,
    callback: callback,
    userInfo: statePointer
) else {
    print("""
    Could not start the event tap.

    Give the app you run this from permission in:
    System Settings -> Privacy & Security -> Accessibility
    and, if macOS asks, Input Monitoring.

    Then run it again.
    """)
    exit(1)
}

let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

let startTime = formatter.string(from: Date())
appendLog("{\"time\":\"\(startTime)\",\"event\":\"watchStarted\"}")

print("Presence Watch is running.")
print("Started: \(startTime)")
print("Log: \(logURL.path)")
print("Leave this window open. Stop with Ctrl-C when you return.")

CFRunLoopRun()
