//
//  MCBoundingBoxGuideView.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/17/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCBoundingBoxGuideView.h"
#import "mapcache_ios-Swift.h"

@interface MCBoundingBoxGuideView()
@property (nonatomic) CGRect boundingBox;
@end

@implementation MCBoundingBoxGuideView

- (void) viewDidLoad {
    [super viewDidLoad];
    
    UIScreen *screen = [UIScreen mainScreen];
    self.view.frame = screen.bounds;
    [self.view setBounds: screen.bounds];
    self.boundingBox = CGRectMake(32, 64, screen.bounds.size.width - 64, screen.bounds.size.height - 240);
    
    UIBezierPath *overlayPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    UIBezierPath *transparentPath = [UIBezierPath bezierPathWithRect: self.boundingBox];
    [overlayPath appendPath:transparentPath];
    [overlayPath setUsesEvenOddFillRule:YES];

    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = overlayPath.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor;
    //[self.guideView.layer addSublayer:fillLayer];
    [self.guideView.layer insertSublayer:fillLayer below:self.layerButton.layer];
    
    
    if (self.tileServer.serverType == MCTileServerTypeWms) {
        [self.layerButton setHidden:NO];
        
    } else {
        [self.layerButton setHidden:YES];
    }
}



- (IBAction)continue:(id)sender {
    [self.delegate boundingBoxCompletionHandler:self.boundingBox];
}


- (IBAction)cancel:(id)sender {
    [self.delegate boundingBoxCanceled];
}

- (IBAction)chooseLayer:(id)sender {
    NSLog(@"Choosing layer");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select a layer" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (MCLayer *layer in self.tileServer.layers) {
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:layer.title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.delegate layerSelected: [alertController.actions indexOfObject:action]];
        }];
        [alertController addAction:alertAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:^{
            
    }];
}

@end
