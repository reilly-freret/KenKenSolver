//
//  LandingController.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/23/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import Vision
import SwiftyTesseract

class LandingController: UIViewController {

    @IBOutlet var image: UIImageView!
    let st = SwiftyTesseract(language: .english)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        solveSample(UIImage(named: "6x6.exp1")!)
    }
    
    func solveSample(_ i: UIImage) {
        var puzzleDict = NSMutableDictionary()
        OpenCVWrapper.extractGroups(i, puzzleDict)
        let dim = OpenCVWrapper.getDimension(i)
        let puzzle = Puzzle.generateFromDict(Int(dim), puzzleDict)
        print(puzzle.desc)
        puzzle.prepPoss()
        if let p = measure(name: "main", { Solver.solve(puzzle) }) {
            print("Success!")
            print(p.formatted)
        } else {
            print("Failure")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let result = Puzzle.resultImage {
            image.image = result
        }
    }
    
}
