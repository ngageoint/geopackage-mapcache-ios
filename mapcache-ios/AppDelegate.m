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
#import "GPKGSProperties.h"
#import "MBFingerTipWindow.h"

@interface AppDelegate ()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGGeoPackageCache *geoPackages;
@end

@implementation AppDelegate

- (UIWindow *)window {
    if ([GPKGSProperties getBoolOfProperty:GPKGS_ANIMATE_SCREEN_TOUCHES] && !_window) {
        MBFingerTipWindow * fingerTip = [[MBFingerTipWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        fingerTip.alwaysShowTouches = YES;
        _window = fingerTip;
    }
    return _window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self setupApplicationAppearance];
    
    UIScreen *screen = [UIScreen mainScreen];
    _window = [[UIWindow alloc] initWithFrame:screen.bounds];
    [_window makeKeyAndVisible];
    MCMapViewController *mapViewController = [[MCMapViewController alloc] init];
    MCMapCoordinator *mapCoordinator = [[MCMapCoordinator alloc] initWithMapViewController:mapViewController];
    NGADrawerCoordinator *drawerCoordinator = [[NGADrawerCoordinator alloc] initWithBackgroundViewController:mapViewController andMCMapDelegate:mapCoordinator];
    [drawerCoordinator start];
    mapCoordinator.drawerViewDelegate = drawerCoordinator;
    [_childCoordinators addObject:drawerCoordinator];
    [_childCoordinators addObject:mapCoordinator];
    _window.rootViewController = mapViewController;
    
    BOOL preventDisclaimer = [[NSUserDefaults standardUserDefaults] boolForKey:@"preventDisclaimer"];
    if (!preventDisclaimer) {
        MCDisclaimerViewController *disclaimer = [[MCDisclaimerViewController alloc] init];
        [_window.rootViewController presentViewController:disclaimer animated:YES completion:nil];
    }
    
    _manager = [GPKGGeoPackageFactory manager];
    _geoPackages = [[GPKGGeoPackageCache alloc] initWithManager:self.manager];
    
    return YES;
}

- (void) initializeUserDefaults {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
    if (nil == [settings objectForKey:GPKGS_PROP_DEFAULTS_INITIALIZED]) {
        [settings setBool:NO forKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
        [settings setBool:YES forKey:GPKGS_PROP_DEFAULTS_INITIALIZED];
    }
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
    [_geoPackages closeAll];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    if (!url) {
        return NO;
    }

    if (url.isFileURL) {
        NSString * fileUrl = [url path];
        
        BOOL imported = false;
        GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
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
            // TODO: handle this with an alert instead
            
//            if ([fileUrl containsString:@"com~apple~CloudDocs"]) {
//                NSURL *url = [[NSURL alloc] initWithString:fileUrl];
//                
//                UIDocumentPickerViewController *docPicker = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeMoveToService];
//            }
        }
    }

    return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)
url sourceApplication:(NSString *) sourceApplication annotation:(id)
annotation {
    return [self application:application openURL:url options:[NSDictionary dictionary]];
}


- (void) setupApplicationAppearance {
    UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleLightContent;
    
    [[UINavigationBar appearance] setBarTintColor:[MCColorUtil getPrimary]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]].textColor = [UIColor whiteColor];
    [[UINavigationBar appearance] setTranslucent:NO];
    
    [[UITabBar appearance] setBarTintColor:[MCColorUtil getPrimary]];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UIToolbar appearance] setBarTintColor:[MCColorUtil getPrimary]];
    [[UIToolbar appearance] setTintColor:[UIColor whiteColor]];
}


@end


// TODO: look into this more
@implementation NSURLRequest(DataController)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host{
    return YES;
}
@end

