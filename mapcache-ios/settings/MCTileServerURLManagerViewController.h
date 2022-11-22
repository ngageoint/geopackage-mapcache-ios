//
//  MCTileServerURLManagerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/22/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCSectionTitleCell.h"
#import "MCButtonCell.h"
#import "MCTitleCell.h"
#import "MCTileServerCell.h"
#import "MCLayerCell.h"
#import "MCProperties.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class MCTileServer;
@class MCTileServerResult;

@protocol MCTileServerManagerDelegate <NSObject>
- (void) showNewTileServerView;
- (void) editTileServer:(MCTileServer *) tileServer;
- (void) deleteTileServer:(NSString *) serverName;
@end


@protocol MCSelectTileServerDelegate <NSObject>
- (void) selectTileServer:(MCTileServer *) tileServer;
@end


@interface MCTileServerURLManagerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MCButtonCellDelegate>
@property (weak, nonatomic) id<MCTileServerManagerDelegate> tileServerManagerDelegate;
@property (weak, nonatomic) id<MCSelectTileServerDelegate> selectServerDelegate;
@property (nonatomic) BOOL selectMode;
- (void) update;
@end

NS_ASSUME_NONNULL_END
