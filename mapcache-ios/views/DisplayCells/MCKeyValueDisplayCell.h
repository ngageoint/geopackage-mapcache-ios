//
//  MCKeyValueDisplayCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCKeyValueDisplayCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

- (void)setKeyLabelText:(NSString *)text;
- (void)setValueLabelText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END

