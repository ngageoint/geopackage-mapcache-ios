//
//  GPKGSButtonCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/27/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSColorUtil.h"
#import "GPKGSConstants.h"

@protocol GPKGSButtonCellDelegate <NSObject>
- (void) performButtonAction:(NSString *) action;
@end


@interface GPKGSButtonCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) id<GPKGSButtonCellDelegate> delegate;
@property (strong, nonatomic) NSString *action;
- (void) enableButton;
- (void) disableButton;
@end
