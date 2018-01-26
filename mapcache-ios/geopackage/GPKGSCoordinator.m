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
@property (strong, nonatomic) id<GPKGSCoordinatorDelegate> delegate;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) GPKGSDatabase *database;
@end


@implementation GPKGSCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDelegate:(id<GPKGSCoordinatorDelegate>)delegate andDatabase:(GPKGSDatabase *) database {
    self = [super init];
    
    _navigationController = navigationController;
    _delegate = delegate;
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
    
    GPKGSNewLayerWizard *newLayerWizard = [[GPKGSNewLayerWizard alloc] init];
    newLayerWizard.database = _database;
    [_navigationController pushViewController:newLayerWizard animated:YES];
}


- (void) copyGeoPackage {
    [_navigationController popViewControllerAnimated:YES];
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


- (void) deleteGeoPackage {
    NSLog(@"Coordinator handling delete");
    [_navigationController popViewControllerAnimated:YES];
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:YES];
}


- (void) callCompletionHandler {
    NSLog(@"Back pressed");
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


// TODO make a new method that creates a feature layer



@end
