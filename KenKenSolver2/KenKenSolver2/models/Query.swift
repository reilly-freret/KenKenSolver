//
//  Query.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/28/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

class OpQuery: Hashable {
    
    var t: Int
    var sets: [[Int]]
    var hashValue: Int {
        var s = String(t) + ":"
        for set in sets {
            for element in set {
                s += String(element) + ","
            }
            s += ";"
        }
        return s.hashValue
    }
    
    init(_ t: Int, _ sets: [[Int]]) {
        self.t = t
        self.sets = sets
    }
    
}

func ==(lhs: OpQuery, rhs: OpQuery) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
