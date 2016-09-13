//
//  AppDelegate.swift
//  Throwaway
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
        
        
        
        
        /* Pick a size for the scene */
        let scene = SKTiledDemoScene(fileNamed:"GameScene") 
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        
        self.skView!.presentScene(scene)
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        self.skView!.ignoresSiblingOrder = true
        
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `NSTimeInterval` transition duration.
     */
    func loadNextScene(interval: NSTimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
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
