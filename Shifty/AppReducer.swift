//
//  AppReducer.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

import ReSwift

func appReducer(action: Action, state: ShiftyState?) -> ShiftyState {
    return ShiftyState(
        preferences: preferencesReducer(action, state: state?.preferences),
        rules: rulesReducer(action, state: state?.rules),
        lastKnownLocation: locationReducer(action, state: state?.lastKnownLocation),
        appLaunchCount: infoReducer(action, state: state?.appLaunchCount) )
}
