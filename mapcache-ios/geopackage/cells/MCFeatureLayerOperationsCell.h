//
//  MCFeatureButtonsCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MCFeatureLayerOperationsCellDelegate <NSObject>
- (void) renameFeatureLayer;
- (void) indexFeatures;
- (void) createOverlay;
- (void) createTiles;
- (void) deleteFeatureLayer;
@end


@interface MCFeatureLayerOperationsCell : UITableViewCell
@property (weak, nonatomic) id<MCFeatureLayerOperationsCellDelegate> delegate;
@end
