//
//  MCMapPointDataViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/16/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCFieldWithTitleCell.h"
#import "MCButtonCell.h"
#import "MCTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCDualButtonCell.h"
#import "MCTextViewCell.h"
#import "MCLayerCell.h"
#import "MCEmptyStateCell.h"
#import "MCKeyValueDisplayCell.h"
#import "GPKGMapUtils.h"
#import "GPKGUserRow.h"
#import "GPKGFeatureRow.h"
#import "MCSwitchCell.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MCMapPointViewMode) {
    MCPointViewModeNew,
    MCPointViewModeEdit,
    MCPointViewModeDisplay
};

// forward declarations
@protocol MCShowAttachmentDelegate;

@protocol MCMapPointDataDelegate <NSObject>
- (BOOL)saveRow:(GPKGUserRow *)row attachments:(NSArray *)media databaseName:(NSString *) databaseName;
- (int)deleteRow:(GPKGUserRow *)row fromDatabase:(NSString *)database andRemoveMapPoint:(GPKGMapPoint *)mapPoint;
- (void)mapPointDataViewClosedWithNewPoint:(BOOL)didCloseWithNewPoint;
@end

@interface MCMapPointDataViewController : NGADrawerViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCDualButtonCellDelegate, MCButtonCellDelegate, MCSwitchCellDelegate>
@property (nonatomic, strong) id<MCMapPointDataDelegate>mapPointDataDelegate;
@property (nonatomic, strong) GPKGMapPoint *mapPoint;
@property (nonatomic, strong) GPKGUserRow *row;
@property (nonatomic, strong) NSMutableArray *media;
@property (nonatomic, strong) NSString *databaseName;
@property (nonatomic, strong) NSString *layerName;
@property (nonatomic) MCMapPointViewMode mode;
@property (nonatomic, strong) id<MCShowAttachmentDelegate>showAttachmentDelegate;
- (void)showEditMode;
- (void)showDisplayMode;
- (void)reloadWith:(GPKGUserRow *)row mapPoint:(GPKGMapPoint *)mapPoint mode:(MCMapPointViewMode)mode;
- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row databaseName:(NSString *)databaseName layerName:(NSString *)layerName mode:(MCMapPointViewMode)mode asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate;
- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row databaseName:(NSString *)databaseName layerName:(NSString *)layerName media:(NSMutableArray *)media mode:(MCMapPointViewMode)mode asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate showAttachmentDelegate:(id<MCShowAttachmentDelegate>) showAttachmentDelegate;
@end

NS_ASSUME_NONNULL_END
