//
//  GPKGSSegmentedControlCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSegmentedControlCell.h"

@implementation MCSegmentedControlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) setLabelText:(NSString *)text {
    [self.label setText:text];
}


- (void) updateItems:(NSArray *)items {
    _updateItems = items;
    
    [_segmentedControl removeAllSegments];
    
    for (int i = 0; i < _updateItems.count; i++) {
        [_segmentedControl insertSegmentWithTitle:[_updateItems objectAtIndex:i] atIndex:i animated:NO];
    }
    
    if (_updateItems.count > 0) {
        [_segmentedControl setSelectedSegmentIndex:0];
    }
}


- (IBAction)selectionChanged:(id)sender {
    [self.delegate selectionChanged:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
}


@end
