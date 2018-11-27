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

var timers: [String: Double] = ["main": 0, "getSolved": 0, "applyConstraints": 0, "mainBlock": 0, "copy": 0]

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    timers[name]! += timeElapsed
    print("Time: \(name) - \(timers[name]!)")
    return result
}
