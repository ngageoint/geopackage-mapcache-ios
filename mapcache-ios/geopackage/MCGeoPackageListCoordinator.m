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
@property (nonatomic, strong) MCGeoPackageCoordinator *geoPackageCoordinator;
@property (nonatomic, strong) MCGeoPackageList *geoPackageListView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableArray *databases;
@property (nonatomic, strong) GPKGGeoPackageCache *geoPacakageCache;
@end


@implementation MCGeoPackageListCoordinator

- (instancetype) init {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _databases = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory getManager];
    _geoPacakageCache = [[GPKGGeoPackageCache alloc] initWithManager:_manager];
    self.active = [GPKGSDatabases getInstance];
    
    return self;
}


- (void) start {
    [self update];
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_databases asFullView:YES andDelegate:self];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundingBoxDrawn:) name:@"boundingBoxResults" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoPackageImported:) name:GPKGS_IMPORT_GEOPACKAGE_NOTIFICATION object:nil];
}


// TODO make a call to the list view controller to update with the new geopackages, maybe as an array
- (void) update {
    self.databases = [[NSMutableArray alloc] init];
    NSArray *databaseNames = [self.manager databases];
    
    for(NSString * databaseName in databaseNames){
        GPKGGeoPackage * geoPackage = nil;
        @try {
            geoPackage = [self.manager open:databaseName];
            
            GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] initWithName:databaseName andExpanded:NO];
            [self.databases addObject:theDatabase];
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
                GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:databaseName andName:tableName andCount:count andMinZoom:tileDao.minZoom andMaxZoom:tileDao.maxZoom];
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


- (void)geoPackageImported:(NSNotification *) notification {
    [self update];
    _geoPackageListView.geoPackages = _databases;
    [_geoPackageListView.tableView reloadData];
    
}


#pragma mark - MCGeoPackageListViewDelegate method
-(void) didSelectGeoPackage:(GPKGSDatabase *)database {
    _geoPackageCoordinator = [[MCGeoPackageCoordinator alloc] initWithDelegate:self andDrawerDelegate:_drawerViewDelegate andMapDelegate:self.mcMapDelegate andDatabase:database];
    [_childCoordinators addObject:_geoPackageCoordinator];
    [_geoPackageCoordinator start];
    // TODO: make a call here to move the map to where the data is, and maybe switch on the layers
    [self.mcMapDelegate zoomToSelectedGeoPackage:database.name];
}


-(void) downloadGeopackageWithExample:(BOOL)prefillExample {
    MCDownloadCoordinator *downloadCoordinator = [[MCDownloadCoordinator alloc] initWithDownlaodDelegate:self andDrawerDelegate:_drawerViewDelegate withExample:prefillExample];
    [downloadCoordinator start];
}


- (void) showNewGeoPackageView {
    MCCreateGeoPacakgeViewController *createGeoPackageView = [[MCCreateGeoPacakgeViewController alloc] initAsFullView:YES];
    createGeoPackageView.drawerViewDelegate = self.drawerViewDelegate;
    createGeoPackageView.createGeoPackageDelegate = self;
    [createGeoPackageView.drawerViewDelegate pushDrawer:createGeoPackageView];
}


-(void) toggleActive:(GPKGSDatabase *)database {
    NSLog(@"Toggling layers for GeoPackage: %@", database.name);

    BOOL switchOn = ![_active isActive:database];
    NSArray *tables = [database getTables];
    
    for (GPKGSTable *table in tables) {
        if (switchOn){
            [_active addTable:table];
        } else {
            [_active removeTable:table];
        }
    }
    
    if (!switchOn && [_geoPacakageCache has:database.name]) {
        [_geoPacakageCache close:database.name];
    }
    
    // make the call to the map view to update the view
    [self.mcMapDelegate updateMapLayers];
}


- (void)deleteGeoPackage:(GPKGSDatabase *)database {
    [self.manager delete:database.name];
    [self.active removeDatabase:database.name andPreserveOverlays:NO];
    [_databases removeObjectIdenticalTo:database];
    
    [_geoPackageListView refreshWithGeoPackages:_databases];
    [self.mcMapDelegate updateMapLayers];
}


#pragma mark - MCCreateGeoPackageDelegate methods
-(BOOL) isValidGeoPackageName:(NSString *)name {
    NSArray *databaseNames = [self.manager databases];
    
    if ([name isEqualToString: @""]) {
        return NO;
    }
    
    for (NSString * databaseName in databaseNames) {
        if ([name isEqualToString:databaseName]) {
            return NO;
        }
    }
    
    return YES;
}


- (void) createGeoPackage:(NSString *) geoPackageName {
    NSLog(@"Creating GeoPackage %@", geoPackageName);
    [_manager create:geoPackageName];
    [self update];
    [_geoPackageListView refreshWithGeoPackages:_databases];
}


#pragma mark - DownloadCoordinatorDelegate
- (void) downloadCoordinatorCompletitonHandler:(bool) didDownload {
    NSLog(@"Downloaded geopakcage");
    [self update];
    [_geoPackageListView refreshWithGeoPackages:_databases];
    [_childCoordinators removeLastObject];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete {
    if (didDelete) {
        [self.manager delete:database];
    }
    
    [self update];
    self.geoPackageListView.geoPackages = self.databases;
    [self.geoPackageListView.tableView reloadData];
}


@end
