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
    @IBOutlet var noImageLabel: UILabel!
    
    let st = SwiftyTesseract(language: .english)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        solveSample(UIImage(named: "6x6.exp0")!)
//        solveSample(UIImage(named: "6x6.exp1")!)
//        solveSample(UIImage(named: "8x8.exp1")!)
    }
    
    func solveSample(_ i: UIImage) {
        var puzzleDict = NSMutableDictionary()
        OpenCVWrapper.extractGroups(i, puzzleDict)
        let dim = OpenCVWrapper.getDimension(i)
        let values = Puzzle.generateStructure(Int(dim), puzzleDict)
        if let v = measure({ Solver.solve(values) }){
            print(Solver.printStep(v))
        } else {
            print("big failure")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let result = Puzzle.resultImage {
            image.image = result
            noImageLabel.isHidden = true
        } else {
            noImageLabel.isHidden = false
        }
    }
    
}
