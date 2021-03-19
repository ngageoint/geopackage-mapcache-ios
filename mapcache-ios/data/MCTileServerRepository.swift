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
        self.loadUserDefaults()
    }
    
    var tileServers: [String:MCTileServer] = [:]
    var layers: [MCLayer] = []
    
    // Objects for keeping track of which tile server and or layer are being used as basemaps managed by the settings view controller and displayed on the map.
    
    /** Object for keeping track of the user basemap.  */
    @objc var baseMapServer:MCTileServer = MCTileServer.init();
    
    /** In the case of a WMS server you will also need to set which layer the user wanted to use as a basemap. Not needed and can be left as default for XYZ servers. */
    @objc var baseMapLayer:MCLayer = MCLayer.init();
    
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
    var layerTitleStack: [String] = []
    
    
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
                        let result = MCTileServerResult.init(tileServer, self.generateError(message: "Unable to get tile", errorType: MCServerErrorType.MCNoData))
                        
                        completion(result)
                        return
                    }

                    tileServer.serverType = .xyz
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
            let error:MCServerError = MCServerError.init(domain: "MCTileServerRepository", code: MCServerErrorType.MCURLInvalid.rawValue, userInfo: ["message" : "Invalid URL"])
            completion(MCTileServerResult.init(tileServer, error))
        }
    }

    
    @objc public func getCapabilites(url:String, completion: @escaping (MCTileServerResult) -> Void) {
        if let wmsURL = URL.init(string: url) {
            let baseURL:String = wmsURL.scheme! + "://" + wmsURL.host! + wmsURL.path
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
                    completion(MCTileServerResult.init(tileServer, self.generateError(message: error?.localizedDescription ?? "Server error", errorType: .MCTileServerParseError)))
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
                    
                    tileServer.serverType = .wms
                    tileServer.url = (builtURL?.string)!
                    tileServer.layers = self.layers
                    self.layers = []
                    
                    completion(MCTileServerResult.init(tileServer, self.generateError(message: "No error", errorType: MCServerErrorType.MCNoError)))
                } else if (parser.parserError != nil) {
                    print("Parser error")
                    tileServer.serverType = .error
                    self.layers = []
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
        
        /*var spaces = ""
        for _ in 1...level {
            spaces = spaces + "\t"
        }
        
        print("\(spaces) \(level) \(elementName)")*/
        
        if elementName == layerKey {
            if (topLevelLayer.title == "") {
                topLevelLayer = currentLayer
                layers.append(topLevelLayer)
            }
            currentLayer = MCLayer()
        }
        
        currentValue = ""
    }

    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }


    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        level -= 1
        if elementName == layerKey {
            if (currentLayer.title != "") {
                currentLayer.titles = self.layerTitleStack
                layers.append(currentLayer)
                self.layerTitleStack.popLast()
            } else {
                if (self.layerTitleStack.count > 0) {
                    self.layerTitleStack.popLast()
                }
            }
            
            currentLayer = MCLayer()
        } else if dictionaryKeys.contains(elementName) {
            if elementName == "CRS" && currentValue == "EPSG:3857" {
                currentLayer.crs = currentValue
            } else if elementName ==  "Title" {
                if (tagStack.count > 2 && tagStack[tagStack.count - 2] == "Layer"){
                    print("topLevelLayer.title: \(self.topLevelLayer.title) currentValue: \(currentValue)")
                    currentLayer.title = currentValue
                    self.layerTitleStack.append(currentValue)
                }
            } else if elementName == "Name" {
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
                //print("hmm, something unexpected found \(currentValue)")
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
    
    
    @objc func saveToUserDefaults(serverName:String, url:String, tileServer:MCTileServer) -> Bool {
        tileServer.serverName = serverName
        
        if var savedServers = self.userDefaults.dictionary(forKey: MC_SAVED_TILE_SERVER_URLS) {
            savedServers[serverName] = url
            self.userDefaults.setValue(savedServers, forKey: MC_SAVED_TILE_SERVER_URLS)
            self.tileServers[serverName] = tileServer
            return true
        } else {
            let savedServers = NSMutableDictionary()
            savedServers[serverName] = url
            self.userDefaults.setValue(savedServers, forKey: MC_SAVED_TILE_SERVER_URLS)
            self.tileServers[serverName] = tileServer
            return true
        }
        
        return false
    }
    
    
    @objc func setBasemap(tileServer:MCTileServer?, layer:MCLayer?) {
        if let updatedServer = tileServer, let updatedLayer = layer {
            self.baseMapServer = updatedServer
            self.baseMapLayer = updatedLayer
            saveBasemapToUserDefaults(serverName: updatedServer.serverName, layerName: updatedLayer.name)
        } else {
            saveBasemapToUserDefaults(serverName: "", layerName: "")
        }
    }
    
    
    @objc func saveBasemapToUserDefaults(serverName:String, layerName:String) {
        self.userDefaults.setValue(serverName, forKey: MC_USER_BASEMAP_SERVER_NAME)
        self.userDefaults.setValue(layerName, forKey: MC_USER_BASEMAP_LAYER_NAME)
        self.userDefaults.synchronize()
    }
    
    
    @objc func removeTileServerFromUserDefaults(serverName:String) {
        // get the defaults
        if var savedServers = self.userDefaults.dictionary(forKey: MC_SAVED_TILE_SERVER_URLS) {
            savedServers.removeValue(forKey: serverName)
            self.tileServers.removeValue(forKey: serverName)
            self.userDefaults.setValue(savedServers, forKey: MC_SAVED_TILE_SERVER_URLS)
        }
        
        // check if the server that was deleted was a being used as a basemap, and if so delete it
        if let currentBasemap:String = self.userDefaults.object(forKey: MC_USER_BASEMAP_SERVER_NAME) as? String {
            if (currentBasemap.elementsEqual(serverName)) {
                self.saveBasemapToUserDefaults(serverName: "", layerName: "")
            }
        }
    }
    
    
    // Load or refresh the tile server list from UserDefaults.
    @objc func loadUserDefaults() {
        if let savedServers = self.userDefaults.dictionary(forKey: MC_SAVED_TILE_SERVER_URLS) {
            for serverName in savedServers.keys {
                if let serverURL = savedServers[serverName] {
                    print("\(serverName) \(serverURL)")
                    var numberOfServersLoaded = 0
                    
                    self.isValidServerURL(urlString: serverURL as! String) { (tileServerResult) in
                        let serverError:MCServerError = tileServerResult.failure as! MCServerError
                        
                        if (serverError.code == MCServerErrorType.MCNoError.rawValue) {
                            print("valid test URL")
                            let tileServer = tileServerResult.success as? MCTileServer
                            tileServer?.serverName = serverName
                            self.tileServers[serverName] = tileServer
                        } else {
                            let tileServer = tileServerResult.success as? MCTileServer
                            tileServer?.serverName = serverName
                            tileServer?.serverType = .error
                            self.tileServers[serverName] = tileServer
                        }
                        
                        numberOfServersLoaded += 1
                        if (numberOfServersLoaded == savedServers.keys.count) {
                            self.loadBasemapsFromUserDefaults()
                        }
                    }
                }
            }
        }
    }
    
    
    @objc func loadBasemapsFromUserDefaults() {
        if let savedBasemapServerName = self.userDefaults.string(forKey: MC_USER_BASEMAP_SERVER_NAME) {
            if self.tileServers.keys.contains(savedBasemapServerName), let server = self.tileServers[savedBasemapServerName] {
                self.baseMapServer = server
                
                if let savedBasemapLayerName = self.userDefaults.string(forKey: MC_USER_BASEMAP_LAYER_NAME) {
                    for layer in server.layers {
                        if (layer.name == savedBasemapLayerName) {
                            self.baseMapLayer = layer
                            break
                        }
                    }
                } else {
                    self.baseMapLayer = MCLayer()
                }
            } else {
                self.baseMapServer = MCTileServer()
            }
        } else {
            self.baseMapServer = MCTileServer()
            self.baseMapLayer = MCLayer()
        }
        
        NotificationCenter.default.post(name: Notification.Name(MC_USER_BASEMAP_LOADED_FROM_DEFAULTS), object: nil)
    }
    
    
    @objc func getTileServers() -> [String:MCTileServer] {
        return self.tileServers
    }
}
