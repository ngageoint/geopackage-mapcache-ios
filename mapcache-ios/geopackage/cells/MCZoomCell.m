//
//  MCZoomCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCZoomCell.h"

@implementation MCZoomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    _minZoom = [NSNumber numberWithInt:0];
    _minZoomStepper.minimumValue = [_minZoom doubleValue];
    _minZoomStepper.stepValue = 1;
    
    _maxZoom = [NSNumber numberWithInt:10];
    _maxZoomStepper.minimumValue = 1;
    _maxZoomStepper.maximumValue = 18;
    _maxZoomStepper.value = 10;
    _maxZoomStepper.stepValue = 1;
    
    _minZoomStepper.maximumValue = [_maxZoom doubleValue] -1;
    
    _minZoomDisplay.text = [NSString stringWithFormat:@"%.0f", _minZoomStepper.minimumValue];
    _maxZoomDisplay.text = [NSString stringWithFormat:@"%.0f", 10.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)minZoomStepperTapped:(UIStepper *)sender {
    _minZoom = [NSNumber numberWithDouble:sender.value];
    _minZoomDisplay.text = [NSString stringWithFormat:@"%.0f", [_minZoom doubleValue]];
    _maxZoomStepper.minimumValue = [_minZoom doubleValue] + 1;
}


- (IBAction)maxZoomStepperTapped:(UIStepper *)sender {
    _maxZoom = [NSNumber numberWithDouble:sender.value];
    _minZoomStepper.maximumValue = [_maxZoom doubleValue] - 1;
    _maxZoomDisplay.text = [NSString stringWithFormat:@"%.0f", [_maxZoom doubleValue]];
}

@end
