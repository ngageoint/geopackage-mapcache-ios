//
//  UITextField+Validators.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "UITextField+Validators.h"
#import "mapcache_ios-Swift.h"


@implementation UITextField (Validators)

- (void)isValidTileServerURL:(UITextField *)textField withResult:(void(^)(MCTileServerResult *tileServerResult))resultBlock {
    [MCTileServerRepository.shared isValidServerURLWithUrlString:textField.text completion:resultBlock];
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


- (void)trimWhiteSpace {
    self.text = [self.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}


- (BOOL)fieldValueValidForType:(enum GPKGDataType) dataType {
    BOOL isValid = YES;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSDecimalNumber *dn;
    
    switch(dataType) {
        case GPKG_DT_BOOLEAN:
        case GPKG_DT_TINYINT:
        case GPKG_DT_SMALLINT:
        case GPKG_DT_MEDIUMINT:
        case GPKG_DT_INT:
        case GPKG_DT_INTEGER:
            // NSNumber
            isValid = [numberFormatter numberFromString:self.text] == nil ? NO : YES;
            break;
        case GPKG_DT_FLOAT:
        case GPKG_DT_DOUBLE:
        case GPKG_DT_REAL:
            // NSDecimalNumber
            dn = [[NSDecimalNumber alloc] initWithString:self.text];
            isValid = dn == [NSDecimalNumber notANumber] ? NO : YES;
            break;
        case GPKG_DT_TEXT:
            // NSString
            isValid = self.text != nil;
            break;
        case GPKG_DT_BLOB: // not alowing editing for these types yet
        case GPKG_DT_DATE:
        case GPKG_DT_DATETIME:
            // NSDate class
            break;
    }
    
    return isValid;
}

@end
