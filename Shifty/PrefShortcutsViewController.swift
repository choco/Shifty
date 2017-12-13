//
//  PrefShortcutsViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences_Shifty
import MASShortcut

@objcMembers
class PrefShortcutsViewController: NSViewController, MASPreferencesViewController {
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefShortcutsViewController") }
    }
    
    var viewIdentifier: String = "PrefShortcutsViewController"
    
    var toolbarItemImage: NSImage? {
        get { return #imageLiteral(resourceName: "shortcutsIcon") }
    }
    
    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
        }
    }
    
    var hasResizableWidth = false
    var hasResizableHeight = false
    
    @IBOutlet weak var toggleNightShiftShortcut: MASShortcutView!
    @IBOutlet weak var incrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var decrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var disableAppShortcut: MASShortcutView!
    @IBOutlet weak var disableHourShortcut: MASShortcutView!
    @IBOutlet weak var disableCustomShortcut: MASShortcutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        toggleNightShiftShortcut.associatedUserDefaultsKey = Keys.toggleNightShiftShortcut
        incrementColorTempShortcut.associatedUserDefaultsKey = Keys.incrementColorTempShortcut
        decrementColorTempShortcut.associatedUserDefaultsKey = Keys.decrementColorTempShortcut
        disableAppShortcut.associatedUserDefaultsKey = Keys.disableAppShortcut
        disableHourShortcut.associatedUserDefaultsKey = Keys.disableHourShortcut
        disableCustomShortcut.associatedUserDefaultsKey = Keys.disableCustomShortcut
    }
    
    override func viewWillDisappear() {
        Event.shortcuts(toggleNightShift: toggleNightShiftShortcut.shortcutValue != nil, increaseColorTemp: incrementColorTempShortcut.shortcutValue != nil, decreaseColorTemp: decrementColorTempShortcut.shortcutValue != nil, disableApp: disableAppShortcut.shortcutValue != nil, disableHour: disableHourShortcut.shortcutValue != nil, disableCustom: disableCustomShortcut.shortcutValue != nil).record()
    }
}
