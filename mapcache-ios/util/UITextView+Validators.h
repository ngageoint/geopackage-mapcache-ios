//
//  UITextView+Validators.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/29/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declarations
@class MCTileServer;
@class MCTileServerResult;

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (Validators)
- (void)isValidTileServerURL:(UITextView *)textView withResult:(void(^)(MCTileServerResult *tileServerResult))resultBlock;
- (void)isValidGeoPackageURL:(UITextView *)textView withResult:(void(^)(BOOL isValid))resultBlock;
- (void)trimWhiteSpace:(UITextView *)textView;
- (void)replaceEncodedCharacters:(UITextView *)textView;
@end

NS_ASSUME_NONNULL_END
