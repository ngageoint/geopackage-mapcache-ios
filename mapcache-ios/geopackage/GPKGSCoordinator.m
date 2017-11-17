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
@property (strong, nonatomic) GPKGSDatabase *geoPackage;
@end


@implementation GPKGSCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andGeoPackage:(GPKGSDatabase *) geoPackage {
    self = [super init];
    
    _navigationController = navigationController;
    _geoPackage = geoPackage;
    
    return self;
}


- (void) start {
    _geoPackageViewController = [[GPKGSGeopackageSingleViewController alloc] initWithNibName:@"SingleGeoPackageView" bundle:nil];
    _geoPackageViewController.geoPackage = _geoPackage;
    
    
    [_navigationController pushViewController:_geoPackageViewController animated:YES];
    [_navigationController setNavigationBarHidden:NO animated:NO];
}




@end
