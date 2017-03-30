//
//  NYPLReaderBookmarkCell.h
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

@interface NYPLReaderBookmarkCell : UITableViewCell

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;


@property (nonatomic) NSString *title;
@property (nonatomic) NSString *excerpt;
@property (nonatomic) NSString *pageNumber;

// designated initializer
//- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
