//
//  GPKGSSegmentedControlCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MCSegmentedControlCellDelegate <NSObject>
- (void)selectionChanged:(NSString *)selection;
@end


@interface MCSegmentedControlCell : UITableViewCell
@property (weak, nonatomic) id<MCSegmentedControlCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *updateItems;

- (void) updateItems:(NSArray *)items;
- (void) setLabelText:(NSString *)text;
@end
