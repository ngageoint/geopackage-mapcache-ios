//
//  WMSTileOverlay.m
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "WMSTileOverlay.h"

@interface WMSTileOverlay ()
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@end

@implementation WMSTileOverlay 

- (id) initWithURL: (NSString *) url {
    self.url = url;
    self.username = @"";
    self.password = @"";
    return [super initWithURLTemplate:self.url];
}


- (id) initWithURL:(NSString *) url username:(NSString *)username password:(NSString *)password {
    self.url = url;
    self.username = username;
    self.password = password;
    return [super initWithURLTemplate:self.url];
}


- (double) xOfColumn:(long) column andZoom: (long) zoom {
    double x = (double) column;
    double z = (double) zoom;
    
    return x / pow(2.0, z) * 360.0 - 180;
}


- (double) yOfRow:(long) row andZoom: (long) zoom {
    double y = (double) row;
    double z = (double) zoom;
    double n = M_PI - 2.0 * M_PI * y / pow(2.0, z);
    return 180.0 / M_PI * atan(0.5 * (exp(n) - exp (-n)));
}


- (double) mercatorXOfLongitude: (double) lon {
    return lon * 20037508.34 / 180;

}

- (double) mercatorYOfLatitude: (double) lat {
    double y = log(tan((90 + lat) * M_PI / 360)) / (M_PI / 180);
    y = y * 20037508.34 / 180;
    return y;
}


- (long) tileZ: (MKZoomScale) zoomScale {
    double numTilesAt1_0 = MKMapSizeWorld.width / 256.0;
    double zoomLevelAt1_0 = log2(numTilesAt1_0);
    double zoomLevel = MAX(0, zoomLevelAt1_0 + floor(log2f((float)zoomScale)) + 0.5);
    return (long) zoomLevel;
}


- (NSURL *) URLForTilePath:(MKTileOverlayPath) path {
    double left = [self mercatorXOfLongitude: [self xOfColumn:path.x andZoom:path.z]];
    double right = [self mercatorXOfLongitude: [self xOfColumn:path.x+1 andZoom:path.z]];
    double bottom = [self mercatorYOfLatitude: [self yOfRow: path.y+1 andZoom:path.z]];
    double top = [self mercatorYOfLatitude: [self yOfRow:path.y andZoom:path.z]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@&BBOX=%f,%f,%f,%f", self.url, left, bottom, right, top]];
    return url;
}


- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData * _Nullable, NSError * _Nullable))result {
    NSURL *url1 = [self URLForTilePath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url1];
    request.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    if (![self.username isEqualToString:@""] && ![self.password isEqualToString:@""]) {
        NSString *loginString = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
        NSData *loginData = [loginString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64LoginString =  [loginData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
        NSString *authString = [NSString stringWithFormat:@"Basic %@", base64LoginString];
        [request setValue:authString forHTTPHeaderField:@"Authorization"];
    }
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"WMS Tile Request completion handler");
            result(data, error);
        }] resume];
}

@end
