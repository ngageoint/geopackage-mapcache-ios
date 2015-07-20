//
//  GPKGSCreateFeaturesViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"
#import "GPKGGeoPackageManager.h"

@class GPKGSCreateFeaturesViewController;

@protocol GPKGSCreateFeaturesDelegate <NSObject>
- (void)createFeaturesViewController:(GPKGSCreateFeaturesViewController *)controller createdFeatures:(BOOL)created withError: (NSString *) error;
@end

@interface GPKGSCreateFeaturesViewController : UIViewController

@property (nonatomic, weak) id <GPKGSCreateFeaturesDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabase *database;
@property (weak, nonatomic) IBOutlet UITextField *minLatValue;
@property (weak, nonatomic) IBOutlet UITextField *maxLatValue;
@property (weak, nonatomic) IBOutlet UITextField *minLonValue;
@property (weak, nonatomic) IBOutlet UITextField *maxLonValue;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;
@property (weak, nonatomic) IBOutlet UITextField *nameValue;
@property (weak, nonatomic) IBOutlet UIButton *geometryTypeButton;

@end
