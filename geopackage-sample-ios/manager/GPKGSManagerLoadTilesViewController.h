//
//  GPKGSManagerLoadTilesViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSLoadTilesData.h"
#import "GPKGSLoadTilesProtocol.h"

@class GPKGSManagerLoadTilesViewController;

@protocol GPKGSManagerLoadTilesDelegate <NSObject>
- (void)loadManagerTilesViewController:(GPKGSManagerLoadTilesViewController *)controller loadedTiles:(int)count withError: (NSString *) error;
@end

@interface GPKGSManagerLoadTilesViewController : UIViewController <GPKGSLoadTilesProtocol>

@property (nonatomic, weak) id <GPKGSManagerLoadTilesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;
@property (nonatomic, strong) GPKGSLoadTilesData *data;


@end
