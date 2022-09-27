//
//  SlowServerModel.h
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SlowServerModel : NSObject
 
- (NSString *) getMessage;
- (void) setMessage: (NSString*) message;

@end
