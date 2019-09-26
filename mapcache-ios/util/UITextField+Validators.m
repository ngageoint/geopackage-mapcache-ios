//
//  UITextField+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "UITextField+Validators.h"

@implementation UITextField (Validators)

- (void)isValidTileServerURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock {
    NSString *urlText = textField.text;
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{x}" withString:@"0"];
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{y}" withString:@"0"];
    urlText = [urlText stringByReplacingOccurrencesOfString:@"{z}" withString:@"0"];
    
    NSURL *url = [NSURL URLWithString:urlText];
    
    if (url) {
        NSURLSessionDownloadTask *downlaodTask = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            UIImage *downloadedTile = [UIImage imageWithData:[NSData dataWithContentsOfURL: location]];
            
            if (error || downloadedTile == nil) {
                resultBlock(NO);
            } else {
                resultBlock(YES);
            }
            
        }];
        [downlaodTask resume];
    } else {
        resultBlock(NO);
    }
}


- (void)isValidGeoPackageURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock {
    NSURL *url = [NSURL URLWithString:textField.text];
    
    if (url) {        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = @"HEAD";
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                resultBlock(NO);
            } else {
                NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
                NSDictionary *headers = [urlResponse allHeaderFields];
                
                if ([[headers objectForKey:@"Content-Type"] isEqualToString:@"gpkg"]) {
                    resultBlock(YES);
                } else {
                    resultBlock(NO);
                }
            }
        }];
        
        [downloadTask resume];
        
        
    }
}


- (void)trimWhiteSpace:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}


@end
