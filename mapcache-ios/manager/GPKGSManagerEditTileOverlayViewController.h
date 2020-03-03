//
//  GPKGSManagerEditTileOverlayViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCFeatureOverlayTable.h"
#import "GPKGGeoPackageManager.h"
#import "MCTable.h"

@class GPKGSManagerEditTileOverlayViewController;

@protocol GPKGSEditTileOverlayDelegate <NSObject>
- (void)editTileOverlayViewController:(GPKGSManagerEditTileOverlayViewController *)controller featureOverlayTable:(MCFeatureOverlayTable *)featureOverlayTable;
@end
@interface GPKGSManagerEditTileOverlayViewController : UIViewController

@property (nonatomic, weak) id <GPKGSEditTileOverlayDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) MCFeatureOverlayTable *table;

@end
