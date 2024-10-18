//
//  MCMetrics.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/30/24.
//  Copyright © 2024 NGA. All rights reserved.
//

import Foundation
import MatomoTracker

@objc class MCMetrics: NSObject {
    static let MATOMO_URL = "https://webanalytics.nga.mil/matomo.php"
    static let MATOMO_SITE_ID = "291"
    
    @objc static let shared = MCMetrics()
    
    private override init () {}
    
    func appRoute(_ route: [String]) {
        MatomoTracker.shared?.track(view: route)
        NSLog("Matomoing")
    }
    
    @objc func appLaunch() {
        NSLog("Record App Launch")
        appRoute(["launch"])
    }
    
    @objc func showMap() {
        NSLog("Record Show Map")
        appRoute(["showMap"])
    }
    
    @objc func showGeoPackageList() {
        NSLog("Record Show GeoPackage List")
        appRoute(["geoPackageList"])
    }
    
    @objc func download() {
        NSLog("Record Download View")
        appRoute(["downloadView"])
    }
    
    @objc func newGeoPackage() {
        NSLog("Record New GeoPackage")
        appRoute(["newGeoPackage"])
    }
    
    @objc func settings() {
        NSLog("Record Show Settings")
        appRoute(["settingsView"])
    }
    
    @objc func newServer() {
        NSLog("Record New Server")
        appRoute(["newServerView"])
    }
    
    @objc func newServerHelp() {
        NSLog("Record New Server Help")
        appRoute(["newServerHelp"])
    }
    
    @objc func about() {
        NSLog("Record About")
        appRoute(["about"])
    }
    
    @objc func geoPackageDetails() {
        NSLog("Record GeoPackage Details")
        appRoute(["geoPackageDetails"])
    }
    
    @objc func tileLayerDetails() {
        NSLog("Record Tile Layer Details")
        appRoute(["tileLayerDetails"])
    }
    
    @objc func featureLayerDetails() {
        NSLog("Record Feature Layer Details")
        appRoute(["featureLayerDetails"])
    }
    
    @objc func newOfflineMap() {
        NSLog("Record New Offline Map")
        appRoute(["newOfflineMap"])
    }
    
    @objc func tileLayerChooseServer() {
        NSLog("Record Choose Tile Server")
        appRoute(["chooseTileServer"])
    }
    
    @objc func tileLayerBoundingBox() {
        NSLog("Record Bounding Box")
        appRoute(["boundingBox"])
    }
    
    @objc func tileLayerZoomSettings() {
        NSLog("Record Zoom Settings")
        appRoute(["zoomSettings"])
    }
    
    @objc func newFeature() {
        NSLog("Record New Feature")
        appRoute(["newFeature"])
    }
    
    @objc func showFeature() {
        NSLog("Record Show Feature")
        appRoute(["showFeature"])
    }
    
    @objc func newField() {
        NSLog("Record New Field")
        appRoute(["newField"])
    }
    
    @objc func newFeatureAttachment() {
        NSLog("Record New Attachment")
        appRoute(["newAttachment"])
    }
    
    @objc func viewFeatureAttachment() {
        NSLog("Record View Attachment")
        appRoute(["viewFeatureAttachment"])
    }
    
    @objc func dispatch() {
        NSLog("Dispatching Matomo Metrics")
        MatomoTracker.shared?.dispatch()
    }
}

extension MatomoTracker {
    static let shared: MatomoTracker? = MatomoTracker(siteId: MCMetrics.MATOMO_SITE_ID, baseURL: URL(string: MCMetrics.MATOMO_URL)!)
}
