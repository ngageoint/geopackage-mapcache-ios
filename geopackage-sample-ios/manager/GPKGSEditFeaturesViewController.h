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

@class GPKGSEditFeaturesViewController;

@protocol GPKGSEditFeaturesDelegate <NSObject>
- (void)editFeaturesViewController:(GPKGSEditFeaturesViewController *)controller editedFeatures:(BOOL)edited withError: (NSString *) error;
@end

@interface GPKGSEditFeaturesViewController : UIViewController

@property (nonatomic, weak) id <GPKGSEditFeaturesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;
@property (weak, nonatomic) IBOutlet UIButton *geometryTypeButton;
@property (weak, nonatomic) IBOutlet UITextField *zTextField;
@property (weak, nonatomic) IBOutlet UITextField *mTextField;

@end
