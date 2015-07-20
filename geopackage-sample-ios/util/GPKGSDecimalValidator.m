//
//  GPKGSDecimalValidator.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDecimalValidator.h"

@interface GPKGSDecimalValidator ()

@property (nonatomic, strong) NSDecimalNumber *min;
@property (nonatomic, strong) NSDecimalNumber *max;

@end

@implementation GPKGSDecimalValidator

-(instancetype) initWithMinimum: (NSDecimalNumber *) minimum andMaximum: (NSDecimalNumber *) maximum{
    self = [super init];
    if(self){
        self.min = minimum;
        self.max = maximum;
    }
    return self;
}

-(instancetype) initWithMinimumDouble: (double) minimum andMaximumDouble: (double) maximum{
    return [self initWithMinimum:[[NSDecimalNumber alloc] initWithDouble:minimum] andMaximum:[[NSDecimalNumber alloc] initWithDouble:maximum]];
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString * newString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    NSNumber * number = [nf numberFromString:newString];
    BOOL valid = false;
    if([nf numberFromString:newString] != nil){
        valid = true;
        if(self.min != nil && [self.min doubleValue] > [number doubleValue]){
            valid = false;
        } else if(self.max != nil && [self.max doubleValue] < [number doubleValue]){
            valid = false;
        }
    }else if([newString length] == 0){
        valid = true;
    }else if([newString length] == 1){
        valid = [newString isEqualToString:@"-"] || [newString isEqualToString:@"."];
    }else if([newString length] == 2){
        valid = [newString isEqualToString:@"-."];
    }
    return valid;
}

@end
