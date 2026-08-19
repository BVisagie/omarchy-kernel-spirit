import QtQuick
import qs.Commons
import qs.Ui

// Speech bubble anchored to the bar penguin. Escape and outside click
// dismiss it; it also auto-hides after autoHideMs.
Panel {
  id: root
  moduleName: "io.github.bvisagie.kernel-spirit"
  ipcTarget: "io.github.bvisagie.kernel-spirit"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var line: hostWidget && hostWidget.currentLine ? hostWidget.currentLine : null
  readonly property int lineEpoch: hostWidget && hostWidget.lineEpoch ? hostWidget.lineEpoch : 0
  readonly property string lineText: line && line.text ? line.text : ""
  readonly property bool quoted: !!(line && line.quoted)
  readonly property string sourceText: line && line.source ? line.source : ""
  readonly property bool muted: hostWidget ? hostWidget.muted === true : false
  readonly property bool snoozed: hostWidget ? hostWidget.snoozed === true : false

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int autoHideMs: hostWidget
    ? Math.max(3000, Number(hostWidget.setting("autoHideMs", 8000)))
    : 8000

  function open() {
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
    restartHideTimer()
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    hideTimer.stop()
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function restartHideTimer() {
    hideTimer.interval = root.autoHideMs
    hideTimer.restart()
  }

  // Beak flaps for a moment whenever a fresh line appears.
  property bool talking: false

  function startTalking() {
    root.talking = true
    talkTimer.restart()
  }

  onLineEpochChanged: {
    if (root.opened) restartHideTimer()
    startTalking()
  }

  onOpenedChanged: if (root.opened) startTalking()

  Timer {
    id: talkTimer
    interval: 1800
    onTriggered: root.talking = false
  }

  Timer {
    id: hideTimer
    repeat: false
    onTriggered: root.close()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(bubble.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: hideTimer.stop()
        onExited: if (root.opened) root.restartHideTimer()
      }

      Row {
        id: bubble
        width: parent.width
        spacing: Style.space(12)

        Loader {
          id: panelPenguin
          width: Style.space(48)
          height: Style.space(48)
          source: Qt.resolvedUrl("PenguinIcon.qml")
        }

        Binding {
          when: panelPenguin.item !== null
          target: panelPenguin.item
          property: "muted"
          value: root.muted || root.snoozed
        }

        Binding {
          when: panelPenguin.item !== null
          target: panelPenguin.item
          property: "talking"
          value: root.talking
        }

        Column {
          width: parent.width - Style.space(48) - Style.space(12)
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: root.quoted ? "“" + root.lineText + "”" : (root.lineText || "…")
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.subtitle
            wrapMode: Text.WordWrap
          }

          Text {
            visible: root.quoted && root.sourceText !== ""
            width: parent.width
            text: root.sourceText
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Row {
            spacing: Style.space(14)

            Text {
              text: root.muted ? "UNMUTE" : "MUTE"
              color: muteMouse.containsMouse
                ? Style.hoverStateColor(root.contentForeground, Color.accent)
                : Qt.darker(root.contentForeground, 1.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              font.bold: true

              MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.hostWidget) root.hostWidget.toggleMute()
              }
            }

            Text {
              text: root.snoozed ? "WAKE" : "SNOOZE"
              color: snoozeMouse.containsMouse
                ? Style.hoverStateColor(root.contentForeground, Color.accent)
                : Qt.darker(root.contentForeground, 1.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              font.bold: true

              MouseArea {
                id: snoozeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (!root.hostWidget) return
                  if (root.snoozed) root.hostWidget.clearSnooze()
                  else root.hostWidget.snooze()
                }
              }
            }
          }
        }
      }
    }
  }
}
