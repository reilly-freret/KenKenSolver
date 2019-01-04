//
//  UIImage.swift
//  KenKenSolver2
//
//  Created by Reilly Freret on 11/26/18.
//  Copyright © 2018 Reilly Freret. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
        
    }
    
    func textOnImage(withText text: String, atPoint point: CGPoint) -> UIImage {
        
        let textColor = UIColor.black
        let textFont = UIFont(name: "Helvetica Bold", size: 40)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
        
        let rect = CGRect(origin: point, size: self.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    
    func drawValues(_ v: [[Int]], _ dim: Int) -> UIImage {
        
        let step = 960 / dim
        
        let textColor = UIColor.black
        let textFont = UIFont(name: "Helvetica Bold", size: CGFloat(Double(step) / 2.4))!
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
        
        for i in 0 ..< v.count {
            for j in 0 ..< v[i].count {
                let point = CGPoint(x: step * j + 20, y: step * i + 20 + (step - Int(textFont.lineHeight)) / 2)
                let rect = CGRect(origin: point, size: CGSize(width: step, height: step - 20))
                String(v[i][j]).draw(in: rect, withAttributes: [NSAttributedString.Key.font: textFont,
                                                                NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: style])
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    
    func drawTypes(_ types: [(String, Int, Int)], _ dim: Int) -> UIImage {
        
        let step = 960 / dim
        
        let textColor = UIColor.black
        let textFont = UIFont(name: "Helvetica", size: 30)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)
        
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
        
        for tuple in types {
            let point = CGPoint(x: step * tuple.1 + 30, y: step * tuple.2 + 25)
            let rect = CGRect(origin: point, size: CGSize(width: CGFloat(step), height: textFont.lineHeight))
            let s = tuple.0.replacingOccurrences(of: "/", with: "÷").replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: "—")
            String(s).draw(in: rect, withAttributes: [NSAttributedString.Key.font: textFont,
                                                        NSAttributedString.Key.foregroundColor: textColor])
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    
}
