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


@objc class MCLayer: NSObject {
    @objc var format: String = ""
    @objc var crs: String = ""
    @objc var title: String = ""
    @objc var name: String = ""
}


@objc class MCTileServer: NSObject {
    @objc var serverName: String
    @objc var url: URL?
    @objc var layers: [MCLayer] = []
    @objc var serverType: MCTileServerType = .error
    
    
    @objc init(serverName: String) {
        self.serverName = serverName
        self.url = nil
    }
    
    @objc func urlForLayer(index:Int) -> String {
        guard self.serverType == .wms else {
            return ""
        }
        
        if var components = URLComponents(string: self.url!.absoluteString) {
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
                //URLQueryItem(name: "bbox", value: "{minLon},{minLat},{maxLon},{maxLat}")
            ]
            
            return components.url!.absoluteString
        }
        
        return ""
    }

}
