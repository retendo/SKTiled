//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit


public class SKTiledDemoScene: SKTiledScene {
    
    public var uiScale: CGFloat = 1
    public var debugMode: Bool = false
    
    // ui controls
    public var resetButton: ButtonNode!
    public var drawButton:  ButtonNode!
    public var nextButton:  ButtonNode!
    
    // debugging labels
    public var tilemapInformation: SKLabelNode!
    public var tileInformation: SKLabelNode!
    
    /// global information label font size.
    private let labelFontSize: CGFloat = 11
    
    override public func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        #if os(OSX)
        // add mouse tracking for OSX
        let options = [NSTrackingAreaOptions.MouseMoved, NSTrackingAreaOptions.ActiveAlways] as NSTrackingAreaOptions
        let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
        #endif
        
        // setup demo UI
        setupDemoUI()
        setupDebuggingLabels()
        updateHud()
        
        
        if let tilemap = tilemap {
            tilemap.debugDraw = debugMode
        }
    }
    
    // MARK: - Setup
    /**
     Set up interface elements for this demo.
     */
    public func setupDemoUI() {
        guard let view = self.view else { return }
        
        // set up camera overlay UI
        var lastZPosition: CGFloat = 500
        if let tilemap = tilemap {
            lastZPosition = tilemap.lastZPosition
        }
        
        if (resetButton == nil){
            resetButton = ButtonNode(defaultImage: "reset-button-norm", highlightImage: "reset-button-pressed", action: {
                if let cameraNode = self.cameraNode {
                    cameraNode.resetCamera()
                }
            })
            cameraNode.addChild(resetButton)
            // position towards the bottom of the scene
            resetButton.position.x -= (view.bounds.size.width / 7)
            resetButton.position.y -= (view.bounds.size.height / 2.25)
            resetButton.zPosition = lastZPosition * 3.0
        }
        
        if (drawButton == nil){
            drawButton = ButtonNode(defaultImage: "draw-button-norm", highlightImage: "draw-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                let debugState = !tilemap.debugDraw
                tilemap.debugDraw = debugState
                
                if (debugState == true){
                    tilemap.debugLayers()
                }
            })
            
            cameraNode.addChild(drawButton)
            // position towards the bottom of the scene
            drawButton.position.y -= (view.bounds.size.height / 2.25)
            drawButton.zPosition = lastZPosition * 3.0
        }
        
        if (nextButton == nil){
            nextButton = ButtonNode(defaultImage: "next-button-norm", highlightImage: "next-button-pressed", action: {
                self.loadNextScene()
            })
            cameraNode.addChild(nextButton)
            // position towards the bottom of the scene
            nextButton.position.x += (view.bounds.size.width / 7)
            nextButton.position.y -= (view.bounds.size.height / 2.25)
            nextButton.zPosition = lastZPosition * 3.0
        }
    }
    
    /**
     Setup debugging labels.
     */
    func setupDebuggingLabels() {
        guard let view = self.view else { return }
        guard let cameraNode = cameraNode else { return }
        
        //let labelYPos = view.bounds.size.height / 3.2
        
        if (tilemapInformation == nil){
            // setup tilemap label
            tilemapInformation = SKLabelNode(fontNamed: "Courier")
            tilemapInformation.fontSize = labelFontSize
            tilemapInformation.text = "Tilemap:"
            cameraNode.addChild(tilemapInformation)
        }
        
        if (tileInformation == nil){
            // setup tile information label
            tileInformation = SKLabelNode(fontNamed: "Courier")
            tileInformation.fontSize = labelFontSize
            tileInformation.text = "Tile:"
            cameraNode.addChild(tileInformation)
        }
        
        tileInformation.hidden = true
        tileInformation.position.y = view.bounds.size.height / 3.2
    }

    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `NSTimeInterval` tile life.
     */
    func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: NSTimeInterval=0) -> DebugTileShape {
        // validate the coordinate
        let validCoord = layer.isValid(x, y)
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
        
        // add debug tile shape
        let tile = DebugTileShape(layer: layer, tileColor: tileColor)
        tile.zPosition = lastZosition
        tile.position = layer.pointForCoordinate(x, y)
        layer.addChild(tile)
        if (duration > 0) {
            let fadeAction = SKAction.fadeAlphaTo(0, duration: duration)
            tile.runAction(fadeAction, completion: {
                tile.removeFromParent()
            })
        }
        return tile
    }
    
    /**
     Call back to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NSNotificationCenter.defaultCenter().postNotificationName("loadNextScene", object: nil)
    }
    
    
    override public func didChangeSize(oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        var dynamicScale = size.width / 400
        let remainder = dynamicScale % 2
        dynamicScale = dynamicScale - remainder
        uiScale = dynamicScale >= 1 ? dynamicScale : 1
        
        updateHud()
        #if os(OSX)
        if let view = self.view {
            let options = [NSTrackingAreaOptions.MouseMoved, NSTrackingAreaOptions.ActiveAlways] as NSTrackingAreaOptions
            // clear out old tracking areas
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
            
            let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea)
        }
        #endif
    }
    
    override public func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        updateLabels()
    }
    
    private func buttonNodes() -> [ButtonNode] {
        var buttons: [ButtonNode] = []
        enumerateChildNodesWithName("//*", usingBlock: {node, _ in
            if let button = node as? ButtonNode {
                if button.hidden == false {
                    buttons.append(button)
                }
            }
        })
        return buttons
    }
    
    func isValidPosition(point: CGPoint) -> Bool {
        let nodesUnderCursor = nodesAtPoint(point)
        for node in nodesUnderCursor {
            if let _ = node as? ButtonNode {
                return false
            }
        }
        return true
    }
    
    /**
     Update the debug label to reflect the current camera position.
     */
    func updateLabels() {
        guard let tilemap = tilemap else { return }
        
        let highestZPos = tilemap.lastZPosition + tilemap.zDeltaForLayers
        
        if let tilemapInformation = tilemapInformation {
            tilemapInformation.text = tilemap.description
            tilemapInformation.zPosition = highestZPos
        }
        
        if let tileInformation = tileInformation {
            tileInformation.zPosition = highestZPos
        }
        
        buttonNodes().forEach {$0.zPosition = highestZPos * 2}
    }
    
    /**
     Update HUD elements.
     */
    private func updateHud(){
        guard let view = self.view else { return }
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition : 200
        
        let viewSize = view.bounds.size
        let buttonYPos: CGFloat = -(size.height * 0.4)
        
        let buttons = buttonNodes()
        guard buttons.count > 0 else { return }
        
        buttons.forEach {$0.setScale(uiScale)}
        
        let buttonWidths = buttons.map { $0.size.width }
        let maxWidth = buttonWidths.reduce(0, combine: {$0 + $1})
        let spacing = (viewSize.width - maxWidth) / CGFloat(buttons.count + 1)
        
        var current = spacing + (buttonWidths[0] / 2)
        for button in buttons {
            let buttonScenePos = CGPoint(x: current - (viewSize.width / 2), y: buttonYPos)
            button.position = buttonScenePos
            button.zPosition = lastZPosition
            current += spacing + button.size.width
        }
        
        let dynamicFontSize = labelFontSize * (size.width / 600)
        
        // Update information labels
        if let tilemapInformation = tilemapInformation {
            let ypos = -(size.height * (uiScale / 8.5))    // approx 0.25
            tilemapInformation.position.y = abs(ypos) < 100 ? -80 : ypos
            tilemapInformation.fontSize = dynamicFontSize
        }
        
        if let tileInformation = tileInformation {
            let ypos = -(size.height * (uiScale / 6.5))    // approx 0.35
            tileInformation.position.y = abs(ypos) < 100 ? -90 : ypos
            tileInformation.fontSize = dynamicFontSize
        }
    }
}


public extension SKNode {
    
    public func posByCanvas(x: CGFloat, y: CGFloat) {
        guard let scene = scene else { return }
        self.position = CGPoint(x: CGFloat(scene.size.width * x), y: CGFloat(scene.size.height * y))
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        for touch in touches {
            
            // make sure there are no UI objects under the mouse
            let scenePosition = touch.locationInNode(self)
            if !isValidPosition(scenePosition) { return }
            
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)            // this needs to take into consideration the adjustments for hex -> square grid
            let coord = baseLayer.screenToTileCoords(positionInLayer)
            // add a tile shape to the base layer where the user has clicked
            
            // highlight the current coordinate
            let _ = addTileAt(baseLayer, Int(coord.x), Int(coord.y), duration: 5)
            
            // update the tile information label
            var coordStr = "Tile: \(coord.coordDescription), \(positionInMap.roundTo())"
            tileInformation.hidden = false
            tileInformation.text = coordStr
        }
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
    
    override public func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
}
#endif


#if os(OSX)
// Mouse-based event handling
extension SKTiledDemoScene {
    
    override public func mouseDown(event: NSEvent) {
        guard let tilemap = tilemap else { return }
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseDown(event)
        
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.locationInNode(self)
        if !isValidPosition(scenePosition) { return }
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event)
        let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)
        let coord = baseLayer.screenToTileCoords(positionInLayer)
        
        // highlight the current coordinate
        let _ = addTileAt(baseLayer, Int(coord.x), Int(coord.y), duration: 5)
        
        // update the tile information label
        let coordStr = "Tile: \(coord.coordDescription), \(positionInMap.roundTo())"
        tileInformation.hidden = false
        tileInformation.text = coordStr
    }
    
    override public func mouseMoved(event: NSEvent) {
        super.mouseMoved(event)
        
        updateTrackingViews()
        
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.locationInNode(self)
        if !isValidPosition(scenePosition) { return }
        
        // get the position in the baseLayer (inverted)
        let positionInLayer = baseLayer.mouseLocation(event)
        let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)
        let coord = baseLayer.screenToTileCoords(positionInLayer)
        
        tileInformation?.hidden = false
        tileInformation?.text = "Tile: \(coord.coordDescription), \(positionInMap.roundTo())"
        
        // highlight the current coordinate
        let _ = addTileAt(baseLayer, Int(coord.x), Int(coord.y), duration: 0.05)
    }
    
    override public func mouseDragged(event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(event)
    }
    
    override public func mouseUp(event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseUp(event)
    }
    
    override public func scrollWheel(event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scrollWheel(event)
    }
    
    override public func keyDown(event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        if event.keyCode == 0x00 || event.keyCode == 0x52 || event.keyCode == 0x1D {
            if let tilemap = tilemap {
                cameraNode.resetCamera(toScale: tilemap.worldScale)
            } else {
                cameraNode.resetCamera()
            }
        }
    }
    
    /**
     Remove old tracking views and add the current.
     */
    public func updateTrackingViews(){
        if let view = self.view {
            let options = [NSTrackingAreaOptions.MouseMoved, NSTrackingAreaOptions.ActiveAlways] as NSTrackingAreaOptions
            // clear out old tracking areas
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
            
            let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea)
        }
    }
}
#endif


