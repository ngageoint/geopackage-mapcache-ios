//
//  GPKGSCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSCoordinator.h"


@interface GPKGSCoordinator()
@property (strong, nonatomic) GPKGSGeopackageSingleViewController *geoPackageViewController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) GPKGSDatabase *database;
@end


@implementation GPKGSCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(GPKGSDatabase *) database {
    self = [super init];
    
    _navigationController = navigationController;
    _database = database;
    
    return self;
}


- (void) start {
    _geoPackageViewController = [[GPKGSGeopackageSingleViewController alloc] initWithNibName:@"SingleGeoPackageView" bundle:nil];
    _geoPackageViewController.database = _database;
    
    _geoPackageViewController.delegate = self;
    
    [_navigationController pushViewController:_geoPackageViewController animated:YES];
    [_navigationController setNavigationBarHidden:NO animated:NO];
}


#pragma mark - Delegate methods

- (void) newLayer {
    NSLog(@"Coordinator handling new layer");
    
    GPKGSNewLayerViewController *newLayerViewController = [[GPKGSNewLayerViewController alloc] init];
    [_navigationController pushViewController:newLayerViewController animated:YES];
    
}


- (void) deleteGeoPackage {
    NSLog(@"Coordinator handling delete");
}

@end
