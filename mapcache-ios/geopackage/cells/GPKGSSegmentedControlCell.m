//
//  GPKGSSegmentedControlCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSSegmentedControlCell.h"

@implementation GPKGSSegmentedControlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) setItems:(NSArray *)items {
    _items = items;
    
    [_segmentedControl removeAllSegments];
    
    for (int i = 0; i < _items.count; i++) {
        [_segmentedControl insertSegmentWithTitle:[_items objectAtIndex:i] atIndex:i animated:NO];
    }
    
    if (_items.count > 0) {
        [_segmentedControl setSelectedSegmentIndex:0];
    }
}


- (IBAction)selectionChanged:(id)sender {
    
}


@end
