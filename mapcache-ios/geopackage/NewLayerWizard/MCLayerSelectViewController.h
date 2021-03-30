//
//  MCLayerSelectViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/30/21.
//  Copyright © 2021 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCTitleCell.h"
#import "MCSectionTitleCell.h"
#import "MCButtonCell.h"
#import "MCTileServerCell.h"
#import "MCLayerCell.h"


// forward declarations
@class MCTileServer;
@class MCLayer;
typedef NS_ENUM(NSInteger, MCTileServerType);


@protocol MCLayerSelectDelegate
- (void)didSelectLayer:(NSInteger)layerIndex;
@end


@interface MCLayerSelectViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) id<MCLayerSelectDelegate> layerSelectDelegate;
@property (nonatomic, strong) MCTileServer *tileServer;
@end

