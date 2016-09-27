//
//  SKTiled+Extensions.swift
//  SKTiled
//
//  Created by Michael Fessenden on 4/5/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
#if os(iOS)
import UIKit
#else
import Cocoa
#endif


#if os(iOS)
/**
 Returns an image of the given size.

 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result (0 seems to scale 2x, using 1 seems best)
 - parameter whatToDraw: function detailing what to draw the image.
 - returns: `CGImage` result.
 */
public func imageOfSize(size: CGSize, scale: CGFloat=1, _ whatToDraw: (_: CGContext, _: CGRect, _: CGFloat) -> ()) -> CGImage {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    let context = UIGraphicsGetCurrentContext()
    let bounds = CGRect(origin: CGPointZero, size: size)
    whatToDraw(context!, bounds, scale)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    return result!.CGImage!
}
    
#else
public func imageOfSize(size: CGSize, scale: CGFloat, _ whatToDraw: (_: CGContext, _: CGRect, _: CGFloat) -> ()) -> CGImage {
    let scaledSize = size * scale
    let image = NSImage(size: scaledSize)
    image.lockFocus()
    let nsContext = NSGraphicsContext.currentContext()!
    let context = nsContext.CGContext
    let bounds = CGRect(origin: CGPointZero, size: size)
    whatToDraw(context, bounds, scale)
    image.unlockFocus()
    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    let imageRef = image.CGImageForProposedRect(&imageRect, context: nil, hints: nil)
    return imageRef!
}
#endif


public extension Bool {
    init<T : IntegerType>(integer: T){
        self.init(integer != 0)
    }
}


public extension CGFloat {
    
    /**
     Convert a float to radians.
     
     - returns: `CGFloat`
     */
    public func radians() -> CGFloat {
        let b = CGFloat(M_PI) * (self/180)
        return b
    }
    
    /**
     Clamp the CGFloat between two values. Returns a new value.
     
     - parameter v1: `CGFloat` min value.
     - parameter v2: `CGFloat` min value.
     - returns: `CGFloat` clamped result.
     */
    public func clamped(minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        let min = minv < maxv ? minv : maxv
        let max = minv > maxv ? minv : maxv
        return self < min ? min : (self > max ? max : self)
    }
    
    /**
     Clamp the current value between min & max values.
     
     - parameter v1: `CGFloat` min value.
     - parameter v2: `CGFloat` min value.
     - returns: `CGFloat` clamped result.
     */
    public mutating func clamp(minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        self = clamped(minv, maxv)
        return self
    }
    
    /**
     Returns a string representation of the value rounded to the current decimals.
     
     - parameter decimals: `Int` number of decimals to round to.
     - returns: `String` rounded display string.
     */
    public func roundTo(decimals: Int=2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }
    
    /**
     Returns the value rounded to the nearest .5 increment.
     
     - returns: `CGFloat` rounded value.
     */
    public func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled % 5)
        return round(result) / 10.0
    }
}


public func floor(flt: CGFloat) -> CGFloat {
    return CGFloat(floor(Double(flt)))
}


public extension CGPoint {
    
    public init(x: Int, _ y: Int) {    
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
    
    /// Returns an point inverted in the Y-coordinate.
    public var invertedY: CGPoint {
        return CGPoint(x: self.x, y: self.y * -1)
    }
    
    /**
     Returns a display string rounded.
     
     - parameter decimals: `Int` decimals to round to.
     - returns: `String` display string.
     */
    public func roundTo(decimals: Int=1) -> String {
        return "x: \(self.x.roundTo(decimals)), y: \(self.y.roundTo(decimals))"
    }
    
    public var xCoord: Int { return Int(x) }
    public var yCoord: Int { return Int(y) }
     
    public var description: String { return "x: \(x.roundTo()), y: \(y.roundTo())" }
    public var coordDescription: String { return "x: \(Int(x)), y: \(Int(y))" }
    }


public func lerp(start: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
    return start + (end - start) * t
}


public extension CGSize {
    
    public init(width: Int, height: Int) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
    
    public var count: Int { return Int(width) * Int(height) }
    public var halfSize: CGSize { return CGSize(width: width / 2, height: height / 2) }
    public var halfWidth: CGFloat { return width / 2.0 }
    public var halfHeight: CGFloat { return height / 2.0 }
    
    public func roundTo(decimals: Int=1) -> String {
        return "w: \(self.width.roundTo(decimals)), h: \(self.height.roundTo(decimals))"
    }
}


public extension CGRect {
    
    /// Initialize with a center point and size.
    public init(center: CGPoint, size: CGSize) {
        self.origin = CGPoint(x: center.x - size.width / 2.0, y: center.y - size.height / 2.0)
        self.size = size
    }
    
    public var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    public var topLeft: CGPoint {
        return origin
    }
    
    public var topRight: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y)
    }
    
    public var bottomLeft: CGPoint {
        return CGPoint(x: origin.x, y: origin.y + size.height)
    }
    
    public var bottomRight: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }
    
    /// Returns the points of the four corners.
    public var points: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
}


public extension CGVector {    
    /**
     * Returns the squared length of the vector described by the CGVector.
     */
    public func lengthSquared() -> CGFloat {
        return dx*dx + dy*dy
    }
}


public extension SKScene {
    /**
     Returns the center point of a scene.
     */
    public var center: CGPoint {
        return CGPoint(x: (size.width / 2) - (size.width * anchorPoint.x), y: (size.height / 2) - (size.height * anchorPoint.y))
    }
    
    /**
     Calculate the distance from the scene's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }
}



internal extension SKNode {
    
    /// visualize a node's anchor point.
    internal var drawAnchor: Bool {
        get {
            return childNodeWithName("Anchor") != nil
        } set {
            childNodeWithName("Anchor")?.removeFromParent()
            
            if (newValue == true) {
                let anchorNode = SKNode()
                anchorNode.name = "Anchor"
                addChild(anchorNode)
                
                let radius: CGFloat = self.frame.size.width / 24 < 2 ? 1.0 : self.frame.size.width / 36
                
                let anchorShape = SKShapeNode(circleOfRadius: radius)
                anchorShape.strokeColor = SKColor.clearColor()
                anchorShape.fillColor = SKColor(white: 1, alpha: 0.4)
                anchorShape.zPosition = zPosition + 10
                anchorNode.addChild(anchorShape)
                
                
                
                if let name = name {
                    let label = SKLabelNode(fontNamed: "Courier")
                    label.fontSize = 8
                    label.position.y -= 10
                    label.position.x -= 6
                    anchorNode.addChild(label)
                    var labelText = name
                    if let scene = scene {
                        labelText += ": \(scene.convertPointFromView(position).roundTo(1))"
                        labelText += ": \(position.roundTo(1))"
                    }
                    label.text = labelText
                }
            }
        }
    }
    
    /**
     Run an action with key & optional completion function.
     
     - parameter action:             `SKAction` SpriteKit action.
     - parameter withKey:            `String` action key.
     - parameter optionalCompletion: `() -> ()` optional completion function.
     */
    internal func runAction(action: SKAction!, withKey: String!, optionalCompletion: dispatch_block_t? ){
        if let completion = optionalCompletion {
            let completionAction = SKAction.runBlock( completion )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            runAction(compositeAction, withKey: withKey)
        } else {
            runAction(action, withKey: withKey)
        }
    }
}

public extension SKColor {
    
    /// Returns the hue, saturation, brightess & alpha components of the color
    internal var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
        self.getHue(&(hsba.h), saturation: &(hsba.s), brightness: &(hsba.b), alpha: &(hsba.a))
        return hsba
    }
    
    /**
     Lightens the color by the given percentage.
     
     - parameter percent: `CGFloat`
     - returns: `SKColor` lightened color.
     */
    internal func lighten(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(1.0 + percent)
    }
    
    /**
     Darkens the color by the given percentage.
     
     - parameter percent: `CGFloat`
     - returns: `SKColor` darkened color.
     */
    internal func darken(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(1.0 - percent)
    }
    
    /**
     Return a modified color using the brightness factor provided
     
     - parameter factor: brightness factor
     - returns: `SKColor` modified color
     */
    internal func colorWithBrightness(factor: CGFloat) -> SKColor {
        let colorComponents = self.hsba
        return SKColor(hue: colorComponents.h, saturation: colorComponents.s, brightness: colorComponents.b * factor, alpha: colorComponents.a)
    }
    
    /**
     Initialize an SKColor with a hexidecimal string.
     
     - parameter hexString:  `String` hexidecimal code.
     - returns: `SKColor`
     */
    convenience init(hexString: String) {
        let hex = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
        var int = UInt32()
        NSScanner(string: hex).scanHexInt(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (24-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (0, 0, 0, 1)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    
    /// Returns the individual color components.
    public var components: [CGFloat] {
        return self.components
    }
    
    /*
     Blend current color with another `SKColor`.
     
     - parameter color:   `SKColor` color to blend.
     - parameter factor:  `CGFloat` blend factor.
     - returns: `SKColor` blended color.
     */
    public func blend(with color: SKColor, factor s: CGFloat = 0.5) -> SKColor {
        
        let r1 = components[0]
        let g1 = components[1]
        let b1 = components[2]
        
        let r2 = color.components[0]
        let g2 = color.components[1]
        let b2 = color.components[2]
        
        let r = (r1 * s) + (1 - s) * r2
        let g = (g1 * s) + (1 - s) * g2
        let b = (b1 * s) + (1 - s) * b2
        
        return SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}


public extension String {
    
    /**
     Initialize a string by repeating a character (or string).
     
     **Swift 2.3 Only**
     
     - parameter repeating: `String` pattern to repeat.
     - parameter count:     `Int` number of repetitions.
     */
    public init?(repeating str: String, count: Int) {
        var newString = ""
        for _ in 0 ..< count {
            newString += str
        }
        self.init(newString)
    }
    
    /// Returns `Int` length of the string.
    public var length: Int {
        return self.characters.count
    }
    
    /**
     Simple function to split the
     
     - parameter pattern: `String` pattern to split string with.
     - returns: `[String]` groups of split strings.
     */
    public func split(pattern: String) -> [String] {
        return self.componentsSeparatedByString(pattern)
    }
    
    /**
     Returns an array of characters.
     
     - returns: `[String]`
     */
    public func toStringArray() -> [String] {
        return self.unicodeScalars.map { String($0) }
    }
    
    /**
     Pads string on the with a pattern to fill width.
     
     - parameter length:  `Int` length to fill.
     - parameter value:   `String` pattern.
     - parameter padLeft: `Bool` toggle this to pad the right.
     - returns: `String` padded string.
     */
    public func zfill(length: Int, pattern: String="0", padLeft: Bool=true) -> String {
        if length < 0 { return "" }
        guard length > self.characters.count else { return self }
        var filler = ""
        for _ in 0..<(length - self.characters.count) {
            filler += pattern
        }
        return (padLeft == true) ? filler + self : self + filler
    }
    
    /**
     Pad a string with zero's (for binary conversion).
     
     - parameter toSize: `Int` size of resulting string.
     - returns: `String` padded string.
     */
    public func pad(toSize: Int) -> String {
        if (toSize < 1) { return self }
        var padded = self
        for _ in 0..<toSize - self.characters.count {
            padded = " " + padded
        }
        return padded
    }
    
    /**
     Substitute a pattern in the string
     
     - parameter pattern:     `String` pattern to replace.
     - parameter replaceWith: replacement `String`.
     - returns: `String` result.
     */
    public func substitute(pattern: String, replaceWith: String) -> String {
        return self.stringByReplacingOccurrencesOfString(pattern, withString: replaceWith)
    }
    
    /**
     Returns an array of hexadecimal components.
     
     - returns: `[String]?` hexadecimal components.
     */
    public func hexComponents() -> [String?] {
        let code = self
        let offset = code.hasPrefix("#") ? 1 : 0
        let start: String.Index = code.startIndex
        return [
            code[start.advancedBy(offset)..<start.advancedBy(offset + 2)],
            code[start.advancedBy(offset + 2)..<start.advancedBy(offset + 4)],
            code[start.advancedBy(offset + 4)..<start.advancedBy(offset + 6)]
        ]
    }
    
    /**
     Initialize with array of bytes.
     
     - parameter bytes: `[UInt8]` byte array.
     */
    public init(bytes: [UInt8]) {
        self.init()
        for b in bytes {
            self.append(UnicodeScalar(b))
        }
    }
    
    /**
     Clean up whitespace & carriage returns.
     
     - returns: `String` scrubbed string.
     */
    public func scrub() -> String {
        var scrubbed = self.stringByReplacingOccurrencesOfString("\n", withString: "")
        scrubbed = scrubbed.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return scrubbed.stringByReplacingOccurrencesOfString(" ", withString: "")
    }
}


public extension SKAction {
    
    /**
     Custom action to animate sprite textures with varying frame durations.
     
     - parameter frames: `[(texture: SKTexture, duration: NSTimeInterval)]` array of tuples containing texture & duration.
     - returns: `SKAction` custom animation action.
     */
    public class func tileAnimation(frames: [(texture: SKTexture, duration: NSTimeInterval)], repeatForever: Bool = true) -> SKAction {
        var actions: [SKAction] = []
        for frame in frames {
            actions.append(SKAction.group([
                SKAction.setTexture(frame.texture),
                SKAction.waitForDuration(frame.duration)
                ])
            )
        }
        
        // add the repeating action
        if (repeatForever == true) {
            return SKAction.repeatActionForever(SKAction.sequence(actions))
        }
        return SKAction.sequence(actions)
    }
}


// MARK: - Operators

// MARK: CGFloat
public func + (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) + rhs
}


public func + (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs + CGFloat(rhs)
}


public func - (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) - rhs
}


public func - (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs - CGFloat(rhs)
}


public func * (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs * CGFloat(rhs)
}


public func / (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) / rhs
}


public func / (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}

// MARK: CGPoint
public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}


public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}


public func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}

public func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
}

public func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
}

public func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}

public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}


// MARK: CGSize
public func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}


public func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}


public func * (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
}


public func / (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
}


public func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width + rhs, height: lhs.height + rhs)
}


public func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width - rhs, height: lhs.height - rhs)
}


public func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}


public func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}

// MARK: CGVector
public func + (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}

/*
public func += (inout lhs: CGVector, rhs: CGVector) {
    lhs = lhs + rhs
}


public func - (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
}


public func -= (inout lhs: CGVector, rhs: CGVector) {
    lhs = lhs - rhs
}


public func * (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy)
}


public func *= (inout lhs: CGVector, rhs: CGVector) {
    lhs = lhs * rhs
}


public func * (vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}


public func *= (inout vector: CGVector, scalar: CGFloat) {
    vector = vector * scalar
}


public func / (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx / rhs.dx, dy: lhs.dy / rhs.dy)
}


public func /= (inout lhs: CGVector, rhs: CGVector) {
    lhs = lhs / rhs
}


public func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
}


public func /= (inout lhs: CGVector, rhs: CGFloat) {
    lhs = lhs / rhs
}


public func lerp(start start: CGVector, end: CGVector, t: CGFloat) -> CGVector {
    return start + (end - start) * t
}
*/


// MARK: - Helper Functions

public func floor(point: CGPoint) -> CGPoint {
    return CGPoint(x: floor(Double(point.x)), y: floor(Double(point.y)))
}


public func normalize(value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
    return (value - minimum) / (maximum - minimum)
}


/**
 Generate a visual grid texture.
 
 - parameter layer: `TiledLayerObject` layer instance.
 - parameter scale: `CGFloat` image scale.
 - returns: `SKTexture?` visual grid texture.
 */
public func drawGrid(layer: TiledLayerObject,  scale: CGFloat = 1) -> CGImage {
    
    let size = layer.size
    let tileWidth = layer.tileWidth //* scale
    let tileHeight = layer.tileHeight //* scale
    
    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2
    
    var sizeInPoints = layer.sizeInPoints
    sizeInPoints = sizeInPoints + 1
    
    return imageOfSize(sizeInPoints, scale: scale) { context, bounds, scale in
        
        let innerColor = layer.gridColor
        let lineWidth: CGFloat = (tileHeight <= 16) ? 1.0 / scale : 1.0
        
        CGContextSetLineWidth(context, lineWidth)
        //CGContextSetLineDash(context, 0.5, 0.5, 1.0)
        CGContextSetShouldAntialias(context, false)
        
        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {
                
                CGContextSetStrokeColorWithColor(context, innerColor.CGColor)
                CGContextSetFillColorWithColor(context, SKColor.clearColor().CGColor)
                
                let screenPosition = layer.tileToScreenCoords(CGPoint(x: col, y: row))
                
                var xpos: CGFloat = screenPosition.x
                var ypos: CGFloat = screenPosition.y
                
                switch layer.orientation {
                case .orthogonal:
                    
                    // rectangle shape
                    let points = rectPointArray(tileWidth, height: tileHeight, origin: CGPoint(x: xpos, y: ypos + tileHeight))
                    let shapePath = polygonPath(points)
                    CGContextAddPath(context, shapePath)
                    
                case .isometric:
                    // xpos, ypos is the top point of the diamond
                    let points: [CGPoint] = [
                        CGPoint(x: xpos, y: ypos),
                        CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                        CGPoint(x: xpos, y: ypos + tileHeight),
                        CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                        CGPoint(x: xpos, y: ypos)
                    ]
                    
                    let shapePath = polygonPath(points)
                    CGContextAddPath(context, shapePath)
                    
                case .hexagonal, .staggered:
                    let staggerX = layer.tilemap.staggerX
                    
                    // mirrored in pointForCoordinate
                        xpos += tileWidthHalf
                        
                    if layer.orientation == .hexagonal {
                    
                        ypos += tileHeightHalf

                        var hexPoints = Array(count: 6, repeatedValue: CGPointZero)
                        var variableSize: CGFloat = 0
                        var r: CGFloat = 0
                        var h: CGFloat = 0
                        
                        // flat - currently not working
                        if (staggerX == true) {
                            r = (tileWidth - layer.tilemap.sideLengthX) / 2
                            h = tileHeight / 2
                            variableSize = tileWidth - (r * 2)
                            hexPoints[0] = CGPoint(x: xpos - (variableSize / 2), y: ypos + h)
                            hexPoints[1] = CGPoint(x: xpos + (variableSize / 2), y: ypos + h)
                            hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos)
                            hexPoints[3] = CGPoint(x: xpos + (variableSize / 2), y: ypos - h)
                            hexPoints[4] = CGPoint(x: xpos - (variableSize / 2), y: ypos - h)
                            hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos)
                            
                            
                        } else {
                            r = tileWidth / 2
                            h = (tileHeight - layer.tilemap.sideLengthY) / 2
                            variableSize = tileHeight - (h * 2)
                            hexPoints[0] = CGPoint(x: xpos, y: ypos + (tileHeight / 2))
                            hexPoints[1] = CGPoint(x: xpos + (tileWidth / 2), y: ypos + (variableSize / 2))
                            hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos - (variableSize / 2))
                            hexPoints[3] = CGPoint(x: xpos, y: ypos - (tileHeight / 2))
                            hexPoints[4] = CGPoint(x: xpos - (tileWidth / 2), y: ypos - (variableSize / 2))
                            hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos + (variableSize / 2))
                        }
                        
                        let shapePath = polygonPath(hexPoints)
                        CGContextAddPath(context, shapePath)
                    }
                    
                    if layer.orientation == .staggered {
                        
                        let points: [CGPoint] = [
                            CGPoint(x: xpos, y: ypos),
                            CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos + tileHeight),
                            CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos)
                        ]
                        
                        let shapePath = polygonPath(points)
                        CGContextAddPath(context, shapePath)
                    }
                }
                
                CGContextStrokePath(context)
            }
        }
    }
}


// MARK: - Polygon Drawing

/**
 Returns an array of points for the given dimensions.
 
 - parameter width:   `CGFloat` rect width.
 - parameter height:  `CGFloat` rect height.
 - parameter origin: `CGPoint` rectangle origin.
 - returns: `[CGPoint]` array of points.
 */
public func rectPointArray(width: CGFloat, height: CGFloat, origin: CGPoint=CGPointZero) -> [CGPoint] {
    let points: [CGPoint] = [
        origin,
        CGPoint(x: origin.x + width, y: origin.y),
        CGPoint(x: origin.x + width, y: origin.y - height),
        CGPoint(x: origin.x, y: origin.y - height)
    ]
    return points
}

/**
 Returns an array of points for the given dimensions.
 
 - parameter size:   `CGSize` rect size.
 - parameter origin: `CGPoint` rectangle origin.
 - returns: `[CGPoint]` array of points.
 */
public func rectPointArray(size: CGSize, origin: CGPoint=CGPointZero) -> [CGPoint] {
    return rectPointArray(size.width, height: size.height, origin: origin)
}


/**
 Returns an array of points describing a polygon shape.
 
 - parameter sides:  `Int` number of sides.
 - parameter radius: `CGSize` radius of circle.
 - parameter offset: `CGFloat` rotation offset (45 to return a rectangle).
 - parameter origin: `CGPoint` origin point.
 - returns: `[CGPoint]` array of points.
 */
public func polygonPointArray(sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint=CGPointZero) -> [CGPoint] {
    let angle = (360 / CGFloat(sides)).radians()
    let cx = origin.x // x origin
    let cy = origin.y // y origin
    let rx = radius.width // radius of circle
    let ry = radius.height
    var i = 0
    var points: [CGPoint] = []
    while i <= sides {
        let xpo = cx + rx * cos(angle * CGFloat(i) - offset.radians())
        let ypo = cy + ry * sin(angle * CGFloat(i) - offset.radians())
        points.append(CGPoint(x: xpo, y: ypo))
        i += 1
    }
    return points
}


/**

 Takes an array of points and returns a path.
 
 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed. 
 - parameter origin: `CGPoint` origin point.
 - returns: `CGPathRef` path from the given points.
 */
public func polygonPath(points: [CGPoint], closed: Bool=true) -> CGPathRef {
    let path = CGPathCreateMutable()
    var mpoints = points
    let first = mpoints.removeAtIndex(0)
    CGPathMoveToPoint(path, nil, first.x, first.y)
    
    for p in mpoints {
        CGPathAddLineToPoint(path, nil, p.x, p.y)
    }
    if (closed == true) {CGPathCloseSubpath(path)}
    return path
}


/**
 Draw a polygon shape based on an aribitrary number of sides.
 - parameter sides:    `Int` number of sides.
 - parameter radius:   `CGSize` w/h radius.
 - parameter offset:   `CGFloat` rotation offset (45 to return a rectangle).
 - returns: `CGPathf`  path from the given points.
 */
public func polygonPath(sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint=CGPointZero) -> CGPathRef {
    let path = CGPathCreateMutable()
    let points = polygonPointArray(sides, radius: radius, offset: offset)
    let cpg = points[0]
    CGPathMoveToPoint(path, nil, cpg.x, cpg.y)
    for p in points {
        CGPathAddLineToPoint(path, nil, p.x, p.y)
    }
    CGPathCloseSubpath(path)
    return path
}


/**
 Takes an array of points and returns a bezier path.
 
 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed.
 - parameter alpha:   `CGFloat` curvature. 
 - returns: `CGPathRef` path from the given points.
 */
public func bezierPath(points: [CGPoint], closed: Bool=true, alpha: CGFloat=0.75) -> CGPathRef {
    guard points.count > 1 else { return CGPathCreateMutable() }
    assert(alpha >= 0 && alpha <= 1.0, "Alpha must be between 0 and 1")
    
    let numberOfCurves = closed ? points.count : points.count - 1
    
    var previousPoint: CGPoint? = closed ? points.last : nil
    var currentPoint:  CGPoint  = points[0]
    var nextPoint:     CGPoint? = points[1]
    
    let path = CGPathCreateMutable()
    CGPathMoveToPoint(path, nil, currentPoint.x, currentPoint.y)
    
    for index in 0 ..< numberOfCurves {
        let endPt = nextPoint!
        
        var mx: CGFloat
        var my: CGFloat
        
        if previousPoint != nil {
            mx = (nextPoint!.x - currentPoint.x) * alpha + (currentPoint.x - previousPoint!.x)*alpha
            my = (nextPoint!.y - currentPoint.y) * alpha + (currentPoint.y - previousPoint!.y)*alpha
        } else {
            mx = (nextPoint!.x - currentPoint.x) * alpha
            my = (nextPoint!.y - currentPoint.y) * alpha
        }
        
        let ctrlPt1 = CGPoint(x: currentPoint.x + mx / 3.0, y: currentPoint.y + my / 3.0)
        
        previousPoint = currentPoint
        currentPoint = nextPoint!
        let nextIndex = index + 2
        if closed {
            nextPoint = points[nextIndex % points.count]
        } else {
            nextPoint = nextIndex < points.count ? points[nextIndex % points.count] : nil
        }
        
        if nextPoint != nil {
            mx = (nextPoint!.x - currentPoint.x) * alpha + (currentPoint.x - previousPoint!.x) * alpha
            my = (nextPoint!.y - currentPoint.y) * alpha + (currentPoint.y - previousPoint!.y) * alpha
        }
        else {
            mx = (currentPoint.x - previousPoint!.x) * alpha
            my = (currentPoint.y - previousPoint!.y) * alpha
        }
        
        let ctrlPt2 = CGPoint(x: currentPoint.x - mx / 3.0, y: currentPoint.y - my / 3.0)
        CGPathAddCurveToPoint(path, nil, ctrlPt1.x, ctrlPt1.y, ctrlPt2.x, ctrlPt2.y, endPt.x, endPt.y)
    }
    if (closed == true) {CGPathCloseSubpath(path)}
    return path
}
