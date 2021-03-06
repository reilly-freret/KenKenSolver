//
//  ARController.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/23/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ARController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var targetRect: UIView!
    
    @IBOutlet var flashOutlet: UISwitch!
    @IBAction func flashToggle(_ sender: Any) {
        toggleTorch(flashOutlet.isOn)
    }
    
    
    var isPaused: Bool = true
    var puzzleImage = UIImage()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        isPaused = false
        startRectangleDetection()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        isPaused = true
        
    }
    
    func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on // set on
                } else {
                    device.torchMode = .off // set off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    func attemptSolve(_ i: UIImage) -> Bool {
        var puzzleDict = NSMutableDictionary()
        OpenCVWrapper.extractGroups(i, puzzleDict)
        let dim = OpenCVWrapper.getDimension(i)
        let puzzle = Puzzle.generateFromDict(Int(dim), puzzleDict)
        print(puzzle.desc)
        puzzle.prepPoss()
        if let solved = Solver.solve(puzzle) {
            solved.generateImage()
            print("==========\nsuccess\n==========")
            return true
        } else {
            print("==========\nfailure\n==========")
            return false
        }
    }
    
    func startRectangleDetection() {
        
        if isPaused { return }
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectRectanglesRequest { (request, error) in
                DispatchQueue.main.async {
                    if let results = request.results as? [VNRectangleObservation], let _ = results.first {
                        for o in results {
                            if self.compareToWindow(o) {
                                let i = self.cropToTarget(self.sceneView.snapshot())
                                self.view.screenLoading()
                                DispatchQueue.global(qos: .background).async {
                                    let t = self.attemptSolve(i)
                                    DispatchQueue.main.async {
                                        self.view.screenLoaded()
                                        self.switchUp(t)
                                    }
                                }
                                self.isPaused = true
                                return
                            }
                        }
                    }
                }
            }
            request.maximumObservations = 0
            request.maximumAspectRatio = 1.1
            request.minimumAspectRatio = 0.9
            if let cf = self.sceneView.session.currentFrame {
                let handler = VNImageRequestHandler(cvPixelBuffer: cf.capturedImage, options: [:])
                try? handler.perform([request])
            }
            self.startRectangleDetection()
        }
    }
    
    func switchUp(_ t: Bool) {
        if t {
            self.targetRect.layer.borderColor = UIColor.green.cgColor
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isPaused = false
                self.startRectangleDetection()
            }
        }
    }
    
    func compareToWindow(_ rect: VNRectangleObservation) -> Bool {
        
        let detectedRect = view.convertFromCamera(rect.boundingBox)
        let threshold: CGFloat = 10.0
        
        let minx = targetRect.frame.minX
        let maxx = targetRect.frame.maxX
        let miny = targetRect.frame.minY
        let maxy = targetRect.frame.maxY
        
        // I'm a geniussss
        let topLeftCheck: Bool = minx ... minx + threshold ~= detectedRect.minX && miny ... miny + threshold ~= detectedRect.minY
        let bottomRightCheck: Bool = maxx - threshold ... maxx ~= detectedRect.maxX && maxy - threshold ... maxy ~= detectedRect.maxY
        
        return topLeftCheck && bottomRightCheck
        
    }
    
    func cropToTarget(_ image: UIImage) -> UIImage {
        
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        
        let lPercent = targetRect.frame.minX / view.frame.width
        let rPercent = targetRect.frame.maxX / view.frame.width
        let tPercent = targetRect.frame.minY / view.frame.height
        let bPercent = targetRect.frame.maxY / view.frame.height
        
        let translatedLeft = lPercent * width
        let translatedRight = rPercent * width
        let translatedTop = tPercent * height
        let translatedBottom = bPercent * height
        
        let newFrame = CGRect(x: translatedLeft, y: translatedTop, width: translatedRight - translatedLeft, height: translatedBottom - translatedTop)
        
        return UIImage(cgImage: image.cgImage!.cropping(to: newFrame)!)
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}
