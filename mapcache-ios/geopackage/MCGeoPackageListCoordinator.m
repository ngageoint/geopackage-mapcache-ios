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
@property (nonatomic, strong) MCGeoPackageList *geoPackageListView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableArray *databases;
@end


@implementation MCGeoPackageListCoordinator

- (instancetype) init {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _databases = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    
    return self;
}


- (void) start {
    [self update];
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_databases asFullView:YES andDelegate:self];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
}


// TODO make a call to the list view controller to update with the new geopackages, maybe as an array
- (void) update {
    _databases = [[NSMutableArray alloc] init];
    NSArray *databaseNames = [_manager databases];
    
    for(NSString * databaseName in databaseNames){
        GPKGGeoPackage * geoPackage = nil;
        @try {
            geoPackage = [self.manager open:databaseName];
            
            GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] initWithName:databaseName andExpanded:NO];
            [_databases addObject:theDatabase];
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
                [table setActive: [self.active exists:table]];
                
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
    
    //TODO: if the layers are on, switch them off
    
    
    
    // iterate through the geopackage, and set all of the layers to active.
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [self.manager open:database.name];
        NSLog(@"How many active layers? %d", [database getActiveTableCount]);
        BOOL switchOn = [database getActiveTableCount] == 0;
        
        GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
        for(NSString * tableName in [geoPackage getFeatureTables]){
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
            int count = [featureDao count];
            GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
            GPKGGeometryColumns * geometryColumns = [contentsDao getGeometryColumns:contents];
            enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
            
            GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] initWithDatabase:database.name andName:tableName andGeometryType:geometryType andCount:count];
            if (switchOn) {
                [self.active addTable:table];
            } else {
                [self.active removeTable:table];
            }
        }
        
        for(NSString * tableName in [geoPackage getTileTables]){
            GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName: tableName];
            int count = [tileDao count];
            GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:database.name andName:tableName andCount:count];

            if (switchOn) {
                [self.active addTable:table];
            } else {
                [self.active removeTable:table];
            }
            
        }
        
        for(GPKGSFeatureOverlayTable * table in [self.active featureOverlays:database.name]){
            if (switchOn) {
                [self.active addTable:table];
            } else {
                [self.active removeTable:table];
            }
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
    [self.manager delete:database.name];
    [self.active removeDatabase:database.name andPreserveOverlays:NO];
    [_databases removeObjectIdenticalTo:database];
    
    [_geoPackageListView refreshWithGeoPackages:_databases];
}



#pragma mark - DownloadCoordinatorDelegate
- (void) downloadCoordinatorCompletitonHandler:(bool) didDownload {
    NSLog(@"Downloaded geopakcage");
    [self update];
    _geoPackageListView.geoPackages = _databases;
    [_geoPackageListView.tableView reloadData];
    [_childCoordinators removeLastObject];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete {
    if (didDelete) {
        [self.manager delete:database];
    }
    
    [self update];
    _geoPackageListView.geoPackages = _databases;
    [_geoPackageListView.tableView reloadData];
}


@end
