//
//  GPKGSUtils.m
//  geopackage-sample-ios
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

@end
