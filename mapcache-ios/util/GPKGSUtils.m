//
//  GPKGSUtils.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"

@implementation GPKGSUtils

+(void) showMessageWithDelegate: (id) delegate andTitle: (NSString *) title andMessage: (NSString *) message{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:message
                          delegate:delegate
                          cancelButtonTitle:nil
                          otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                          nil];
    [alert show];
}

+(void) disableButton: (UIButton *) button{
    if(button.enabled){
        button.enabled = false;
        button.alpha = 0.5;
    }
}

+(void) enableButton: (UIButton *) button{
    if(!button.enabled){
        button.enabled = true;
        button.alpha = 1.0;
    }
}

+(void) disableTextField: (UITextField *) textField{
    if(textField.enabled){
        textField.enabled = false;
        textField.alpha = 0.5;
    }
}

+(UIToolbar *) buildKeyboardDoneToolbarWithTarget: (id) target andAction:(SEL)action{
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:flexSpace, doneBarButton, nil];
    return toolbar;
}

+(UIProgressView *) buildProgressBarView{
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.frame = CGRectMake(0, 0, 200, 15);
    progressView.bounds = CGRectMake(0, 0, 200, 15);
    [progressView setUserInteractionEnabled:NO];
    [progressView setProgressTintColor:[UIColor greenColor]];
    return progressView;
}

+(UIColor *) getColor: (NSDictionary *) color{
    
    UIColor * createdColor = nil;
    
    NSNumber * alpha = [color objectForKey:GPKGS_PROP_COLORS_ALPHA];
    NSNumber * white = [color objectForKey:GPKGS_PROP_COLORS_WHITE];
    if(white != nil){
        createdColor = [UIColor colorWithWhite:[white doubleValue] alpha:[alpha doubleValue]];
    }else{
        NSNumber * red = [color objectForKey:GPKGS_PROP_COLORS_RED];
        NSNumber * green = [color objectForKey:GPKGS_PROP_COLORS_GREEN];
        NSNumber * blue = [color objectForKey:GPKGS_PROP_COLORS_BLUE];
        createdColor = [UIColor colorWithRed:[red doubleValue] green:[green doubleValue] blue:[blue doubleValue] alpha:[alpha doubleValue]];
    }
    
    return createdColor;
}

@end
