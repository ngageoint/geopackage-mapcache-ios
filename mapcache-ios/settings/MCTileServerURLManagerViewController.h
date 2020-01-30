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
#import "MCLayerCell.h"
#import "GPKGSProperties.h"


NS_ASSUME_NONNULL_BEGIN

@protocol MCTileServerManagerDelegate <NSObject>
- (void) showNewTileServerView;
- (void) editTileServer:(NSString *) serverName;
- (void) deleteTileServer:(NSString *) serverName;
@end


@protocol MCSelectTileServerDelegate <NSObject>
- (void) selectTileServer:(NSString *) serverURL;
@end


@interface MCTileServerURLManagerViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (weak, nonatomic) id<MCTileServerManagerDelegate> tileServerManagerDelegate;
@property (weak, nonatomic) id<MCSelectTileServerDelegate> selectServerDelegate;
@property (nonatomic) BOOL selectMode;
- (void) update;
@end

NS_ASSUME_NONNULL_END
