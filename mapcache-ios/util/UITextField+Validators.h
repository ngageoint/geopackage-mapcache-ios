//
//  UITextField+Validators.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGDataTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MCTileServerResult;
@class MCServerError;
@class MCTileServer;
@class MCTileServerRepository;

@interface UITextField (Validators)

- (void)isValidTileServerURL:(UITextField *)textField withResult:(void(^)(MCTileServerResult *tileServerResult))resultBlock;
- (void)isValidGeoPackageURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock;
- (void)trimWhiteSpace;
- (BOOL)fieldValueValidForType:(enum GPKGDataType) dataType;
@end

NS_ASSUME_NONNULL_END
