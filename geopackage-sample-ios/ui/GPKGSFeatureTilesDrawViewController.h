//
//  GPKGSFeatureTilesDrawViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSFeatureTilesDrawData.h"

@interface GPKGSFeatureTilesDrawViewController : UIViewController

@property (nonatomic, strong) GPKGSFeatureTilesDrawData * data;
@property (weak, nonatomic) IBOutlet UIButton *pointColorButton;
@property (weak, nonatomic) IBOutlet UITextField *pointAlphaTextField;
@property (weak, nonatomic) IBOutlet UITextField *pointRadiusTextField;
@property (weak, nonatomic) IBOutlet UIButton *lineColorButton;
@property (weak, nonatomic) IBOutlet UITextField *lineAlphaTextField;
@property (weak, nonatomic) IBOutlet UITextField *lineStrokeTextField;
@property (weak, nonatomic) IBOutlet UIButton *polygonColorButton;
@property (weak, nonatomic) IBOutlet UITextField *polygonAlphaTextField;
@property (weak, nonatomic) IBOutlet UITextField *polygonStrokeTextField;
@property (weak, nonatomic) IBOutlet UISwitch *polygonFillSwitch;
@property (weak, nonatomic) IBOutlet UIButton *polygonFillColorButton;
@property (weak, nonatomic) IBOutlet UITextField *polygonFillAlphaTextField;

@end
