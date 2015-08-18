//
//  GPGKSMapPointInitializer.m
//  mapcache-ios
//
//  Created by Brian Osborn on 8/18/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPGKSMapPointInitializer.h"
#import "GPKGSMapPointData.h"
#import "GPKGMapPoint.h"

@implementation GPGKSMapPointInitializer

-(instancetype) initWithPointType: (enum GPKGSMapPointDataType) pointType{
    self = [super init];
    if(self != nil){
        self.pointType = pointType;
    }
    return self;
}

-(void) initializeAnnotation: (NSObject<MKAnnotation> *) annotation{
    GPKGMapPoint * mapPoint = (GPKGMapPoint *) annotation;
    GPKGSMapPointData * data = (GPKGSMapPointData *) mapPoint.data;
    if(data == nil){
        data = [[GPKGSMapPointData alloc] init];
        mapPoint.data = data;
    }
    data.type = self.pointType;
}

@end
