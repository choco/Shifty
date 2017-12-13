//
//  ShiftyState.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

import Cocoa
import ReSwift

struct ShiftyState: StateType {
    var preferences: ShiftyPreferences
    var rules: [AppRule]
    var lastKnownLocation: Location?
    var appLaunchCount: UInt
}
