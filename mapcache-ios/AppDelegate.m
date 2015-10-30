//
//  AppDelegate.m
//  QuoteGen
//
//  Created by Brian Osborn on 5/6/15.
//  Copyright (c) 2015 Test. All rights reserved.
//

#import "AppDelegate.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSManagerViewController.h"
#import "GPKGSConstants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)
url sourceApplication:(NSString *) sourceApplication annotation:(id)
annotation {
    
    if (!url) {
        return NO;
    }

    if (url.isFileURL) {
        NSString * fileUrl = [url path];
        
        BOOL imported = false;
        GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
        @try {
            imported = [manager importGeoPackageFromPath:fileUrl andOverride:true andMove:true];
        }
        @finally {
            [manager close];
        }
        
        if(imported){
            [[NSNotificationCenter defaultCenter] postNotificationName:GPKGS_IMPORT_GEOPACKAGE_NOTIFICATION object:self];
        }else{
            NSLog(@"Error importing file %@", fileUrl);
        }
    }

    return YES;
}

@end
