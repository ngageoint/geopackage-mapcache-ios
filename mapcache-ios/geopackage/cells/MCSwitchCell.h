//
//  MCSwitchCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 6/19/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MCSwitchCellDelegate <NSObject>
- (void) switchChanged:(BOOL) switchValue;
@end


@interface MCSwitchCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) id<MCSwitchCellDelegate> switchDelegate;

- (void) switchOn;
- (void) switchOff;

@end

NS_ASSUME_NONNULL_END
