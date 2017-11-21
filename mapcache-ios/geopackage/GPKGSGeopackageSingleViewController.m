//
//  GPKGSGeopackageSingleViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSGeopackageSingleViewController.h"

@interface GPKGSGeopackageSingleViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *cellArray;
@end

@implementation GPKGSGeopackageSingleViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    GPKGSHeaderCellTableViewCell *headerCell = [_tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = _geoPackage.name;
    
    GPKGSSectionTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"sectionTitle"];
    titleCell.sectionTitleLabel.text = @"Layers";
    
    _cellArray = [[NSMutableArray alloc] initWithObjects: headerCell, titleCell, nil];
    
    // loop over layers, create new cells, push to array
    // add new layer button cell
    // add title cell for reference systems
    // loop over geospatial reference systems create cells, push to array
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) registerCellTypes {
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSHeaderCellDisplay" bundle:nil] forCellReuseIdentifier:@"header"];
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
}


#pragma mark - Delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[_cellArray objectAtIndex:indexPath.row] isMemberOfClass:[GPKGSHeaderCellTableViewCell class]]) {
        return 148;
    } else if ([[_cellArray objectAtIndex:indexPath.row] isMemberOfClass:[GPKGSSectionTitleCell class]]) {
        return 44;
    }
    
    return 40;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}

@end
