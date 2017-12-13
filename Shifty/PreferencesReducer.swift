//
//  PreferencesReducer.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//
import MASShortcut
import ReSwift

func preferencesReducer(_ action: Action, state: ShiftyPreferences?) -> ShiftyPreferences {
    var state = state ?? initialPreferencesState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    default:
        break
    }
    
    return state
}

func initialPreferencesState() -> ShiftyPreferences {
    let shortcuts = ShiftyShortcuts(toggleNightShiftShortcut: MASShortcut(),
                                    incrementColorTempShortcut: MASShortcut(),
                                    decrementColorTempShortcut: MASShortcut(),
                                    disableAppShortcut: MASShortcut(),
                                    disableHourShortcut: MASShortcut(),
                                    disableCustomShortcut: MASShortcut())
    return ShiftyPreferences(isStatusToggleEnabled: false,
                             isAutoLaunchEnabled: false,
                             isIconSwitchingEnabled: false,
                             isDarkModeSyncEnabled: false,
                             isWebsiteControlEnabled: false,
                             shortucuts: shortcuts)
}
