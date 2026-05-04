import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

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
        width: badgeMetrics.width + 22
        height: badgeText.implicitHeight + 6
        radius: Appearance.rounding.full
        color: {
            if (root.menuOpen) return Appearance.colors.colPrimary
            if (PomodoroBarService.isAlerting) return PomodoroBarService.alertFlash ? Appearance.colors.colPrimary : "transparent"
            return "transparent"
        }

        Behavior on color { ColorAnimation { duration: 200 } }

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                width: 6
                height: 6
                radius: Appearance.rounding.full
                color: PomodoroBarService.dotColor
                opacity: {
                    if (PomodoroBarService.state === "idle") return 0
                    if (PomodoroBarService.isAlerting) return PomodoroBarService.alertFlash ? 1.0 : 0.4
                    if (PomodoroBarService.isPaused) return 0.7
                    return 1.0
                }
                anchors.verticalCenter: parent.verticalCenter

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            StyledText {
                id: badgeText
                text: PomodoroBarService.displayText
                font.pixelSize: Appearance.font.pixelSize.normal
                font.family: Appearance.font.family.numbers
                font.variableAxes: Appearance.font.variableAxes.numbers
                color: root.menuOpen ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface

                TextMetrics {
                    id: badgeMetrics
                    font: badgeText.font
                    text: "+00:00"
                }
            }
        }
    }

    Loader {
        id: menuLoader
        active: root.menuOpen

        sourceComponent: PanelWindow {
            id: pomoMenu

            color: "transparent"

            anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
            anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
            anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
            anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:popup"
            WlrLayershell.layer: WlrLayer.Overlay

            implicitWidth: menuBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: menuBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

            margins {
                left: root.QsWindow?.mapFromItem(badge, 0, 0).x - (menuBackground.implicitWidth - badge.width) / 2 - Appearance.sizes.elevationMargin
                top: Config.options.bar.bottom ? undefined : Appearance.sizes.barHeight
                bottom: Config.options.bar.bottom ? Appearance.sizes.barHeight : undefined
                right: Appearance.sizes.verticalBarWidth
            }

            mask: Region {
                item: menuBackground
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
                readonly property real margin: 12
                anchors {
                    fill: parent
                    leftMargin: Appearance.sizes.elevationMargin
                    rightMargin: Appearance.sizes.elevationMargin
                    topMargin: Appearance.sizes.elevationMargin
                    bottomMargin: Appearance.sizes.elevationMargin
                }
                implicitWidth: menuLayout.implicitWidth + margin * 2
                implicitHeight: menuLayout.implicitHeight + margin * 2
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: menuLayout
                    anchors.fill: parent
                    anchors.margins: menuBackground.margin
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.larger
                            text: "timer"
                            color: PomodoroBarService.dotColor
                        }

                        StyledText {
                            text: Translation.tr("Pomodoro")
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnSurfaceVariant
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: PomodoroBarService.state.replace("_", " ")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: PomodoroBarService.dotColor
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
                            color: Appearance.colors.colOnSurfaceVariant
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
                            color: Appearance.colors.colOnSurfaceVariant
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
                            text: Translation.tr("Mute sounds")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurfaceVariant
                            Layout.fillWidth: true
                        }

                        StyledSwitch {
                            scale: 0.85
                            checked: PomodoroBarService.muteSound
                            onToggled: PomodoroBarService.muteSound = checked
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
                        colBackground: Appearance.colors.colSurfaceContainerHighest
                        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                        colRipple: Appearance.colors.colSurfaceContainerHighestActive
                        downAction: () => { PomodoroBarService.reset(); root.menuOpen = false }
                        contentItem: Row {
                            spacing: 4
                            anchors.centerIn: parent
                            MaterialSymbol {
                                text: "delete_outline"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colError
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: Translation.tr("Reset")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}