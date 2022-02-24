//
//  MCSettingsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCTitleCell.h"
#import "MCSectionTitleCell.h"
#import "MCSegmentedControlCell.h"
#import "MCDescriptionCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCSwitchCell.h"
#import "MCButtonCell.h"
#import "MCTileServerCell.h"
#import "MCLayerCell.h"
#import "MCProperties.h"
#import <MapKit/MapKit.h>

// forward declarations
@class MCTileServer;
@class MCLayer;
typedef NS_ENUM(NSInteger, MCTileServerType);


/* Settings that change the state of the map, or the controls that are shown are handled here */
@protocol MCMapSettingsDelegate <NSObject>
- (void)setMapType:(NSString *) mapType;
- (void)updateBasemaps:(NSString *)url serverType:(MCTileServerType) serverType;
- (void)setMaxFeatures:(int) maxFeatures;
- (void)toggleZoomIndicator;
- (void)settingsCompletionHandler;
@end


/* Details about the app, tile servers, and other details that do not change the map state. */
@protocol MCSettingsDelegate <NSObject>
- (void)showNoticeAndAttributeView;
- (void)showTileURLManager;
- (void)editTileServer:(NSString *) serverName;
- (void)deleteTileServer:(MCTileServer *) tileServer;
- (void)setUserBasemap:(MCTileServer *)tileServer layer:(MCLayer *)layer;
@end


@interface MCSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MCSegmentedControlCellDelegate, MCButtonCellDelegate, MCSwitchCellDelegate>
@property (nonatomic, strong) id<MCMapSettingsDelegate> mapSettingsDelegate;
@property (nonatomic, strong) id<MCSettingsDelegate> settingsDelegate;
@property (nonatomic, strong) MCTileServer *basemapTileServer;
@property (nonatomic, strong) MCLayer *basemapLayer;
- (void) update;
@end
