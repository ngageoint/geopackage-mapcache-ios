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
@property (strong, nonatomic) GPKGUserDao *dao;
@property (strong, nonatomic) GPKGSDatabase *database;
@property (strong, nonatomic) UINavigationController *navigationController;
@end


@implementation MCLayerCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(GPKGSDatabase *) database
                                       andDao:(GPKGSUserDao *) dao {
    self = [super init];
    _navigationController = navigationController;
    _database = database;
    _dao = dao;
}


- (void) start {
    _layerViewController = [[MCLayerViewController alloc] init];
    [_navigationController pushViewController:_layerViewController animated:YES];
    [_navigationController setNavigationBarHidden:NO animated:NO];
}


#pragma mark - MCFeatureButtonsCellDelegate methods
- (void) editLayer {
    NSLog(@"MCFeatureButtonsCellDelegate editLayer");
}


- (void) indexLayer {
    NSLog(@"MCFeatureButtonsCellDelegate indexLayer");
}


- (void) createOverlay {
    NSLog(@"MCFeatureButtonsCellDelegate createOverlay");
}


- (void) createTiles {
    NSLog(@"MCFeatureButtonsCellDelegate createTiles");
}


- (void) deleteLayer {
    NSLog(@"MCFeatureButtonsCellDelegate deleteLayer");
}

@end
