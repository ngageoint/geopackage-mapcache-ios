//
//  GPKGSAddTileOverlayViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCTable.h"
#import "GPKGGeoPackageManager.h"
#import "MCFeatureOverlayTable.h"

@class GPKGSAddTileOverlayViewController;

@protocol GPKGSAddTileOverlayDelegate <NSObject>
- (void)addTileOverlayViewController:(GPKGSAddTileOverlayViewController *)controller featureOverlayTable:(MCFeatureOverlayTable *)featureOverlayTable;
@end

@interface GPKGSAddTileOverlayViewController : UIViewController

@property (nonatomic, weak) id <GPKGSAddTileOverlayDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) MCTable *table;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;
@property (weak, nonatomic) IBOutlet UITextField *nameValue;

@end
