//
//  MCTileServer.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/6/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation

@objc enum MCTileServerType: Int {
    case xyz, wms, tms, error
}


@objc class MCLayer: NSObject, NSCoding {
    static let (formatKey, crsKey, titleKey, nameKey) = ("format", "crs", "title", "name")
    
    @objc var format: String = ""
    @objc var crs: String = ""
    @objc var title: String = ""
    @objc var name: String = ""
    
    
    override init() {
        super.init()
    }
    
    
    init(format:String, crs:String, title:String, name:String) {
        super.init()
        self.format = format
        self.crs = crs
        self.title = title
        self.name = name
    }
    
    
    required convenience init?(coder: NSCoder) {
        let format = coder.decodeObject(forKey: MCLayer.formatKey) as! String
        let crs = coder.decodeObject(forKey: MCLayer.crsKey) as! String
        let title = coder.decodeObject(forKey: MCLayer.nameKey) as! String
        let name = coder.decodeObject(forKey: MCLayer.nameKey) as! String
        self.init(format: format, crs: crs, title: title, name: name)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(self.format, forKey: MCLayer.formatKey)
        coder.encode(self.crs, forKey: MCLayer.crsKey)
        coder.encode(self.title, forKey: MCLayer.titleKey)
        coder.encode(self.name, forKey: MCLayer.nameKey)
    }
}


@objc class MCTileServer: NSObject, NSCoding {
    static let (serverNameKey, urlKey, layersKey, serverTypeKey) = ("serverName", "url", "layers", "serverType")
    
    @objc var serverName: String = ""
    @objc var url: String = ""
    @objc var layers: [MCLayer] = []
    @objc var serverType: MCTileServerType = .error
    
    
    override init() {
        super.init()
    }
    
    @objc init(serverName: String) {
        self.serverName = serverName
    }
    
    
    init(serverName:String, url:String, layers:[MCLayer], serverType:MCTileServerType) {
        self.serverName = serverName
        self.url = url
        self.layers = layers
        self.serverType = serverType
    }
    
    
    required convenience init?(coder: NSCoder) {
        let serverName = coder.decodeObject(forKey: MCTileServer.serverNameKey) as! String
        //let layers = coder.decodeArrayOfObjects(ofClass: MCLayer, forKey: MCTileServer.layersKey)
        let url = coder.decodeObject(forKey: MCTileServer.urlKey) as! String
        let serverType = coder.decodeObject(forKey: MCTileServer.serverTypeKey) as! MCTileServerType
        
        self.init(serverName:serverName, url: url, layers:[], serverType:serverType)
    }
    
    
    func encode(with coder:NSCoder) {
        
    }
    
    
    /**
        Creates a URL that can be used to preview or download tiles for a given WMS layer.
        - Parameter index: the layer that you would like to build the layer for
        - Parameter boundingBoxTemplate: Add the bounding box template to the end of the URL, this should only be used when downloading tiles
     */
    @objc func urlForLayer(index:Int, boundingBoxTemplate:Bool) -> String {
        guard self.serverType == .xyz else {
            return self.url
        }
        
        if let url = URL.init(string: self.url) {
            if var components = URLComponents(string: url.absoluteString) {
                print("building url..")
                
                let layer:MCLayer = self.layers[index]
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
                ]
                
                var urlString = components.url!.absoluteString
                
                if (boundingBoxTemplate) {
                    urlString = urlString + "&bbox={minLon},{minLat},{maxLon},{maxLat}"
                }
                
                return urlString
            }
        }
        
        return ""
    }

}
