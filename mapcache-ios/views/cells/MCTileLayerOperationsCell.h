//
//  MCTileLayerOperationsCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MCTileLayerOperationsCellDelegate <NSObject>
- (void) renameTileLayer;
- (void) showScalingOptions;
- (void) deleteTileLayer;
@end


@interface MCTileLayerOperationsCell : UITableViewCell
@property (weak, nonatomic) id<MCTileLayerOperationsCellDelegate> delegate;
@end
