//
//  MCGeoPackageRepository.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageCache.h"
#import "GPKGMultipleFeatureIndexResults.h"
#import "GPKGFeatureIndexListResults.h"
#import "GPKGFeatureIndexManager.h"
#import "GPKGMapShapeConverter.h"
#import "MCDatabase.h"
#import "MCDatabases.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCFeatureOverlayTable.h"


NS_ASSUME_NONNULL_BEGIN

@interface MCGeoPackageRepository : NSObject
@property (nonatomic, strong) NSString *selectedGeoPackageName;
@property (nonatomic, strong) NSString *selectedLayerName;

+ (MCGeoPackageRepository *) sharedRepository;
- (NSMutableArray *)databaseList;
- (MCDatabases *)activeDatabases;
- (NSMutableArray *)regenerateDatabaseList;
- (MCDatabase *)databaseNamed:(NSString *)databaseName;
- (BOOL)exists:(NSString *)geoPackageName;
- (BOOL)database:(MCDatabase *)database containsTableNamed:(NSString *)tableName;
- (BOOL)createGeoPackage:(NSString *)geoPackageName;
- (BOOL)copyGeoPacakge:(NSString *)geoPacakgeName to:(NSString *)newName;
- (BOOL)savePoints:(NSArray<GPKGMapPoint *> *) points toDatabase:(MCDatabase *) database table:(MCTable *) table;
- (BOOL)createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns boundingBox:(GPKGBoundingBox *)boundingBox srsId:(NSNumber *) srsId;
- (GPKGUserRow *)queryRow:(int)rowId fromTableNamed:(NSString *)tableName inDatabase:(NSString *)databaseName;
- (BOOL)saveRow:(GPKGUserRow *)row;
- (GPKGFeatureRow *)newRowInTable:(NSString *) table database:(NSString *)database mapPoint:(GPKGMapPoint *)mapPoint;
- (int)deleteRow:(GPKGUserRow *)featureRow fromDatabase:(NSString *)databaseName;
- (NSArray *)columnsForTable:(NSString *) table database:(NSString *)database;
- (BOOL)addColumn:(GPKGFeatureColumn *)featureColumn to:(MCTable *)table;
@end

NS_ASSUME_NONNULL_END
