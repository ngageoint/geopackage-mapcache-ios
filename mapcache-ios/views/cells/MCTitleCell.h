//
//  MCTitleCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 12/8/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCTitleCell : UITableViewCell
- (void)setLabelText:(NSString *) text;
@property (weak, nonatomic) IBOutlet UILabel *label;
@end

NS_ASSUME_NONNULL_END
