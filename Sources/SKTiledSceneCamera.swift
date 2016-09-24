//
//  SKTiledSceneCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Adapted from http://www.avocarrot.com/blog/implement-gesture-recognizers-swift/


import SpriteKit
#if os(iOS)
import UIKit
#else
import Cocoa
#endif


/**
  Custom scene camera that responds to finger/mouse gestures.
 */
public class SKTiledSceneCamera: SKCameraNode {
    
    public let world: SKNode
    private var bounds: CGRect
    public var zoom: CGFloat = 1.0
    public var initialZoom: CGFloat = 1.0
    
    // movement constraints
    public var allowMovement: Bool = true
    public var allowZoom: Bool = true
    public var allowRotation: Bool = false
    
    // zoom constraints
    private var minZoom: CGFloat = 0.2
    private var maxZoom: CGFloat = 5.0
    
    public var isAtMaxZoom: Bool { return zoom == maxZoom }
    
    // gestures
    #if os(iOS)
    /// Gesture recognizer to recognize camera panning
    public var cameraPanned: UIPanGestureRecognizer!
    #endif
    
    // locations
    private var focusLocation = CGPointZero
    private var lastLocation: CGPoint!

    // MARK: - Init
    public init(view: SKView, world node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
        
        #if os(iOS)
        // setup pan recognizer
        cameraPanned = UIPanGestureRecognizer(target: self, action: #selector(cameraPanned(_:)))
        cameraPanned.minimumNumberOfTouches = 1
        cameraPanned.maximumNumberOfTouches = 1
        view.addGestureRecognizer(cameraPanned)
        #endif
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Apply zooming to the world node (as scale).
     
     - parameter scale: `CGFloat` zoom amount.
     */
    public func setWorldScale(scale: CGFloat) {
        self.zoom = scale
        var realScale = scale <= minZoom ? minZoom : scale
        realScale = realScale >= maxZoom ? maxZoom : realScale
        self.zoom = realScale
        world.setScale(realScale)
    }
    
    /**
     Set the camera min/max zoom values.
     
     - parameter minimum:    `CGFloat` minimum zoom vector.
     - parameter maximum:    `CGFloat` maximum zoom vector.
     */
    public func setZoomConstraints(minimum: CGFloat, maximum: CGFloat) {
        let minValue = minimum > 0 ? minimum : 0
        minZoom = minValue
        maxZoom = maximum
    }
    
    /**
     Move camera around manually.
     
     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `NSTimeInterval` duration of move.
     */
    public func panToPoint(point: CGPoint, duration: NSTimeInterval=0.3) {
        runAction(SKAction.moveTo(point, duration: duration))
    }
    
    /**
     Center the camera on a location in the scene.
     
     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `NSTimeInterval` ease in/out speed.
     */
    public func centerOn(scenePoint point: CGPoint, duration: NSTimeInterval=0) {
        if duration == 0 {
            position = point
        } else {
            let moveAction = SKAction.moveTo(point, duration: duration)
            moveAction.timingMode = .EaseOut
            runAction(moveAction)
        }
    }
    
    /**
     Center the camera on a node in the scene.
     
     - parameter scenePoint: `SKNode` node in scene.
     - parameter easeInOut:  `NSTimeInterval` ease in/out speed.
     */
    public func centerOn(node: SKNode, duration: NSTimeInterval=0) {
        guard let scene = self.scene else { return }
        
        let nodePosition = scene.convertPoint(node.position, fromNode: node)
        if duration == 0 {
            position = nodePosition
        } else {
            let moveAction = SKAction.moveTo(nodePosition, duration: duration)
            moveAction.timingMode = .EaseOut
            runAction(moveAction)
        }
    }
    
    /**
     Reset the camera position & zoom level.
     */
    public func resetCamera() {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setWorldScale(initialZoom)
    }
    
    public func resetCamera(toScale scale: CGFloat) {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setWorldScale(scale)
    }
}


#if os(iOS)
public extension SKTiledSceneCamera {
    // MARK: - Gesture Handlers
    
    /**
     Update the scene camera when a pan gesture is recogized.
     
     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
     */
    public func cameraPanned(recognizer: UIPanGestureRecognizer) {
        guard let scene = self.scene else { return }
        if (recognizer.state == .Began) {
            let location = recognizer.locationInView(recognizer.view)
            lastLocation = location
        }
        
        if (recognizer.state == .Changed) && (allowMovement == true) {
            if lastLocation == nil { return }
            let location = recognizer.locationInView( recognizer.view)
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - -difference.y)))
            lastLocation = location
        }
    }
}
#endif


#if os(OSX)
extension SKTiledSceneCamera {
    // MARK: - Mouse Events
    
    /**
     Handler for double clicks.
     
     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    public func sceneDoubleClicked(event: NSEvent) {
        guard let scene = self.scene as? SKTiledScene else { return }
        //let sceneLocation = event.locationInNode( scene)
    }
    
    override public func mouseDown(event: NSEvent) {
        let location = event.locationInNode( self)
        lastLocation = location
    }
    
    override public func mouseUp(event: NSEvent) {
        let location = event.locationInNode( self)
        lastLocation = location
        focusLocation = location
    }
    
    override public func scrollWheel(event: NSEvent) {
        let location = event.locationInNode( self)
        focusLocation = location
        centerOn(scenePoint: focusLocation)
        
        zoom += (event.deltaY * 0.25)
        // set the world scaling here
        setWorldScale(zoom)
    }
    
    public func scenePositionChanged(event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let location = event.locationInNode(self)
        if lastLocation == nil { lastLocation = location }
        if allowMovement == true {
            if lastLocation == nil { return }
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - difference.y)))
            lastLocation = location
        }
    }
}
#endif

