//
//  MCGeoPackageListCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCGeoPackageListCoordinator.h"


@interface MCGeoPackageListCoordinator()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) NSMutableArray *geoPackages;
@property (strong, nonatomic) MCGeoPackageList *geoPackageListView;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@end


@implementation MCGeoPackageListCoordinator

- (instancetype) init {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _geoPackages = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory getManager];
    
    return self;
}

- (void) start {
    NSArray *databases = [_manager databases];
    
    for(NSString * databaseName in databases){
        GPKGGeoPackage * geoPackage = nil;
        @try {
            geoPackage = [self.manager open:databaseName];
            
            GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] initWithName:databaseName andExpanded:NO];
            [_geoPackages addObject: theDatabase];
            NSMutableArray * tables = [[NSMutableArray alloc] init];
            
            GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
            for(NSString * tableName in [geoPackage getFeatureTables]){
                GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
                int count = [featureDao count];
                
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
                GPKGGeometryColumns * geometryColumns = [contentsDao getGeometryColumns:contents];
                enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
                
                GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] initWithDatabase:databaseName andName:tableName andGeometryType:geometryType andCount:count];
                
                [tables addObject:table];
                [theDatabase addFeature:table];
            }
            
            for(NSString * tableName in [geoPackage getTileTables]){
                GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName: tableName];
                int count = [tileDao count];
                GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:databaseName andName:tableName andCount:count];
                
                [tables addObject:table];
                [theDatabase addTile:table];
            }
            
            for(GPKGSFeatureOverlayTable * table in [geoPackage getFeatureTables]){
                //GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:table.featureTable];
                //int count = [featureDao count];
                //[table setCount:count];
                
                //[tables addObject:table];
                //[theDatabase addFeatureOverlay:table]; // TODO checkout what is going on with this call, getting an object mismatch.
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
    
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_geoPackages asFullView:YES andDelegate:self];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
}


#pragma mark - MCGeoPackageListViewDelegate method
-(void) didSelectGeoPackage:(GPKGSDatabase *)database {
    MCGeoPackageCoordinator *geoPackageCoordinator = [[MCGeoPackageCoordinator alloc] initWithDelegate:self andDrawerDelegate:_drawerViewDelegate andDatabase:database];
    [_childCoordinators addObject:geoPackageCoordinator];
    [geoPackageCoordinator start];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete {
    if (didDelete) {
        [self.manager delete:database];
    }
    
    //TODO: Update the geopackage list view
}


@end
