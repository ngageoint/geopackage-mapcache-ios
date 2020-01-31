//
//  MCGeoPackageList.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/15/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCGeoPackageCell.h"
#import "MCEmptyStateCell.h"
#import "MCTutorialCell.h"
#import "NGADrawerViewController.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSDatabase.h"
#import "GPKGSDatabases.h"


@protocol MCGeoPacakageListViewDelegate <NSObject>
- (void) didSelectGeoPackage: (GPKGSDatabase*) database;
- (void) downloadGeopackageWithExample:(BOOL) prefillExample;
- (void) toggleActive:(GPKGSDatabase *) database;
- (void) deleteGeoPackage:(GPKGSDatabase *) database;
- (void) showNewGeoPackageView;
@end

@interface MCGeoPackageList: NGADrawerViewController <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) id<MCGeoPacakageListViewDelegate> geopackageListViewDelegate;
- (instancetype) initWithGeoPackages: (NSMutableArray *) geoPackages asFullView: (BOOL) fullView andDelegate:(id<MCGeoPacakageListViewDelegate>) delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *geoPackages;


- (void)toggleGeoPacakge:(NSIndexPath *) indexPath;
- (void)deleteGeoPackageAtIndexPath:(NSIndexPath *) indexPath;
- (void)refreshWithGeoPackages:(NSMutableArray *) geoPackages;
@end
