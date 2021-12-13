//
//  MCServerError.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/26/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MCServerType) {
    MCXYZTileServer,
    MCTMSTileServer,
    MCWMSTileServer
};


typedef NS_ENUM(NSInteger, MCServerErrorType) {
    MCURLInvalid,
    MCTileServerNoResponse,
    MCNoData,
    MCTileServerParseError,
    MCNoError,
    MCUnauthorized
};

@interface MCServerError : NSError
    
@end

NS_ASSUME_NONNULL_END
