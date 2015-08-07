//
//  GPKGSEditTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSEditContentsData.h"

@interface GPKGSEditTilesViewController : UIViewController

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;
@property (weak, nonatomic) IBOutlet UITextField *minYTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxYTextField;
@property (weak, nonatomic) IBOutlet UITextField *minXTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxXTextField;

@end
