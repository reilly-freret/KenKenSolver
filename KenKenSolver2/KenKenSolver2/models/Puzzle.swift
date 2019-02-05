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
        
        self.groups.removeAll()
        
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
    
    static func generateImage(_ values: [[Int]]) -> UIImage {
        
        let image = drawConstantsAndOps(drawGroups(drawMainGrid()))
        
        return image.drawValues(values, Puzzle.dimension)
        
    }
    
    private static func drawMainGrid() -> UIImage {
        
        let image = UIImage(color: UIColor.white, size: CGSize(width: 500, height: 500))!
        let dim = Puzzle.dimension
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        image.draw(at: CGPoint.zero)
        
        let rectangle = CGRect(x: 20, y: 20, width: 960, height: 960)
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(12)
        
        context.stroke(rectangle)
        
        for i in 1 ..< dim {
            let hPath = UIBezierPath()
            hPath.move(to: CGPoint(x: (960 / dim) * i + 20, y: 20))
            hPath.addLine(to: CGPoint(x: (960 / dim) * i + 20, y: 980))
            UIColor.black.setStroke()
            hPath.lineWidth = 4
            hPath.stroke()
            
            let vPath = UIBezierPath()
            vPath.move(to: CGPoint(x: 20, y: (960 / dim) * i + 20))
            vPath.addLine(to: CGPoint(x: 980, y: (960 / dim) * i + 20))
            vPath.lineWidth = 4
            vPath.stroke()
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    private static func drawGroups(_ image: UIImage) -> UIImage {
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint.zero)
        UIColor.black.setStroke()
        
        let step = 960 / Puzzle.dimension
        
        for (_, value) in Puzzle.groups {
            let cells = value.cells
            for cell in cells {
                let a = cells.contains { $0.x == cell.x && $0.y == cell.y - 1 }
                let b = cells.contains { $0.x == cell.x + 1 && $0.y == cell.y }
                let c = cells.contains { $0.x == cell.x && $0.y == cell.y + 1 }
                let d = cells.contains { $0.x == cell.x - 1 && $0.y == cell.y }
                if !a {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: cell.x * step + 20, y: cell.y * step + 20))
                    path.addLine(to: CGPoint(x: (cell.x + 1) * step + 20, y: cell.y * step + 20))
                    path.lineWidth = 12
                    path.stroke()
                }
                if !b {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: (cell.x + 1) * step + 20, y: cell.y * step + 20))
                    path.addLine(to: CGPoint(x: (cell.x + 1) * step + 20, y: (cell.y + 1) * step + 20))
                    path.lineWidth = 12
                    path.stroke()
                }
                if !c {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: (cell.x + 1) * step + 20, y: (cell.y + 1) * step + 20))
                    path.addLine(to: CGPoint(x: cell.x * step + 20, y: (cell.y + 1) * step + 20))
                    path.lineWidth = 12
                    path.stroke()
                }
                if !d {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: cell.x * step + 20, y: (cell.y + 1) * step + 20))
                    path.addLine(to: CGPoint(x: cell.x * step + 20, y: cell.y * step + 20))
                    path.lineWidth = 12
                    path.stroke()
                }
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    private static func drawConstantsAndOps(_ image: UIImage) -> UIImage {
        
        var types = [(String, Int, Int)]()
        
        for (_, value) in Puzzle.groups {
            let s = String(value.constant) + value.operation
            let cell = value.cells[0]
            types.append((s, cell.x, cell.y))
        }
        
        return image.drawTypes(types, Puzzle.dimension)
        
    }

}
