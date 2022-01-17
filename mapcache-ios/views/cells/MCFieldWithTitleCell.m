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
    self.field.layer.cornerRadius = 5.0;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, self.field.frame.size.height)];
    self.field.leftView = paddingView;
    self.field.leftViewMode = UITextFieldViewModeAlways;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void) setTitleText:(NSString *) titleText {
    [self.title setText:titleText];
}


- (void) setPlaceholder:(NSString *) placeholder {
    self.field.placeholder = placeholder;
}


- (void) setFieldText:(NSString *) text {
    self.field.text = text;
}


- (void) useSecureTextEntry {
    [self.field setSecureTextEntry:YES];
}


/**
    Change the return key to be a done button for the text field. 
 */
- (void) useReturnKeyDone {
    [self.field setReturnKeyType:UIReturnKeyDone];
}


- (void) useReturnKeyNext {
    [self.field setReturnKeyType:UIReturnKeyNext];
}


- (void) clearButtonMode {
    self.field.clearButtonMode = UITextFieldViewModeWhileEditing;
}


- (NSString *)fieldValue {
    return self.field.text;
}


- (void)setTextFieldDelegate: (id<UITextFieldDelegate>)delegate {
    self.field.delegate = delegate;
}


- (void)setupNumericalKeyboard {
    self.field.keyboardType = UIKeyboardTypeNumberPad;
    UIToolbar *keyboardAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [[UIApplication sharedApplication] keyWindow].frame.size.width, 40)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    [keyboardAccessoryView setItems:@[doneButton]];
    [keyboardAccessoryView sizeToFit];
    self.field.inputAccessoryView = keyboardAccessoryView;
}


- (void) useNormalAppearance {
//    UIColor *borderColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
//    self.field.layer.borderColor = borderColor.CGColor;
//    self.field.layer.borderWidth = 1.0;
//    self.field.layer.cornerRadius = 5.0;
    self.field.layer.borderColor = [[UIColor clearColor] CGColor];
}


- (void) useErrorAppearance {
    self.field.borderStyle = UITextBorderStyleRoundedRect;
    self.field.layer.cornerRadius = 5.0;
    self.field.layer.borderColor = [[UIColor redColor] CGColor];
    self.field.layer.borderWidth = 2.0;
}


- (IBAction)done: (id)sender {
    NSLog(@"Done button tapped");
    [self.field endEditing:YES];
}

@end
