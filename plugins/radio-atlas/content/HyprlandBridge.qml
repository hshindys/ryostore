pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// Hyprland-only bridge for radio-atlas Panel. Loaded conditionally so the
// plugin keeps working on niri/Wayfire (where Quickshell.Hyprland is absent).
Item {
    id: bridge

    readonly property var focusedMonitor: Hyprland.focusedMonitor
    function monitorFor(screen) { return Hyprland.monitorFor(screen); }
    function refreshMonitors() { Hyprland.refreshMonitors(); }

    signal rawEvent(var event)
    Connections {
        target: Hyprland
        function onRawEvent(event) { bridge.rawEvent(event); }
    }
}
