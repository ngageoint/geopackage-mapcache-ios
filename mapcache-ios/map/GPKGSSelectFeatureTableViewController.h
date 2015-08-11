//
//  GPKGSSelectFeatureTableViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/11/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGGeoPackageManager.h"
#import "GPKGSDatabases.h"

@class GPKGSSelectFeatureTableViewController;

@protocol GPKGSSelectFeatureTableDelegate <NSObject>
- (void)selectFeatureTableViewController:(GPKGSSelectFeatureTableViewController *)controller database:(NSString *)database table: (NSString *) table request: (NSString *) request;
@end

@interface GPKGSSelectFeatureTableViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) id <GPKGSSelectFeatureTableDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSString *request;
@property (weak, nonatomic) IBOutlet UIPickerView *databasePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *featurePicker;
@property (weak, nonatomic) IBOutlet UIButton *okButton;

@end
