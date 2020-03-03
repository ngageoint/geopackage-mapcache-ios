//
//  GPKGSDatabases.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCDatabase.h"

extern NSString * const GPKGS_DATABASES_PREFERENCE;
extern NSString * const GPKGS_TILE_TABLES_PREFERENCE_SUFFIX;
extern NSString * const GPKGS_FEATURE_TABLES_PREFERENCE_SUFFIX;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLES_PREFERENCE_SUFFIX;
extern NSString * const GPKGS_TABLE_VALUES_PREFERENCE;

@interface MCDatabases : NSObject

@property (nonatomic) BOOL modified;

+(MCDatabases *) getInstance;

-(BOOL) exists: (MCTable *) table;

-(BOOL) existsWithDatabase: (NSString *) database andTable: (NSString *) table ofType: (enum GPKGSTableType) tableType;

- (BOOL)isActive:(MCDatabase *) database;

-(NSArray *) featureOverlays: (NSString *) database;

-(MCDatabase *) getDatabaseWithTable:(MCTable *) table;

-(MCDatabase *) getDatabaseWithName:(NSString *) database;

-(NSArray *) getDatabases;

-(void) addTable: (MCTable *) table;

-(void) addTable: (MCTable *) table andUpdatePreferences: (BOOL) updatePreferences;

-(void) removeTable: (MCTable *) table;

-(void) removeTable: (MCTable *) table andPreserveOverlays: (BOOL) preserveOverlays;

-(BOOL) isEmpty;

-(int) getTableCount;

-(int) getActiveTableCount;

-(void) clearActive;

-(void) removeDatabase: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays;

-(void) renameDatabase: (NSString *) database asNewDatabase: (NSString *) newDatabase;

@end
