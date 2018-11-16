//
//  MCGeoPackageListCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCGeoPackageListCoordinator.h"


@interface MCGeoPackageListCoordinator()
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@property (nonatomic, strong) NSMutableArray *geoPackages;
@property (nonatomic, strong) MCGeoPackageList *geoPackageListView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@end


@implementation MCGeoPackageListCoordinator

- (instancetype) init {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _geoPackages = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    
    return self;
}

- (void) start {
    [self update];
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_geoPackages asFullView:YES andDelegate:self];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
}


- (void) update {
    _geoPackages = [[NSMutableArray alloc] init];
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
                
                [self.active removeTable:table];
                
                [tables addObject:table];
                [theDatabase addTile:table];
            }
            
            for(GPKGSFeatureOverlayTable * table in [self.active featureOverlays:databaseName]){
                GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:table.featureTable];
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
}


#pragma mark - MCGeoPackageListViewDelegate method
-(void) didSelectGeoPackage:(GPKGSDatabase *)database {
    MCGeoPackageCoordinator *geoPackageCoordinator = [[MCGeoPackageCoordinator alloc] initWithDelegate:self andDrawerDelegate:_drawerViewDelegate andDatabase:database];
    [_childCoordinators addObject:geoPackageCoordinator];
    [geoPackageCoordinator start];
    // TODO: make a call here to move the map to where the data is, and maybe switch on the layers
    [self.mcMapDelegate zoomToSelectedGeoPackage:database.name];
}


- (void) downloadGeopackage {
    MCDownloadCoordinator *downloadCoordinator = [[MCDownloadCoordinator alloc] initWithDownlaodDelegate:self andDrawerDelegate:_drawerViewDelegate];
    [downloadCoordinator start];
}


-(void) toggleActive:(GPKGSDatabase *)database {
    NSLog(@"Toggling layers for GeoPackage: %@", database.name);
    
    // iterate through the geopackage, and set all of the layers to active.
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [self.manager open:database.name];
        
        GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] initWithName:database.name andExpanded:NO];
        [_geoPackages addObject: theDatabase];
        
        GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
        for(NSString * tableName in [geoPackage getFeatureTables]){
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
            int count = [featureDao count];
            GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
            GPKGGeometryColumns * geometryColumns = [contentsDao getGeometryColumns:contents];
            enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
            
            GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] initWithDatabase:database.name andName:tableName andGeometryType:geometryType andCount:count];
            [self.active addTable:table];
        }
        
        for(NSString * tableName in [geoPackage getTileTables]){
            GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName: tableName];
            int count = [tileDao count];
            GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:database.name andName:tableName andCount:count];
            [self.active addTable:table];
        }
        
        for(GPKGSFeatureOverlayTable * table in [self.active featureOverlays:database.name]){
            [self.active addTable:table];
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
    
    // make the call to the map view to update the view
    [self.mcMapDelegate updateMapLayers];
}


- (void)deleteGeoPackage:(GPKGSDatabase *)database {
    //TODO: fill this in
}



#pragma mark - DownloadCoordinatorDelegate
- (void) downloadCoordinatorCompletitonHandler:(bool) didDownload {
    NSLog(@"Downloaded geopakcage");
    [self update];
    _geoPackageListView.geoPackages = _geoPackages;
    [_geoPackageListView.tableView reloadData];
    [_childCoordinators removeLastObject];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete {
    if (didDelete) {
        [self.manager delete:database];
    }
    
    [self update];
    _geoPackageListView.geoPackages = _geoPackages;
    [_geoPackageListView.tableView reloadData];
}


@end
