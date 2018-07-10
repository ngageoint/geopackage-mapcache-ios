//
//  MCFeatureButtonsCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MCFeatureButtonsCellDelegate <NSObject>
- (void) editLayer;
- (void) indexLayer;
- (void) createOverlay;
- (void) createTiles;
- (void) deleteLayer;
@end


@interface MCFeatureButtonsCell : UITableViewCell
@property (weak, nonatomic) id<MCFeatureButtonsCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *indexButton;
@property (weak, nonatomic) IBOutlet UIButton *overlayButton;
@property (weak, nonatomic) IBOutlet UIButton *createTilesButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@end
