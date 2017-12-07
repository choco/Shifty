//
//  AppDelegate.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import ServiceManagement
import Fabric
import Crashlytics
import MASPreferences_Shifty
import AXSwift

let BLClient = CBBlueLightClient.shared
let Prefs = PrefManager.sharedInstance
let SSLocationManager = SunriseSetLocationManager()

class AppDelegate: NSObject, NSApplicationDelegate {

    var accessibilityPromptWindow: AccessibilityPromptWindow!
    var statusMenuController: StatusMenuController!
    
    lazy var preferenceWindowController: PrefWindowController = {
        return PrefWindowController(
            viewControllers: [
                PrefGeneralViewController(),
                PrefShortcutsViewController(),
                PrefAboutViewController()],
            title: NSLocalizedString("prefs.title", comment: "Preferences"))
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Prefs.userDefaults.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        Event.appLaunched.record()
        
        // Check if macOS version > 10.12.4 which introduced Night Shift
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 4)) {
            Event.oldMacOSVersion(version: ProcessInfo().operatingSystemVersionString).record()
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.version_message", comment: "This version of macOS does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.version_informative", comment: "Update your Mac to version 10.12.4 or higher to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        }
        
        // Check if mac supports Night Shift
        if !CBBlueLightClient.supportsBlueLightReduction() {
            Event.unsupportedHardware.record()
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.hardware_message", comment: "Your Mac does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.hardware_informative", comment: "A newer Mac is required to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        }
        
        // Check if Shifty was launched by ShiftyHelper, if so terminate the helper
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        let runningApps = NSWorkspace.shared.runningApplications
        let startedAtLogin = !runningApps.filter { $0.bundleIdentifier == launcherAppIdentifier }.isEmpty
        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: Notification.Name("killme"),
                                                         object: Bundle.main.bundleIdentifier!)
        }

        // Show accessibility permission prompt on third app launch
        let count = Prefs.userDefaults.integer(forKey: Keys.appLaunchCount)
        Prefs.userDefaults.set(count + 1, forKey: Keys.appLaunchCount)
        if count == 2 && !UIElement.isProcessTrusted(withPrompt: false) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            accessibilityPromptWindow = AccessibilityPromptWindow()
            accessibilityPromptWindow.showWindow(nil)
        }
        
        // Setup statusMenuController
        statusMenuController = StatusMenuController()
        statusMenuController.showWindow(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

