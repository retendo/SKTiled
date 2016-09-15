//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
public class SKTile: SKSpriteNode {
    
    weak public var layer: SKTileLayer!                         // layer parent, assigned on add
    private var tileOverlap: CGFloat = 1.5                      // tile overlap amount
    private var maxOverlap: CGFloat = 3.0               // maximum tile overlap
    public var tileData: SKTilesetData                          // tile data
    public var tileSize: CGSize                                 // tile size
    public var highlightColor: SKColor = SKColor.whiteColor()   // tile highlight color
    
    // blending/visibility
    public var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    public var visible: Bool {
        get { return !self.hidden }
        set { self.hidden = !newValue }
    }
    
    /// Boolean flag to enable/disable texture filtering.
    public var smoothing: Bool {
        get { return texture?.filteringMode != .Nearest }
        set { texture?.filteringMode = newValue ? SKTextureFilteringMode.Linear : SKTextureFilteringMode.Nearest }
    }
    
    // MARK: - Init
    /**
     Initialize the tile with a tile size.
     
     - parameter tileSize: `CGSize` tile size in pixels.
     
     - returns: `SKTile` tile sprite.
     */
    public init(tileSize size: CGSize){
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clearColor(), size: tileSize)
    }
    
    /**
     Initialize the tile object with `SKTilesetData`.
     
     - parameter data: `SKTilesetData` tile data.
     
     - returns: `SKTile` tile sprite.
     */
    public init?(data: SKTilesetData){
        guard let tileset = data.tileset else { return nil }
        self.tileData = data

        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clearColor(), size: data.texture.size())
        orientTile()
    }
    
    public func setupDynamics(){
        physicsBody = SKPhysicsBody(rectangleOfSize: size)
        physicsBody?.dynamic = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Animation
    
    /**
     Check if the tile is animated and run an action to animated it.
     */
    public func runAnimation(){
        guard tileData.isAnimated == true else { return }
        var framesData: [(texture: SKTexture, duration: NSTimeInterval)] = []
        for frame in tileData.frames {
            guard let frameTexture = tileData.tileset.getTileData(frame.gid)?.texture else {
                print("Error: Cannot access texture for id: \(frame.gid)")
                return
            }
            framesData.append((texture: frameTexture, duration: frame.duration))
        }
        
        let animationAction = SKAction.tileAnimation(framesData)
        runAction(animationAction, withKey: "Animation")
    }
    
    /// Pauses tile animation
    public var pauseAnimation: Bool = false {
        didSet {
            guard oldValue != pauseAnimation else { return }
            guard let action = actionForKey("Animation") else { return }
            action.speed = (pauseAnimation == true) ? 0 : 1.0
        }
    }
    
    /**
     Set the tile overlap amount.
     
     - parameter overlap: `CGFloat` tile overlap.
     */
    public func setTileOverlap(overlap: CGFloat) {
        // clamp the overlap value.
        var overlapValue = overlap <= 1.5 ? overlap : 1.5
        overlapValue = overlapValue > 0 ? overlapValue : 0
        guard overlapValue != tileOverlap else { return }
        guard let tileTexture = tileData.texture else { return }
        
        let width: CGFloat = tileData.texture.size().width
        let overlapWidth = width + (overlap / width)

        let height: CGFloat = tileData.texture.size().height
        let overlapHeight = height + (overlap / height)
        
        xScale *= overlapWidth / width
        yScale *= overlapHeight / height
        tileOverlap = overlap
    }

        /**
     Orient the tile based on the current flip flags.
     */
    private func orientTile() {
        // reset orientation
        zRotation = 0
        setScale(1)
        
        if (tileData.flipDiag) {
            if (tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
            }
            
            if (tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
                xScale *= -1                   // flip horizontally
            }
            
            if (!tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
            }
            
            if (!tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
                xScale *= -1                   // flip horizontally
            }
        } else {
            if (tileData.flipHoriz) {
                xScale *= -1
            }
            
            if (tileData.flipVert) {
                yScale *= -1
            }
        }
    }

    /**
     Returns the points of the tile's shape.
     
     - returns: `[CGPoint]?` array of points.
     */
    private func getVertices() -> [CGPoint] {
        var vertices: [CGPoint] = []
        guard let layer = layer else { return vertices }
        
        let tileSizeHalved = CGSize(width: layer.tileSize.halfWidth, height: layer.tileSize.halfHeight)
        
        switch layer.orientation {
        case .Orthogonal:
            let origin = CGPoint(x: -tileSizeHalved.width, y: tileSizeHalved.height)
            vertices = rectPointArray(tileSize, origin: origin)
            
        case .Isometric, .Staggered:
            vertices = [
                CGPoint(x: -tileSizeHalved.width, y: 0),    // left-side
                CGPoint(x: 0, y: tileSizeHalved.height),
                CGPoint(x: tileSizeHalved.width, y: 0),
                CGPoint(x: 0, y: -tileSizeHalved.height),   // bottom
            ]
            
        case .Hexagonal:
            var hexPoints = Array(count: 6, repeatedValue: CGPointZero)
            let staggerX = layer.tilemap.staggerX
            let tileWidth = layer.tilemap.tileWidth
            let tileHeight = layer.tilemap.tileHeight
            
            let sideLengthX = layer.tilemap.sideLengthX
            let sideLengthY = layer.tilemap.sideLengthY
            var variableSize: CGFloat = 0
            
            // flat
            if (staggerX == true) {
                let r = (tileWidth - sideLengthX) / 2
                let h = tileHeight / 2
                variableSize = tileWidth - (r * 2)
                hexPoints[0] = CGPoint(x: -(variableSize / 2), y: h)
                hexPoints[1] = CGPoint(x: (variableSize / 2), y: h)
                hexPoints[2] = CGPoint(x: (tileWidth / 2), y: 0)
                hexPoints[3] = CGPoint(x: (variableSize / 2), y: -h)
                hexPoints[4] = CGPoint(x: -(variableSize / 2), y: -h)
                hexPoints[5] = CGPoint(x: -(tileWidth / 2), y: 0)
                
            // pointy
            } else {
                let r = tileWidth / 2
                let h = (tileHeight - sideLengthY) / 2
                variableSize = tileHeight - (h * 2)
                hexPoints[0] = CGPoint(x: 0, y: (tileHeight / 2))
                hexPoints[1] = CGPoint(x: r, y: (variableSize / 2))
                hexPoints[2] = CGPoint(x: r, y: -(variableSize / 2))
                hexPoints[3] = CGPoint(x: 0, y: -(tileHeight / 2))
                hexPoints[4] = CGPoint(x: -r, y: -(variableSize / 2))
                hexPoints[5] = CGPoint(x: -r, y: (variableSize / 2))
            }
            
            vertices = hexPoints.map{$0.invertedY}
        }
        
        return vertices
    }

    /**
     Draw the tile's boundary shape.

     - parameter color: `SKColor` highlight color.
     */
    public func drawBounds(antialiasing: Bool=true, duration: NSTimeInterval=0) {
        guard let layer = layer else { return }
        childNodeWithName("Anchor")?.removeFromParent()
        childNodeWithName("Bounds")?.removeFromParent()
        
        let vertices = getVertices()
        let path = polygonPath(vertices)
        let shape = SKShapeNode(path: path)
        shape.name = "Bounds"
        let shapeZPos = zPosition + 10
        
        // draw the path
        shape.antialiased = false
        shape.lineCap = .Butt
        shape.miterLimit = 0
        shape.lineWidth = 0.5
        
        shape.strokeColor = highlightColor.colorWithAlphaComponent(0.4)
        shape.fillColor = highlightColor.colorWithAlphaComponent(0.35)
        shape.zPosition = shapeZPos
        addChild(shape)
        
        // anchor
        let anchorRadius: CGFloat = tileSize.height / 12 > 1.0 ? tileSize.height / 30 : 1.0
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "Anchor"
        shape.addChild(anchor)
        anchor.fillColor = highlightColor.colorWithAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clearColor()
        anchor.zPosition = shapeZPos + 10
        anchor.antialiased = true
        
        if (duration > 0) {
            let fadeAction = SKAction.fadeOutWithDuration(duration)
            shape.runAction(fadeAction, completion: {
                shape.removeFromParent()
                
            })
        }
    }
}
    


public extension SKTile {
    
    /// Tile description.
    override public var description: String {
        let descString = "\(tileData.description)"
        let descGroup = descString.componentsSeparatedByString(".")
        var resultString = descGroup.first!
        if let layer = layer {resultString += ", Layer: \"\(layer.name!)\"" }
        
        // add the properties
        if descGroup.count > 1 {
            for i in 1..<descGroup.count {
                resultString += ", \(descGroup[i])"
            }
        }
        return resultString
    }
    
    override public var debugDescription: String {
        return description
    }
    
    /**
     Highlight the tile with a given color.
     
     - parameter color: `SKColor` highlight color.
     */
    public func highlightWithColor(color: SKColor?=nil, duration: NSTimeInterval=1.0, antialiasing: Bool=true) {
        
        let highlight: SKColor = (color == nil) ? highlightColor : color!
        
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .Orthogonal {
            childNodeWithName("HIGHLIGHT")?.removeFromParent()
            let highlightNode = SKShapeNode(rectOfSize: tileSize, cornerRadius: 0)
            highlightNode.strokeColor = highlight.colorWithAlphaComponent(0.1)
            highlightNode.fillColor = highlight.colorWithAlphaComponent(0.35)
            highlightNode.name = "HIGHLIGHT"
            
            highlightNode.antialiased = antialiasing
            addChild(highlightNode)
            highlightNode.zPosition = zPosition + 10
            
            // fade out highlight
            removeActionForKey("HIGHLIGHT_FADE")
            let fadeAction = SKAction.sequence([
                SKAction.waitForDuration(duration * 1.5),
                SKAction.fadeAlphaTo(0, duration: duration/4.0)
                ])
            
            highlightNode.runAction(fadeAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                highlightNode.removeFromParent()
            })
        }
        
        if orientation == .Isometric {
            removeActionForKey("HIGHLIGHT_FADE")
            let fadeOutAction = SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 1, duration: duration)
            runAction(fadeOutAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                let fadeInAction = SKAction.sequence([
                    SKAction.waitForDuration(duration * 1.5),
                    //fadeOutAction.reversedAction()
                    SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 0, duration: duration/4.0)
                    ])
                self.runAction(fadeInAction, withKey: "HIGHLIGHT_FADE")
            })
        }
    }
    
    /**
     Clear highlighting.
     */
    public func clearHighlight() {
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .Orthogonal {
            childNodeWithName("HIGHLIGHT")?.removeFromParent()
        }
        if orientation == .Isometric {
            removeActionForKey("HIGHLIGHT")
        }
    }

    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    func debugQuickLookObject() -> AnyObject {
        let shape = SKShapeNode(rectOfSize: self.tileData.tileset.tileSize)
        return shape
    }
}


/// Shape node used for highlighting and placing tiles.
public class DebugTileShape: SKShapeNode {
    
    public var tileSize: CGSize
    public var orientation: TilemapOrientation = .Orthogonal
    public var color: SKColor
    public var layer: TiledLayerObject
    
    
    public init(layer: TiledLayerObject, tileColor: SKColor){
        self.layer = layer
        self.tileSize = layer.tileSize
        self.color = tileColor
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawObject() {
        // draw the path
        var points: [CGPoint] = []
        
        let tileSizeHalved = CGSizeMake(tileSize.halfWidth, tileSize.halfHeight)
        
        switch orientation {
        case .Orthogonal:
            let origin = CGPoint(x: -tileSize.halfWidth, y: tileSize.halfHeight)
            points = rectPointArray(tileSize, origin: origin)
            
        case .Isometric, .Staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)
            
        case .Hexagonal:
            var hexPoints = Array(count: 6, repeatedValue: CGPointZero)
            let staggerX = layer.tilemap.staggerX
            let tileWidth = layer.tilemap.tileWidth
            let tileHeight = layer.tilemap.tileHeight
            
            let sideLengthX = layer.tilemap.sideLengthX
            let sideLengthY = layer.tilemap.sideLengthY
            var variableSize: CGFloat = 0
            
            // flat (broken)
            if (staggerX == true) {
                let r = (tileWidth - sideLengthX) / 2
                let h = tileHeight / 2
                variableSize = tileWidth - (r * 2)
                hexPoints[0] = CGPoint(x: position.x - (variableSize / 2), y: position.y + h)
                hexPoints[1] = CGPoint(x: position.x + (variableSize / 2), y: position.y + h)
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y)
                hexPoints[3] = CGPoint(x: position.x + (variableSize / 2), y: position.y - h)
                hexPoints[4] = CGPoint(x: position.x - (variableSize / 2), y: position.y - h)
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y)
            } else {
                let r = tileWidth / 2
                let h = (tileHeight - sideLengthY) / 2
                variableSize = tileHeight - (h * 2)
                hexPoints[0] = CGPoint(x: position.x, y: position.y + (tileHeight / 2))
                hexPoints[1] = CGPoint(x: position.x + (tileWidth / 2), y: position.y + (variableSize / 2))
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[3] = CGPoint(x: position.x, y: position.y - (tileHeight / 2))
                hexPoints[4] = CGPoint(x: position.x - (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y + (variableSize / 2))
            }
            
            points = hexPoints.map{$0.invertedY}
        }
        
        // draw the path
        self.path = polygonPath(points)
        self.antialiased = false
        self.lineCap = .Butt
        self.miterLimit = 0
        self.lineWidth = 0.5
        
        self.strokeColor = self.color.colorWithAlphaComponent(0.4)
        self.fillColor = self.color.colorWithAlphaComponent(0.35)
        
        // anchor
        childNodeWithName("Anchor")?.removeFromParent()
        let anchorRadius: CGFloat = tileSize.height / 12 > 1.0 ? tileSize.height / 12 : 1.0
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "Anchor"
        addChild(anchor)
        anchor.fillColor = self.color.colorWithAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clearColor()
        anchor.zPosition = zPosition + 10
        anchor.antialiased = true
    }
}
