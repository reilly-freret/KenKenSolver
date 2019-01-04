import UIKit

extension UIImage {
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
}

func drawMainGrid(_ image: UIImage, _ dim: Int = 1) -> UIImage {
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

func drawGroups(_ image: UIImage, _ groups: Dictionary<Int, [(Int, Int)]>, _ dim: Int) -> UIImage {
    let imageSize = image.size
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
    let context = UIGraphicsGetCurrentContext()!
    
    image.draw(at: CGPoint.zero)
    UIColor.black.setStroke()
    
    let step = 960 / dim
    
    for (key, value) in groups {
        for cell in value {
            let a = value.contains { $0 == (cell.0, cell.1 - 1) }
            let b = value.contains { $0 == (cell.0 + 1, cell.1) }
            let c = value.contains { $0 == (cell.0, cell.1 + 1) }
            let d = value.contains { $0 == (cell.0 - 1, cell.1) }
            if !a {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: cell.0 * step + 20, y: cell.1 * step + 20))
                path.addLine(to: CGPoint(x: (cell.0 + 1) * step + 20, y: cell.1 * step + 20))
                path.lineWidth = 12
                path.stroke()
            }
            if !b {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: (cell.0 + 1) * step + 20, y: cell.1 * step + 20))
                path.addLine(to: CGPoint(x: (cell.0 + 1) * step + 20, y: (cell.1 + 1) * step + 20))
                path.lineWidth = 12
                path.stroke()
            }
            if !c {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: (cell.0 + 1) * step + 20, y: (cell.1 + 1) * step + 20))
                path.addLine(to: CGPoint(x: cell.0 * step + 20, y: (cell.1 + 1) * step + 20))
                path.lineWidth = 12
                path.stroke()
            }
            if !d {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: cell.0 * step + 20, y: (cell.1 + 1) * step + 20))
                path.addLine(to: CGPoint(x: cell.0 * step + 20, y: cell.1 * step + 20))
                path.lineWidth = 12
                path.stroke()
            }
        }
    }
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return newImage
}

var puzzle: Dictionary<Int, [(Int, Int)]> = [0: [(0,0)]]

var mainImage = UIImage(color: UIColor.white, size: CGSize(width: 500, height: 500))

puzzle[0] = [(0, 0), (0, 1)]

let i = drawMainGrid(mainImage!, 7)

drawGroups(i, puzzle, 7)



