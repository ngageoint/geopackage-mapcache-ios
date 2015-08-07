//
//  GPKGSBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGBoundingBox.h"

@class GPKGSBoundingBoxViewController;

@protocol GPKGSBoundingBoxDelegate <NSObject>
- (void)boundingBoxViewController:(GPKGBoundingBox *) boundingBox;
@end

@interface GPKGSBoundingBoxViewController : UIViewController

@property (nonatomic, weak) id <GPKGSBoundingBoxDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *minLatValue;
@property (weak, nonatomic) IBOutlet UITextField *maxLatValue;
@property (weak, nonatomic) IBOutlet UITextField *minLonValue;
@property (weak, nonatomic) IBOutlet UITextField *maxLonValue;
@property (nonatomic, strong) GPKGBoundingBox * boundingBox;

@end
