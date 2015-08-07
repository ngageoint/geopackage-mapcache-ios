//
//  GPKGSDecimalValidator.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSDecimalValidator : NSObject<UITextFieldDelegate>

@property (nonatomic, strong) NSDecimalNumber *min;
@property (nonatomic, strong) NSDecimalNumber *max;

-(instancetype) initWithMinimum: (NSDecimalNumber *) minimum andMaximum: (NSDecimalNumber *) maximum;

-(instancetype) initWithMinimumDouble: (double) minimum andMaximumDouble: (double) maximum;

-(instancetype) initWithMinimumNumber: (NSNumber *) minimum andMaximumNumber: (NSNumber *) maximum;

-(instancetype) initWithMinimumInt: (int) minimum andMaximumInt: (int) maximum;

@end
