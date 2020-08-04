//
//  MCGeoPackageRepository.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCGeoPackageRepository.h"
#import "mapcache_ios-Swift.h"

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


- (MCDatabases *)activeDatabases {
    return _activeDatabases;
}


- (NSMutableArray *)regenerateDatabaseList {
    _databaseList = [[NSMutableArray alloc] init];
    NSArray *databaseNames = [_manager databases];
    
    for(NSString * databaseName in databaseNames){
        [_databaseList addObject: [self readGeoPacakgeIntoDatabase:databaseName]];
    }
    
    return _databaseList;
}


- (MCDatabase *)refreshDatabaseAndUpdateList:(NSString *)databaseName {
    MCDatabase * theDatabase = [self readGeoPacakgeIntoDatabase:databaseName];
    
    for (int i = 0; i < _databaseList.count; i++) {
        MCDatabase *database = [_databaseList objectAtIndex:i];
        if ([database.name isEqualToString:databaseName]) {
            [_databaseList replaceObjectAtIndex:i withObject:theDatabase];
        }
    }
    
    return theDatabase;
}


- (MCDatabase *) readGeoPacakgeIntoDatabase:(NSString *) databaseName {
    MCDatabase * theDatabase = nil;
    GPKGGeoPackage * geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:databaseName];
        theDatabase = [[MCDatabase alloc] initWithName:databaseName andExpanded:NO];
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
            
            MCTileHelper *tileHelper = [[MCTileHelper alloc] init];
            GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
            GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
            GPKGSpatialReferenceSystem *tileMatrixSetSrs = [tileMatrixSetDao srs:tileMatrixSet];
            GPKGBoundingBox *boundingBox = [tileDao boundingBoxWithZoomLevel:tileDao.maxZoom];
            
            table.center = [tileHelper transformBoundingBoxToWgs84:boundingBox withSrs:tileMatrixSetSrs].center;
            
            for (GPKGTileMatrix *tileMatrix in tileDao.tileMatrices) {
                MCTileMatrix *mcTileMatrix = [[MCTileMatrix alloc] init];
                mcTileMatrix.zoomLevel = tileMatrix.zoomLevel;
                mcTileMatrix.tileCount = [NSNumber numberWithInt:[tileDao countWithZoomLevel:[tileMatrix.zoomLevel intValue]]];
                mcTileMatrix.matrixWidth = tileMatrix.matrixWidth;
                mcTileMatrix.matrixHeight = tileMatrix.matrixHeight;
                mcTileMatrix.tileWidth = tileMatrix.tileWidth;
                mcTileMatrix.tileHeight = tileMatrix.tileHeight;
                mcTileMatrix.pixelXSize = tileMatrix.pixelXSize;
                mcTileMatrix.pixelYSize = tileMatrix.pixelYSize;
                [table.tileMatrices addObject:mcTileMatrix];
            }
            
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
    } @catch(NSException *e) {
        NSLog(@"Problem reading database %@ :\n%@",databaseName, e.reason);
    } @finally {
        if(geoPackage == nil){
            @try {
                [self.manager delete:geoPackage.name];
            }
            @catch (NSException *exception) {
                NSLog(@"Caught Exception trying to delete %@ %@", databaseName, exception.reason);
            }
        }else{
            [geoPackage close];
        }
    }
    
    return theDatabase;
}


//MARK: GeoPackage aka Database operations
/**
  Get a  database by name.
  @return the database you were looking for
 */
- (MCDatabase *)databaseNamed:(NSString *)databaseName {
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
    GPKGGeoPackage *geoPackage = nil;
    GPKGFeatureIndexManager *indexer = nil;
    BOOL saved = YES;
    
    @try {
        geoPackage = [_manager open:database.name];
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


//MARK: Table aka Layer operations
- (BOOL) createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns boundingBox:(GPKGBoundingBox *)boundingBox srsId:(NSNumber *) srsId {
    GPKGGeoPackage * geoPackage;
    BOOL didCreateLayer = YES;
    
    @try {
        geoPackage = [_manager open:database];
        //[geoPackage createFeatureTableWithGeometryColumns:geometryColumns andBoundingBox:boundingBox andSrsId:srsId];
        [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andIdColumnName:@"id" andBoundingBox:boundingBox andSrsId:srsId];
    }
    @catch (NSException *e) {
        // TODO handle this
        NSLog(@"There was a problem creating the layer, %@", e.reason);
        didCreateLayer = NO;
    } @finally {
        [geoPackage close];
        [self regenerateDatabaseList];
        return didCreateLayer;
    }
}


- (BOOL) renameTable:(MCTable *) table toNewName:(NSString *)newTableName {
    GPKGGeoPackage *geoPackage;
    BOOL didRenameTable = YES;
    BOOL addToActive = NO;
    
    if ([self.activeDatabases exists:table]) {
        [self.activeDatabases removeTable:table];
        addToActive = YES;
    }
    
    @try {
        geoPackage = [_manager open:table.database];
        NSLog(@"Tables before renaming");
        
        for(NSString *table in geoPackage.tables) {
            NSLog(@"%@", table);
        }
        
        [geoPackage renameTable:table.name toTable:newTableName];
        MCDatabase *updatedDatabase = [self refreshDatabaseAndUpdateList:table.database];;
        
        if (addToActive) {
            [self.activeDatabases addTable:[updatedDatabase tableNamed:newTableName]];
        }
        
        NSLog(@"Tables after renaming");
        
        for(NSString *table in geoPackage.tables) {
            NSLog(@"%@", table);
        }
        didRenameTable = YES;
    } @catch (NSException *e) {
        NSLog(@"MCGeoPackageRepository - Probem renaiming table: %@", e.reason);
        didRenameTable = NO;
    } @finally {
        [geoPackage close];
        return didRenameTable;
    }
}


- (NSArray *)tileMatricesForTableNamed:(NSString *) tableName inDatabase:(NSString *)databaseName {
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:databaseName];
        GPKGTileDao *tileDao = [geoPackage tileDaoWithTableName:tableName];
        return tileDao.tileMatrices;
    } @catch(NSException *e) {
        NSLog(@"Problem getting tile table details %@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
    }
}


- (GPKGUserRow *)queryRow:(int)rowId fromTableNamed:(NSString *)tableName inDatabase:(NSString *)databaseName {
    GPKGUserRow *userRow = nil;
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:databaseName];
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


- (BOOL)saveRow:(GPKGFeatureRow *)featureRow {
    GPKGGeoPackage *geoPackage = nil;
    GPKGFeatureIndexManager *indexer = nil;
    BOOL saved = YES;
    
    @try {
        geoPackage = [_manager open:self.selectedGeoPackageName];
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:self.selectedLayerName];
        
        if (featureRow.values[0] && [featureRow.values[0] isKindOfClass:NSNull.class]) { // new row
            [featureDao insert:featureRow];
            indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            NSArray<NSString *> *indexedTypes = [indexer indexedTypes];
            
            if (indexedTypes.count > 0) {
                [indexer indexWithFeatureRow:featureRow andFeatureIndexTypes:indexedTypes];
            }
            
        } else {
            int update = [featureDao update:featureRow];
            if (update == 0) {
                saved = NO;
            }
        }
        
        MCDatabase *database = [self databaseNamed:geoPackage.name];
        MCTable *table = [database tableNamed:featureRow.tableName];
        
        if (table != nil) {
            [_activeDatabases addTable:table];
        }
        
        self.selectedLayerName = @"";
        self.selectedGeoPackageName = @"";
        
    } @catch (NSException *e) {
        NSLog(@"Problem while saving point data: %@", e.reason);
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


- (GPKGFeatureRow *)newRowInTable:(NSString *) table database:(NSString *)database mapPoint:(GPKGMapPoint *)mapPoint {
    GPKGFeatureRow *newRow = nil;
    GPKGFeatureIndexManager *indexer = nil;
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:database];
        GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:table];
        newRow = [featureDao newRow];
        NSNumber *srsId = featureDao.geometryColumns.srsId;
        indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        GPKGMapShapeConverter *converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];

        SFPoint *point = [converter toPointWithMapPoint:mapPoint];
        GPKGGeometryData *pointGeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [pointGeomData setGeometry: point];
        [newRow setGeometry:pointGeomData];
        
    } @catch (NSException *e) {
        NSLog(@"Problem while deleting point data: %@", e.reason);
        newRow = nil;
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        [self regenerateDatabaseList];
        return newRow;
    }
    
    
}


- (int)deleteRow:(GPKGUserRow *)featureRow fromDatabase:(NSString *)databaseName {
    GPKGGeoPackage *geoPackage = nil;
    int rowsDeleted = 0;
    
    @try {
        geoPackage = [_manager open:databaseName];
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


- (NSArray *)columnsForTable:(NSString *) table database:(NSString *)database {
    NSArray *columns = nil;
    GPKGGeoPackage *geoPackage =nil;
    
    @try {
        geoPackage = [_manager open:database];
        GPKGFeatureDao* featureDao = [geoPackage featureDaoWithTableName:table];
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
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:table.database];
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


- (NSArray<GPKGUserColumn *> *)renameColumn:(GPKGUserColumn*)column newName:(NSString *)newColumnName table:(MCTable *)table {
    GPKGGeoPackage *geoPackage = nil;
    GPKGFeatureDao *featureDao = nil;
    
    BOOL addToActive = NO;
    
    if ([self.activeDatabases exists:table]) {
        [self.activeDatabases removeTable:table];
        addToActive = YES;
    }
    
    @try {
        geoPackage = [_manager open:table.database];
        featureDao = [geoPackage featureDaoWithTableName:table.name];
        [featureDao renameColumn:column toColumn:newColumnName];
        MCDatabase *updatedDatabase = [self refreshDatabaseAndUpdateList:table.database];
        
        if (addToActive) {
            [self.activeDatabases addTable:[updatedDatabase tableNamed:table.name]];
        }
    } @catch(NSException *e) {
        NSLog(@"Problem querying row: %@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        return [featureDao columns];
    }
}


- (NSArray<GPKGUserColumn *> *)deleteColumn:(GPKGUserColumn*)column table:(MCTable *)table {
    GPKGGeoPackage *geoPackage;
    GPKGFeatureDao *featureDao = nil;
    BOOL addToActive = NO;
    
    if ([self.activeDatabases exists:table]) {
        [self.activeDatabases removeTable:table];
        addToActive = YES;
    }
    
    @try {
        geoPackage = [_manager open:table.database];
        featureDao = [geoPackage featureDaoWithTableName:table.name];
        [featureDao dropColumn:column];
        MCDatabase *updatedDatabase = [self refreshDatabaseAndUpdateList:table.database];
        
        if (addToActive) {
            [self.activeDatabases addTable:[updatedDatabase tableNamed:table.name]];
        }
    } @catch (NSException *e) {
        NSLog(@"MCGeoPackageRepository - Probem renaiming table: %@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
        
        return [featureDao columns];
    }
}


@end
