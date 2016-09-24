//
//  AppDelegate.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!
    
    var demoFiles: [String] = []
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        // load demo files from a propertly list
        demoFiles = loadDemoFiles("DemoFiles")
        
        let currentFilename = demoFiles.first!
        
        /* Pick a size for the scene */
        let scene = SKTiledDemoScene(size: self.skView!.bounds.size, tmxFile: currentFilename)
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        
        self.skView!.presentScene(scene)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadNextScene), name: "loadNextScene", object: nil)
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        self.skView!.ignoresSiblingOrder = true
        
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
        
        if let window = window {
            window.title = "SKTiled: \(currentFilename)"
            window.acceptsMouseMovedEvents = true
            window.makeFirstResponder(self.skView.scene)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `NSTimeInterval` transition duration.
     */
    func loadNextScene(interval: NSTimeInterval=0.4) {
        guard let view = self.skView else { return }
        
        var demoFiles: [String] = loadDemoFiles("DemoFiles")
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let tilemap = currentScene.tilemap {
                currentFilename = tilemap.name!
            }
            currentScene.removeFromParent()
        }
        
        view.presentScene(nil)
        
        var nextFilename = demoFiles.first!
        if let index = demoFiles.indexOf(currentFilename) where index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        
        let nextScene = SKTiledDemoScene(size: view.bounds.size, tmxFile: nextFilename)
        nextScene.scaleMode = .AspectFill
        let transition = SKTransition.fadeWithDuration(interval)
        view.presentScene(nextScene, transition: transition)
        
        if let window = window {
            window.title = "SKTiled: \(nextFilename)"
        }
    }
    
    private func loadDemoFiles(filename: String) -> [String] {
        var result: [String] = []
        if let fileList = NSBundle.mainBundle().pathForResource(filename, ofType: "plist"){
            if let data = NSArray(contentsOfFile: fileList) as? [String] {
                result = data
            }
        }
        return result
    }
}


// MARK: - Swift 2.3 only

/// Forward scroll wheel events to the scene.
extension SKView {
    override public func scrollWheel(event: NSEvent) {
        if let scene = scene {
            scene.scrollWheel(event)
        }
    }
}
