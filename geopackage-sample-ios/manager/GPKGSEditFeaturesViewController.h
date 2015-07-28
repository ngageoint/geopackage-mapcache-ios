//
//  GPKGSEditFeaturesViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSEditContentsData.h"

@interface GPKGSEditFeaturesViewController : UIViewController

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;

@end
