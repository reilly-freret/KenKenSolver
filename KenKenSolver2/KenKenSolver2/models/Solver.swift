//
//  Solver.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/24/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

final class Solver {
    
    static func solve(_ values: [[Dictionary<String, Any>]]) -> [[Dictionary<String, Any>]]? {
        
        func getMostSolved(_ values: [[Dictionary<String, Any>]]) -> (Int, Int)? {
            var min = 50
            var cords: (Int, Int)? = nil
            for i in 0 ..< values.count {
                for j in 0 ..< values[i].count {
                    let poss = values[i][j]["poss"] as! Set<Int>
                    let count = poss.count
                    if count != 0 && count < min && values[i][j]["currVal"] as! Int == 0 {
                        min = count
                        cords = (i, j)
                    }
                }
            }
            return cords
        }
        
        guard let (y, x) = measure(name: "getMostSolved", { getMostSolved(values) } ) else { return values }
        
        let currPoss = values[y][x]["poss"] as! Set<Int>
        for testVal in currPoss {
            
            if measure(name: "applyConstraints", { self.applyConstraints(values, (y, x), testVal) } ) {
                
                var nextStep = values
                
                measure(name: "assignment", { nextStep[y][x]["currVal"] = testVal } )
                
                measure(name: "innerLoop", {
                    for i in 0 ..< values.count {
                        let first = (nextStep[y][i]["poss"] as! Set<Int>)
                        let second = (nextStep[i][x]["poss"] as! Set<Int>)
                        if first.contains(testVal) { nextStep[y][i]["poss"] = first.subtracting([testVal]) }
                        if second.contains(testVal) { nextStep[i][x]["poss"] = second.subtracting([testVal]) }
                    }
                })
                
                if let newPuzzle = self.solve(nextStep) {
                    return newPuzzle
                }
            }
        }
        
        return nil
    }
    
    static func applyConstraints(_ values: [[Dictionary<String, Any>]], _ target: (Int, Int), _ v: Int) -> Bool {
        
        let checkCross = !(any((0 ..< values.count).map { values[target.0][$0]["currVal"] as! Int == v || values[$0][target.1]["currVal"] as! Int == v}))
        
        return checkCross && checkMath(values, target, v)
        
    }
    
    static func checkMath(_ values: [[Dictionary<String, Any>]], _ target: (Int, Int), _ v: Int) -> Bool {
        
        func canMakeSum(_ t: Int, _ sets: [[Int]]) -> Bool {
            if sets.count == 1 { return sets[0].contains(t) }
            let head = sets[0]
            let tail: [[Int]] = Array(sets.dropFirst())
            return any(head.filter { $0 <= t }.map { canMakeSum(t - $0, tail) })
        }
        
        func canMakeProd(_ t: Int, _ sets: [[Int]]?) -> Bool {
            guard let s = sets else { return t == 1 }
            let head = s[0]
            var tail: [[Int]]? = Array(s.dropFirst())
            if tail!.count == 0 { tail = nil }
            return any(head.filter { (t % $0) == 0 }.map { canMakeProd(t / $0, tail) })
        }
        
        
        guard let targetGroupDict = Puzzle.groups.first(where: { $0.key == values[target.0][target.1]["group"] as! Int }) else { print("fuq"); return false }
        let targetGroup = targetGroupDict.value
        
        switch targetGroup.operation {
        case "+":
            var sets = [[Int]]()
            sets.append([v])
            for i in 0 ..< values.count {
                for j in 0 ..< values.count {
                    if i == target.0 && j == target.1 { continue }
                    if values[i][j]["group"] as! Int != targetGroupDict.key { continue }
                    if let neighborVal = values[i][j]["currVal"] as? Int, neighborVal != 0 {
                        sets.append([neighborVal])
                    } else {
                        sets.append(Array(values[i][j]["poss"] as! Set<Int>))
                    }
                }
            }
            return canMakeSum(targetGroup.constant, sets)
        case "-":
            for i in 0 ..< values.count {
                for j in 0 ..< values.count {
                    if i == target.0 && j == target.1 { continue }
                    if values[i][j]["group"] as! Int != targetGroupDict.key { continue }
                    if let neighborVal = values[i][j]["currVal"] as? Int, neighborVal != 0 {
                        return v - neighborVal == targetGroup.constant || neighborVal - v == targetGroup.constant
                    }
                }
            }
            return true
        case "/":
            for i in 0 ..< values.count {
                for j in 0 ..< values.count {
                    if i == target.0 && j == target.1 { continue }
                    if values[i][j]["group"] as! Int != targetGroupDict.key { continue }
                    if let neighborVal = values[i][j]["currVal"] as? Int, neighborVal != 0 {
                        return v / neighborVal == targetGroup.constant || neighborVal / v == targetGroup.constant
                    }
                }
            }
            return true
        case "x":
            var sets = [[Int]]()
            sets.append([v])
            for i in 0 ..< values.count {
                for j in 0 ..< values.count {
                    if i == target.0 && j == target.1 { continue }
                    if values[i][j]["group"] as! Int != targetGroupDict.key { continue }
                    if let neighborVal = values[i][j]["currVal"] as? Int, neighborVal != 0 {
                        sets.append([neighborVal])
                    } else {
                        sets.append(Array(values[i][j]["poss"] as! Set<Int>))
                    }
                }
            }
            return canMakeProd(targetGroup.constant, sets)
        default:
            return true
        }
        
    }
    
    static func printStep(_ values: [[Dictionary<String, Any>]]) -> String {
        
        var s = ""
        for row in values {
            for cell in row {
                s += String(cell["currVal"] as! Int) + " "
            }
            s += "\n"
        }
        return s
        
    }
    
    static func solutionArray(_ values: [[Dictionary<String, Any>]]) -> [[Int]] {
        
        var a = [[Int]]()
        var r = [Int]()
        for row in values {
            for cell in row {
                r.append(cell["currVal"] as! Int)
            }
            a.append(r)
            r.removeAll()
        }
        return a
        
    }
    
}
