//
//  GPKGSEditTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSEditContentsData.h"

@class GPKGSEditTilesViewController;

@protocol GPKGSEditTilesDelegate <NSObject>
- (void)editTilesViewController:(GPKGSEditTilesViewController *)controller tilesEdited:(BOOL)edited;
@end

@interface GPKGSEditTilesViewController : UIViewController

@property (nonatomic, weak) id <GPKGSEditTilesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) MCTable *table;
@property (weak, nonatomic) IBOutlet UITextField *minYTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxYTextField;
@property (weak, nonatomic) IBOutlet UITextField *minXTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxXTextField;

@end
