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

@end
