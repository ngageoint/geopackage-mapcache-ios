//
//  GPKGSAddTileOverlayViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSFeatureOverlayTable.h"

@class GPKGSAddTileOverlayViewController;

@protocol GPKGSAddTileOverlayDelegate <NSObject>
- (void)createFeatureTilesViewController:(GPKGSAddTileOverlayViewController *)controller featureOverlayTable:(GPKGSFeatureOverlayTable *)featureOverlayTable;
@end

@interface GPKGSAddTileOverlayViewController : UIViewController

@property (nonatomic, weak) id <GPKGSAddTileOverlayDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;
@property (weak, nonatomic) IBOutlet UITextField *nameValue;

@end
