//
//  GPKGSManagerCreateTilesViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/22/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSCreateTilesData.h"

@class GPKGSManagerCreateTilesViewController;

@protocol GPKGSManagerCreateTilesDelegate <NSObject>
- (void)createManagerTilesViewController:(GPKGSManagerCreateTilesViewController *)controller createdTiles:(BOOL)created withError: (NSString *) error;
@end

@interface GPKGSManagerCreateTilesViewController : UIViewController

@property (nonatomic, weak) id <GPKGSManagerCreateTilesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabase *database;
@property (nonatomic, strong) GPKGSCreateTilesData *data;

@end
