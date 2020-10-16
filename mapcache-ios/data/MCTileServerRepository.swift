//
//  MCWMSUtil.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/28/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation


enum MCTileServerError: Error {
    case badURL, badResponse, unknown, none
}

@objc class MCTileServerResult: NSObject {
    @objc public private(set) var success: Any?
    @objc public private(set) var failure: Error?
    
    private override init() {
        super.init()
        success = nil
        failure = nil
    }
    
    public convenience init<Success, Failure>(_ arg1: Success, _ arg2: Failure) where Failure: Error {
        self.init()
        success = arg1
        failure = arg2
    }
}



@objc class MCTileServerRepository: NSObject, XMLParserDelegate {
    static let _sharedInstance = MCTileServerRepository()
    
    var tileServers: [String:MCTileServer] = [:]
    var layers: [MCLayer] = []
    
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
    
    @objc class func sharedInstance() -> MCTileServerRepository {
        return MCTileServerRepository._sharedInstance
    }
    
    @objc func isValidServerURL(urlString: String, completion: @escaping (MCTileServerResult) -> Void) {
        var tryXYZ = false;
        var tryWMS = false;
        var editedURLString = urlString
        
        if (!urlString.range(of: "{x}")!.isEmpty && !urlString.range(of: "{y}")!.isEmpty && !urlString.range(of: "{x}")!.isEmpty) {
            
            editedURLString.replaceSubrange(editedURLString.range(of: "{x}")!, with: "0")
            editedURLString.replaceSubrange(editedURLString.range(of: "{y}")!, with: "0")
            editedURLString.replaceSubrange(editedURLString.range(of: "{z}")!, with: "0")
            tryXYZ = true
        } else {
            tryWMS = true
        }
        
        guard let url:URL = URL.init(string: editedURLString) else {
            return // TODO: call results block
        }
        
        if (tryXYZ) {
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                
            }.resume()
            
        } else if (tryWMS) {
            // TODO: hook up WMS GetCapabilities and parse to verify URL
        } else {
            let server = MCTileServer.init(url: URL.init(string: "")!, serverName: "")
            let result = MCTileServerResult.init(server, MCTileServerError.unknown)
            completion(result)
        }
    }

    
    @objc public func getCapabilites(url:String, completion: @escaping (_ result: MCTileServerResult) -> Void) {
        if let wmsURL = URL.init(string: url) {
            let baseURL = wmsURL.scheme! + "://" + wmsURL.host! + wmsURL.path
            
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
                    
                    let server = MCTileServer.init(url: URL.init(string: (builtURL?.string)!)!, serverName: (builtURL?.string)!)
                    let result = MCTileServerResult.init(server, MCTileServerError.none)
                    completion(result)
                } else {
                    print("oh noes")
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
}
