//
//  GPKGSFieldWithTitleCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCFieldWithTitleCell.h"

@implementation MCFieldWithTitleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (NSString *)fieldValue {
    return self.field.text;
}


- (void)setTextFielDelegate: (id<UITextFieldDelegate>)delegate {
    self.field.delegate = delegate;
}


- (void)setupNumericalKeyboard {
    self.field.keyboardType = UIKeyboardTypeNumberPad;
    
    UIToolbar *keyboardAccessoryView = [[UIToolbar alloc] init];
    [keyboardAccessoryView sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    [keyboardAccessoryView setItems:@[doneButton]];
    self.field.inputAccessoryView = keyboardAccessoryView;
}


- (IBAction)done: (id)sender {
    NSLog(@"Done button tapped");
    [self.field endEditing:YES];
}

@end
