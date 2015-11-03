//
//  GPKGSGenerateTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSBoundingBoxViewController.h"
#import "GPKGSGenerateTilesData.h"

@interface GPKGSGenerateTilesViewController : UIViewController <GPKGSBoundingBoxDelegate>

@property (weak, nonatomic) IBOutlet UITextField *minZoomTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxZoomTextField;
@property (weak, nonatomic) IBOutlet UILabel *maxFeaturesPerTileLabel;
@property (weak, nonatomic) IBOutlet UITextField *maxFeaturesPerTileTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *compressFormatSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *compressQualityTextField;
@property (weak, nonatomic) IBOutlet UITextField *compressScaleTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tileFormatSegmentedControl;
@property (nonatomic, strong) GPKGSGenerateTilesData * data;

-(void) setAllowedZoomRangeWithMin: (int) minZoom andMax: (int) maxZoom;

@end
