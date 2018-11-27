//
//  UIView.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/23/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    /**
     Adds the full-frame loading animation to a view.
     
     - Important: Use this one only for full-screen loading animations
     */
    func screenLoading() {
        // full loading view
        let loadingView = UIView(frame: self.frame)
        loadingView.tag = 69
        
        // background bouncing circle
        let backgroundAnimation = UIView()
        backgroundAnimation.frame.size = CGSize(width: 100, height: 100)
        backgroundAnimation.layer.cornerRadius = 50
        backgroundAnimation.center = loadingView.center
        backgroundAnimation.backgroundColor = UIColor.white
        loadingView.addSubview(backgroundAnimation)
        
        // blur filter
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = loadingView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingView.addSubview(blurEffectView)
        
        // bouncing circle
        let loadingAnimation = UIView()
        loadingAnimation.frame.size = CGSize(width: 100, height: 100)
        loadingAnimation.layer.cornerRadius = 50
        loadingAnimation.center = loadingView.center
        loadingAnimation.backgroundColor = UIColor.white
        loadingView.addSubview(loadingAnimation)
        
        UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
            loadingAnimation.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            backgroundAnimation.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            loadingAnimation.backgroundColor = UIColor.lightGray
            backgroundAnimation.backgroundColor = UIColor.lightGray
        })
        self.addSubview(loadingView)
        self.bringSubviewToFront(loadingView)
    }
    
    /**
     Removes a full-frame animation from a view
     */
    func screenLoaded() {
        self.viewWithTag(69)?.removeFromSuperview()
    }
    
    func convertFromCamera(_ point: CGPoint) -> CGPoint {
        let orientation = UIApplication.shared.statusBarOrientation
        
        switch orientation {
        case .portrait, .unknown:
            return CGPoint(x: point.y * frame.width, y: point.x * frame.height)
        case .landscapeLeft:
            return CGPoint(x: (1 - point.x) * frame.width, y: point.y * frame.height)
        case .landscapeRight:
            return CGPoint(x: point.x * frame.width, y: (1 - point.y) * frame.height)
        case .portraitUpsideDown:
            return CGPoint(x: (1 - point.y) * frame.width, y: (1 - point.x) * frame.height)
        }
    }
    
    func convertFromCamera(_ rect: CGRect) -> CGRect {
        
        let x, y, w, h: CGFloat
        
        w = rect.height
        h = rect.width
        x = rect.origin.y
        y = rect.origin.x
        
        return CGRect(x: x * frame.width - 40, y: y * frame.height, width: w * frame.width + 80, height: h * frame.height)
        
    }
    
    // inspectable variables for setting in StoryBoard
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
}
