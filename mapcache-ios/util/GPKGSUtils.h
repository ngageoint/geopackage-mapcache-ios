//
//  GPKGSUtils.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GPKGSUtils : NSObject

+(void) showMessageWithDelegate: (id) delegate andTitle: (NSString *) title andMessage: (NSString *) message;

+(void) disableButton: (UIButton *) button;

+(void) enableButton: (UIButton *) button;

+(void) disableTextField: (UITextField *) textField;

+(UIToolbar *) buildKeyboardDoneToolbarWithTarget: (id) target andAction:(SEL)action;

+(UIProgressView *) buildProgressBarView;

@end
