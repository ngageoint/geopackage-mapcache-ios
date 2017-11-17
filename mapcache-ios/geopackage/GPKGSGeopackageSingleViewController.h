//
//  GPKGSGeopackageSingleViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"

@interface GPKGSGeopackageSingleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) GPKGSDatabase *geoPackage;
@end
