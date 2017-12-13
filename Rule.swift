//
//  Rules.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

class AppRule {
    var bundleIdentifier: String
    var disableNightShift: Bool
    
    init(bundleIdentifier: String, disableNightShift: Bool) {
        self.bundleIdentifier = bundleIdentifier
        self.disableNightShift = disableNightShift
    }
}

enum BrowserRuleType {
    case Domain
    case Subdomain
}

class BrowserRuleX: AppRule {
    var type: BrowserRuleType
    var host: String
    init(bundleIdentifier: String, disableNightShift: Bool,
         type: BrowserRuleType, host: String) {
        self.type = type
        self.host = host
        super.init(bundleIdentifier: bundleIdentifier, disableNightShift: disableNightShift)
    }
}
