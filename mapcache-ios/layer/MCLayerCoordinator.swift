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
    var layerViewController: MCLayerViewController
    var fieldViewController: MCCreateLayerFieldViewController
    
    @objc public init(table: MCTable, drawerDelegate: NGADrawerViewDelegate) {
        self.drawerViewDelegate = drawerDelegate
        self.table = table
        self.layerViewController = MCLayerViewController(asFullView: true)
        self.fieldViewController = MCCreateLayerFieldViewController(asFullView: true)
        super.init()
    }
    
    
    @objc public func start() {
        self.layerViewController.table = self.table
        self.layerViewController.delegate = self
        self.layerViewController.columns = MCGeoPackageRepository.shared().columns(forTable: table.name, database: table.database)
        self.layerViewController.drawerViewDelegate = self.drawerViewDelegate
        self.layerViewController.pushOntoStack()
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
        self.fieldViewController.drawerViewDelegate = self.drawerViewDelegate
        self.fieldViewController.createLayerFieldDelegate = self
        self.fieldViewController.pushOntoStack()
    }
    
    
    func layerViewDidClose() {
        MCGeoPackageRepository.shared().selectedLayerName = ""
    }
    
    
    func setSelectedLayerName() {
        MCGeoPackageRepository.shared().selectedLayerName = self.table.name
        MCGeoPackageRepository.shared().selectedGeoPackageName = self.table.database
    }
    
    
    //MARK: MCCreateLayerFieldDelegate
    func createField(name: String, type: GPKGDataType) {
        if let column = GPKGFeatureColumn.createColumn(withName: name, andDataType: type) {
            let didAdd = MCGeoPackageRepository.shared().add(column, to: self.table)
            
            if (didAdd) {
                MCGeoPackageRepository.shared().regenerateDatabaseList()
                self.fieldViewController.closeDrawer()
                self.layerViewController.columns = MCGeoPackageRepository.shared().columns(forTable: self.table.name, database: self.table.database)
                self.layerViewController.update()
            }
        }
    }
}
