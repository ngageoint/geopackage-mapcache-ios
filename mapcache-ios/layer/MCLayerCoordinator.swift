//
//  MCLayerCoordinator.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 5/19/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import UIKit

@objc protocol MCLayerCoordinatorDelegate: AnyObject {
    func layerCoordinatorCompletionHandler()
}


@objc class MCLayerCoordinator: NSObject, MCLayerOperationsDelegate, MCCreateLayerFieldDelegate {       
    var table: MCTable
    var drawerViewDelegate: NGADrawerViewDelegate
    var layerViewController: MCLayerViewController
    var fieldViewController: MCCreateLayerFieldViewController
    @objc weak var layerCoordinatorDelegate:MCLayerCoordinatorDelegate?
    
    @objc public init(table:MCTable, drawerDelegate:NGADrawerViewDelegate, layerCoordinatorDelegate:MCLayerCoordinatorDelegate) {
        self.drawerViewDelegate = drawerDelegate
        self.layerCoordinatorDelegate = layerCoordinatorDelegate
        self.table = table
        self.layerViewController = MCLayerViewController(asFullView: true)
        self.fieldViewController = MCCreateLayerFieldViewController(asFullView: true)
        super.init()
    }
    
    
    @objc public func start() {
        self.layerViewController.table = self.table
        self.layerViewController.delegate = self
        
        if (self.table is MCFeatureTable) {
            self.layerViewController.columns = MCGeoPackageRepository.shared().columns(forTable: table.name, database: table.database)
        }
        
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
    
    
    func renameLayer(_ newLayerName: String!) -> Bool {
        print("MCLayerCoordinator renameLayer")
        // TODO refhresh the geopackage and hand it to the view
        let didUpdate:Bool =  MCGeoPackageRepository.shared().renameTable(self.table, toNewName: newLayerName)
        let updatedDatabase:MCDatabase = MCGeoPackageRepository.shared().databaseNamed(self.table.database)
        
        if let renamedTable = updatedDatabase.tableNamed(newLayerName) {
            self.table = renamedTable
            self.layerViewController.table = self.table
            self.layerViewController.update()
            NotificationCenter.default.post(name: Notification.Name("MC_LAYER_RENAMED"), object: nil)
        }
        
        return didUpdate
    }
    
    
    func showTileScalingOptions() {
        //TODO: fill in
        print("MCLayerCoordinator showTileScalingOptions")
    }
    
    
    func renameColumn(_ column: GPKGUserColumn!, name: String!) {
        self.layerViewController.columns = MCGeoPackageRepository.shared().renameColumn(column, newName: name, table: self.table)
        let updatedDatabase:MCDatabase = MCGeoPackageRepository.shared().databaseNamed(self.table.database)
        self.table = updatedDatabase.tableNamed(self.table.name)
        self.layerViewController.table = self.table
        self.layerViewController.update()
    }
    
    
    func delete(_ column: GPKGUserColumn!) {
        MCGeoPackageRepository.shared().delete(column, table: self.table)
        self.layerViewController.columns = MCGeoPackageRepository.shared().columns(forTable: self.table.name, database: self.table.database)
        self.layerViewController.update()
    }
    
    
    func showFieldCreationView() {
        self.fieldViewController = MCCreateLayerFieldViewController(asFullView: true)
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
    
    
    func layerViewCompletionHandler() {
        layerCoordinatorDelegate?.layerCoordinatorCompletionHandler()
    }
    
    //MARK: MCCreateLayerFieldDelegate
    func createField(name: String, type: GPKGDataType) {
        if let column = GPKGFeatureColumn.createColumn(withName: name, andDataType: type) {
            let didAdd = MCGeoPackageRepository.shared().add(column, to: self.table)
            
            if (didAdd) {
                MCGeoPackageRepository.shared().refreshDatabaseAndUpdateList(self.table.database)
                self.fieldViewController.closeDrawer()
                self.layerViewController.columns = MCGeoPackageRepository.shared().columns(forTable: self.table.name, database: self.table.database)
                self.layerViewController.update()
            }
        }
    }
    
    
    func checkFieldNameCollision(name: String) -> Bool {
        let columns = MCGeoPackageRepository.shared().columns(forTable: self.table.name, database: self.table.database)
        
        for column in columns {
            let c = column as! GPKGUserColumn
            if (name == c.name) {
                return false
            }
        }
        
        return true
    }
}
