//
//  Solver.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/24/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

class Solver {
    
    static func solve(_ p: Puzzle) -> Puzzle? {
        
        guard let (x, y) = p.getMostSolved() else { return p }
        
        for possibility in p.groups[x].cells[y].possibilities {
            if self.applyConstraints(p, p.groups[x], p.groups[x].cells[y], possibility) {
                
                let nextStep = measure(name: "copy", { p.copy() as! Puzzle } )
                
                nextStep.groups[x].cells[y].currentVal = possibility
                
                let n = nextStep.groups[x].cells[y].x
                let m = nextStep.groups[x].cells[y].y
                for group in nextStep.groups {
                    for cell in group.cells {
                        if ((cell.x == n) != (cell.y == m)) {
                            cell.possibilities.remove(possibility)
                        }
                    }
                }
                if let newPuzzle = self.solve(nextStep) {
                    return newPuzzle
                }
            }
        }
        
        return nil
    }
    
    static func applyConstraints(_ p: Puzzle, _ g: Group, _ c: Cell, _ v: Int) -> Bool {
        let x = c.x
        let y = c.y
        for group in p.groups {
            for cell in group.cells {
                if ((cell.x == x) != (cell.y == y)) && cell.currentVal == v {
                    return false
                }
            }
        }
        
        return self.checkMath(g, c, v)
    }
    
    static func checkMath(_ g: Group, _ c: Cell, _ v: Int) -> Bool {
        
        func canMakeSum(_ t: Int, _ sets: [[Int]]?) -> Bool {
            guard let s = sets else { return t == 0 }
            let head = s[0]
            var tail: [[Int]]? = Array(s.dropFirst())
            if tail!.count == 0 { tail = nil }
            return any(head.filter { $0 <= t }.map { canMakeSum(t - $0, tail) })
        }
        
        func canMakeProd(_ t: Int, _ sets: [[Int]]?) -> Bool {
            guard let s = sets else { return t == 1 }
            let head = s[0]
            var tail: [[Int]]? = Array(s.dropFirst())
            if tail!.count == 0 { tail = nil }
            return any(head.filter { (t % $0) == 0 }.map { canMakeProd(t / $0, tail) })
        }
        
        let x = c.x
        let y = c.y
        switch g.operation {
        case "+":
            var sets = [[Int]]()
            for cell in g.cells {
                if cell.x == x && cell.y == y {
                    sets.append([v])
                } else {
                    if let val = cell.currentVal {
                        sets.append([val])
                    } else {
                        sets.append(Array(cell.possibilities))
                    }
                }
            }
            return canMakeSum(g.constant, sets)
        case "-":
            for cell in g.cells {
                if let other = cell.currentVal {
                    return v - other == g.constant || other - v == g.constant
                }
            }
            return true
        case "/":
            for cell in g.cells {
                if let other = cell.currentVal {
                    return v / other == g.constant || other / v == g.constant
                }
            }
            return true
        case "x":
            var sets = [[Int]]()
            for cell in g.cells {
                if cell.x == x && cell.y == y {
                    sets.append([v])
                } else {
                    if let val = cell.currentVal {
                        sets.append([val])
                    } else {
                        sets.append(Array(cell.possibilities))
                    }
                }
            }
            return canMakeProd(g.constant, sets)
        default:
            return true
        }
        
    }
    
}
