//
//  InfoReducer.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

import ReSwift

func infoReducer(_ action: Action, state: UInt?) -> UInt {
    var state = state ?? initialInfoState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    default:
        break
    }
    
    return state
}

func initialInfoState() -> UInt {
    return 0
}
