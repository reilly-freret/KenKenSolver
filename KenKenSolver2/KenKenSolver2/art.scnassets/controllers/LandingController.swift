//
//  LandingController.swift
//  kenken-solver
//
//  Created by Reilly Freret on 11/18/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import Vision

class LandingController: UIViewController {
    
    @IBOutlet var image: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let i = Puzzle.image {
            self.image.image = OpenCVWrapper.extractGroups(i)
            print(OpenCVWrapper.getDimension(i))
            detectTextRects(i)
        }
    }
    
    func detectTextRects(_ image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectTextRectanglesRequest { (request, error) in
                DispatchQueue.main.async {
                    if let results = request.results as? [VNTextObservation], let _ = results.first {
                        //print(results.count)
                    }
                }
            }
            request.reportCharacterBoxes = true
            let handler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: .up, options: [:])
            try? handler.perform([request])
        }
    }
    
}
