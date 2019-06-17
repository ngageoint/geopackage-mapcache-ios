//
//  UITextField+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "UITextField+Validators.h"

@implementation UITextField (Validators)

- (BOOL)isValidURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock {
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    
    NSString *urlText = textField.text;
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{x}" withString:@"0"];
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{y}" withString:@"0"];
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{z}" withString:@"0"];
    
    NSURL *url = [NSURL URLWithString:urlText];
    if (url) {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = YES;
        [securityPolicy setValidatesDomainName:NO];
        sessionManager.securityPolicy = securityPolicy;
        sessionManager.responseSerializer = [AFImageResponseSerializer serializer];
        
        [sessionManager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
            NSLog(@"response object: %@", responseObject);
            resultBlock(YES);
        } failure:^(NSURLSessionDataTask * task, NSError * error) {
            NSLog(@"Problem getting...%@", error);
            resultBlock(NO);
        }];
        
        NSLog(@"was able to make a url");
        return YES;
    } else {
        resultBlock(NO);
    }
    
    return NO;
}


- (void)trimWhiteSpace:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}

@end
