//
//  MCTextAreaCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+Validators.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCTextViewCellDelegate <NSObject>
- (void) textViewCellDidEndEditing:(UITextView *) textView;
@end


@interface MCTextViewCell : UITableViewCell <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) NSString *placeholder;
@property (strong, nonatomic) id<MCTextViewCellDelegate>textViewCellDelegate;
- (void)setTextViewContent:(NSString *) text;
- (void)setPlaceholderText:(NSString *) placeholder;
- (NSString *)getText;
- (void) useNormalAppearance;
- (void) useErrorAppearance;
@end

NS_ASSUME_NONNULL_END
