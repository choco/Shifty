//
//  BrowserManager.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 25/11/2017.
//

import ScriptingBridge
import AXSwift
import PublicSuffix
import SwiftLog


typealias BundleIdentifier = String

enum SupportedBrowserID: BundleIdentifier {
    case safari = "com.apple.Safari"
    case safariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    
    case chrome = "com.google.Chrome"
    case chromeCanary = "com.google.Chrome.canary"
    case chromium = "org.chromium.Chromium"
    
    case opera = "com.operasoftware.Opera"
    case operaBeta = "com.operasoftware.OperaNext"
    case operaDeveloper = "com.operasoftware.OperaDeveloper"
    
    case vivaldi = "com.vivaldi.Vivaldi"
    
    init?(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    init?(_ application: NSRunningApplication) {
        if let bundleIdentifier = application.bundleIdentifier {
            self.init(bundleIdentifier)
        } else {
            return nil
        }
    }
}


enum BrowserManager {
    private static var browserObserver: Observer?
    private static var observedApp: Application?
    private static var focusedWindow: UIElement?
    
    private static var cachedBrowsers: [SupportedBrowserID: BrowserProtocol] = [:]
    
    
    static var currentURL: URL? {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return nil
        }
        guard let application = RuleManager.currentApp,
            let browserID = SupportedBrowserID(application) else {
                return nil
        }
        
        if let cachedBrowser = cachedBrowsers[browserID] {
            return url(for: cachedBrowser, withBundleID: browserID)
            
        } else if let browser = SBApplication(bundleIdentifier: browserID.rawValue) {
            cachedBrowsers[browserID] = browser
            return url(for: browser, withBundleID: browserID)
        } else {
            return nil
        }
    }
    
    
    
    static var currentDomain: String? {
        return currentURL?.registeredDomain
    }
    
    static var currentSubdomain: String? {
        return currentURL?.host
    }
    
    
    
    static var currentAppIsSupportedBrowser: Bool {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return false
        }
        
        guard let currentApp = RuleManager.currentApp else { return false }
        return SupportedBrowserID(currentApp) != nil
    }
    
    
    
    /// Returns the AppleEvent Automation permission state of the current app.
    /// Blocks main thread if user is prompted for consent.
    /// I don't think this is currently an issue since the prompt will appear when the browser becomes the current app.
    static var permissionToAutomateCurrentApp: PrivacyConsentState {
        guard let bundleID = RuleManager.currentApp?.bundleIdentifier else { return .undetermined }

        return AppleEventsManager.automationConsent(forBundleIdentifier: bundleID)
    }
    
    
    
    static var hasValidDomain: Bool {
        return currentDomain != nil
    }
    
    
    
    static var hasValidSubdomain: Bool {
        if let currentDomain = currentDomain {
            if currentDomain == currentSubdomain || currentSubdomain == "www.\(currentDomain)" {
                return false
            }
        }
        return currentSubdomain != nil
    }
    
    
    
    static func updateForSupportedBrowser() {
        guard let application = RuleManager.currentApp,
            let id = SupportedBrowserID(application) else {
                return
        }

        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            tryStartBrowserWatcher(repeatCount: 0, processIdentifier: application.processIdentifier, browserID: id, callback: fireNightShiftEvent)
            fireNightShiftEvent()
        }
    }
    
    private static func fireNightShiftEvent() {
        if RuleManager.ruleForSubdomain == .enabled {
            NightShiftManager.respond(to: .nightShiftEnableRuleActivated)
        } else if RuleManager.disabledForDomain || RuleManager.ruleForSubdomain == .disabled {
            NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
        } else {
            NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
        }
    }
    
    
    
    // When browser is launching, we're not able to add a notification right away, so we need to try again.
    private static func tryStartBrowserWatcher(
        repeatCount: Int,
        processIdentifier: pid_t,
        browserID: SupportedBrowserID,
        callback: @escaping () -> Void)
    {
        let maxTries = 10
        
        do {
            try startBrowserWatcher(processIdentifier, browserID, callback: callback)
        } catch let error {
            if repeatCount < maxTries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tryStartBrowserWatcher(
                        repeatCount: repeatCount + 1,
                        processIdentifier: processIdentifier,
                        browserID: browserID,
                        callback: callback)
                }
            } else {
                logw("Error: Could not watch app [\(processIdentifier)]: \(error)")
            }
        }
    }
    
    
    
    private static func startBrowserWatcher(
        _ processIdentifier: pid_t,
        _ browserID: SupportedBrowserID,
        callback: @escaping () -> Void) throws
    {
        guard let observedApp = Application(forProcessID: processIdentifier) else { return }
        
        browserObserver = observedApp.createObserver { (
            observer: Observer,
            element: UIElement,
            event: AXNotification,
            info: [String: AnyObject]?) in
            
            switch event {
            case .loadComplete:
                callback()
            case .focusedTabChanged:
                callback()
            case .valueChanged:
                if let role = try? element.role(), role == .staticText, let parent: UIElement = try? element.attribute(.parent),
                    let parent_role = try? parent.role(), parent_role == .window {
                    callback()
                }
            case .uiElementDestroyed:
                if element == focusedWindow {
                    focusedWindow = nil
                    callback()
                }
            case .focusedWindowChanged:
                focusedWindow = element
                callback()
            default:
                logw("Error: Unexpected notification \(event) received")
            }
        }
        switch browserID {
            case .chrome, .chromeCanary, .chromium, .opera, .operaBeta, .operaDeveloper, .vivaldi:
                try browserObserver?.addNotification(.valueChanged, forElement: observedApp)
            case .safari, .safariTechnologyPreview:
                try browserObserver?.addNotification(.focusedTabChanged, forElement: observedApp)
                try browserObserver?.addNotification(.loadComplete, forElement: observedApp)
        }
        try browserObserver?.addNotification(.focusedWindowChanged, forElement: observedApp)
        try browserObserver?.addNotification(.uiElementDestroyed, forElement: observedApp)
        focusedWindow = try observedApp.attribute(.focusedWindow)
    }
    
    
    
    static func stopBrowserWatcher() {
        guard let browserObserver = browserObserver else { return }
        
        if let observedApp = observedApp {
            do {
                try browserObserver.removeNotification(.valueChanged, forElement: observedApp)
                try browserObserver.removeNotification(.focusedTabChanged, forElement: observedApp)
                try browserObserver.removeNotification(.focusedWindowChanged, forElement: observedApp)
                try browserObserver.removeNotification(.loadComplete, forElement: observedApp)
                try browserObserver.removeNotification(.uiElementDestroyed, forElement: observedApp)
            } catch let error {
                logw("Error: Couldn't remove notifications: \(error)")
            }
            BrowserManager.observedApp = nil
        }
        focusedWindow = nil
        browserObserver.stop()
        BrowserManager.browserObserver = nil
    }
    
    
    
    enum BrowserError: Error {
        case closedApp
        case noWindow
        case axError
    }
    
    private static func sb_generalWindow(for browser: BrowserProtocol) -> Window? {
        guard let windows = browser.windows?(), let window = windows.firstObject as? Window else {
            logw("Error: Could not get url, there are no windows")
            return nil
        }
        return window
    }
    
    private static func url(for browser: BrowserProtocol, withBundleID browserID: SupportedBrowserID) -> URL? {
        let tab: Tab?
        switch browserID {
        case .chrome, .chromeCanary, .chromium, .opera, .operaBeta, .operaDeveloper, .vivaldi:
            if !browser.isRunning {
                logw("Error: Could not get url, app already closed")
                return nil
            }
            tab = sb_generalWindow(for: browser)?.activeTab
        case .safari, .safariTechnologyPreview:
            do {
                // Try to get URL from special full screen window (i.e. full screen video)
                let url = try ax_safariURL(for: browser)
                return url
            } catch BrowserError.axError {
                logw("Error: Could not get url using AX API")
                tab = sb_generalWindow(for: browser)?.currentTab
                NSLog("ahaha")
            } catch {
                logw("Error: Could not get url, \(error)")
                return nil
            }
        }
        return tab?.URL.flatMap(URL.init(string:))
    }
    
    
    
    private static func ax_safariURL(for browser: BrowserProtocol) throws -> URL? {
        guard let axwin = focusedWindow,
            let axwin_children: [UIElement] = try axwin.arrayAttribute(.children)
            else { throw BrowserError.axError }
        
        if let win_subrole = try axwin.subrole(), win_subrole == .dialog {
            // Special fullscreen win
            var axchild = axwin_children[0]
            for _ in 1...3 {
                guard let children: [UIElement] = try axchild.arrayAttribute(.children) else { throw BrowserError.axError }
                if !children.isEmpty {
                    axchild = children[0]
                }
            }
            return try axchild.attribute("AXURL")
        } else {
            let splitGroup = try axwin_children.filter {
                let role = try $0.role()
                return role == .splitGroup
            }
            guard let splitGroupChildren: [UIElement] = try splitGroup.first?.arrayAttribute(.children)
                else { throw BrowserError.axError }
            let tabGroup = try splitGroupChildren.filter {
                let role = try $0.role()
                return role == .tabGroup
            }
            guard let tabGroupChildren: [UIElement] = try tabGroup.first?.arrayAttribute(.children)
                else { throw BrowserError.axError }
            if let maybeGroupElement = tabGroupChildren.first,
                let role = try maybeGroupElement.role() {
                if role == .group {
                    var groupElement = maybeGroupElement;

                    for _ in 1...3 {
                        guard let children: [UIElement] = try groupElement.arrayAttribute(.children)
                            else { throw BrowserError.axError }
                        if !children.isEmpty {
                            groupElement = children[0]
                        }
                    }
                    return try groupElement.attribute("AXURL")
                } else if role == .scrollArea {
                    return nil
                }
            }
            throw BrowserError.axError
        }
    }
}
