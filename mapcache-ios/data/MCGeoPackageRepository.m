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
/**
    This class is a singleton.
 */
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


/**
    Get an array of the available GeoPackage databases.
 */
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


/**
  Get a  database by name.
  @return the database you were looking for
 */
- (MCDatabase *)databseNamed:(NSString *)databaseName {
    for (MCDatabase *database in _databaseList) {
        if ([database.name isEqualToString:databaseName]) {
            return database;
        }
    }
    
    return nil;
}


/**
 Check to see if the database has a table with a specific name.
 @param database The MCDatabase you want to search.
 @param tableName The table you are looking for
 @return a boolean, yes if the table was found, no if it was not.
 @return
 */
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
        geoPackage = [_manager open:database];
        [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andBoundingBox:boundingBox andSrsId:srsId];
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
    GPKGUserRow *userRow = nil;
    GPKGGeoPackage *geoPackage = [_manager open:databaseName];
    
    @try {
        GPKGFeatureDao* featureDao = [geoPackage featureDaoWithTableName:tableName];
        userRow = [featureDao queryForIdRow:rowId];
    } @catch(NSException *e) {
        NSLog(@"Problem querying row: %@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        return userRow;
    }
}


- (BOOL)saveRow:(GPKGFeatureRow *)featureRow toDatabase:(NSString *)databaseName {
    GPKGGeoPackage *geoPackage = [_manager open:databaseName];
    BOOL saved = YES;
    
    @try {
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:featureRow.table.tableName];
        [featureDao update:featureRow];
    } @catch (NSException *e) {
        NSLog(@"Problem while saving point data: %@", e.reason);
        saved = NO;
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        [self regenerateDatabaseList];
        return saved;
    }
}


- (int)deleteRow:(GPKGUserRow *)featureRow fromDatabase:(NSString *)databaseName {
    GPKGGeoPackage *geoPackage = [_manager open:databaseName];
    int rowsDeleted = 0;
    
    @try {
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:featureRow.table.tableName];
        rowsDeleted = [featureDao delete:featureRow] > 0;
    } @catch (NSException *e) {
        NSLog(@"Problem while deleting point data: %@", e.reason);
        rowsDeleted = 0;
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        [self regenerateDatabaseList];
        return rowsDeleted;
    }
}


- (NSArray *)columnsForTable:(MCTable *) table {
    NSArray *columns = nil;
    GPKGGeoPackage *geoPackage = [_manager open:table.database];
    
    @try {
        GPKGFeatureDao* featureDao = [geoPackage featureDaoWithTableName:table.name];
        columns = [featureDao columns];
    } @catch(NSException *e) {
        NSLog(@"Problem querying row: %@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        return columns;
    }
}


- (BOOL)addColumn:(GPKGFeatureColumn *)featureColumn to:(MCTable *)table {
    BOOL didAdd = YES;
    GPKGGeoPackage *geoPackage = [_manager open:table.database];
    
    @try {
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:table.name];
        [featureDao addColumn:featureColumn];
    } @catch(NSException *e) {
        NSLog(@"Problem creating column %@ in %@ table in %@", featureColumn.name, table.name, table.database);
        didAdd = NO;
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
    }
    
    return didAdd;
}

@end
