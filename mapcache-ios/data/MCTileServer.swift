//
//  MCTileServer.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/6/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation

@objc class MCLayer: NSObject {
    @objc var format: String = ""
    @objc var crs: String = ""
    @objc var title: String = ""
    @objc var name: String = ""
}

@objc class MCTileServer: NSObject {
    @objc var url: URL
    @objc var serverName: String?
    @objc var layers: [MCLayer] = []
    
    
    @objc init(url: URL, serverName: String) {
        self.url = url
        self.serverName = serverName
    }
}
