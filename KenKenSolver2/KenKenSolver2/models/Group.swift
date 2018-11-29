//
//  Group.swift
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation

final class Group {
    
    var operation: String
    var constant: Int
    var cells: [Cell]
    
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
        self.constant = 1
        self.operation = "?"
        
    }
    
    func initialPoss(_ dim: Int) -> Set<Int> {
        if constant == 0 { return Set() }
        switch operation {
        case "=":
            return Set([constant])
        case "+":
            let range = constant <= dim ? (1 ... constant - 1) : (1 ... dim)
            return Set(range)
        case "-":
            if constant < dim {
                let lrange = (1 ... dim - constant)
                let urange = (constant + 1 ... dim)
                return Set(lrange).union(urange)
            }
            return Set(1 ... dim)
        case "x":
            return Set((1 ... dim).filter { constant % $0 == 0 }) // numbers between 1 and dimension (inclusive) that divide the constant with no remainder
        default:
            let range = constant > dim ? 1 ... dim : 1 ... dim / constant
            return Set(range).union(range.map { $0 * constant }) 
        }
        
    }
    
}
