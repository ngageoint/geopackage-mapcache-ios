//
//  MCDrawingStatusViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCDualButtonCell.h"
#import "MCDescriptionCell.h"

NS_ASSUME_NONNULL_BEGIN


@protocol MCDrawingStatusDelegate <NSObject>
@end


@interface MCDrawingStatusViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCDualButtonCellDelegate>
- (void)updateStatusLabelWithString:(NSString *) string;
@end

NS_ASSUME_NONNULL_END
