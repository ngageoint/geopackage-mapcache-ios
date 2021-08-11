//
//  MCDualButtonCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCColorUtil.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCDualButtonCellDelegate <NSObject>
- (void)performDualButtonAction: (NSString *) action;
@end

@interface MCDualButtonCell : UITableViewCell
@property (nonatomic, weak) id<MCDualButtonCellDelegate> dualButtonDelegate;
@property (nonatomic, weak) IBOutlet UIButton *leftButton;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;
@property (nonatomic, strong) NSString *leftButtonAction;
@property (nonatomic, strong) NSString *rightButtonAction;

- (void)setLeftButtonLabel: (NSString *) text;
- (void)setRightButtonLabel: (NSString *) text;
- (void)enableLeftButton;
- (void)enableRightButton;
- (void)disableLeftButton;
- (void)disableRightButton;
- (void)disableButtons;
- (void)enableButtons;
- (void)leftButtonUseClearBackground;
- (void)rightButtonUseClearBackground;
- (void)leftButtonUsePrimaryColors;
- (void)leftButtonUseSecondaryColors;
- (void)rightButtonUsePrimaryColors;
- (void)rightButtonUseSecondaryColors;
@end

NS_ASSUME_NONNULL_END
