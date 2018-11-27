//
//  Group.swift
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

class Group {
    
    var operation: String
    var constant: Int
    var cells: [Cell]
    
    var desc: String {
        var s = "\(operation) \(constant) "
        for c in cells {
            s += c.desc
        }
        return s
    }
    
    init(_ text: String) {
        self.cells = []
        
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "÷", with: "/")
        let reg = try! NSRegularExpression(pattern: "\\d+[x\\-\\+/]")
        let range = NSRange(location: 0, length: t.utf16.count)
        if let res = reg.firstMatch(in: t, options: [], range: range) {
            let first = String(t[Range(res.range, in: t)!])
            let regD = try! NSRegularExpression(pattern: "\\d+")
            let regO = try! NSRegularExpression(pattern: "[x\\-\\+/]")
            if let constant = regD.firstMatch(in: first, options: [], range: NSRange(location: 0, length: first.utf16.count)), let op = regO.firstMatch(in: first, options: [], range: NSRange(location: 0, length: first.utf16.count)) {
                self.operation = String(first[Range(op.range, in: first)!])
                self.constant = Int(String(first[Range(constant.range, in: first)!]))!
                return
            }
        } else {
            let justNum = try! NSRegularExpression(pattern: "\\d")
            if let numRes = justNum.firstMatch(in: t, options: [], range: NSRange(location: 0, length: t.utf16.count)) {
                self.constant = Int(String(t[Range(numRes.range, in: t)!]))!
                self.operation = "="
                return
            }
        }
        self.constant = -1
        self.operation = "?"
    }
    
    func initialPoss(_ dim: Int) {
        switch operation {
        case "=":
            let _ = cells.map { $0.possibilities.insert(constant) }
            break;
        case "+":
            let range = constant <= dim ? (1 ... constant - 1) : (1 ... dim)
            for i in range {
                let _ = cells.map { $0.possibilities.insert(i) }
            }
            break;
        case "-":
            let lrange = (1 ... dim - constant)
            let urange = (constant + 1 ... dim)
            for i in lrange {
                let _ = cells.map { $0.possibilities.insert(i) }
            }
            for i in urange {
                let _ = cells.map { $0.possibilities.insert(i) }
            }
            break;
        case "x":
            for i in (1 ... dim) {
                if constant % i == 0 {
                    let _ = cells.map { $0.possibilities.insert(i) }
                }
            }
            break;
        default:
            for i in (1 ... dim / constant) {
                let _ = cells.map { $0.possibilities.insert(i); $0.possibilities.insert(i * constant) }
            }
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let g = Group(String(self.constant) + self.operation)
        g.cells = self.cells.map { $0.copy() as! Cell }
        return g
    }
    
}
