//
//  GPKGSLayerCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/21/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCTable.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCConstants.h"
#import "MCProperties.h"
#import <UIKit/UIKit.h>

@class MCLayer;
@class MCTileServer;

@interface MCLayerCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *activeIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *layerTypeImage;
@property (nonatomic, weak) IBOutlet UILabel *layerNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) MCTable *table;
@property (nonatomic, strong) MCLayer *mapLayer;
@property (nonatomic, strong) MCTileServer *tileServer;
- (void)activeIndicatorOn;
- (void)activeIndicatorOff;
- (void)toggleActiveIndicator;
- (void) setDetails: (NSString *) details;
- (void) setName: (NSString *) name;
- (void)setContentsWithTable:(MCTable *) table;
- (void)setContentsWithLayer:(MCLayer *) layer tileServer:(MCTileServer *) tileServer;
@end
