//
//  MCNewTileServerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCTextViewCell.h"
#import "MCButtonCell.h"
#import "MCDescriptionCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCSaveTileServerDelegate
- (BOOL)saveURL:(NSString *)url forServerNamed:(NSString *)serverName;
@end


@interface MCNewTileServerViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, GPKGSButtonCellDelegate, MCTextViewCellDelegate>
@property (nonatomic, strong) id<MCSaveTileServerDelegate>saveTileServerDelegate;
- (void) setServerName:(NSString *) serverName;
- (void) setServerURL:(NSString *) serverURL;
@end

NS_ASSUME_NONNULL_END
