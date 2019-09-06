//
//  UITextField+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "UITextField+Validators.h"

@implementation UITextField (Validators)

- (BOOL)isValidTileServerURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock {
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


- (BOOL)isValidGeoPackageURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock {
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    NSURL *url = [NSURL URLWithString:textField.text];
    
    if (url) {
        
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = YES;
        [securityPolicy setValidatesDomainName:NO];
        sessionManager.securityPolicy = securityPolicy;
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [sessionManager HEAD:url.absoluteString parameters:nil success:^(NSURLSessionDataTask * _Nonnull task) {
            NSLog(@"HEAD from GeoPacakge pre-import %@", task.response.description);
            NSHTTPURLResponse *response = ((NSHTTPURLResponse *) [task response]);
            NSDictionary *headers = [response allHeaderFields];
            
            if ([[headers objectForKey:@"Content-Type"] isEqualToString:@"gpkg"]) {
                resultBlock(YES);
            } else {
                resultBlock(NO);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Unable to reach GeoPacakge to import %@", error);
            resultBlock(NO);
        }];
        
        return YES;
    }
    
    return NO;
}


- (void)trimWhiteSpace:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}


@end
