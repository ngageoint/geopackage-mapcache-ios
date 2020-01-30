//
//  UITextView+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/29/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "UITextView+Validators.h"

@implementation UITextView (Validators)
- (void)isValidTileServerURL:(UITextView *)textView withResult:(void(^)(BOOL isValid))resultBlock {
    resultBlock(YES);
    
    NSString *urlText = textView.text;
    BOOL isXYZ = NO;
    BOOL isWMS = NO;
    NSURL *url;
    
    if ([urlText rangeOfString:@"{x}"].length > 0) {
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{x}" withString:@"0"];
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{y}" withString:@"0"];
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{z}" withString:@"0"];
        url = [NSURL URLWithString:urlText];
        isXYZ = YES;
    } else if ([urlText rangeOfString:@"{minLon}"].length > 0) {
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{minLon}" withString:@"0"];
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{minLat}" withString:@"0"];
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{maxLon}" withString:@"1"];
        urlText = [urlText stringByReplacingOccurrencesOfString:@"{maxLat}" withString:@"1"];
        url = [NSURL URLWithString:urlText];
        isWMS = YES;
    }
    

    if (url) {
        if (isXYZ) {
            NSURLSessionDownloadTask *downlaodTask = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            UIImage *downloadedTile = [UIImage imageWithData:[NSData dataWithContentsOfURL: location]];
            
            if (error || downloadedTile == nil) {
                resultBlock(NO);
            } else {
                resultBlock(YES);
            }
            }];
            [downlaodTask resume];
        } else if (isWMS) {
            
        } else {
            resultBlock(NO);
        }
    } else {
        resultBlock(NO);
    }
}


- (void)isValidGeoPackageURL:(UITextView *)textView withResult:(void(^)(BOOL isValid))resultBlock {
    NSURL *url = [NSURL URLWithString:textView.text];
    
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


- (void)trimWhiteSpace:(UITextView *)textView {
    textView.text = [textView.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}
@end
