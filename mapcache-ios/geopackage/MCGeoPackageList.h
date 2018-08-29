//
//  MCGeoPackageList.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/15/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCGeoPackageCell.h"
#import "NGADrawerViewController.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSDatabase.h"

@protocol MCGeoPackageListDelegate <NSObject>
- (void) didSelectGeoPackage:(GPKGSDatabase *) geoPackage;
@end

@interface MCGeoPackageList: NGADrawerViewController <UITableViewDelegate, UITableViewDataSource>
- (instancetype) initWithGeoPackages: (NSMutableArray *) geoPackages asFullView: (BOOL) fullView;
@property (weak, nonatomic) id<MCGeoPackageListDelegate> geoPackageListDelegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *geoPackages;
@end
