//
//  MCTextAreaCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCTextViewCell.h"

@implementation MCTextViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.textView.delegate = self;
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) setTextViewContent:(NSString *) text {
    [self.textView setText:text];
    
    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        self.textView.textColor = UIColor.labelColor;
    } else {
        self.textView.textColor = [UIColor blackColor];
    }
}


- (NSString *)getText {
    return self.textView.text;
}


- (void)setPlaceholderText:(NSString *) placeholder {
    self.placeholder = placeholder;
    [self.textView setText:placeholder];
    self.textView.textColor = [UIColor lightGrayColor];
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([self.textView.text isEqualToString:self.placeholder]) {
        self.textView.text = @"";
        
        // iOS 13 dark mode support
        if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
            self.textView.textColor = UIColor.labelColor;
        } else {
            self.textView.textColor = [UIColor blackColor];
        }
    }
    
    [self.textView becomeFirstResponder];
}


- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.textView.text isEqualToString:self.placeholder]) {
        self.textView.text = self.placeholder;
        self.textView.textColor = [UIColor lightGrayColor];
    }
    
    [self.textView resignFirstResponder];
    [self.textViewCellDelegate textViewCellDidEndEditing:self.textView];
}


- (void) useNormalAppearance {
    self.textView.layer.borderColor = [[UIColor clearColor] CGColor];
}


- (void) useErrorAppearance {
    self.textView.layer.cornerRadius = 5.0;
    self.textView.layer.borderColor = [[UIColor redColor] CGColor];
    self.textView.layer.borderWidth = 2.0;
}


// There is no method to change the return key to into a done button on UITextView, but we can use similar behavior.
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


@end

