//
//  MCLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/3/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGUserDao.h"
#import "GPKGFeatureDao.h"
#import "GPKGTileDao.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "MCButtonCell.h"
#import "MCSectionTitleCell.h"
#import "MCHeaderCell.h"
#import "MCFeatureButtonsCell.h"

@interface MCLayerViewController : UITableViewController
@property (strong, nonatomic) GPKGUserDao *layerDao;
@property (strong, nonatomic) id<MCFeatureButtonsCellDelegate> featureButtonsCellDelegate;
@end
