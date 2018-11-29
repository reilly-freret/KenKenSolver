//
//  Misc.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/25/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

func any(_ set : [Bool]) -> Bool {
    for e in set {
        if e { return true }
    }
    return false
}

var typeDict: [String: Double] = ["main": 0, "applyConstraints": 0, "getMostSolved": 0, "innerLoop": 0, "assignment": 0]

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    typeDict[name]! += timeElapsed
    print("Time: \(name) - \(typeDict[name]!)")
    if name == "main" {
        typeDict.forEach { typeDict[$0.key] = 0 }
    }
    return result
}
