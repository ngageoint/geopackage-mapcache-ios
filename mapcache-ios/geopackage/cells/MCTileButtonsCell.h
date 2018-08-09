//
//  MCTileButtonsCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MCTileButtonsCellDelegate <NSObject>
- (void) renameTileLayer;
- (void) showScalingOptions;
- (void) deleteTileLayer;
@end


@interface MCTileOperationsCell : UITableViewCell
@property (weak, nonatomic) id<MCTileButtonsCellDelegate> delegate;

@end
