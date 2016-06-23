//
//  GPKGSLoadTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSLoadTilesViewController.h"
#import "GPKGSGenerateTilesViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"

NSString * const GPKGS_LOAD_TILES_SEG_GENERATE_TILES = @"generateTiles";

@interface GPKGSLoadTilesViewController ()

@property (nonatomic, strong) NSArray * urls;
@property (nonatomic, strong) GPKGSGenerateTilesViewController *generateTilesViewController;
@property (nonatomic, strong) GPKGSDecimalValidator * epsgValidator;

@end

@implementation GPKGSLoadTilesViewController

#define TAG_PRELOADED_URLS 1

- (void)viewDidLoad {
    [super viewDidLoad];

    self.urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_TILE_URLS];
    
    self.epsgValidator = [[GPKGSDecimalValidator alloc] initWithMinimumInt:-1 andMaximumInt:99999];
    [self.epsgTextField setDelegate:self.epsgValidator];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.urlTextField.inputAccessoryView = keyboardToolbar;
    self.epsgTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.urlTextField resignFirstResponder];
    [self.epsgTextField resignFirstResponder];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_PRELOADED_URLS:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.urls count]){
                    NSDictionary * url = (NSDictionary *)[self.urls objectAtIndex:buttonIndex];
                    NSString * name =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_NAME];
                    NSString * urlValue =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_URL];
                    NSNumber * minZoom =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_MIN_ZOOM];
                    NSNumber * maxZoom =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_MAX_ZOOM];
                    NSNumber * defaultMinZoom =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_DEFAULT_MIN_ZOOM];
                    NSNumber * defaultMaxZoom =[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_DEFAULT_MAX_ZOOM];
                    NSNumber * epsg = [url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_EPSG];
                    
                    [self.urlTextField setText:urlValue];
                    self.data.url = self.urlTextField.text;
                    
                    [self.epsgTextField setText:[epsg stringValue]];
                    self.data.epsg = [epsg intValue];
                    
                    [self.generateTilesViewController setAllowedZoomRangeWithMin:[minZoom intValue] andMax:[maxZoom intValue]];
                    
                    if(self.data.generateTiles.setZooms){
                        [self.generateTilesViewController.minZoomTextField setText:[defaultMinZoom stringValue]];
                        [self.data.generateTiles setMinZoom:defaultMinZoom];
                        [self.generateTilesViewController.maxZoomTextField setText:[defaultMaxZoom stringValue]];
                        [self.data.generateTiles setMaxZoom:defaultMaxZoom];
                    }
                    
                    if(self.delegate != nil){
                        [self.delegate loadTilesViewControllerUrlName:name];
                    }
                }
            }
            
            break;
    }
    
}

- (IBAction)preloadedUrlsButton:(id)sender {
    NSMutableArray * urlLabels = [[NSMutableArray alloc] init];
    for(NSDictionary * url in self.urls){
        [urlLabels addObject:[url objectForKey:GPKGS_PROP_PRELOADED_TILE_URLS_LABEL]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_LOAD_TILES_PRELOADED_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *urlLabel in urlLabels) {
        [alert addButtonWithTitle:urlLabel];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_PRELOADED_URLS;
    
    [alert show];
}

- (IBAction)urlChanged:(id)sender {
    self.data.url = self.urlTextField.text;
}

- (IBAction)epsgChanged:(id)sender {
    self.data.epsg = [self.epsgTextField.text intValue];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_LOAD_TILES_SEG_GENERATE_TILES])
    {
        self.generateTilesViewController = segue.destinationViewController;
        self.generateTilesViewController.data = self.data.generateTiles;
    }
}


@end
