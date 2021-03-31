//
//  MCZoomCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCZoomCellValueChangedDelegate <NSObject>
- (void) zoomValuesChanged:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom;
@end

@interface MCZoomCell : UITableViewCell
@property (weak, nonatomic) id<MCZoomCellValueChangedDelegate> valueChangedDelegate;

@property (weak, nonatomic) IBOutlet UILabel *minZoomDisplay;
@property (weak, nonatomic) IBOutlet UILabel *maxZoomDisplay;
@property (weak, nonatomic) IBOutlet UIStepper *minZoomStepper;
@property (weak, nonatomic) IBOutlet UIStepper *maxZoomStepper;

@property (nonatomic, strong) NSNumber* minZoom;
@property (nonatomic, strong) NSNumber* maxZoom;
@end
