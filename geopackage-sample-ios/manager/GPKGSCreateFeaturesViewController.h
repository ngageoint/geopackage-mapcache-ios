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
#import "GPKGSBoundingBoxViewController.h"

@class GPKGSCreateFeaturesViewController;

@protocol GPKGSCreateFeaturesDelegate <NSObject>
- (void)createFeaturesViewController:(GPKGSCreateFeaturesViewController *)controller createdFeatures:(BOOL)created withError: (NSString *) error;
@end

@interface GPKGSCreateFeaturesViewController : UIViewController <GPKGSBoundingBoxDelegate>

@property (nonatomic, weak) id <GPKGSCreateFeaturesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabase *database;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;
@property (weak, nonatomic) IBOutlet UITextField *nameValue;
@property (weak, nonatomic) IBOutlet UIButton *geometryTypeButton;
@property (weak, nonatomic) IBOutlet UIView *bboxView;

@end
