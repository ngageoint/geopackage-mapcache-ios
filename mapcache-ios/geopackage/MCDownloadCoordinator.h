//
//  GPKGSDownloadCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/1/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCDownloadGeopackage.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"


@protocol GPKGSDownloadCoordinatorDelegate <NSObject>
- (void) downloadCoordinatorCompletitonHandler:(bool) didDownload;
@end

@protocol GPKGSDownloadCoordinatorDismissedDelegate <NSObject>
- (void) dismissDownloadCoordinator;
@end


@interface MCDownloadCoordinator : NSObject <MCDownloadDelegate>
- (instancetype)initWithDownlaodDelegate:(id<GPKGSDownloadCoordinatorDelegate>) delegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate withExample:(BOOL) prefillExample;
- (void)start;
@property (nonatomic) BOOL prefillExample;
@end
