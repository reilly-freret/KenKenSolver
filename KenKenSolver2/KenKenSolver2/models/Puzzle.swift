//
//  Puzzle.swift
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation
import UIKit
import SwiftyTesseract

class Puzzle {
    
    var dimension: Int
    var groups: [Group]
    
    static var resultImage: UIImage?
    
    var desc: String {
        var s = "\(dimension)\n"
        for g in groups {
            s += (g.desc + "\n")
        }
        return s
    }
    
    var formatted: String {
        var allCells: [Cell] = []
        for g in groups {
            for c in g.cells {
                allCells.append(c)
            }
        }
        allCells = allCells.sorted()
        var s = ""
        for i in (0 ..< allCells.count) {
            s += (String(allCells[i].currentVal ?? 0) + " ")
            if (i + 1) % dimension == 0 {
                s += "\n"
            }
        }
        return s
    }
    
    static let st = SwiftyTesseract(language: .english)
    
    init(_ dim: Int) {
        self.groups = []
        self.dimension = dim
    }
    
    static func generateFromDict(_ dim: Int, _ dict: NSMutableDictionary) -> Puzzle {
        let puzzle = Puzzle(dim)
        for n in 0 ..< dict.count {
            var group = Group("asdf")
            if let g = dict[n] as? NSMutableArray {
                if let img = g[0] as? UIImage {
                    st.performOCR(on: img) { recognizedString in
                        group = Group(recognizedString!)
                    }
                }
                for k in 1 ..< g.count {
                    if let cord = g[k] as? NSMutableArray {
                        group.cells.append(Cell(cord))
                    }
                }
            }
            puzzle.groups.append(group)
        }
        return puzzle
    }
    
    func prepPoss() {
        let _ = groups.map { $0.initialPoss(dimension) }
    }
    
    func getMostSolved() -> (Int, Int)? {
        var max = dimension + 1
        var ret: (Int, Int)? = nil
        for i in (0 ..< groups.count) {
            for j in (0 ..< groups[i].cells.count) {
                if groups[i].cells[j].currentVal == nil && groups[i].cells[j].possibilities.count < max {
                    
                    max = groups[i].cells[j].possibilities.count
                    ret = (i, j)
                }
            }
        }
        return ret
    }
    
    static func sample() -> Puzzle {
        let p = Puzzle(6)
        
        var group = Group("2-")
        var cell = Cell(NSMutableArray(array: [0,0]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [0,1]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("2/")
        cell = Cell(NSMutableArray(array: [1,0]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [2,0]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("11+")
        cell = Cell(NSMutableArray(array: [3,0]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [4,0]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("1")
        cell = Cell(NSMutableArray(array: [5,0]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("120x")
        cell = Cell(NSMutableArray(array: [1,1]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [2,1]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [3,1]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("30x")
        cell = Cell(NSMutableArray(array: [4,1]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [5,1]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [5,2]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("3/")
        cell = Cell(NSMutableArray(array: [0,2]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [1,2]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("2-")
        cell = Cell(NSMutableArray(array: [2,2]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [3,2]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("5+")
        cell = Cell(NSMutableArray(array: [4,2]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [4,3]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("2-")
        cell = Cell(NSMutableArray(array: [0,3]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [1,3]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("2/")
        cell = Cell(NSMutableArray(array: [2,3]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [3,3]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("15+")
        cell = Cell(NSMutableArray(array: [5,3]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [5,4]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [5,5]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [4,5]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("2/")
        cell = Cell(NSMutableArray(array: [0,4]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [1,4]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("8+")
        cell = Cell(NSMutableArray(array: [2,4]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [2,5]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("12+")
        cell = Cell(NSMutableArray(array: [3,4]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [4,4]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [3,5]))
        group.cells.append(cell)
        p.groups.append(group)
        
        group = Group("5-")
        cell = Cell(NSMutableArray(array: [0,5]))
        group.cells.append(cell)
        cell = Cell(NSMutableArray(array: [1,5]))
        group.cells.append(cell)
        p.groups.append(group)
        
        return p
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let newPuzzle = Puzzle(self.dimension)
        newPuzzle.groups = self.groups.map { $0.copy() as! Group }
        return newPuzzle
    }
    
    func generateImage() {
        let dims = 200
        let i = UIImage(color: .black, size: CGSize(width: dims, height: dims))!
        Puzzle.resultImage = i.textOnImage(withText: self.formatted, atPoint: CGPoint(x: 0, y: 0))
    }
    
}
