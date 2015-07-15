//
//  GPKGSDatabases.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSDatabase.h"

extern NSString * const GPKGS_DATABASES_PREFERENCE;
extern NSString * const GPKGS_TILE_TABLES_PREFERENCE_SUFFIX;
extern NSString * const GPKGS_FEATURE_TABLES_PREFERENCE_SUFFIX;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLES_PREFERENCE_SUFFIX;

@interface GPKGSDatabases : NSObject

@property (nonatomic) BOOL modified;

+(GPKGSDatabases *) getInstance;

-(BOOL) exists: (GPKGSTable *) table;

-(NSArray *) featureOverlays: (NSString *) database;

-(GPKGSDatabase *) getDatabaseWithTable:(GPKGSTable *) table;

-(GPKGSDatabase *) getDatabaseWithName:(NSString *) database;

-(NSArray *) getDatabases;

-(void) addTable: (GPKGSTable *) table;

-(void) addTable: (GPKGSTable *) table andUpdatePreferences: (BOOL) updatePreferences;

-(void) removeTable: (GPKGSTable *) table;

-(BOOL) isEmpty;

-(int) count;

-(void) clearActive;

-(void) removeDatabase: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays;

-(void) renameDatabase: (NSString *) database asNewDatabase: (NSString *) newDatabase;

@end
