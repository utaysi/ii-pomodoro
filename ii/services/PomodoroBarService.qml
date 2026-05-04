pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root

    property int focusDuration: Config.options.time.pomodoro.focus
    property int breakDuration: Config.options.time.pomodoro.breakTime

    property bool mutePomodoroSound: false
    property bool muteBreakSound: false

    property string state: "idle"

    property int secondsLeft: focusDuration
    property int _activeDuration: focusDuration
    property int _startTimestamp: 0
    property int _elapsedAtPause: 0
    property int _alertTimestamp: 0
    property int alertOverflow: 0
    property bool alertFlash: false

    readonly property color displayColor: {
        switch (state) {
        case "idle": return "#E53935"
        case "running_pomodoro": case "paused_pomodoro":
        case "alert_pomodoro": case "ready_pomodoro": return "#43A047"
        case "running_break": case "paused_break":
        case "alert_break": case "ready_break": return "#FFB300"
        default: return "#E53935"
        }
    }

    readonly property color displayTextColor: {
        switch (state) {
        case "idle": return "#FFFFFF"
        case "running_pomodoro": case "paused_pomodoro":
        case "alert_pomodoro": case "ready_pomodoro": return "#FFFFFF"
        case "running_break": case "paused_break":
        case "alert_break": case "ready_break": return "#1A1A2E"
        default: return "#FFFFFF"
        }
    }

    readonly property string displayText: {
        if (state === "idle") return "POMO"
        if (state === "alert_pomodoro" || state === "alert_break") {
            var m = Math.floor(alertOverflow / 60).toString().padStart(2, '0')
            var s = Math.floor(alertOverflow % 60).toString().padStart(2, '0')
            return "+" + m + ":" + s
        }
        var m = Math.floor(secondsLeft / 60).toString().padStart(2, '0')
        var s = Math.floor(secondsLeft % 60).toString().padStart(2, '0')
        return m + ":" + s
    }

    readonly property bool isPaused: state === "paused_pomodoro" || state === "paused_break"
    readonly property bool isAlerting: state === "alert_pomodoro" || state === "alert_break"
    readonly property bool isRunning: state === "running_pomodoro" || state === "running_break"
    readonly property bool isReady: state === "ready_pomodoro" || state === "ready_break"

    function _now() { return Math.floor(Date.now() / 1000) }

    Timer {
        id: tickTimer
        interval: 200
        repeat: true
        running: root.isRunning
        onTriggered: root._tick()
    }

    Timer {
        id: alertFlashTimer
        interval: 500
        repeat: true
        running: root.isAlerting
        onTriggered: root.alertFlash = !root.alertFlash
    }

    Timer {
        id: alertTickTimer
        interval: 1000
        repeat: true
        running: root.isAlerting
        onTriggered: root.alertOverflow = root._now() - root._alertTimestamp
    }

    function _tick() {
        var elapsed = _now() - _startTimestamp
        secondsLeft = Math.max(0, _activeDuration - elapsed)
        if (secondsLeft <= 0) {
            if (state === "running_pomodoro") {
                _alertTimestamp = _now()
                state = "alert_pomodoro"
            } else {
                _alertTimestamp = _now()
                state = "alert_break"
            }
            secondsLeft = 0
            _playAlertSound()
        }
    }

    function _playAlertSound() {
        if (state === "alert_pomodoro" && !mutePomodoroSound) {
            Audio.playSystemSound("complete")
        } else if (state === "alert_break" && !muteBreakSound) {
            Audio.playSystemSound("alarm-clock-elapsed")
        }
    }

    function _playClickSound() {
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", "-hide_banner", "-loglevel", "quiet", Quickshell.shellPath("assets/sounds/thock.ogg")])
    }

    function handleClick() {
        _playClickSound()
        switch (state) {
        case "idle":
            _startPomodoro()
            break
        case "ready_pomodoro":
            _startPomodoro()
            break
        case "ready_break":
            _startBreak()
            break
        case "running_pomodoro":
        case "running_break":
            _pause()
            break
        case "paused_pomodoro":
            _resumePomodoro()
            break
        case "paused_break":
            _resumeBreak()
            break
        case "alert_pomodoro":
        case "alert_break":
            nextMode()
            break
        }
    }

    function _startPomodoro() {
        _activeDuration = focusDuration
        _startTimestamp = _now()
        secondsLeft = focusDuration
        state = "running_pomodoro"
    }

    function _startBreak() {
        _activeDuration = breakDuration
        _startTimestamp = _now()
        secondsLeft = breakDuration
        state = "running_break"
    }

    function _pause() {
        _elapsedAtPause = _now() - _startTimestamp
        state = (state === "running_pomodoro") ? "paused_pomodoro" : "paused_break"
    }

    function _resumePomodoro() {
        _startTimestamp = _now() - _elapsedAtPause
        secondsLeft = Math.max(0, _activeDuration - _elapsedAtPause)
        state = "running_pomodoro"
    }

    function _resumeBreak() {
        _startTimestamp = _now() - _elapsedAtPause
        secondsLeft = Math.max(0, _activeDuration - _elapsedAtPause)
        state = "running_break"
    }

    function nextMode() {
        _stopAlerts()
        var pomodoroStates = ["idle", "ready_pomodoro", "running_pomodoro", "paused_pomodoro", "alert_pomodoro"]
        if (pomodoroStates.indexOf(state) >= 0) {
            state = "ready_break"
            secondsLeft = breakDuration
        } else {
            state = "ready_pomodoro"
            secondsLeft = focusDuration
        }
    }

    function reset() {
        _stopAlerts()
        state = "idle"
        secondsLeft = focusDuration
    }

    function _stopAlerts() {
        
        alertFlashTimer.stop()
        alertTickTimer.stop()
        alertFlash = false
        alertOverflow = 0
    }

    onFocusDurationChanged: {
        if (state === "idle" || state === "ready_pomodoro") {
            secondsLeft = focusDuration
        }
    }

    onBreakDurationChanged: {
        if (state === "ready_break") {
            secondsLeft = breakDuration
        }
    }
}