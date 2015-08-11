//
//  GPKGSDatabases.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDatabases.h"
#import "GPKGSTileTable.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGSFeatureTable.h"

NSString * const GPKGS_DATABASES_PREFERENCE = @"databases";
NSString * const GPKGS_TILE_TABLES_PREFERENCE_SUFFIX = @"_tile_tables";
NSString * const GPKGS_FEATURE_TABLES_PREFERENCE_SUFFIX = @"_feature_tables";
NSString * const GPKGS_FEATURE_OVERLAY_TABLES_PREFERENCE_SUFFIX = @"_feature_overlay_tables";
NSString * const GPKGS_TABLE_VALUES_PREFERENCE = @"_tables_values_";

static GPKGSDatabases * instance;

@interface GPKGSDatabases ()

@property (nonatomic, strong) NSUserDefaults * settings;
@property (nonatomic, strong) NSMutableDictionary * databases;

@end

@implementation GPKGSDatabases

+(GPKGSDatabases *) getInstance{
    if(instance == nil){
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        GPKGSDatabases * active = [[GPKGSDatabases alloc] initWithSettings:settings];
        [active loadFromPreferences];
        instance = active;
    }
    return instance;
}

-(instancetype) initWithSettings: (NSUserDefaults *) settings{
    self = [super init];
    if(self != nil){
        self.settings = settings;
        self.modified = false;
        self.databases = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(BOOL) exists: (GPKGSTable *) table{
    BOOL exists = false;
    GPKGSDatabase * database = [self getDatabaseWithTable:table];
    if(database != nil) {
        exists = [database exists:table];
    }
    return exists;
}

-(BOOL) existsWithDatabase: (NSString *) database andTable: (NSString *) table ofType: (enum GPKGSTableType) tableType{
    BOOL exists = false;
    GPKGSDatabase * db = [self getDatabaseWithName:database];
    if(database != nil) {
        exists = [db existsWithTable:table ofType:tableType];
    }
    return exists;
}

-(NSArray *) featureOverlays: (NSString *) database{
    
    NSMutableArray * response = [[NSMutableArray alloc] init];
    
    NSArray * featureOverlays = [self.settings stringArrayForKey:[self getFeatureOverlayTablesPreferenceKeyForDatabase:database]];
    
    for(NSString * featureOverlay in featureOverlays){
        GPKGSFeatureOverlayTable * featureOverlayTable = [self readFeatureOverlayTable:featureOverlay withDatabase:database];
        if(featureOverlayTable != nil){
            [response addObject:featureOverlayTable];
        }
    }
    
    return response;
}

-(GPKGSDatabase *) getDatabaseWithTable:(GPKGSTable *) table{
    return [self getDatabaseWithName:table.database];
}

-(GPKGSDatabase *) getDatabaseWithName:(NSString *) database{
    return [self.databases objectForKey:database];
}

-(NSArray *) getDatabases{
    return [self.databases allValues];
}

-(void) addTable: (GPKGSTable *) table{
    [self addTable:table andUpdatePreferences:true];
}

-(void) addTable: (GPKGSTable *) table andUpdatePreferences: (BOOL) updatePreferences{
    GPKGSDatabase * database = [self.databases objectForKey:table.database];
    if(database == nil){
        database = [[GPKGSDatabase alloc] initWithName:table.database andExpanded:false];
        [self.databases setObject:database forKey:table.database];
    }
    [database add:table];
    if(updatePreferences){
        [self addTableToPreferences: table];
    }
    self.modified = true;
}

-(void) removeTable: (GPKGSTable *) table{
    [self removeTable:table andPreserveOverlays:false];
}

-(void) removeTable: (GPKGSTable *) table andPreserveOverlays: (BOOL) preserveOverlays{
    GPKGSDatabase * database = [self.databases objectForKey:table.database];
    if(database != nil){
        [database remove:table];
        [self removeTableFromPreferences:table];
        if([database isEmpty]){
            [self.databases removeObjectForKey:database.name];
            [self removeDatabaseFromPreferences:database.name andPreserveOverlays:preserveOverlays];
        }
        if(!preserveOverlays && [table getType] == GPKGS_TT_FEATURE){
            NSMutableArray * deleteFeatureOverlays = [[NSMutableArray alloc] init];
            for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                if([featureOverlay.featureTable isEqualToString:table.name]){
                    [deleteFeatureOverlays addObject:featureOverlay];
                }
            }
            for(GPKGSFeatureOverlayTable * featureOverlay in deleteFeatureOverlays){
                [self removeTable:featureOverlay];
            }
        }
        self.modified = true;
    }
}

-(BOOL) isEmpty{
    return [self getTableCount] == 0;
}

-(int) getTableCount{
    int count = 0;
    for(GPKGSDatabase * database in [self.databases allValues]){
        count += [database getTableCount];
    }
    return count;
}

-(int) getActiveTableCount{
    int count = 0;
    for(GPKGSDatabase * database in [self.databases allValues]){
        count += [database getActiveTableCount];
    }
    return count;
}

-(void) clearActive{
    NSMutableArray * allDatabases = [[NSMutableArray alloc] init];
    [allDatabases addObjectsFromArray:[self.databases allKeys]];
    for(NSString * database in allDatabases){
        GPKGSDatabase * db = [self.databases objectForKey:database];
        for(GPKGSTable * table in [db getFeatureOverlays]){
            if(table.active){
                table.active = false;
                [self addTable:table andUpdatePreferences:true];
            }
        }
        [self removeDatabase:database andPreserveOverlays:true];
    }
}

-(void) removeDatabase: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays{
    [self.databases removeObjectForKey:database];
    [self removeDatabaseFromPreferences:database andPreserveOverlays:preserveOverlays];
    self.modified = true;
}

-(void) renameDatabase: (NSString *) database asNewDatabase: (NSString *) newDatabase{
    GPKGSDatabase * geoPackageDatabase = [self.databases objectForKey:database];
    if(geoPackageDatabase != nil){
        [self.databases removeObjectForKey:database];
        geoPackageDatabase.name = newDatabase;
        [self.databases setObject:geoPackageDatabase forKey:newDatabase];
        [self removeDatabaseFromPreferences:database andPreserveOverlays:false];
        for(GPKGSTable * table in [geoPackageDatabase getTables]){
            table.database = newDatabase;
            [self addTableToPreferences:table];
        }
    }
    self.modified = true;
}

-(void) loadFromPreferences{
    [self.databases removeAllObjects];
    NSArray * databases = [self.settings stringArrayForKey:GPKGS_DATABASES_PREFERENCE];
    for(NSString * database in databases){
        NSArray * tiles = [self.settings stringArrayForKey:[self getTileTablesPreferenceKeyForDatabase:database]];
        NSArray * features = [self.settings stringArrayForKey:[self getFeatureTablesPreferenceKeyForDatabase:database]];
        NSArray * featureOverlays = [self.settings stringArrayForKey:[self getFeatureOverlayTablesPreferenceKeyForDatabase:database]];
        
        if(tiles != nil){
            for(NSString * tile in tiles){
                [self addTable:[[GPKGSTileTable alloc] initWithDatabase:database andName:tile andCount:0] andUpdatePreferences:false];
            }
        }
        if(features != nil){
            for(NSString * feature in features){
                [self addTable:[[GPKGSFeatureTable alloc] initWithDatabase:database andName:feature andGeometryType:WKB_NONE andCount:0] andUpdatePreferences:false];
            }
        }
        if(featureOverlays != nil){
            for(NSString * featureOverlay in featureOverlays){
                GPKGSFeatureOverlayTable * featureOverlayTable = [self readFeatureOverlayTable:featureOverlay withDatabase:database];
                if(featureOverlayTable != nil){
                    [self addTable:featureOverlayTable andUpdatePreferences:false];
                }
            }
        }
    }
}

-(void) removeDatabaseFromPreferences: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays{

    NSArray * databases = [self.settings stringArrayForKey:GPKGS_DATABASES_PREFERENCE];
    if(databases != nil && [databases containsObject:database]){
        NSMutableArray * newDatabases = [[NSMutableArray alloc] initWithArray:databases];
        [newDatabases removeObject:database];
        [self.settings setObject:newDatabases forKey:GPKGS_DATABASES_PREFERENCE];
    }
    [self.settings removeObjectForKey:[self getTileTablesPreferenceKeyForDatabase:database]];
    [self.settings removeObjectForKey:[self getFeatureTablesPreferenceKeyForDatabase:database]];
    if(!preserveOverlays){
        NSArray * featureOverlays = [self.settings stringArrayForKey:[self getFeatureOverlayTablesPreferenceKeyForDatabase:database]];
        for(NSString * featureOverlay in featureOverlays){
            [self deleteTableValues:featureOverlay withDatabase:database];
        }
        [self.settings removeObjectForKey:[self getFeatureOverlayTablesPreferenceKeyForDatabase:database]];
    }
    
    [self.settings synchronize];
}

-(void) removeTableFromPreferences: (GPKGSTable *) table{
    
    switch([table getType]){
        case GPKGS_TT_FEATURE:
            {
                NSArray * features = [self.settings stringArrayForKey:[self getFeatureTablesPreferenceKeyForTable:table]];
                if(features != nil && [features containsObject:table.name]){
                    NSMutableArray * newFeatures = [[NSMutableArray alloc] initWithArray:features];
                    [newFeatures removeObject:table.name];
                    [self.settings setObject:newFeatures forKey:[self getFeatureTablesPreferenceKeyForTable:table]];
                }
            }
            break;
            
        case GPKGS_TT_TILE:
            {
                NSArray * tiles = [self.settings stringArrayForKey:[self getTileTablesPreferenceKeyForTable:table]];
                if(tiles != nil && [tiles containsObject:table.name]){
                    NSMutableArray * newTiles = [[NSMutableArray alloc] initWithArray:tiles];
                    [newTiles removeObject:table.name];
                    [self.settings setObject:newTiles forKey:[self getTileTablesPreferenceKeyForTable:table]];
                }
            }
            break;
            
        case GPKGS_TT_FEATURE_OVERLAY:
            {
                NSArray * featureOverlays = [self.settings stringArrayForKey:[self getFeatureOverlayTablesPreferenceKeyForTable:table]];
                if(featureOverlays != nil && [featureOverlays containsObject:table.name]){
                    NSMutableArray * newFeatureOverlays = [[NSMutableArray alloc] initWithArray:featureOverlays];
                    [newFeatureOverlays removeObject:table.name];
                    [self.settings setObject:newFeatureOverlays forKey:[self getFeatureOverlayTablesPreferenceKeyForTable:table]];
                }
                [self deleteTableValues:table];
            }
            break;
            
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", [table getType]];
    }
    
    [self.settings synchronize];
}

-(void) addTableToPreferences: (GPKGSTable *) table{
    
    NSArray * databases = [self.settings stringArrayForKey:GPKGS_DATABASES_PREFERENCE];
    if(databases == nil || ![databases containsObject:table.database]){
        NSMutableArray * newDatabases = [[NSMutableArray alloc] init];
        if(databases != nil){
            [newDatabases addObjectsFromArray:databases];
        }
        [newDatabases addObject:table.database];
        [self.settings setObject:newDatabases forKey:GPKGS_DATABASES_PREFERENCE];
    }
    
    switch ([table getType]){
            
        case GPKGS_TT_FEATURE:
            {
                NSArray * features = [self.settings stringArrayForKey:[self getFeatureTablesPreferenceKeyForTable:table]];
                if(features == nil || ![features containsObject:table.name]){
                    NSMutableArray * newFeatures = [[NSMutableArray alloc] init];
                    if(features != nil){
                        [newFeatures addObjectsFromArray:features];
                    }
                    [newFeatures addObject:table.name];
                    [self.settings setObject:newFeatures forKey:[self getFeatureTablesPreferenceKeyForTable:table]];
                }
            }
            break;
            
        case GPKGS_TT_TILE:
            {
                NSArray * tiles = [self.settings stringArrayForKey:[self getTileTablesPreferenceKeyForTable:table]];
                if(tiles == nil || ![tiles containsObject:table.name]){
                    NSMutableArray * newTiles = [[NSMutableArray alloc] init];
                    if(tiles != nil){
                        [newTiles addObjectsFromArray:tiles];
                    }
                    [newTiles addObject:table.name];
                    [self.settings setObject:newTiles forKey:[self getTileTablesPreferenceKeyForTable:table]];
                }
            }
            break;
            
        case GPKGS_TT_FEATURE_OVERLAY:
            {
                NSArray * featureOverlays = [self.settings stringArrayForKey:[self getFeatureOverlayTablesPreferenceKeyForTable:table]];
                if(featureOverlays == nil || ![featureOverlays containsObject:table.name]){
                    NSMutableArray * newFeatureOverlays = [[NSMutableArray alloc] init];
                    if(featureOverlays != nil){
                        [newFeatureOverlays addObjectsFromArray:featureOverlays];
                    }
                    [newFeatureOverlays addObject:table.name];
                    [self.settings setObject:newFeatureOverlays forKey:[self getFeatureOverlayTablesPreferenceKeyForTable:table]];
                }
                [self writeTableValues:table];
            }
            break;
            
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", [table getType]];
    }
    
    [self.settings synchronize];
}

-(NSString *) getTileTablesPreferenceKeyForTable: (GPKGSTable *) table{
    return [self getTileTablesPreferenceKeyForDatabase:table.database];
}

-(NSString *) getTileTablesPreferenceKeyForDatabase: (NSString *) database{
    return [NSString stringWithFormat:@"%@%@", database, GPKGS_TILE_TABLES_PREFERENCE_SUFFIX];
}

-(NSString *) getFeatureTablesPreferenceKeyForTable: (GPKGSTable *) table{
    return [self getFeatureTablesPreferenceKeyForDatabase:table.database];
}

-(NSString *) getFeatureTablesPreferenceKeyForDatabase: (NSString *) database{
    return [NSString stringWithFormat:@"%@%@", database, GPKGS_FEATURE_TABLES_PREFERENCE_SUFFIX];
}

-(NSString *) getFeatureOverlayTablesPreferenceKeyForTable: (GPKGSTable *) table{
    return [self getFeatureOverlayTablesPreferenceKeyForDatabase:table.database];
}

-(NSString *) getFeatureOverlayTablesPreferenceKeyForDatabase: (NSString *) database{
    return [NSString stringWithFormat:@"%@%@", database, GPKGS_FEATURE_OVERLAY_TABLES_PREFERENCE_SUFFIX];
}

-(void) writeTableValues: (GPKGSTable *) table{
    
    NSDictionary * values = [table getValues];
    
    [self.settings setObject:values forKey:[self getTableValuesPreferenceKeyForTable:table]];
    [self.settings synchronize];
}

-(GPKGSFeatureOverlayTable *) readFeatureOverlayTable: (NSString *) table withDatabase: (NSString *) database{
    
    NSDictionary * tableValues = [self readTableValues:table withDatabase:database];
    GPKGSFeatureOverlayTable * featureOverlayTable = [[GPKGSFeatureOverlayTable alloc] initWithValues:tableValues];
    
    return featureOverlayTable;
}

-(NSDictionary *) readTableValues: (NSString *) table withDatabase: (NSString *) database{
    
    NSDictionary * tableValues = [self.settings dictionaryForKey:[self getTableValuesPreferenceKeyForTable:table withDatabase:database]];
    
    return tableValues;
}

-(void) deleteTableValues: (GPKGSTable *) table{
    [self deleteTableValues:table.name withDatabase:table.database];
}

-(void) deleteTableValues: (NSString *) table withDatabase: (NSString *) database{
    [self.settings removeObjectForKey:[self getTableValuesPreferenceKeyForTable:table withDatabase:database]];
    [self.settings synchronize];
}

-(NSString *) getTableValuesPreferenceKeyForTable: (GPKGSTable *) table{
    return [self getTableValuesPreferenceKeyForTable:table.name withDatabase:table.database];
}

-(NSString *) getTableValuesPreferenceKeyForTable: (NSString *) table withDatabase: (NSString *) database{
    return [NSString stringWithFormat:@"%@%@%@", database, GPKGS_TABLE_VALUES_PREFERENCE, table];
}

@end
