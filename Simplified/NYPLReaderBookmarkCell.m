//
//  NYPLReaderBookmarkCell.m
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#import "NYPLReaderSettings.h"

#import "NYPLReaderBookmarkCell.h"

@interface NYPLReaderBookmarkCell()

//@property (nonatomic) UILabel *titleLabel;
//@property (nonatomic) UILabel *excerptLabel;
//@property (nonatomic) UILabel *pageNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *excerptLabel;
@property (weak, nonatomic) IBOutlet UILabel *pageNumberLabel;

@end

@implementation NYPLReaderBookmarkCell


// designated initializer
/*
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(!self) return nil;
    
    //self.backgroundColor = [UIColor blueColor];
    self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
    
    
    // set values for titleLabel
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [NYPLReaderSettings sharedSettings].foregroundColor;
    [self.contentView addSubview:self.titleLabel];
    
    // set values for excerptLabel
    self.excerptLabel = [[UILabel alloc] init];
    self.excerptLabel.textColor = [NYPLReaderSettings sharedSettings].foregroundColor;
    [self.contentView addSubview:self.excerptLabel];
    
    // set values for pageNumberLabel
    self.pageNumberLabel = [[UILabel alloc] init];
    self.pageNumberLabel.textColor = [NYPLReaderSettings sharedSettings].foregroundColor;
    [self.contentView addSubview:self.pageNumberLabel];
    
    return self;
  
}
 */

#pragma mark UIView

- (void) layoutSubviews
{
    /*
    CGRect titleFrame = self.contentView.bounds;
    titleFrame.size.height = self.contentView.bounds.size.height / 3.0;
    self.titleLabel.frame = titleFrame;
    
    CGRect excerptFrame = self.contentView.bounds;
    excerptFrame.size.height = self.contentView.bounds.size.height / 3.0;
    //excerptFrame.origin.y = self.contentView.bounds.origin.y / 3.0;
    //excerptFrame.origin.y = self.contentView.bounds.origin.y * 1.3;
    excerptFrame.origin.y += 15 ;
    self.excerptLabel.frame = excerptFrame;
    
    CGRect pageNumberFrame = self.contentView.bounds;
    pageNumberFrame.size.height = self.contentView.bounds.size.height / 3.0;
    //pageNumberFrame.origin.y = self.contentView.bounds.origin.y * (2/3);
    //pageNumberFrame.origin.y = self.contentView.bounds.origin.y * 1.6;
    pageNumberFrame.origin.y += 30;
    self.pageNumberLabel.frame = pageNumberFrame;
     */
}



#pragma mark -

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *const)title
{
    self.titleLabel.text = title;
}

- (NSString *)excerpt
{
    return self.excerptLabel.text;
}

- (void)setExcerpt:(NSString *)excerpt
{
    self.excerptLabel.text = excerpt;
}

- (NSString *)pageNumber
{
    return self.pageNumberLabel.text;
}

- (void)setPageNumber:(NSString *)pageNumber
{
    self.pageNumberLabel.text = pageNumber;
}

@end
