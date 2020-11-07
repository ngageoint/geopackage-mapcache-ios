 //
//  MCBoundingBoxGuideView.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/17/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCServerError.h"

NS_ASSUME_NONNULL_BEGIN

@class MCTileServer;
@class MCLayer;

@protocol MCBoundingBoxGuideDelegate <NSObject>
- (void) layerSelected:(NSUInteger)index;
- (void) boundingBoxCompletionHandler:(CGRect) boundingBox;
- (void) boundingBoxCanceled;
@end


@interface MCBoundingBoxGuideView : UIViewController
@property (weak, nonatomic) IBOutlet UIView *guideView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *layerButton;
@property (weak, nonatomic) id<MCBoundingBoxGuideDelegate> delegate;
@property (strong, nonatomic) MCTileServer *tileServer;
@end

NS_ASSUME_NONNULL_END
