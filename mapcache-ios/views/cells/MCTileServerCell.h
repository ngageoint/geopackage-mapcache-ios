//
//  MCTileServerCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/28/21.
//  Copyright © 2021 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCTileServer;

@interface MCTileServerCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *visibilityStatusIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *layersLabel;
@property (nonatomic, strong) MCTileServer *tileServer;
@property (nonatomic) BOOL layersExpanded;
- (void) setContentWithTileServer:(MCTileServer *)tileServer;
- (void) setNameLabelText:(NSString *)serverName;
- (void) setUrlLabelText:(NSString *)url;
- (void) setLayersLabelText:(NSString *)layersText;
- (void)activeIndicatorOn;
- (void)activeIndicatorOff;
- (void)toggleActiveIndicator;
@end
