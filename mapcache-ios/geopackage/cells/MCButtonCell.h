//
//  GPKGSButtonCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/27/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MCColorUtil.h"
#import "GPKGSConstants.h"

@protocol MCButtonCellDelegate <NSObject>
- (void) performButtonAction:(NSString *) action;
@end


@interface MCButtonCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) id<MCButtonCellDelegate> delegate;
@property (strong, nonatomic) NSString *action;
- (void) enableButton;
- (void) disableButton;
- (void) useSecondaryColors;
- (void) setButtonLabel: (NSString *) text;
@end
