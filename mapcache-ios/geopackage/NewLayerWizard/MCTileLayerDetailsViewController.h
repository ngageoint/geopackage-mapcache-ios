//
//  GPKGSTileLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFPProjectionConstants.h"
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCButtonCell.h"
#import "MCSegmentedControlCell.h"
#import "MCColorUtil.h"
#import "MCTitleCell.h"
#import "NGADrawerViewController.h"


@protocol MCTileLayerDetailsDelegate
- (void) tileLayerDetailsCompletionHandlerWithName:(NSString *)name URL:(NSString *) url andReferenceSystemCode:(int)referenceCode;
- (void) showURLHelp;
- (void) showTileServerList;
- (BOOL) isLayerNameAvailable: (NSString *) layerName;
@end

@interface MCTileLayerDetailsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MCButtonCellDelegate>
@property (weak, nonatomic) id<MCTileLayerDetailsDelegate> delegate;
@property (nonatomic, strong) NSString *selectedServerURL;
@property (nonatomic, strong) NSString *layerName;
- (void)update;
@end
