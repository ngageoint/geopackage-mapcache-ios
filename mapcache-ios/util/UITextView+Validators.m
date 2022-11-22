//
//  UITextView+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/29/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "UITextView+Validators.h"
#import "mapcache_ios-Swift.h"


@implementation UITextView (Validators)

- (void)isValidTileServerURL:(UITextView *)textView withViewController:(UIViewController *)viewController withResult:(void(^)(MCTileServerResult *tileServerResult))resultBlock {
    [MCTileServerRepository.shared isValidServerURLWithUrlString:textView.text viewController:viewController completion:resultBlock];
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


- (void)replaceEncodedCharacters:(UITextView *)textView {
    NSString *string = textView.text;
    string = [string stringByReplacingOccurrencesOfString:@"%7B" withString:@"{"];
    string = [string stringByReplacingOccurrencesOfString:@"%7D" withString:@"}"];
    [textView setText:string];
}
@end
