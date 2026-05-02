import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    property bool menuOpen: false
    implicitWidth: badge.width + 8
    implicitHeight: Appearance.sizes.barHeight

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (event) => {
            if (event.button === Qt.RightButton) {
                root.menuOpen = !root.menuOpen
            } else {
                if (root.menuOpen) root.menuOpen = false
                PomodoroBarService.handleClick()
            }
        }
    }

    Rectangle {
        id: badge
        anchors.centerIn: parent
        width: badgeMetrics.width + 12
        height: badgeText.implicitHeight + 6
        radius: Appearance.rounding.unsharpen
        color: root.menuOpen ? "#FFFFFF" : PomodoroBarService.displayColor
        opacity: {
            if (PomodoroBarService.isAlerting) return PomodoroBarService.alertFlash ? 1.0 : 0.4
            if (PomodoroBarService.isPaused) return 0.7
            return 1.0
        }

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            text: PomodoroBarService.displayText
            font.pixelSize: Appearance.font.pixelSize.normal
            font.family: Appearance.font.family.numbers
            font.variableAxes: Appearance.font.variableAxes.numbers
            color: root.menuOpen ? "#000000" : PomodoroBarService.displayTextColor

            TextMetrics {
                id: badgeMetrics
                font: badgeText.font
                text: "00:00"
            }
        }
    }

    Loader {
        id: menuLoader
        active: root.menuOpen

        sourceComponent: PopupWindow {
            id: pomoMenu

            color: "transparent"
            visible: true

            implicitWidth: menuLayout.implicitWidth + 24
            implicitHeight: menuLayout.implicitHeight + 24

            anchor {
                window: root.QsWindow.window
                rect.x: root.mapToItem(null, 0, 0).x
                rect.y: root.mapToItem(null, 0, 0).y + (Config.options.bar.bottom ? 0 : root.height)
                rect.width: root.width
                rect.height: root.height
                edges: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
                gravity: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
                adjustment: PopupAdjustment.ResizeY | PopupAdjustment.SlideX
            }

            HyprlandFocusGrab {
                active: true
                windows: [pomoMenu]
                onCleared: root.menuOpen = false
            }

            StyledRectangularShadow {
                target: menuBackground
            }

            Rectangle {
                id: menuBackground
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                width: menuLayout.implicitWidth + 24
                height: menuLayout.implicitHeight + 24

                ColumnLayout {
                    id: menuLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.larger
                            text: "timer"
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text: Translation.tr("Pomodoro")
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: PomodoroBarService.state.replace("_", " ")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: Translation.tr("Focus") + ":"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledSpinBox {
                            Layout.fillWidth: true
                            from: 1
                            to: 120
                            value: Math.round(PomodoroBarService.focusDuration / 60)
                            onValueModified: PomodoroBarService.focusDuration = value * 60
                        }

                        StyledText {
                            text: Translation.tr("min")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: Translation.tr("Break") + ":"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledSpinBox {
                            Layout.fillWidth: true
                            from: 1
                            to: 60
                            value: Math.round(PomodoroBarService.breakDuration / 60)
                            onValueModified: PomodoroBarService.breakDuration = value * 60
                        }

                        StyledText {
                            text: Translation.tr("min")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.unsharpen
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryActive
                        downAction: () => { PomodoroBarService.nextMode(); root.menuOpen = false }
                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Next Mode")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Mute focus sound")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }

                        StyledSwitch {
                            scale: 0.85
                            checked: PomodoroBarService.mutePomodoroSound
                            onToggled: PomodoroBarService.mutePomodoroSound = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Mute break sound")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }

                        StyledSwitch {
                            scale: 0.85
                            checked: PomodoroBarService.muteBreakSound
                            onToggled: PomodoroBarService.muteBreakSound = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.unsharpen
                        colBackground: Appearance.colors.colErrorContainer
                        colBackgroundHover: Appearance.colors.colErrorContainerHover
                        colRipple: Appearance.colors.colErrorContainerActive
                        downAction: () => { PomodoroBarService.reset(); root.menuOpen = false }
                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Reset")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnErrorContainer
                        }
                    }
                }
            }
        }
    }
}