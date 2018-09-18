//
//  MCGeoPackageList.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/15/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "MCGeoPackageList.h"

@interface MCGeoPackageList()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end


@implementation MCGeoPackageList

- (instancetype) initWithGeoPackages: (NSMutableArray *) geoPackages asFullView: (BOOL) fullView andDelegate:(id<MCGeoPacakageListViewDelegate>) delegate {
    self = [super initAsFullView:fullView];
    _geoPackages = geoPackages;
    _geopackageListViewDelegate = delegate;
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 126.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"MCGeoPackageCell" bundle:nil] forCellReuseIdentifier:@"geopackage"];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(toggleActive:)];
    longPressRecognizer.minimumPressDuration = 1.5;
    longPressRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:longPressRecognizer];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) updateAndReloadData {
    // TODO add code to do this
}


- (void) toggleActive:(UILongPressGestureRecognizer *) gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (indexPath == nil) {
        NSLog(@"Long press detected, but not on a cell");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Long press on row: %ld", indexPath.row);
        MCGeoPackageCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell activeLayersIndicatorOn];
        [self.geopackageListViewDelegate toggleActive:[_geoPackages objectAtIndex:indexPath.row]];
    } else {
        NSLog(@"Gesture recognizer state %ld", gestureRecognizer.state);
    }
}


- (IBAction)downloadGeopackage:(id)sender {
    [_geopackageListViewDelegate downloadGeopackage];
}



#pragma mark - TableView delegate and data souce methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MCGeoPackageCell *cell = (MCGeoPackageCell *)[self.tableView dequeueReusableCellWithIdentifier:@"geopackage"];
    
    if (!cell) {
        cell = [[MCGeoPackageCell alloc] init];
    }
    
    GPKGSDatabase *gpkg = [_geoPackages objectAtIndex:indexPath.row];
    
    cell.geoPackageNameLabel.text = gpkg.name;
    cell.featureLayerDetailsLabel.text = [NSString stringWithFormat:@"%ld Feature layers", (long)[gpkg getFeatures].count];
    cell.tileLayerDetailsLabel.text = [NSString stringWithFormat:@"%ld Tile layers", (long)[gpkg getTileCount]];
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _geoPackages.count;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GPKGSDatabase *selectedGeoPackage = [_geoPackages objectAtIndex:indexPath.row];
    NSLog(@"didSelectRowAtIndexPath for %@", selectedGeoPackage.name);
    [_geopackageListViewDelegate didSelectGeoPackage:selectedGeoPackage];
}


#pragma mark - MCGeoPackageCoordinatorDelegate method
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *)database withDelete:(BOOL)didDelete {
    
    /*if (didDelete) {
        [self.manager delete:database];
        [self.active removeDatabase:database andPreserveOverlays:false];
    }*/
    
    [self updateAndReloadData];
}


@end
