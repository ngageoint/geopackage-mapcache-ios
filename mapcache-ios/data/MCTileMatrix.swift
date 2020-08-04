//
//  MCTileMatrix.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation

class MCTileMatrix: NSObject {
    
    @objc var zoomLevel: NSNumber = 0
    @objc var tileCount: NSNumber = 0
    @objc var matrixWidth: NSNumber = 0
    @objc var matrixHeight: NSNumber = 0
    @objc var tileWidth: NSNumber = 0
    @objc var tileHeight: NSNumber = 0
    @objc var pixelXSize: NSDecimalNumber = 0.0
    @objc var pixelYSize: NSDecimalNumber = 0.0
    
}
