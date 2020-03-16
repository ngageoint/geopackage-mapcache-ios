//
//  MCGeoPackageRepository.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCGeoPackageRepository.h"

static MCGeoPackageRepository *sharedRepository;

@interface MCGeoPackageRepository()
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) MCDatabases *activeDatabases;
@property (nonatomic, strong) NSMutableArray *databaseList;
@end


@implementation MCGeoPackageRepository

+ (MCGeoPackageRepository *) sharedRepository {
    if (sharedRepository == nil) {
        sharedRepository = [[self alloc] init];
    }
    
    return sharedRepository;
}


- (id)init {
    self = [super init];
    
    _databaseList = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory manager];
    _activeDatabases = [MCDatabases getInstance];
    
    return self;
}


- (NSMutableArray *)databaseList {
    return _databaseList;
}


- (NSMutableArray *)refreshDatabaseList {
    _databaseList = [[NSMutableArray alloc] init];
    NSArray *databaseNames = [_manager databases];
    
    for(NSString * databaseName in databaseNames){
        GPKGGeoPackage * geoPackage = nil;
        @try {
            geoPackage = [_manager open:databaseName];
            
            MCDatabase * theDatabase = [[MCDatabase alloc] initWithName:databaseName andExpanded:NO];
            [_databaseList addObject:theDatabase];
            NSMutableArray * tables = [[NSMutableArray alloc] init];
            
            GPKGContentsDao * contentsDao = [geoPackage contentsDao];
            for(NSString * tableName in [geoPackage featureTables]){
                GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:tableName];
                int count = [featureDao count];
                
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
                GPKGGeometryColumns * geometryColumns = [contentsDao geometryColumns:contents];
                enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
                
                MCFeatureTable * table = [[MCFeatureTable alloc] initWithDatabase:databaseName andName:tableName andGeometryType:geometryType andCount:count];
                
                [tables addObject:table];
                [theDatabase addFeature:table];
            }
            
            for(NSString * tableName in [geoPackage tileTables]){
                GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName: tableName];
                int count = [tileDao count];
                MCTileTable * table = [[MCTileTable alloc] initWithDatabase:databaseName andName:tableName andCount:count andMinZoom:tileDao.minZoom andMaxZoom:tileDao.maxZoom];
                [table setActive: [_activeDatabases exists:table]];
                
                [tables addObject:table];
                [theDatabase addTile:table];
            }
            
            for(MCFeatureOverlayTable * table in [_activeDatabases featureOverlays:databaseName]){
                GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:table.featureTable];
                int count = [featureDao count];
                [table setCount:count];
                
                [tables addObject:table];
                [theDatabase addFeatureOverlay:table];
            }
        }
        @finally {
            if(geoPackage == nil){
                @try {
                    [self.manager delete:geoPackage.name];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught Exception trying to delete %@", exception.reason);
                }
            }else{
                [geoPackage close];
            }
        }
    }
    
    return _databaseList;
}


- (void)deleteGeoPackage:(MCDatabase *)database {
    [self.manager delete:database.name];
    [_activeDatabases removeDatabase:database.name andPreserveOverlays:NO];
    [_databaseList removeObjectIdenticalTo:database];
}


@end
