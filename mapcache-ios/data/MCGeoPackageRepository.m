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


- (NSMutableArray *)regenerateDatabaseList {
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


- (MCDatabase *)databseNamed:(NSString *)databaseName {
    for (MCDatabase *database in _databaseList) {
        if ([database.name isEqualToString:databaseName]) {
            return database;
        }
    }
    
    return nil;
}


- (BOOL)database:(MCDatabase *) database containsTableNamed:(NSString *) tableName {
    return [database hasTableNamed:tableName];
}


- (BOOL)createGeoPackage:(NSString *)geoPackageName {
    return [_manager create:geoPackageName];
}


- (BOOL)copyGeoPacakge:(NSString *)geoPacakgeName to:(NSString *)newName {
    return [_manager copy:geoPacakgeName to:newName];
}


- (BOOL)exists:(NSString *)geoPackageName {
    return [_manager exists:geoPackageName];
}


- (void)deleteGeoPackage:(MCDatabase *)database {
    [self.manager delete:database.name];
    [_activeDatabases removeDatabase:database.name andPreserveOverlays:NO];
    [_databaseList removeObjectIdenticalTo:database];
}


- (BOOL)savePoints:(NSArray<GPKGMapPoint *> *) points toDatabase:(MCDatabase *) database table:(MCTable *) table {
    GPKGGeoPackage *geoPackage = [_manager open:database.name];
    GPKGFeatureIndexManager *indexer = nil;
    
    BOOL saved = YES;
    
    @try {
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:table.name];
        NSNumber *srsId = featureDao.geometryColumns.srsId;
        indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        NSArray<NSString *> *indexedTypes = [indexer indexedTypes];
        GPKGMapShapeConverter *converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        
        for (GPKGMapPoint *mapPoint in points) {
            SFPoint *point = [converter toPointWithMapPoint:mapPoint];
            GPKGFeatureRow *newPoint = [featureDao newRow];
            GPKGGeometryData *pointGeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
            [pointGeomData setGeometry: point];
            [newPoint setGeometry:pointGeomData];
            
            [featureDao insert:newPoint];
            // TODO expand the bounds of the geopackage
            
            if (indexedTypes.count > 0) {
                [indexer indexWithFeatureRow:newPoint andFeatureIndexTypes:indexedTypes];
            }
        }
        
    } @catch (NSException *e) {
        NSLog(@"Problem while saving points: %@", e.reason);
        saved = NO;
    } @finally {
        if (indexer != nil) {
            [indexer close];
        }
        
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        [self regenerateDatabaseList];
        return saved;
    }
}


- (BOOL) createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns boundingBox:(GPKGBoundingBox *)boundingBox srsId:(NSNumber *) srsId {
    GPKGGeoPackage * geoPackage;
    BOOL didCreateLayer = YES;
    
    @try {
        
        GPKGFeatureColumn *titleColumn = [GPKGFeatureColumn createColumnWithName:@"title" andDataType:GPKG_DT_TEXT];
        
        GPKGFeatureColumn *descriptionColumn = [GPKGFeatureColumn createColumnWithName:@"description" andDataType:GPKG_DT_TEXT];
        
        geoPackage = [_manager open:database];
        
        [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andAdditionalColumns:@[titleColumn, descriptionColumn] andBoundingBox:boundingBox andSrsId:srsId];
    }
    @catch (NSException *e) {
        // TODO handle this
        NSLog(@"There was a problem creating the layer, %@", e.reason);
        didCreateLayer = NO;
    }
    @finally {
        [geoPackage close];
        [self regenerateDatabaseList];
        return didCreateLayer;
    }
}


- (GPKGUserRow *)queryRow:(int)rowId fromTableNamed:(NSString *)tableName inDatabase:(NSString *)databaseName {
    GPKGGeoPackage *geoPacakge = [_manager open:databaseName];
    GPKGFeatureDao* featureDao = [geoPacakge featureDaoWithTableName:tableName];
    
    GPKGUserRow* userRow = [featureDao queryForIdRow:rowId];
    
    return userRow;
}

@end
