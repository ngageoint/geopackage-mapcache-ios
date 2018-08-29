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
                [tables addObject:table];
                //[theDatabase addFeatureOverlay:table]; // TODO check on this, might be grabbing the wrong thing to run through, featureTable vs featureOverlay
            }
            
        }
        @finally {
            if(geoPackage == nil){
                @try {
                    [self.manager delete:geoPackage.name];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught Exception trying to delete");
                }
            }else{
                [geoPackage close];
            }
        }
    }
    
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_geoPackages asFullView:YES];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
}


#pragma mark - MCGeoPackageListDelegate method
- (void) didSelectGeoPackage:(GPKGSDatabase *) geoPackage {
    
}

@end
