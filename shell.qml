// shell.qml - QuickShell entry point
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // Set by the NixOS module through environment variables
    readonly property string cfgPosition: Quickshell.env("STATS_POSITION") || "bottom-left"
    readonly property int cfgFontSize: parseInt(Quickshell.env("STATS_FONT_SIZE")) || 20
    readonly property int cfgInterval: parseInt(Quickshell.env("STATS_INTERVAL")) || 2000
    readonly property bool cfgGpu: Quickshell.env("STATS_GPU") === "1"
    // Comma separated monitor names (e.g. "DP-1,HDMI-A-1"), empty = all screens
    readonly property var cfgScreens: (Quickshell.env("STATS_SCREENS") || "").split(",").filter(n => n.length > 0)

    readonly property var targetScreens: {
        var out = [];
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i];
            if (cfgScreens.length === 0 || cfgScreens.indexOf(s.name) >= 0)
                out.push(s);
        }
        return out;
    }

    Variants {
        model: targetScreens

        delegate: PanelWindow {
            required property var modelData

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            color: "transparent"
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Stats {
                statsScale: cfgFontSize / 20
                gpuEnabled: cfgGpu
                interval: cfgInterval

                readonly property bool isCenter: cfgPosition === "center"
                anchors {
                    margins: 30
                    centerIn: isCenter ? parent : undefined
                    left: !isCenter && cfgPosition.endsWith("left") ? parent.left : undefined
                    right: !isCenter && cfgPosition.endsWith("right") ? parent.right : undefined
                    top: !isCenter && cfgPosition.startsWith("top") ? parent.top : undefined
                    bottom: !isCenter && cfgPosition.startsWith("bottom") ? parent.bottom : undefined
                }
            }
        }
    }
}
