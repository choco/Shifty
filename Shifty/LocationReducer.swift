//
//  LocationReducer.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

import ReSwift

func locationReducer(_ action: Action, state: Location?) -> Location? {
    var state = state ?? initialLocationState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    default:
        break
    }
    
    return state
}

func initialLocationState() -> Location? {
    return nil
}
