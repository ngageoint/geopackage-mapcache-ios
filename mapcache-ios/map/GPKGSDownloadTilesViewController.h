//
//  GPKGSDownloadTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSLoadTilesProtocol.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGGeoPackageManager.h"

@class GPKGSDownloadTilesViewController;

@protocol GPKGSDownloadTilesDelegate <NSObject>
- (void)downloadTilesViewController:(GPKGSDownloadTilesViewController *)controller downloadedTiles:(int)count withError: (NSString *) error;
@end

@interface GPKGSDownloadTilesViewController : UIViewController <GPKGSLoadTilesProtocol>

@property (nonatomic, weak) id <GPKGSDownloadTilesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSCreateTilesData *data;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;

@end
