//
//  MCLayerCoordinator.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 5/19/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import UIKit

@objc class MCLayerCoordinator: NSObject, MCLayerOperationsDelegate, MCCreateLayerFieldDelegate {
    var table: MCTable
    var drawerViewDelegate: NGADrawerViewDelegate
    
    @objc public init(table: MCTable, drawerDelegate: NGADrawerViewDelegate) {
        self.drawerViewDelegate = drawerDelegate
        self.table = table
        super.init()
    }
    
    
    @objc public func start() {
        if let layerViewController = MCLayerViewController(asFullView: true) {
            layerViewController.table = self.table
            layerViewController.delegate = self
            layerViewController.columns = MCGeoPackageRepository.shared().columns(for: table)
            layerViewController.drawerViewDelegate = self.drawerViewDelegate
            layerViewController.pushOntoStack()
        }
    }
    
    
    //MARK: MCLayerOperationsDelegate
    func deleteLayer() {
        //TODO: fill in
        print("MCLayerCoordinator deleteLayer")
    }
    
    
    func createOverlay() {
        //TODO: fill in
        print("MCLayerCoordinator createOverlay")
    }
    
    
    func indexLayer() {
        //TODO: fill in
        print("MCLayerCoordinator indexLayer")
    }
    
    
    func createTiles() {
        //TODO: fill in
        print("MCLayerCoordinator createTiles")
    }
    
    
    func renameLayer(_ layerName: String!) {
        //TODO: fill in
        print("MCLayerCoordinator renameLayer")
    }
    
    
    func showTileScalingOptions() {
        //TODO: fill in
        print("MCLayerCoordinator showTileScalingOptions")
    }
    
    
    func showFieldCreationView() {
        let fieldViewController = MCCreateLayerFieldViewController(asFullView: true)
        fieldViewController?.drawerViewDelegate = self.drawerViewDelegate
        fieldViewController?.createLayerFieldDelegate = self
        fieldViewController!.pushOntoStack()
    }
    
    
    func layerViewDidClose() {
        MCGeoPackageRepository.shared().selectedLayerName = ""
    }
    
    
    //MARK: MCCreateLayerFieldDelegate
    func createField(name: String, type: GPKGDataType) {
        if let column = GPKGFeatureColumn.createColumn(withName: name, andDataType: type) {
            let didAdd = MCGeoPackageRepository.shared().add(column, to: table)
            
            if (didAdd) {
                
            }
            
        }
        
        
    }
}
