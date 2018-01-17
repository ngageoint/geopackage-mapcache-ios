//
//  GPKGSGeopackageSingleViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGSHeaderCellTableViewCell.h"
#import "GPKGSSectionTitleCell.h"
#import "GPKGSLayerCell.h"
#import "GPKGSButtonCell.h"
#import "GPKGSConstants.h"
#import "GPKGSProperties.h"
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "GPKGSUtils.h"


@protocol GPKGSOperationsDelegate <NSObject>
- (void) newLayer;
- (void) deleteGeoPackage;
- (void) copyGeoPackage;
- (void) callCompletionHandler;
@end


@interface GPKGSGeopackageSingleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, GPKGSButtonCellDelegate, GPKGSHeaderCellButtonPressedDelegate>
@property (strong, nonatomic) GPKGSDatabase *database;
@property (weak, nonatomic) id<GPKGSOperationsDelegate> delegate;
@end
