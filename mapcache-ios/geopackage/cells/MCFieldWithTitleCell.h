//
//  GPKGSFieldWithTitleCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCFieldWithTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextField *field;

- (NSString *)fieldValue;
- (void)setTextFielDelegate: (id<UITextFieldDelegate>)delegate;
- (void)setupNumericalKeyboard;
@end
