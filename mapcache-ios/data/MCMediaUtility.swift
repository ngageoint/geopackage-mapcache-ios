//
//  MCMediaUtility.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/22/21.
//  Copyright © 2021 NGA. All rights reserved.
//

import Foundation


@objc class MCMediaUtility: NSObject {
    @objc static let shared = MCMediaUtility()
    let manager = GPKGGeoPackageFactory.manager()
    let mediaTableName = "gpkg_media"
    let idColumnName = "id"
    let relatedIdColumnName = "related_id"
    let dataColumnName = "data"
    let contentTypeColumnName = "content_type"
    
    private override init() {
        super.init()
    }
    
    
    @objc func mediaRelationsFor(geoPackageName: String, row:GPKGUserRow) -> [GPKGUserRow] {
        let geoPackage = manager?.open(geoPackageName)
        let relatedTables = GPKGRelatedTablesExtension.init(geoPackage: geoPackage)
        
        if (relatedTables?.has() != nil) {
            print("Have related tables!")
            if let featureDao:GPKGFeatureDao = geoPackage?.featureDao(withTableName: row.tableName()) {
                let relationships:[GPKGExtendedRelation] = (relatedTables?.relationships())!
                for relationship:GPKGExtendedRelation in relationships {
                    print("base table name: \(relationship.baseTableName) related table name: \(relationship.relatedTableName) mapping table name: \(relationship.mappingTableName)")
                    if row.tableName() == relationship.baseTableName && relationship.relatedTableName == self.mediaTableName {
                        if let mappedIDs = relatedTables?.mappings(for: relationship, withBaseId: row.idValue()) {
                            if let mediaDao = relatedTables?.mediaDao(for: relationship) {
                                if let mediaRows = mediaDao.rows(withIds: mappedIDs) {
                                    return mediaRows
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return []
    }
    
    
    @objc func saveAttachmentsFor(row: GPKGUserRow, media:(NSArray), databaseName:String) {
        if let geoPackage = self.manager?.open(databaseName) {
            if let relatedTables = GPKGRelatedTablesExtension.init(geoPackage: geoPackage) {
                let mappingTableName = row.tableName() + "_" + self.mediaTableName
                var mediaTable:GPKGMediaTable = GPKGMediaTable.init()
                
                if !relatedTables.has() || !geoPackage.isTable(self.mediaTableName) || !geoPackage.isTable(mappingTableName) {
                    // Create the media table
                    let columns = NSMutableArray()

                    if !geoPackage.isTable(self.mediaTableName) {
                        mediaTable = GPKGMediaTable.create(with: GPKGMediaTableMetadata.create(withTable: self.mediaTableName, andAdditionalColumns: (columns as! [GPKGUserCustomColumn])))
                    } else {
                        if let mediaDao = relatedTables.mediaDao(forTableName: self.mediaTableName) {
                            mediaTable = mediaDao.mediaTable()
                        }
                    }

                    if !geoPackage.isTable(mappingTableName) {
                        let mappingColumns = NSMutableArray()
                        let userMappingTable = GPKGUserMappingTable.create(withName: mappingTableName, andAdditionalColumns: (mappingColumns as! [GPKGUserCustomColumn]))
                        // relate the tables
                        relatedTables.addMediaRelationship(withBaseTable: row.tableName(), andMediaTable: mediaTable, andUserMappingTable: userMappingTable)
                    }
                }
                    
                if let mediaDao = relatedTables.mediaDao(forTableName: self.mediaTableName) {
                    // do some saving
                    for m in media {
                        if let image:UIImage = (m as? UIImage)?.rotateImage() {
                            if let data:Data = image.pngData() {
                                let contentType = "image/png"
                                var mediaRow:GPKGMediaRow = mediaDao.newRow()
                                mediaRow.setData(data)
                                mediaRow.setContentType(contentType)
                                //mediaRow.setId(NSNumber.init(value: mediaDao.create(mediaRow)))
                                mediaDao.create(mediaRow)
                        
                                let mappingTableName = row.tableName() + "_" + self.mediaTableName
                                let userMappingDao = relatedTables.mappingDao(forTableName: mappingTableName)
                                let userMappingRow = userMappingDao?.newRow()
                                userMappingRow?.setBaseId(row.idValue())
                                userMappingRow?.setRelatedId(mediaRow.idValue())
                                userMappingDao?.create(userMappingRow)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    @objc func deleteAttachment(geoPackageName: String, row:GPKGUserRow, mediaRow:GPKGMediaRow) -> Bool {
        let geoPackage = manager?.open(geoPackageName)
        let relatedTables = GPKGRelatedTablesExtension.init(geoPackage: geoPackage)
        
        if (relatedTables?.has() != nil) {
            print("Have related tables!")
            if let featureDao:GPKGFeatureDao = geoPackage?.featureDao(withTableName: row.tableName()) {
                let relationships:[GPKGExtendedRelation] = (relatedTables?.relationships())!
                for relationship:GPKGExtendedRelation in relationships {
                    if row.tableName() == relationship.baseTableName {
                        if let mappedIDs = relatedTables?.mappings(for: relationship, withBaseId: row.idValue()) {
                            if let mediaDao = relatedTables?.mediaDao(for: relationship) {
                                return mediaDao.delete(mediaRow) > 0
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
}

