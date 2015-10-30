//
//  GPKGSEditTileOverlayViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSBoundingBoxViewController.h"
#import "GPKGSEditTileOverlayData.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSTable.h"

@interface GPKGSEditTileOverlayViewController : UIViewController <GPKGSBoundingBoxDelegate>

@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UITextField *minZoomTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxZoomTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxFeaturesPerTileTextField; // TODO
@property (nonatomic, strong) GPKGSEditTileOverlayData * data;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSString *database;
@property (nonatomic, strong) NSString *featureTable;

@end
