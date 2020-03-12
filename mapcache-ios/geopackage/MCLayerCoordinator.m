//
//  MCLayerCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/17/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCLayerCoordinator.h"

@interface MCLayerCoordinator()
@property (strong, nonatomic) MCLayerViewController *layerViewController;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) GPKGUserDao *dao;
@property (strong, nonatomic) GPKGSDatabase *database;
@property (strong, nonatomic) UINavigationController *navigationController;
@end


@implementation MCLayerCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(GPKGSDatabase *) database
                                       andDao:(GPKGUserDao *) dao {
    self = [super init];
    _navigationController = navigationController;
    _manager = [GPKGGeoPackageFactory manager];
    _database = database;
    _dao = dao;
    return self;
}


- (void) start {
    _layerViewController = [[MCLayerViewController alloc] init];
    _layerViewController.layerDao = _dao;
    _layerViewController.delegate = self;
    [_navigationController pushViewController:_layerViewController animated:YES];
    [_navigationController setNavigationBarHidden:NO animated:NO];
}


#pragma mark - MCLayerOperationsDelegate methods
- (void) renameLayer:(NSString *) layerName {
    NSLog(@"MCLayerCoordinator - renameLayer");
}


- (void) deleteLayer {
    NSLog(@"MCLayerCoordinator - deleteLayer");
    
    GPKGGeoPackage *geoPackage = [_manager open:_database.name];
    
    @try {
        [geoPackage deleteTable:_dao.tableName];
        [_navigationController popViewControllerAnimated:YES];
    }
    @catch (NSException *exception) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"%@ %@ - %@ Table", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL], _database.name, _dao.tableName]
                                 andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
    }
    @finally {
        [geoPackage close];
        
    }
}


- (void) createOverlay {
    NSLog(@"MCLayerCoordinator - createLayer");
}


- (void) createTiles {
    NSLog(@"MCLayerCoordinator - createTiles");
}


- (void) indexLayer {
    NSLog(@"MCLayerCoordinator - indexLayer");
}


- (void) showTileScalingOptions {
    NSLog(@"MCLayerCoordinator - showTileScalingOptions");
}

@end
