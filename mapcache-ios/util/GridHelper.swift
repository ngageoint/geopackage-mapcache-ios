//
//  GridHelper.swift
//  mapcache-ios
//
//  Created by Brian Osborn on 9/12/22.
//  Copyright © 2022 NGA. All rights reserved.
//

import Foundation

import gars_ios
import mgrs_ios

/**
 * Grid objective c to swift helper
 */
@objc public class GridHelper : NSObject {
    
    @objc public static func garsTileOverlay() -> GARSTileOverlay {
        let tileOverlay = GARSTileOverlay()
        // Customize GARS grid as needed here
        return tileOverlay
    }
    
    @objc public static func mgrsTileOverlay() -> MGRSTileOverlay {
        let tileOverlay = MGRSTileOverlay()
        // Customize MGRS grid as needed here
        return tileOverlay
    }
    
    @objc public static func garsCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return gars(coordinate).coordinate()
    }
    
    public static func gars(_ coordinate: CLLocationCoordinate2D) -> GARS {
        return GARS.from(coordinate.longitude, coordinate.latitude)
    }

    @objc public static func mgrsCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return mgrs(coordinate).coordinate()
    }
    
    public static func mgrs(_ coordinate: CLLocationCoordinate2D) -> MGRS {
        return MGRS.from(coordinate.longitude, coordinate.latitude)
    }
    
}
