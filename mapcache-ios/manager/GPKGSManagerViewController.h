//
//  GPKGSManagerViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDownloadFileViewController.h"
#import "GPKGSIndexerProtocol.h"
#import "GPKGSCreateFeaturesViewController.h"
#import "GPKGSManagerCreateTilesViewController.h"
#import "GPKGSManagerLoadTilesViewController.h"
#import "GPKGSEditFeaturesViewController.h"
#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSAddTileOverlayViewController.h"
#import "GPKGSManagerEditTileOverlayViewController.h"
#import "GPKGSLinkedTablesViewController.h"
#import "GPKGSDownloadCoordinator.h"

extern NSString * const GPKGS_MANAGER_SEG_DOWNLOAD_FILE;
extern NSString * const GPKGS_MANAGER_SEG_DISPLAY_TEXT;
extern NSString * const GPKGS_MANAGER_SEG_CREATE_FEATURES;
extern NSString * const GPKGS_MANAGER_SEG_CREATE_TILES;
extern NSString * const GPKGS_EXPANDED_PREFERENCE;

extern const char ConstantKey;

@interface GPKGSManagerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, GPKGSDownloadCoordinatorDelegate, GPKGSIndexerProtocol, GPKGSCreateFeaturesDelegate, GPKGSManagerCreateTilesDelegate, GPKGSManagerLoadTilesDelegate, GPKGSEditFeaturesDelegate, GPKGSCreateFeatureTilesDelegate, GPKGSAddTileOverlayDelegate, GPKGSEditTileOverlayDelegate, GPKGSLinkedTablesDelegate>

@property (weak, nonatomic) IBOutlet UIButton *clearActiveButton;

@end
