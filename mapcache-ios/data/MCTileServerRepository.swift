//
//  MCWMSUtil.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/28/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation


@objc class MCTileServerRepository: NSObject, XMLParserDelegate {
    @objc static let shared = MCTileServerRepository()
    
    private override init() {
        super.init()
        self.loadUserPreferences()
    }
    
    var tileServers: [String:MCTileServer] = [:]
    var layers: [MCLayer] = []
    
    // Arrays for keeping track of which tile servers and layers are being used as basemaps managed by the settings view controller and displayed on the map.
    var xyzBaseMaps: [MCTileServer] = [];
    var wmsLayerBaseMaps: [MCLayer] = [];
    
    // URL query parameters
    let getCapabilities = "request=GetCapabilities"
    let getMap = "request=GetMap"
    let service = "service=WMS"
    let version = "version=1.3.0"
    let bboxTemplate = "bbox={minLon},{minLat},{maxLon},{maxLat}"
    let webMercatorEPSG = "crs=EPSG:3857"
    
    // a few constants that identify what element names we're looking for inside the XML
    let layerKey = "Layer"
    let getMapKey = "GetMap"
    let formatKey = "Format"
    let dictionaryKeys = Set<String>(["CRS", "Name", "Title", "Name", "Format"])
    
    let userDefaults = UserDefaults.standard;
    var layerDictionary = NSMutableDictionary()
    var formats: [String] = []
    var currentValue = String() // the current value that the parser is handling
    var currentTag = String()
    var parentTag = String()
    var topLevelLayer = MCLayer()
    var currentLayer = MCLayer()
    var urlString = ""
    var level = 0
    var tagStack: [String] = []
    
    
    @objc func tileServerForURL(urlString: String) -> MCTileServer {
        if let tileServer:MCTileServer = self.tileServers[urlString] {
            return tileServer
        }
        
        
        return MCTileServer.init(serverName: "")
    }
    
    
    @objc func isValidServerURL(urlString: String, completion: @escaping (MCTileServerResult) -> Void) {
        var tryXYZ = false;
        var tryWMS = false;
        var editedURLString = urlString
        let tileServer = MCTileServer.init(serverName: urlString)
        tileServer.url = urlString;
        
        if (urlString.contains("{x}") && urlString.contains("{y}") && urlString.contains("{x}")) {
            
            editedURLString.replaceSubrange(editedURLString.range(of: "{x}")!, with: "0")
            editedURLString.replaceSubrange(editedURLString.range(of: "{y}")!, with: "0")
            editedURLString.replaceSubrange(editedURLString.range(of: "{z}")!, with: "0")
            tryXYZ = true
        } else {
            tryWMS = true
        }
        
        guard let url:URL = URL.init(string: editedURLString) else {
            tileServer.serverType = .error
            let result = MCTileServerResult.init(tileServer, self.generateError(message: "Invalid URL", errorType: MCServerErrorType.MCURLInvalid))
            
            completion(result)
            return
        }
        
        if (tryXYZ) {
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                do {
                    guard let tile = UIImage.init(data: try Data.init(contentsOf: location!)) else {
                        tileServer.serverType = .error
                        let result = MCTileServerResult.init(tileServer, self.generateError(message: "Ubable to get tile", errorType: MCServerErrorType.MCNoData))
                        
                        completion(result)
                        return
                    }

                    tileServer.serverType = .xyz
                    self.tileServers[urlString] = tileServer
                    completion(MCTileServerResult.init(tileServer, self.generateError(message: "No error", errorType: MCServerErrorType.MCNoError)))
                } catch {
                    tileServer.serverType = .error
                    let error:MCServerError = MCServerError.init(domain: "MCTileServerRepository", code: MCServerErrorType.MCTileServerNoResponse.rawValue, userInfo: ["message" : "no response from server"])
                    let result = MCTileServerResult.init(tileServer, self.generateError(message: "No response from server", errorType: MCServerErrorType.MCTileServerNoResponse))
                    completion(result)
                }
            }.resume()
            
        } else if (tryWMS) {
            self.getCapabilites(url: urlString, completion: completion)
        } else {
            tileServer.serverType = .error
            let error:MCServerError = MCServerError.init(domain: "MCTileServerRepository", code: MCServerErrorType.MCURLInvalid.rawValue, userInfo: ["message" : "invalid URL"])
            completion(MCTileServerResult.init(tileServer, error))
        }
    }

    
    @objc public func getCapabilites(url:String, completion: @escaping (MCTileServerResult) -> Void) {
        if let wmsURL = URL.init(string: url) {
            let baseURL = wmsURL.scheme! + "://" + wmsURL.host! + wmsURL.path
            let tileServer = MCTileServer.init(serverName: self.urlString)
            self.layers = []
            
            var builtURL = URLComponents(string: baseURL)
            builtURL?.queryItems = [
                URLQueryItem(name: "request", value: "GetCapabilities"),
                URLQueryItem(name: "service", value: "WMS"),
                URLQueryItem(name: "version", value: "1.3.0")
            ]
            
            let task = URLSession.shared.dataTask(with: (builtURL?.url)!) { data, response, error in
                guard let data = data, error == nil else {
                    print(error ?? "Unknown error")
                    return
                }
                
                let parser = XMLParser(data: data)
                parser.delegate = self
                
                if parser.parse() {
                    print("have \(self.layers.count) layers")
                    
                    for layer in self.layers {
                        print("Title: \(layer.title)")
                        print("Name: \(layer.name)")
                        print("CRS: \(layer.crs)")
                        print("Format: \(layer.format)\n\n")
                    }
                    
                    self.buildMapCacheURLs(url: url)
                    tileServer.serverType = .wms
                    tileServer.url = (builtURL?.string)!
                    tileServer.layers = self.layers
                    self.tileServers[url] = tileServer
                    
                    completion(MCTileServerResult.init(tileServer, self.generateError(message: "No error", errorType: MCServerErrorType.MCNoError)))
                } else {
                    tileServer.serverType = .error
                    let error:MCServerError = MCServerError.init(domain: "MCTileServerRepository", code: MCServerErrorType.MCURLInvalid.rawValue, userInfo: ["message" : "invalid URL"])
                    completion(MCTileServerResult.init(tileServer, error))
                }
            }
            task.resume()
        } else {
            print("Invalid URL")
        }
    }
    
    
    func buildMapCacheURLs(url:String) {
        if var components = URLComponents(string: url) {
            print("building url..")
            for layer in layers {
                components.queryItems = [
                    URLQueryItem(name: "service", value: "WMS"),
                    URLQueryItem(name: "request", value: "GetMap"),
                    URLQueryItem(name: "layers", value: layer.name),
                    URLQueryItem(name: "styles", value: ""),
                    URLQueryItem(name: "format", value: layer.format),
                    URLQueryItem(name: "transparent", value: "true"),
                    URLQueryItem(name: "version", value: "1.3.0"),
                    URLQueryItem(name: "width", value: "256"),
                    URLQueryItem(name: "height", value: "256"),
                    URLQueryItem(name: "crs", value: layer.crs),
                    URLQueryItem(name: "bbox", value: "{minLon},{minLat},{maxLon},{maxLat}")
                ]
                
                print(components.url!.absoluteString)
            }
        }
    }
    
    
    // MARK: WMS XML parsing
    func parserDidStartDocument(_ parser: XMLParser) {
        print("parserDidStartDocument")
    }


    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        level += 1
        tagStack.append(elementName)
        
        var spaces = ""
        for _ in 1...level {
            spaces = spaces + "\t"
        }
        
        print("\(spaces) \(level) \(elementName)")
        if elementName == layerKey {
            if (topLevelLayer.title == "" && topLevelLayer.title != "") {
                topLevelLayer = currentLayer
                layers.append(topLevelLayer)
            }
            currentLayer = MCLayer()
        }
        
        currentValue = ""
    }

    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        //print("found characters")
        currentValue += string
        //print("\t\(string)")
    }


    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        level -= 1
        //print("did end element")
        //print(elementName)
        if elementName == layerKey {
            print("found a layer")
            print("adding currentLayer to layer")
            if (currentLayer.title != "") {
                layers.append(currentLayer)
            }
            
            currentLayer = MCLayer()
        } else if dictionaryKeys.contains(elementName) {
            print("found layer details")
            
            if elementName == "CRS" && currentValue == "EPSG:3857" {
                currentLayer.crs = currentValue
            } else if elementName ==  "Title" {
                if (tagStack.count > 2 && tagStack[tagStack.count - 2] == "Layer"){
                    currentLayer.title = currentValue
                }
            } else if elementName == "Name" {
                print("************** Name Tag \(tagStack[tagStack.count - 2])")
                if (tagStack.count > 2 && tagStack[tagStack.count - 2] == "Layer"){
                    currentLayer.name = currentValue
                }
            } else if elementName ==  "Format" && currentLayer.format == "" {
                if currentValue == "image/jpeg" {
                    currentLayer.format = "image/jpeg"
                } else if currentValue == "image/png" {
                    currentLayer.format = "image/png"
                }
                
            } else {
                print("hmm, something unexpected found \(currentValue)")
            }
        } else if elementName == formatKey {
            formats.append(currentValue)
        }
        
        currentValue = String()
        tagStack.popLast()
    }

    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)

        currentValue = String()
        
    }
    
    func generateError(message:String, errorType: MCServerErrorType) -> MCServerError {
        return MCServerError.init(domain: "MCTileServerRepository", code: errorType.rawValue, userInfo: ["message" : message])
    }
    
    
    // TODO: function to save a tile server to the UserDefaults
    
    // TODO: function to remove a tile server from UserDefaults
    
    
    // function to refresh the tile server list from UserDefaults
    @objc func loadUserPreferences() {
        print(self.userDefaults.dictionaryRepresentation())
        
        if let savedServers = self.userDefaults.dictionary(forKey: MC_SAVED_TILE_SERVER_URLS) {
            for server in savedServers.keys {
                // TODO: check the URL and add it to the dictionary
            }
        }
        
        // test code for checking map functionality
        self.isValidServerURL(urlString: "https://basemap.nationalmap.gov/arcgis/services/USGSTopo/MapServer/WmsServer") { (tileServerResult) in
            let serverError:MCServerError = tileServerResult.failure as! MCServerError
            
            if (serverError.code == MCServerErrorType.MCNoError.rawValue) {
                print("valid test URL")
            }
        }
        
        self.isValidServerURL(urlString: "https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png") { (tileServerResult) in
            let serverError:MCServerError = tileServerResult.failure as! MCServerError
            
            if (serverError.code == MCServerErrorType.MCNoError.rawValue) {
                print("valid test URL")
            }
        }
    }
    
    @objc func getTileServers() -> [String:MCTileServer] {
        return self.tileServers
    }
    
}
