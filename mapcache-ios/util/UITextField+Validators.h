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

@interface UITextField (Validators)

typedef NS_ENUM(NSInteger, MCTileServerURLType) {
    MCXYZTileServerURL,
    MCWMSTileServerURL,
    MCInvalidURL
};


- (void)isValidTileServerURL:(UITextField *)textField withResult:(void(^)(MCTileServerURLType serverURLType))resultBlock;
- (void)isValidGeoPackageURL:(UITextField *)textField withResult:(void(^)(BOOL isValid))resultBlock;
- (void)trimWhiteSpace;
- (BOOL)fieldValueValidForType:(enum GPKGDataType) dataType;
@end

NS_ASSUME_NONNULL_END
