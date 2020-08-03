//
//  GPKGSIndexerTask.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MCIndexerTask.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "MCProperties.h"
#import "MCConstants.h"
#import "MCUtils.h"
#import "GPKGFeatureIndexManager.h"

@interface MCIndexerTask ()

@property (nonatomic, strong) NSNumber *maxIndex;
@property (nonatomic, strong) GPKGGeoPackage *geoPackage;
@property (nonatomic) int progress;
@property (nonatomic, strong) GPKGFeatureIndexManager *indexer;
@property (nonatomic, strong) NSObject<GPKGSIndexerProtocol> *callback;
@property (nonatomic) BOOL canceled;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation MCIndexerTask

+(void) indexFeaturesWithCallback: (NSObject<GPKGSIndexerProtocol> *) callback
                                     andDatabase: (NSString *) database
                                 andTable: (NSString *) tableName
                                    andFeatureIndexType: (enum GPKGFeatureIndexType) indexLocation{
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory manager];
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [manager open:database];
    } @catch (NSException *e) {
        NSLog(@"---------- MCIndexerTask - Problem indexing \n%@", e.reason);
    } @finally {
        [manager close];
    }
    
    GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:tableName];
    
    GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
    [indexer setIndexLocation:indexLocation];
    
    MCIndexerTask * indexTask = [[MCIndexerTask alloc] initWithCallback:callback andGeoPackage:geoPackage andIndexer:indexer];
    
    int max = [featureDao count];
    [indexTask setMax:max];
    [indexer setProgress:indexTask];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"%@ %@ - %@", [MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE], database, tableName]
                              message:@""
                              delegate:indexTask
                              cancelButtonTitle:[MCProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                              otherButtonTitles:nil];
    UIProgressView *progressView = [MCUtils buildProgressBarView];
    [alertView setValue:progressView forKey:@"accessoryView"];
    
    indexTask.alertView = alertView;
    indexTask.progressView = progressView;
    
    [alertView show];
    
    [indexTask execute];
}

-(instancetype) initWithCallback: (NSObject<GPKGSIndexerProtocol> *) callback
                      andGeoPackage: (GPKGGeoPackage *) geoPackage
                  andIndexer: (GPKGFeatureIndexManager *) indexer{
    self = [super init];
    if(self != nil){
        self.callback = callback;
        self.geoPackage = geoPackage;
        self.indexer = indexer;
        self.progress = 0;
        self.canceled = false;
    }
    return self;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        self.canceled = true;
    }
}

-(void) execute{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        
        int count = 0;
        
        @try {
            count = [self.indexer indexWithForce:true];
            if(count < [self.maxIndex intValue]){
                NSString * countError = [NSString stringWithFormat:@"Fewer features were indexed than expected. Expected: %@, Actual: %u", self.maxIndex, count];
                if(self.error != nil){
                    countError = [NSString stringWithFormat:@"%@, Error: %@", countError, self.error];
                }
                self.error = countError;
            }
        }
        @catch (NSException *e) {
            self.error = [e description];
        }
        @finally{
            [self.indexer close];
            [self.geoPackage close];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.alertView dismissWithClickedButtonIndex:-1 animated:true];

            if(self.error == nil){
                [self.callback onIndexerCompleted:count];
            }else{
                if(self.canceled){
                    [self.callback onIndexerCanceled:[self.error description]];
                }else{
                    [self.callback onIndexerFailure:[self.error description]];
                }
            }
        });
            
    });
    
}

-(void) setMax: (int) max{
    self.maxIndex = [NSNumber numberWithInt:max];
}

-(void) addProgress: (int) progress{
    self.progress += progress;
    float progressPercentage = self.progress / [self.maxIndex floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.alertView setMessage:[NSString stringWithFormat:@"( %d of %@ )", self.progress, self.maxIndex]];
        [self.progressView setProgress:progressPercentage];
    });
}

-(BOOL) isActive{
    return !self.canceled;
}

-(BOOL) cleanupOnCancel{
    return false;
}

-(void) completed{

}

-(void) failureWithError: (NSString *) error{
    self.error = error;
}

@end
