//
//  MCEmptyStateCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/1/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCEmptyStateCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
-(void)useAsSpacer;
@end

NS_ASSUME_NONNULL_END
