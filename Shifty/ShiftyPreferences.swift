//
//  ShiftyPreferences.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//
import MASShortcut

struct ShiftyPreferences {
    var isStatusToggleEnabled: Bool
    var isAutoLaunchEnabled: Bool
    var isIconSwitchingEnabled: Bool
    var isDarkModeSyncEnabled: Bool
    var isWebsiteControlEnabled: Bool

    var shortucuts: ShiftyShortcuts
}

struct ShiftyShortcuts {
    var toggleNightShiftShortcut: MASShortcut
    var incrementColorTempShortcut: MASShortcut
    var decrementColorTempShortcut: MASShortcut
    var disableAppShortcut: MASShortcut
    var disableHourShortcut: MASShortcut
    var disableCustomShortcut: MASShortcut
}
