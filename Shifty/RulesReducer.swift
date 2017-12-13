//
//  RulesReducer.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 10/12/2017.
//

import ReSwift

func rulesReducer(_ action: Action, state: [AppRule]?) -> [AppRule] {
    var state = state ?? initialRulesState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    default:
        break
    }
    
    return state
}

func initialRulesState() -> [AppRule] {
    return []
}
