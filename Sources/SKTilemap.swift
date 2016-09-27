//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


internal enum TiledColors: String {
    case white  =  "#f7f5ef"
    case grey   =  "#969696"
    case red    =  "#990000"
    case blue   =  "#86b9e3"
    case green  =  "#33cc33"
    case orange =  "#ff9933"
    case debug  =  "#999999"
    
    public var color: SKColor {
        return SKColor(hexString: self.rawValue)
    }
}


/**
 Describes the map tile orientation.

 - orthogonal:   map is orthogonal type.
 - isometric:    map is isometric type.
 - hexagonal:    map is hexagonal type.
 - staggered:    map is isometric staggered type.
 */
public enum TilemapOrientation: String {
    case orthogonal   = "orthogonal"
    case isometric    = "isometric"
    case hexagonal    = "hexagonal"
    case staggered    = "staggered"
}


internal enum RenderOrder: String {
    case rightDown  = "right-down"
    case rightUp    = "right-up"
    case leftDown   = "left-down"
    case leftUp     = "left-up"
}


/**
 Tile offset hint for coordinate conversion.
 
 ```
    center:        returns the center of the tile.
    top:           returns the top of the tile.
    topLeft:       returns the top left of the tile.
    topRight:      returns the top left of the tile.
    bottom:        returns the bottom of the tile.
    bottomLeft:    returns the bottom left of the tile.
    bottomRight:   returns the bottom right of the tile.
    left:          returns the left side of the tile.
    right:         returns the right side of the tile.
 ```
 */
public enum TileOffset: Int {
    case center
    case top
    case topLeft
    case topRight
    case bottom
    case bottomLeft
    case bottomRight
    case left
    case right
}


/**
 Tilemap data encoding.
 */
internal enum TilemapEncoding: String {
    case base64  = "base64"
    case csv     = "csv"
    case xml     = "xml"
}


/**
 Alignment hint used to position the layers within the `SKTilemap` node.
 
 - bottomLeft:   node bottom left rests at parent zeropoint (0)
 - center:       node center rests at parent zeropoint (0.5)
 - topRight:     node top right rests at parent zeropoint. (1)
 */
internal enum LayerPosition {
    case bottomLeft
    case center
    case topRight
}

/**
 Hexagonal stagger axis.
 
 - x: axis is along the x-coordinate.
 - y: axis is along the y-coordinate.
 */
internal enum StaggerAxis: String {
    case x  = "x"
    case y  = "y"
}


/**
 Hexagonal stagger index.
 
 - even: stagger evens.
 - odd:  stagger odds.
 */
internal enum StaggerIndex: String {
    case odd   
    case even
}


///  Common tile size aliases
internal let TileSizeZero  = CGSize(width: 0, height: 0)
internal let TileSize8x8   = CGSize(width: 8, height: 8)
internal let TileSize16x16 = CGSize(width: 16, height: 16)
internal let TileSize32x32 = CGSize(width: 32, height: 32)


/**
 The `SKTilemap` class represents a container node which manages layers, tiles (sprites), objects & images.
 
 - size:         tile map size in tiles.
 - tileSize:     tile map tile size in pixels.
 - sizeInPoints: tile map size in points.
 
 Tile data is added via `SKTileset` tile sets.
 */
public class SKTilemap: SKNode, SKTiledObject{
    
    public var filename: String!                                    // tilemap filename
    public var uuid: String = NSUUID().UUIDString                   // unique id
    public var size: CGSize                                         // map size (in tiles)
    public var tileSize: CGSize                                     // tile size (in pixels)
    public var orientation: TilemapOrientation                      // map orientation
    internal var renderOrder: RenderOrder = .rightDown              // render order
    
    // hexagonal
    public var hexsidelength: Int = 0                               // hexagonal side length
    internal var staggeraxis: StaggerAxis = .y                      // stagger axis
    internal var staggerindex: StaggerIndex = .odd                  // stagger index.
    
    // camera overrides
    public var worldScale: CGFloat = 1.0                            // initial world scale
    public var allowZoom: Bool = true                               // allow camera zoom
    public var allowMovement: Bool = true                           // allow camera movement
    public var minZoom: CGFloat = 0.2
    public var maxZoom: CGFloat = 5.0
    
    // current tile sets
    public var tileSets: Set<SKTileset> = []                        // tilesets
    
    // current layers
    private var layers: Set<TiledLayerObject> = []                  // layers
    public var layerCount: Int { return self.layers.count }         // layer count attribute
    public var properties: [String: String] = [:]                   // custom properties
    public var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    public var backgroundColor: SKColor? = nil                      // optional background color (read from the Tiled file)
    public var ignoreBackground: Bool = false                       // ignore Tiled scene background color
    
    /** 
    The tile map default base layer, used for displaying the current grid, getting coordinates, etc.
    */
    lazy public var baseLayer: SKTileLayer = {
        let layer = SKTileLayer(layerName: "Base", tilemap: self)
        self.addLayer(layer)
        return layer
    }()
    
    // debugging
    public var debugMode: Bool = false
    public var gridColor: SKColor = SKColor.blackColor()            // color used to visualize the tile grid
    public var frameColor: SKColor = SKColor.blackColor()           // bounding box color
    public var highlightColor: SKColor = SKColor.greenColor()       // color used to highlight tiles
    
    /// Rendered size of the map in pixels.
    public var sizeInPoints: CGSize {
        switch orientation {
        case .orthogonal:
            return CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)
        case .isometric:
            let side = width + height
            return CGSize(width: side * tileWidthHalf,  height: side * tileHeightHalf)
        case .hexagonal, .staggered:
            var result = CGSize.zero
            if staggerX == true {
                result = CGSize(width: width * columnWidth + sideOffsetX,
                                height: height * (tileHeight + sideLengthY))
                
                if width > 1 { result.height += rowHeight }
            } else {
                result = CGSize(width: width * (tileWidth + sideLengthX),
                                height: height * rowHeight + sideOffsetY)
            
                if height > 1 { result.width += columnWidth }
            }
            return result
        }
    }

    // used to align the layers within the tile map
    internal var layerAlignment: LayerPosition = .center {
        didSet {
            layers.forEach({self.positionLayer($0)})
        }
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tileSets.count > 0 ? tileSets.map {$0.lastGID}.maxElement()! : 0
    }    
    
    /// Returns the last GID for all tilesets.
    public var lastIndex: Int {
        return layers.count > 0 ? layers.map {$0.index}.maxElement()! : 0
    }
    
    /// Returns the last (highest) z-position in the map.
    public var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.maxElement()! : 0
    }
    
    /// Tile overlap amount. 1 is typically a good value.
    public var tileOverlap: CGFloat = 0.5 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }
    
    /// Global property to show/hide all `SKTileObject` objects.
    public var showObjects: Bool = false {
        didSet {
            guard oldValue != showObjects else { return }
            for objectLayer in objectGroups {
                objectLayer.showObjects = showObjects
            }
        }
    }
    
    /// Convenience property to return all tile layers.
    public var tileLayers: [SKTileLayer] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKTileLayer != nil}) as! [SKTileLayer]
    }
    
    /// Convenience property to return all object groups.
    public var objectGroups: [SKObjectGroup] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKObjectGroup != nil}) as! [SKObjectGroup]
    }
    
    /// Convenience property to return all image layers.
    public var imageLayers: [SKImageLayer] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKImageLayer != nil}) as! [SKImageLayer]
    }
    
    /// Global antialiasing of lines
    public var antialiasLines: Bool = false {
        didSet {
            layers.forEach({$0.antialiased = antialiasLines})
        }
    }
    
    // MARK: - Loading
    
    /**
     Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a problem reading the file
     
     - parameter filename: `String` Tiled file name.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(fromFile filename: String) -> SKTilemap? {
        if let tilemap = SKTilemapParser().load(fromFile: filename) {
            return tilemap
        }
        return nil
    }
    
    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.
     
     - parameter attributes: `Dictionary` attributes dictionary.
     - returns: `SKTileMapNode?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }
        
        // initialize tile size & map size
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        size = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        
        // tile orientation
        guard let tileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient) else {
            fatalError("orientation \"\(orient)\" not supported.")
        }
        
        self.orientation = tileOrientation
        
        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("orientation \"\(rendorder)\" not supported.")
            }
            self.renderOrder = renderorder
        }
        
        // hex side
        if let hexside = attributes["hexsidelength"] {
            self.hexsidelength = Int(hexside)!
        }
        
        // hex stagger axis
        if let hexStagger = attributes["staggeraxis"] {
            guard let staggerAxis: StaggerAxis = StaggerAxis(rawValue: hexStagger) else {
                fatalError("stagger axis \"\(hexStagger)\" not supported.")
            }
            self.staggeraxis = staggerAxis
        }
        
        // hex stagger index
        if let hexIndex = attributes["staggerindex"] {
            guard let hexindex: StaggerIndex = StaggerIndex(rawValue: hexIndex) else {
                fatalError("stagger index \"\(hexIndex)\" not supported.")
            }
            self.staggerindex = hexindex
        }

        // background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            if !(ignoreBackground == true){
            self.backgroundColor = SKColor(hexString: backgroundHexColor)
            }
        }
        
        
        // global antialiasing
        antialiasLines = tileSize.width > 16 ? true : false
        super.init()
    }
    
    /**
     Initialize with map size/tile size
     
     - parameter sizeX:     `Int` map width in tiles.
     - parameter sizeY:     `Int` map height in tiles.
     - parameter tileSizeX: `Int` tile width in pixels.
     - parameter tileSizeY: `Int` tile height in pixels.     
     - returns: `SKTilemap`
     */
    public init(sizeX: Int, _ sizeY: Int,
                _ tileSizeX: Int, _ tileSizeY: Int,
                  orientation: TilemapOrientation = .orthogonal) {
        self.size = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
        self.orientation = orientation
        self.antialiasLines = tileSize.width > 16 ? true : false
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    
    /**
     Add a tileset to tileset set.
     
     - parameter tileset: `SKTileset` tileset object.
     */
    public func addTileset(tileset: SKTileset) {
        tileSets.insert(tileset)
        tileset.tilemap = self
        tileset.parseProperties()
    }
    
    /**
     Remove a tileset from the tilesets.
     
     - parameter tileset: `SKTileset` removed tileset.
     */
    public func removeTileset(tileset: SKTileset) -> SKTileset? {
        return tileSets.remove(tileset)
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.     
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(named name: String) -> SKTileset? {
        if let index = tileSets.indexOf(  { $0.name == name } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    /**
     Returns an external tileset with a given filename.
     
     - parameter filename: `String` tileset source file.     
     - returns: `SKTileset?`
     */
    public func getTileset(fileNamed filename: String) -> SKTileset? {
        if let index = tileSets.indexOf(  { $0.filename == filename } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    
    // MARK: - Layers
    /**
     Returns all layers, sorted by index (first is lowest, last is highest).
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    public func allLayers() -> [TiledLayerObject] {
        return layers.sort({$0.index < $1.index})
    }
    
    /**
     Returns an array of layer names.
     
     - returns: `[String]` layer names.
     */
    public func layerNames() -> [String] {
        return layers.flatMap { $0.name }
    }
    
    /**
     Add a layer to the layers set. Automatically sets zPosition based on the zDeltaForLayers attributes.
     
     - parameter layer: `TiledLayerObject` layer object.
     */
    public func addLayer(layer: TiledLayerObject, parse: Bool = false) {
        // set the layer index
        layer.index = layers.count > 0 ? lastIndex + 1 : 0
        
        layers.insert(layer)
        addChild(layer)
        
        // align the layer to the anchorpoint
        positionLayer(layer)
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
        
        // override debugging colors
        layer.gridColor = self.gridColor
        layer.frameColor = self.frameColor
        layer.highlightColor = self.highlightColor
        
        if (parse == true) {
            layer.parseProperties()  // moved this to parser
        }
    }
    
    /**
     Remove a layer from the current layers set.
     
     - parameter layer: `TiledLayerObject` layer object.
     - returns: `TiledLayerObject?` removed layer.
     */
    public func removeLayer(layer: TiledLayerObject) -> TiledLayerObject? {
        return layers.remove(layer)
    }
    
    /**
     Create and add a new tile layer.
     
     - parameter named: `String` layer name.
     - returns: `SKTileLayer` new layer.
     */
    public func addNewTileLayer(named: String) -> SKTileLayer {
        let layer = SKTileLayer(layerName: named, tilemap: self)
        addLayer(layer)
        return layer
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.name == layerName } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer matching the given UUID.
     
     - parameter uuid: `String` tile layer UUID.     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(withID uuid: String) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.uuid == uuid } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer given the index (0 being the lowest).
     
     - parameter index: `Int` layer index.     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(atIndex index: Int) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.index == index } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Isolate a named layer (hides other layers). Pass `nil`
     to show all layers.
     
     - parameter named: `String` layer name.
     */
    public func isolateLayer(named: String?=nil) {
        guard named != nil else {
            layers.forEach {$0.visible = true}
            return
        }
        
        layers.forEach {
            let hidden: Bool = $0.name == named ? true : false
            $0.visible = hidden
        }
    }
    
    /**
     Returns a named tile layer if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.     
     - returns: `SKTileLayer?`
     */
    public func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers.indexOf( { $0.name == name } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a tile layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.     
     - returns: `SKTileLayer?`
     */
    public func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers.indexOf( { $0.index == index } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a named object group if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.     
     - returns: `SKObjectGroup?`
     */
    public func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups.indexOf( { $0.name == name } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns an object group at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.     
     - returns: `SKObjectGroup?`
     */
    public func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups.indexOf( { $0.index == index } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns the index of a named layer.
    
     - parameter named: `String` layer name.
     - returns: `Int` layer index.
     */
    public func indexOf(layedNamed named: String) -> Int {
        if let layer = getLayer(named: named) {
            return layer.index
        }
        return 0
    }
    
    /**
     Position child layers in relation to the anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    private func positionLayer(layer: TiledLayerObject) {
        var layerPos = CGPoint.zero
        switch orientation {
            
        case .orthogonal:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
            
        case .isometric:
            // layer offset
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        
        case .hexagonal, .staggered:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        }
    
        layer.position = layerPos
    }
    
    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).
     
     - parameter fromZ: `CGFloat?` optional starting z-positon.
     */
    public func sortLayers(fromZ: CGFloat?=nil) {
        let startingZ: CGFloat = (fromZ != nil) ? fromZ! : zPosition
        allLayers().forEach {$0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index))}
    }
    
    // MARK: - Tiles
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter coord: `CGPoint` coordinate.     
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(coord: CGPoint) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            if let tile = layer.tileAt(coord){
                result.append(tile)
            }
        }
        return result
    }
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` - y-coordinate.     
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(CGPoint(x: x, y: y))
    }
    
    /**
     Returns a tile at the given coordinate from a layer.
     
     - parameter coord: `CGPoint` tile coordinate.
     - parameter name:  `String?` layer name.     
     - returns: `SKTile?` tile, or nil.
     */
    public func tileAt(coord: CGPoint, inLayer: String?) -> SKTile? {
        if let name = name {
            if let layer = getLayer(named: name) as? SKTileLayer {
                return layer.tileAt(coord)
            }
        }
        return nil
    }
    
    public func tileAt(x: Int, _ y: Int, inLayer name: String?) -> SKTile? {
        return tileAt(CGPoint(x: x, y: y), inLayer: name)
    }
    
    /**
     Returns tiles with a property of the given type (all tile layers).
     
     - parameter type: `String` type.     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(ofType type: String) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(ofType: type)
        }
        return result
    }
    
    /**
     Returns tiles matching the given gid (all tile layers).
     
     - parameter type: `Int` tile gid.     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(withID id: Int) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(withID: id)
        }
        return result
    }
    
    /**
     Returns tiles with a property of the given type & value (all tile layers).
     
     - parameter named: `String` property name.
     - parameter value: `AnyObject` property value.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTilesWithProperty(named: String, _ value: AnyObject) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTilesWithProperty(named, value as! String as AnyObject)
        }
        return result
    }
    
    /**
     Return tile data with a property of the given type (all tile layers).
     
     - parameter named: `String` property name.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTileData(withProperty named: String) -> [SKTilesetData] {
        return tileSets.flatMap { $0.getTileData(withProperty: named)}
    }
    
    /**
     Returns an array of all animated tile objects.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getAnimatedTiles() -> [SKTile] {
        return tileLayers.flatMap {$0.getAnimatedTiles()}
    }
    
    /**
     Return the top-most tile at the given coordinate.
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `SKTile?` first tile in layers.
     */
    public func firstTileAt(coord: CGPoint) -> SKTile? {
        for layer in tileLayers.reverse() {
            if layer.visible == true{
                if let tile = layer.tileAt(coord) {
                    return tile
                }
            }
        }
        return nil
    }
    
    // MARK: - Objects
    
    /**
     Return all of the current tile objects.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects() -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            if let node = node as? SKTileObject {
                result.append(node)
            }
        }
        return result
    }
    
    /**
     Return objects matching a given type.
     
     - parameter type: `String` object name to query.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(ofType type: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectType = node.type {
                    if objectType == type {
                        result.append(node)
                    }
                }
            }
        }
        return result
    }
    
    /**
     Return objects matching a given name.
     
     - parameter named: `String` object name to query.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(named: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectName = node.name {
                    if objectName == named {
                        
                        result.append(node)
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Data
    /**
     Returns data for a global tile id.
     
     - parameter gid: `Int` global tile id.
     - returns: `SKTilesetData` tile data, if it exists.
     */
    public func getTileData(gid: Int) -> SKTilesetData? {
        for tileset in tileSets {
            if let tileData = tileset.getTileData(gid) {
                return tileData
            }
        }
        return nil
    }
    
    // MARK: - Coordinates
    
    
    /**
     Returns a touch location in negative-y space.
     
     *Position is in converted space*
     
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS)
    public func touchLocation(touch: UITouch) -> CGPoint {
        return baseLayer.touchLocation(touch)
    }
    #endif
    
    /**
     Returns a mouse event location in negative-y space.
     
     *Position is in converted space*
    
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(OSX)
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return baseLayer.mouseLocation(event)
    }
    #endif
    
    
    public func positionInMap(point: CGPoint) -> CGPoint {
        return convertPoint(point, toNode: baseLayer).invertedY
    }
}


// MARK: - Extensions


public extension TilemapOrientation {
    
    /// Hint for aligning tiles within each layer.
    public var alignmentHint: CGPoint {
        switch self {
        case .orthogonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .isometric:
            return CGPoint(x: 0.5, y: 0.5)
        case .hexagonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .staggered:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }
}


extension LayerPosition: CustomStringConvertible {
    
    internal var description: String {
        return "\(name): (\(self.anchorPoint.x), \(self.anchorPoint.y))"
    }
    
    internal var name: String {
        switch self {
        case .bottomLeft: return "Bottom Left"
        case .center: return "Center"
        case .topRight: return "Top Right"
        }
    }
    
    internal var anchorPoint: CGPoint {
        switch self {
        case .bottomLeft: return CGPoint(x: 0, y: 0)
        case .center: return CGPoint(x: 0.5, y: 0.5)
        case .topRight: return CGPoint(x: 1, y: 1)
        }
    }
}


extension SKTilemap {
    
    // convenience properties
    public var width: CGFloat { return size.width }
    public var height: CGFloat { return size.height }
   
    /// Returns the current tile width
    public var tileWidth: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.width) & ~1)
        default:
            return tileSize.width
        }
    }
    
    /// Returns the current tile height
    public var tileHeight: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.height) & ~1)
        default:
            return tileSize.height
        }
    }
    
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }
    
    // hexagonal/staggered
    public var staggerX: Bool { return (staggeraxis == .x) }
    public var staggerEven: Bool { return staggerindex == .even }
    
    public var sideLengthX: CGFloat { return (staggeraxis == .x) ? CGFloat(hexsidelength) : 0 }
    public var sideLengthY: CGFloat { return (staggeraxis == .y) ? CGFloat(hexsidelength) : 0 }
    
    public var sideOffsetX: CGFloat { return (tileWidth - sideLengthX) / 2 }
    public var sideOffsetY: CGFloat { return (tileHeight - sideLengthY) / 2 }
    
    // coordinate grid values for hex/staggered
    public var columnWidth: CGFloat { return sideOffsetX + sideLengthX }
    public var rowHeight: CGFloat { return sideOffsetY + sideLengthY }
    
    // MARK: - Hexagonal / Staggered methods
    /**
     Returns true if the given x-coordinate represents a staggered column.
     
     - parameter x:  `Int` map x-coordinate.
     - returns: `Bool` column should be staggered.
     */
    public func doStaggerX(x: Int) -> Bool {
        return staggerX && Bool((x & 1) ^ staggerEven.hashValue)
    }
    
    /**
     Returns true if the given y-coordinate represents a staggered row.
     
     - parameter x:  `Int` map y-coordinate.
     - returns: `Bool` row should be staggered.
     */
    public func doStaggerY(y: Int) -> Bool {
        return !staggerX && Bool((y & 1) ^ staggerEven.hashValue)
    }
    
    public func topLeft(x: CGFloat, _ y: CGFloat) -> CGPoint {
        // pointy-topped
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y - 1)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        } else {
            // if the value of x is odd & stagger index is odd
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        }
    }
    
    public func topRight(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y - 1)
            } else {
                return CGPoint(x: x, y: y - 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y)
            } else {
                return CGPoint(x: x + 1, y: y - 1)
            }
        }
    }
    
    public func bottomLeft(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y + 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y)
            }
        }
    }
    
    public func bottomRight(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x, y: y + 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x + 1, y: y)
            }
        }
    }
    
    override public var description: String {
        var tilemapName = "(None)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        let renderSizeDesc = "\(sizeInPoints.width.roundTo(1)) x \(sizeInPoints.height.roundTo(1))"
        let sizeDesc = "\(Int(size.width)) x \(Int(size.height))"
        let tileSizeDesc = "\(Int(tileSize.width)) x \(Int(tileSize.height))"
        
        return "Map: \(tilemapName), \(renderSizeDesc): (\(sizeDesc) @ \(tileSizeDesc))"
    }
    
    override public var debugDescription: String { return description }
    
    /// Visualize the current grid & bounds.
    public var debugDraw: Bool {
        get {
            return baseLayer.debugDraw
        } set {
            guard newValue != baseLayer.debugDraw else { return }
            baseLayer.debugDraw = newValue
            baseLayer.showGrid = newValue
            showObjects = newValue
        }
    }
    
    /**
     Prints out all the data it has on the tilemap's layers.
     */
    public func debugLayers(reverse: Bool = false) {
        guard (layerCount > 0) else { return }
        let largestName = layerNames().maxElement() { (a, b) -> Bool in a.characters.count < b.characters.count }
        let nameStr = "# Tilemap \"\(name!)\": \(layerCount) Layers:"
        let filled = String(repeating: "-", count: nameStr.characters.count)!
        print("\n\(nameStr)\n\(filled)")
        
        var layersToPrint = allLayers()
        if reverse == true {
            layersToPrint = allLayers().reverse()
        }
        
        for layer in layersToPrint {
            if (layer != baseLayer) {
                let layerName = layer.name!
                let nameString = "\"\(layerName)\""
                print("\(layer.index): \(layer.layerType.stringValue.capitalizedString.zfill(6, pattern: " ", padLeft: false)) \(nameString.zfill(largestName!.characters.count + 2, pattern: " ", padLeft: false))   pos: \(layer.position.roundTo(1)), size: \(layer.sizeInPoints.roundTo(1)),  offset: \(layer.offset.roundTo(1)), anc: \(layer.anchorPoint.roundTo()), z: \(layer.zPosition.roundTo())")
                
            }
        }
        print("\n")
    }
}
