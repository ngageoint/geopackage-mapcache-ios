//
//  MCLayerCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/17/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCLayerViewController.h"
#import "MCFeatureButtonsCell.h"
#import "GPKGSDatabase.h"
#import "GPKGUserDao"

@interface MCLayerCoordinator : NSObject <MCFeatureButtonsCellDelegate>
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(GPKGSDatabase *) database
                                       andDao:(GPKGSUserDao) dao;
- (void) start;
@end
