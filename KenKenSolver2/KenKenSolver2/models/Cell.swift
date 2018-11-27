//
//  Cell.swift
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

class Cell: Comparable {
    
    var x: Int
    var y: Int
    var possibilities = Set<Int>()
    var currentVal: Int? = nil
    
    var desc: String {
        return " \(letters[x]!)\(y), "
    }
    
    let letters: [Int: String] = [0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G", 7: "H", 8: "I"]
    
    init(_ cords: NSMutableArray) {
        self.x = cords[0] as! Int
        self.y = cords[1] as! Int
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let cell = Cell(NSMutableArray(array: [self.x, self.y]))
        cell.possibilities = self.possibilities
        cell.currentVal = self.currentVal
        return cell
    }
    
}

func < (lhs: Cell, rhs: Cell) -> Bool {
    if lhs.y < rhs.y {
        return true
    } else if lhs.y == rhs.y {
        return lhs.x < rhs.x
    }
    return false
}

func == (lhs: Cell, rhs: Cell) -> Bool {
    return lhs.x == rhs.x && lhs.y == lhs.y
}

func + (lhs: Int, rhs: Cell) -> Int {
    return lhs + (rhs.currentVal ?? 0)
}
