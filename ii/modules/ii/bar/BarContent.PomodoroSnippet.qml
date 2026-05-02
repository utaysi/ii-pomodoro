// Snippet to insert into BarContent.qml for Pomodoro widget integration
BarGroup {
    anchors.verticalCenter: parent.verticalCenter

    PomodoroBarWidget {
        Layout.alignment: Qt.AlignVCenter
    }
}

VerticalBarSeparator {
    visible: Config.options?.bar.borderless
}