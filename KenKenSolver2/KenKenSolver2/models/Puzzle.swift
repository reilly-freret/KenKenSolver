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

final class Puzzle {
    
    static var dimension: Int = 0
    static var groups = [Int: Group]()
    
    static var resultImage: UIImage?
    
    static let st = SwiftyTesseract(language: .english)
    
    static func generateStructure(_ dim: Int, _ dict: NSMutableDictionary) -> [[Dictionary<String, Any>]] {
        
        Puzzle.dimension = dim
        var valArray = [[Dictionary<String, Any>]]()
        var initialRow = [Dictionary<String, Any>]()
        for _ in 0 ..< dim {
            initialRow.append(["currVal": 0, "poss": Set<Int>(), "group": 0])
        }
        for _ in 0 ..< dim {
            valArray.append(initialRow)
        }
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
                        let cell = Cell(cord)
                        group.cells.append(cell)
                        valArray[cell.y][cell.x]["group"] = n
                        valArray[cell.y][cell.x]["poss"] = group.initialPoss(dim)
                    }
                }
            }
            Puzzle.groups[n] = group
        }
        
        return valArray
    }

}
