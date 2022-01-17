//
//  GPKGSTileLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PROJProjectionConstants.h"
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCButtonCell.h"
#import "MCSegmentedControlCell.h"
#import "MCColorUtil.h"
#import "MCTitleCell.h"
#import "MCEmptyStateCell.h"
#import "NGADrawerViewController.h"

// Forward declarations
@class MCTileServer;
@class MCTileServerResult;

@protocol MCTileLayerDetailsDelegate
- (void) tileLayerDetailsCompletionHandlerWithName:(NSString *)name tileServer:(MCTileServer *) tileServer username:(NSString *)username password:(NSString *)password andReferenceSystemCode:(int)referenceCode;
- (void) showURLHelp;
- (void) showTileServerList;
- (BOOL) isLayerNameAvailable: (NSString *) layerName;
@end

@interface MCTileLayerDetailsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MCButtonCellDelegate>
@property (weak, nonatomic) id<MCTileLayerDetailsDelegate> delegate;
@property (nonatomic, strong) MCFieldWithTitleCell *urlCell;
@property (nonatomic, strong) MCTileServer *tileServer;
@property (nonatomic, strong) NSString *layerName;
- (void)update;
@end
