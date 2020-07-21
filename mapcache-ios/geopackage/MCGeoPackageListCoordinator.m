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
@property (nonatomic, strong) MCDatabases *active;
@property (nonatomic, strong) NSMutableArray *databases;
@property (nonatomic, strong) GPKGGeoPackageCache *geoPacakageCache;
@property (nonatomic, strong) MCGeoPackageRepository *repository;
@end


@implementation MCGeoPackageListCoordinator

- (instancetype) init {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _databases = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory manager];
    _repository = [MCGeoPackageRepository sharedRepository];
    _geoPacakageCache = [[GPKGGeoPackageCache alloc] initWithManager:_manager];
    self.active = [MCDatabases getInstance];
    
    return self;
}


- (void) start {
    _databases = [_repository regenerateDatabaseList];
    _geoPackageListView = [[MCGeoPackageList alloc] initWithGeoPackages:_databases asFullView:YES andDelegate:self];
    _geoPackageListView.drawerViewDelegate = _drawerViewDelegate;
    [_geoPackageListView.drawerViewDelegate pushDrawer:_geoPackageListView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regenerateAndReload:) name:GPKGS_IMPORT_GEOPACKAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regenerateAndReload:) name:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:nil];
}


- (void)regenerateAndReload:(NSNotification *) notification {
    [_repository regenerateDatabaseList];
    _geoPackageListView.geoPackages = [_repository databaseList];
    [_geoPackageListView.tableView reloadData];
    
}


#pragma mark - MCGeoPackageListViewDelegate method
-(void) didSelectGeoPackage:(MCDatabase *)database {
    _geoPackageCoordinator = [[MCGeoPackageCoordinator alloc] initWithDelegate:self andDrawerDelegate:_drawerViewDelegate andMapDelegate:self.mcMapDelegate andDatabase:database];
    [_childCoordinators addObject:_geoPackageCoordinator];
    [_geoPackageCoordinator start];
    _repository.selectedGeoPackageName = database.name;
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


-(void) toggleActive:(MCDatabase *)database {
    NSLog(@"Toggling layers for GeoPackage: %@", database.name);

    BOOL switchOn = ![_active isActive:database];
    NSArray *tables = [database getTables];
    
    for (MCTable *table in tables) {
        if (switchOn){
            [_active addTable:table];
        } else {
            [_active removeTable:table];
        }
    }
    
    if (!switchOn && [_geoPacakageCache hasName:database.name]) {
        [_geoPacakageCache closeByName:database.name];
    }
    
    // make the call to the map view to update the view
    [self.mcMapDelegate updateMapLayers];
}


- (void)deleteGeoPackage:(MCDatabase *)database {
    [_repository deleteGeoPackage:database];
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
    _databases = [_repository regenerateDatabaseList];
    [_geoPackageListView refreshWithGeoPackages:_databases];
}


#pragma mark - DownloadCoordinatorDelegate
- (void) downloadCoordinatorCompletitonHandler:(bool) didDownload {
    NSLog(@"Downloaded geopakcage");
    _databases = [_repository regenerateDatabaseList];
    [_geoPackageListView refreshWithGeoPackages:_databases];
    [_childCoordinators removeLastObject];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete {
    _repository.selectedGeoPackageName = @"";
    [_childCoordinators removeAllObjects];
    
    if (didDelete) {
        [self deleteGeoPackage:[_repository databaseNamed:database]];
    } else {
        _databases = [_repository regenerateDatabaseList];
        [self.geoPackageListView refreshWithGeoPackages:_databases];
    }
}


@end
