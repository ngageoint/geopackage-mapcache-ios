//
//  GPKGSFieldWithTitleCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextField+Validators.h"
#import "GPKGDataTypes.h"

@interface MCFieldWithTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextField *field;

/**
    When editing the contents of a feature row this can be used to know which column the value of the field will need to be saved to.
 */
@property (strong, nonatomic) NSString *columnName;

/**
    Optional value used when validating data input from MCPointDataViewController. 
 */
@property (nonatomic) enum GPKGDataType dataType;

- (NSString *) fieldValue;
- (void) setTitleText:(NSString *) titleText;
- (void) setPlaceholder:(NSString *) placeholder;
- (void) setFieldText:(NSString *) text;
- (void) setTextFieldDelegate: (id<UITextFieldDelegate>)delegate;
- (void) useReturnKeyDone;
- (void) useReturnKeyNext;
- (void) clearButtonMode;
- (void) setupNumericalKeyboard;
- (void) useNormalAppearance;
- (void) useErrorAppearance;
- (void) useSecureTextEntry;
- (void) useSentenceAutocapitalization;
- (void) useTitleAutocapitalization;
- (void) useNoAutocapitalization;
@end
