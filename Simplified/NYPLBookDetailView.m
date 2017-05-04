#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookCellDelegate.h"
#import "NYPLBookDetailButtonsView.h"
#import "NYPLBookDetailDownloadFailedView.h"
#import "NYPLBookDetailDownloadingView.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLBookDetailView.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"
#import "UIFont+NYPLSystemFontOverride.h"

#import <PureLayout/PureLayout.h>

@interface NYPLBookDetailView () <NYPLBookDetailDownloadingDelegate>

@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) BOOL beganInitialRequest;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIVisualEffectView *visualEffectView;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) UIImageView *blurCoverImageView;
@property (nonatomic) UIButton *closeButton;

@property (nonatomic) NYPLBookDetailButtonsView *buttonsView;

@property (nonatomic) NYPLBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) NYPLBookDetailDownloadingView *downloadingView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;

@property (nonatomic) UILabel *summarySectionLabel;
@property (nonatomic) UITextView *summaryTextView;
@property (nonatomic) NSLayoutConstraint *textHeightConstraint;
@property (nonatomic) UIButton *readMoreLabel;

@property (nonatomic) UILabel *infoSectionLabel;
@property (nonatomic) UILabel *publishedLabelKey;
@property (nonatomic) UILabel *publisherLabelKey;
@property (nonatomic) UILabel *categoriesLabelKey;
@property (nonatomic) UILabel *distributorLabelKey;
@property (nonatomic) UILabel *publishedLabelValue;
@property (nonatomic) UILabel *publisherLabelValue;
@property (nonatomic) UILabel *categoriesLabelValue;
@property (nonatomic) UILabel *distributorLabelValue;

@property (nonatomic) UIView *topFootnoteSeparater;
@property (nonatomic) UIView *bottomFootnoteSeparator;

@end

static CGFloat const SubtitleBaselineOffset = 10;
static CGFloat const AuthorBaselineOffset = 12;
static CGFloat const CoverImageAspectRatio = 0.8;
static CGFloat const CoverImageMaxWidth = 160.0;
static CGFloat const TitleLabelMinimumWidth = 185.0;
static CGFloat const NormalViewMinimumHeight = 38.0;
static CGFloat const VerticalPadding = 10.0;
static CGFloat const MainTextPaddingLeft = 10.0;
static CGFloat const SummaryTextAbbreviatedHeight = 150.0;
static NSString *DetailHTMLTemplate = nil;

@implementation NYPLBookDetailView

// designated initializer
- (instancetype)initWithBook:(NYPLBook *const)book
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.book = book;
  self.backgroundColor = [NYPLConfiguration backgroundColor];
  self.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.contentView = [[UIView alloc] init];
  self.contentView.layoutMargins = UIEdgeInsetsMake(self.layoutMargins.top,
                                                    self.layoutMargins.left+12,
                                                    self.layoutMargins.bottom,
                                                    self.layoutMargins.right+12);
  
  
  
  [self createHeaderLabels];
  [self createFooterLabels];
  
  self.buttonsView = [[NYPLBookDetailButtonsView alloc] init];
  self.buttonsView.translatesAutoresizingMaskIntoConstraints = NO;
  self.buttonsView.showReturnButtonIfApplicable = YES;
  self.buttonsView.delegate = [NYPLBookCellDelegate sharedDelegate];
  self.buttonsView.downloadingDelegate = self;
  self.buttonsView.book = book;
  
  [self addSubview:self.contentView];
  [self.contentView addSubview:self.blurCoverImageView];
  [self.contentView addSubview:self.visualEffectView];
  [self.contentView addSubview:self.coverImageView];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subtitleLabel];
  [self.contentView addSubview:self.authorsLabel];
  [self.contentView addSubview:self.buttonsView];
  [self.contentView addSubview:self.summarySectionLabel];
  [self.contentView addSubview:self.summaryTextView];
  [self.contentView addSubview:self.readMoreLabel];
  
  [self.contentView addSubview:self.topFootnoteSeparater];
  [self.contentView addSubview:self.infoSectionLabel];
  [self.contentView addSubview:self.publishedLabelKey];
  [self.contentView addSubview:self.publisherLabelKey];
  [self.contentView addSubview:self.categoriesLabelKey];
  [self.contentView addSubview:self.distributorLabelKey];
  [self.contentView addSubview:self.publishedLabelValue];
  [self.contentView addSubview:self.publisherLabelValue];
  [self.contentView addSubview:self.categoriesLabelValue];
  [self.contentView addSubview:self.distributorLabelValue];
  [self.contentView addSubview:self.bottomFootnoteSeparator];
  [self.contentView addSubview:self.reportProblemLabel];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:self.closeButton];
  }
  
  [self createDownloadViews];
  [self updateFonts];
  
  return self;
}

- (void)updateFonts
{
  self.titleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleHeadline];
  self.subtitleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption2];
  self.authorsLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption2];
  self.summaryTextView.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1];
  self.readMoreLabel.titleLabel.font = [UIFont systemFontOfSize:14];
  self.reportProblemLabel.titleLabel.font = [UIFont systemFontOfSize:14];
}

- (void)createHeaderLabels
{
  UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.blurCoverImageView = [[UIImageView alloc] init];
  self.blurCoverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.blurCoverImageView.alpha = 0.4f;
  
  [[NYPLBookRegistry sharedRegistry]
   thumbnailImageForBook:self.book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
     self.blurCoverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.numberOfLines = 2;
  self.titleLabel.attributedText = NYPLAttributedStringForTitleFromString(self.book.title);
  
  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.attributedText = NYPLAttributedStringForTitleFromString(self.book.subtitle);
  self.subtitleLabel.numberOfLines = 3;
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authorsLabel.numberOfLines = 2;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.authorsLabel.text = self.book.authors;
  } else {
    self.authorsLabel.attributedText = NYPLAttributedStringForAuthorsFromString(self.book.authors);
  }
  
  self.summarySectionLabel = [[UILabel alloc] init];
  self.summarySectionLabel.font = [UIFont boldSystemFontOfSize:12.0];
  self.summarySectionLabel.text = @"Description";
  self.infoSectionLabel = [[UILabel alloc] init];
  self.infoSectionLabel.font = [UIFont boldSystemFontOfSize:12.0];
  self.infoSectionLabel.text = @"Information";
  
  self.summaryTextView = [[UITextView alloc] init];
  self.summaryTextView.backgroundColor = [UIColor clearColor];
  self.summaryTextView.scrollEnabled = NO;
  self.summaryTextView.editable = NO;
  self.summaryTextView.clipsToBounds = YES;
  self.summaryTextView.textContainer.lineFragmentPadding = 0;
  [self.summaryTextView setTextContainerInset:UIEdgeInsetsZero];
  
  NSString *htmlString = [NSString stringWithFormat:DetailHTMLTemplate,
                          [NYPLConfiguration systemFontName],
                          self.book.summary ? self.book.summary : @""];
  NSData *htmlData = [htmlString dataUsingEncoding:NSUnicodeStringEncoding];
  NSDictionary *attributes = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
  NSAttributedString *atrString = [[NSAttributedString alloc] initWithData:htmlData options:attributes documentAttributes:nil error:nil];
  self.summaryTextView.attributedText = atrString;
  
  self.readMoreLabel = [[UIButton alloc] init];
  self.readMoreLabel.hidden = YES;
  self.readMoreLabel.titleLabel.textAlignment = NSTextAlignmentRight;
  [self.readMoreLabel addTarget:self action:@selector(readMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
  
  [self.readMoreLabel setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
  [self.readMoreLabel setTitle:NSLocalizedString(@"More...", nil) forState:UIControlStateNormal];
  [self.readMoreLabel setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
}

- (void)createDownloadViews
{
  self.normalView = [[NYPLBookDetailNormalView alloc] init];
  self.normalView.translatesAutoresizingMaskIntoConstraints = NO;
  self.normalView.book = self.book;
  self.normalView.hidden = YES;

  self.downloadFailedView = [[NYPLBookDetailDownloadFailedView alloc] init];
  self.downloadFailedView.hidden = YES;
  
  self.downloadingView = [[NYPLBookDetailDownloadingView alloc] init];
  self.downloadingView.hidden = YES;
  
  [self.contentView addSubview:self.normalView];
  [self.contentView addSubview:self.downloadFailedView];
  [self.contentView addSubview:self.downloadingView];
}

- (void)createFooterLabels
{
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeStyle = NSDateFormatterNoStyle;
  dateFormatter.dateStyle = NSDateFormatterLongStyle;
  
  NSString *const publishedKeyString =
  self.book.published
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Published", nil)]
  : nil;
  
  NSString *const publisherKeyString =
  self.book.publisher
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Publisher", nil)]
  : nil;
  
  NSString *const categoriesKeyString =
  self.book.categoryStrings.count
  ? [NSString stringWithFormat:@"%@: ",
     (self.book.categoryStrings.count == 1
      ? NSLocalizedString(@"Category", nil)
      : NSLocalizedString(@"Categories", nil))]
  : nil;
  
  NSString *const categoriesValueString = self.book.categories;
  NSString *const publishedValueString = self.book.published ? [dateFormatter stringFromDate:self.book.published] : nil;
  NSString *const publisherValueString = self.book.publisher;
  NSString *const distributorKeyString = self.book.distributor ? [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerDistributedByFormat", nil)] : nil;
  
  if (!categoriesValueString && !publishedValueString && !publisherValueString && !self.book.distributor) {
    self.topFootnoteSeparater.hidden = YES;
    self.bottomFootnoteSeparator.hidden = YES;
  }
  
  self.categoriesLabelKey = [self createFooterLabelWithString:categoriesKeyString alignment:NSTextAlignmentRight];
  self.publisherLabelKey = [self createFooterLabelWithString:publisherKeyString alignment:NSTextAlignmentRight];
  self.publishedLabelKey = [self createFooterLabelWithString:publishedKeyString alignment:NSTextAlignmentRight];
  self.distributorLabelKey = [self createFooterLabelWithString:distributorKeyString alignment:NSTextAlignmentRight];
  
  self.categoriesLabelValue = [self createFooterLabelWithString:categoriesValueString alignment:NSTextAlignmentLeft];
  self.categoriesLabelValue.numberOfLines = 2;
  self.publisherLabelValue = [self createFooterLabelWithString:publisherValueString alignment:NSTextAlignmentLeft];
  self.publisherLabelValue.numberOfLines = 2;
  self.publishedLabelValue = [self createFooterLabelWithString:publishedValueString alignment:NSTextAlignmentLeft];
  self.distributorLabelValue = [self createFooterLabelWithString:self.book.distributor alignment:NSTextAlignmentLeft];
  
  self.reportProblemLabel = [[UIButton alloc] init];
  [self.reportProblemLabel setTitle:NSLocalizedString(@"ReportProblem", nil) forState:UIControlStateNormal];
  [self.reportProblemLabel addTarget:self action:@selector(reportProblemTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.reportProblemLabel setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
  
  self.topFootnoteSeparater = [[UIView alloc] init];
  self.topFootnoteSeparater.backgroundColor = [UIColor grayColor];
  self.bottomFootnoteSeparator = [[UIView alloc] init];
  self.bottomFootnoteSeparator.backgroundColor = [UIColor grayColor];
}

- (UILabel *)createFooterLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment
{
  UILabel *label = [[UILabel alloc] init];
  label.textAlignment = alignment;
  label.textColor = [UIColor grayColor];
  label.text = string;
  label.font = [UIFont systemFontOfSize:12];
  return label;
}

- (void)setupAutolayoutConstraints
{
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
  
  [self.visualEffectView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
  [self.visualEffectView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.normalView];
  
  [self.coverImageView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.coverImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:VerticalPadding];
  [self.coverImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.coverImageView withMultiplier:CoverImageAspectRatio];
  [self.coverImageView autoSetDimension:ALDimensionWidth toSize:CoverImageMaxWidth relation:NSLayoutRelationLessThanOrEqual];
  [self.blurCoverImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.coverImageView];
  
  [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  [self.titleLabel autoSetDimension:ALDimensionWidth toSize:TitleLabelMinimumWidth relation:NSLayoutRelationGreaterThanOrEqual];
  NSLayoutConstraint *titleLabelConstraint = [self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  
  [self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.subtitleLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.titleLabel withOffset:SubtitleBaselineOffset];
  
  [self.authorsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.authorsLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  if (self.subtitleLabel.text) {
    [self.authorsLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.subtitleLabel withOffset:AuthorBaselineOffset];
  } else {
    [self.authorsLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.titleLabel withOffset:AuthorBaselineOffset];
  }
  
  [self.buttonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorsLabel withOffset:VerticalPadding relation:NSLayoutRelationGreaterThanOrEqual];
  [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
    [self.buttonsView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.coverImageView];
  }];
  [self.buttonsView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  
  [self.normalView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.normalView autoSetDimension:ALDimensionHeight toSize:NormalViewMinimumHeight relation:NSLayoutRelationGreaterThanOrEqual];
  
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadingView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.downloadingView autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:self.normalView];

  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadFailedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.downloadFailedView autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:self.normalView];
  
  [self.summarySectionLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.summarySectionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.normalView withOffset:VerticalPadding];
  
  [self.summaryTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summarySectionLabel withOffset:VerticalPadding];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  self.textHeightConstraint = [self.summaryTextView autoSetDimension:ALDimensionHeight toSize:SummaryTextAbbreviatedHeight relation:NSLayoutRelationLessThanOrEqual];

  [self.readMoreLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.readMoreLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.readMoreLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBottom ofView:self.summaryTextView];
  
  [self.infoSectionLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.infoSectionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summaryTextView withOffset:VerticalPadding + 40];
  
  [self.publishedLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.publishedLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.infoSectionLabel withOffset:VerticalPadding];
  [self.publishedLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.publishedLabelKey withOffset:MainTextPaddingLeft];
  
  [self.publisherLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.publisherLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publishedLabelValue];
  [self.publisherLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.publisherLabelKey withOffset:MainTextPaddingLeft];
  
  [self.categoriesLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.categoriesLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publisherLabelValue];
  [self.categoriesLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.categoriesLabelKey withOffset:MainTextPaddingLeft];
  
  [self.distributorLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.distributorLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.categoriesLabelValue];
  [self.distributorLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.distributorLabelKey withOffset:MainTextPaddingLeft];
  
  [self.publishedLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.publishedLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.publisherLabelKey];
  [self.publishedLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publishedLabelValue];
  
  [self.publisherLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.publisherLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.categoriesLabelKey];
  [self.publisherLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publisherLabelValue];
  
  [self.categoriesLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.categoriesLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.distributorLabelKey];
  [self.categoriesLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.categoriesLabelValue];
  
  [self.distributorLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.distributorLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.distributorLabelValue];
  
  [self.reportProblemLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bottomFootnoteSeparator withOffset:VerticalPadding];
  [self.reportProblemLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.reportProblemLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
  
  if (!self.book.acquisition.report) {
    self.reportProblemLabel.hidden = YES;
    [self.reportProblemLabel autoSetDimension:ALDimensionHeight toSize:0];
  }
  
  if (self.closeButton) {
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    [self.closeButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.titleLabel];
    [NSLayoutConstraint deactivateConstraints:@[titleLabelConstraint]];
    [self.closeButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.titleLabel withOffset:MainTextPaddingLeft];
  }
  
  [self.topFootnoteSeparater autoSetDimension:ALDimensionHeight toSize: 1.0f / [UIScreen mainScreen].scale];
  [self.topFootnoteSeparater autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.topFootnoteSeparater autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.topFootnoteSeparater autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.infoSectionLabel withOffset:-VerticalPadding];
  
  [self.bottomFootnoteSeparator autoSetDimension:ALDimensionHeight toSize: 1.0f / [UIScreen mainScreen].scale];
  [self.bottomFootnoteSeparator autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.bottomFootnoteSeparator autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.bottomFootnoteSeparator autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.distributorLabelValue withOffset:VerticalPadding];
}

#pragma mark NSObject

+ (void)initialize
{
  DetailHTMLTemplate = [NSString
                    stringWithContentsOfURL:[[NSBundle mainBundle]
                                             URLForResource:@"DetailSummaryTemplate"
                                             withExtension:@"html"]
                    encoding:NSUTF8StringEncoding
                    error:NULL];
  
  assert(DetailHTMLTemplate);
}

- (void)updateConstraints
{
  if (!self.didSetupConstraints) {
    [self setupAutolayoutConstraints];
    self.didSetupConstraints = YES;
  }
  if (self.textHeightConstraint.constant >= SummaryTextAbbreviatedHeight) {
    self.readMoreLabel.hidden = NO;
  } else {
    self.readMoreLabel.hidden = YES;
  }
  [super updateConstraints];
}

#pragma mark NYPLBookDetailDownloadingDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(__attribute__((unused)) NYPLBookDetailDownloadingView *)bookDetailDownloadingView
{
  [self.detailViewDelegate didSelectCancelDownloadingForBookDetailView:self];
}

- (void)didSelectCancelForBookDetailDownloadFailedView:
(__attribute__((unused)) NYPLBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView
{
  [self.detailViewDelegate didSelectCancelDownloadFailedForBookDetailView:self];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(__attribute__((unused)) UIWebView *)webView
{
  [self setNeedsLayout];
}

- (BOOL)webView:(__attribute__((unused)) UIWebView *)webView
shouldStartLoadWithRequest:(__attribute__((unused)) NSURLRequest *)request
navigationType:(__attribute__((unused)) UIWebViewNavigationType)navigationType
{
  // Deny any secondary requests generated by rendering the HTML (e.g. from 'img' tags).
  if(self.beganInitialRequest) return NO;
  
  self.beganInitialRequest = YES;
  
  return YES;
}

#pragma mark -

- (void)setState:(NYPLBookState)state
{
  _state = state;
  
  switch(state) {
    case NYPLBookStateUnregistered:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      if(self.book.acquisition.openAccess || ![[AccountsManager sharedInstance] currentAccount].needsAuth) {
        self.normalView.state = NYPLBookButtonsStateCanKeep;
        self.buttonsView.state = NYPLBookButtonsStateCanKeep;
      } else {
        if (self.book.availableCopies > 0) {
          self.normalView.state = NYPLBookButtonsStateCanBorrow;
          self.buttonsView.state = NYPLBookButtonsStateCanBorrow;
        } else {
          self.normalView.state = NYPLBookButtonsStateCanHold;
          self.buttonsView.state = NYPLBookButtonsStateCanHold;
        }
      }
      break;
    case NYPLBookStateDownloadNeeded:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.normalView.state = NYPLBookButtonsStateDownloadNeeded;
      self.buttonsView.state = NYPLBookButtonsStateDownloadNeeded;
      break;
    case NYPLBookStateDownloading:
//      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:NO];
      self.buttonsView.hidden = NO;
      self.buttonsView.state = NYPLBookButtonsStateDownloadInProgress;
      break;
    case NYPLBookStateDownloadFailed:
//      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = NO;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.buttonsView.state = NYPLBookButtonsStateDownloadFailed;
      break;
    case NYPLBookStateDownloadSuccessful:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.normalView.state = NYPLBookButtonsStateDownloadSuccessful;
      self.buttonsView.state = NYPLBookButtonsStateDownloadSuccessful;
      break;
    case NYPLBookStateHolding:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      if (self.book.availabilityStatus == NYPLBookAvailabilityStatusReady) {
        self.normalView.state = NYPLBookButtonsStateHoldingFOQ;
        self.buttonsView.state = NYPLBookButtonsStateHoldingFOQ;
      } else {
        self.normalView.state = NYPLBookButtonsStateHolding;
        self.buttonsView.state = NYPLBookButtonsStateHolding;
      }
      break;
    case NYPLBookStateUsed:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.normalView.state = NYPLBookButtonsStateUsed;
      self.buttonsView.state = NYPLBookButtonsStateUsed;
      break;
  }
}

- (void)hideDownloadingView:(BOOL)shouldHide
{
  CGFloat duration = 0.5f;
  if (shouldHide) {
    if (!self.downloadingView.isHidden) {
      [UIView transitionWithView:self.downloadingView
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
                        self.downloadingView.hidden = YES;
                      } completion:^(__unused BOOL finished) {
                        self.downloadingView.hidden = YES;
                      }];
    }
  } else {
    if (self.downloadingView.isHidden) {
      [UIView transitionWithView:self.downloadingView
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
                        self.downloadingView.hidden = NO;
                      } completion:^(__unused BOOL finished) {
                        self.downloadingView.hidden = NO;
                      }];
    }
  }
}

- (void)setBook:(NYPLBook *)book
{
  _book = book;
  self.normalView.book = book;
  self.buttonsView.book = book;
}

- (double)downloadProgress
{
  return self.downloadingView.downloadProgress;
}

- (void)setDownloadProgress:(double)downloadProgress
{
  self.downloadingView.downloadProgress = downloadProgress;
}

- (BOOL)downloadStarted
{
  return self.downloadingView.downloadStarted;
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  self.downloadingView.downloadStarted = downloadStarted;
}

- (void)closeButtonPressed
{
  [self.detailViewDelegate didSelectCloseButton:self];
}

-(BOOL)accessibilityPerformEscape {
  [self.detailViewDelegate didSelectCloseButton:self];
  return YES;
}

- (void)reportProblemTapped:(id)sender
{
  [self.detailViewDelegate didSelectReportProblemForBook:self.book sender:sender];
}

- (void)readMoreTapped:(__unused UIButton *)sender
{
  self.textHeightConstraint.active = NO;
  [self.readMoreLabel removeFromSuperview];
}


@end
