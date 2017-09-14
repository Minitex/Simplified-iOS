#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLBook.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLCatalogGroupedFeed.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLIndeterminateProgressView.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLSession.h"
#import "NYPLXML.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLSettings.h"

#import "NYPLCatalogGroupedFeedViewController.h"

#import <PureLayout/PureLayout.h>

static CGFloat const rowHeight = 115.0;
static CGFloat const sectionHeaderHeight = 50.0;

@interface NYPLCatalogGroupedFeedViewController ()
  <NYPLCatalogLaneCellDelegate, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic) NSMutableDictionary *bookIdentifiersToImages;
@property (nonatomic) NSMutableDictionary *cachedLaneCells;
@property (nonatomic) NYPLCatalogGroupedFeed *feed;
@property (nonatomic) NSUInteger indexOfNextLaneRequiringImageDownload;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NYPLOpenSearchDescription *searchDescription;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NYPLBook *mostRecentBookSelected;
@property (nonatomic) int tempBookPosition;

@end

@implementation NYPLCatalogGroupedFeedViewController

#pragma mark NSObject

- (instancetype)initWithGroupedFeed:(NYPLCatalogGroupedFeed *)feed
{
  self = [super init];
  if(!self) return nil;
  
  self.bookIdentifiersToImages = [NSMutableDictionary dictionary];
  self.cachedLaneCells = [NSMutableDictionary dictionary];
  self.feed = feed;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(userDidRefresh:) forControlEvents:UIControlEventValueChanged];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  if (@available(iOS 11.0, *)) {
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  [self.tableView addSubview:self.refreshControl];
  [self.view addSubview:self.tableView];
  
  if(self.feed.openSearchURL) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithImage:[UIImage imageNamed:@"Search"]
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(didSelectSearch)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = NSLocalizedString(@"Search", nil);
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self fetchOpenSearchDescription];
  }
  
  [self downloadImages];
  [self enable3DTouch];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
  [super didMoveToParentViewController:parent];
  
  if(parent) {
    CGFloat top = parent.topLayoutGuide.length;
    CGFloat bottom = parent.bottomLayoutGuide.length;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(top, 0, bottom, 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
    [self.tableView setContentOffset:CGPointMake(0, -top) animated:NO];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  [self.cachedLaneCells removeAllObjects];
}

- (void)userDidRefresh:(UIRefreshControl *)refreshControl
{
  if ([[self.navigationController.visibleViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] &&
      [self.navigationController.visibleViewController respondsToSelector:@selector(load)]) {
    NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.navigationController.visibleViewController;
    [viewController load];
  }
  
  [refreshControl endRefreshing];
  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (!self.presentedViewController) {
    self.mostRecentBookSelected = nil;
  }
}

// Transition book detail view between Form Sheet and Nav Controller
// when changing between compact and regular size classes
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  NYPLLOG_F(@"View's horizontal size class changed from %ld to %ld",
            (long)previousTraitCollection.horizontalSizeClass,
            (long)self.traitCollection.horizontalSizeClass);

  if (!self.mostRecentBookSelected) {
    return;
  }

  if (self.presentedViewController) {
    [self dismissViewControllerAnimated:NO completion:nil];
  } else if ([self.navigationController viewControllers].count > 1) {
    [self.navigationController popToRootViewControllerAnimated:NO];
  }

  [[[NYPLBookDetailViewController alloc] initWithBook:self.mostRecentBookSelected] presentFromViewController:self];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // Caching cells helps with performance and lets us retain horizontal scroll positions. Cells are
  // only stored in |self.cachedLaneCells| if they are final.
  UITableViewCell *const cachedCell = self.cachedLaneCells[indexPath];
  if(cachedCell) {
    return cachedCell;
  }
  
  if(indexPath.section < (NSInteger) self.indexOfNextLaneRequiringImageDownload) {
    NYPLCatalogLaneCell *const cell =
    [[NYPLCatalogLaneCell alloc]
     initWithLaneIndex:indexPath.section
     books:((NYPLCatalogLane *) self.feed.lanes[indexPath.section]).books
     bookIdentifiersToImages:self.bookIdentifiersToImages];
    cell.delegate = self;
    self.cachedLaneCells[indexPath] = cell;
    return cell;
  } else {
    UITableViewCell *const cell = [[UITableViewCell alloc] init];
    CGRect const progressViewFrame = CGRectMake(5,
                                                0,
                                                CGRectGetWidth(cell.contentView.bounds) - 10,
                                                CGRectGetHeight(cell.contentView.bounds));
    NYPLIndeterminateProgressView *const progressView = [[NYPLIndeterminateProgressView alloc]
                                                         initWithFrame:progressViewFrame];
    progressView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
    progressView.color = [UIColor colorWithWhite:0.95 alpha:1.0];
    progressView.layer.borderWidth = 2;
    progressView.speedMultiplier = 2.0;
    [progressView startAnimating];
    [cell.contentView addSubview:progressView];
    return cell;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.feed.lanes.count;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return rowHeight;
}

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForHeaderInSection:(__attribute__((unused)) NSInteger)section
{
  return sectionHeaderHeight;
}

- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForHeaderInSection:(NSInteger const)section
{
  CGRect const frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), sectionHeaderHeight);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  view.backgroundColor = [[NYPLConfiguration backgroundColor] colorWithAlphaComponent:0.9];
  
  {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = [UIFont systemFontOfSize:21];
    NSString *const title = ((NYPLCatalogLane *) self.feed.lanes[section]).title;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    if (CGRectGetWidth(button.frame) > self.tableView.frame.size.width - 100) {
      button.frame = CGRectMake(7, 5, self.tableView.frame.size.width - 100, CGRectGetHeight(button.frame));
    } else {
      button.frame = CGRectMake(7, 5, CGRectGetWidth(button.frame), CGRectGetHeight(button.frame));
    }
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    button.tag = section;
    [button addTarget:self
               action:@selector(didSelectCategory:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [view addSubview:button];
  }
  
  {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = [UIFont systemFontOfSize:13];
    NSString *const title = NSLocalizedString(@"More...", nil);
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(CGRectGetWidth(view.frame) - CGRectGetWidth(button.frame) - 10,
                              13,
                              CGRectGetWidth(button.frame),
                              CGRectGetHeight(button.frame));
    button.tag = section;
    NYPLCatalogLane *const lane = self.feed.lanes[button.tag];
    button.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"MoreBooks", nil), lane.title];
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [button addTarget:self
               action:@selector(didSelectCategory:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [view addSubview:button];
  }
  return view;
}

#pragma mark NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *const)cell
     didSelectBookIndex:(NSUInteger const)bookIndex
{
  NYPLCatalogLane *const lane = self.feed.lanes[cell.laneIndex];
  NYPLBook *const feedBook = lane.books[bookIndex];
  
  NYPLBook *const localBook = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:feedBook.identifier];
  NYPLBook *const book = (localBook != nil) ? localBook : feedBook;
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
  self.mostRecentBookSelected = book;
}

#pragma mark - 3D Touch

- (void)enable3DTouch
{
  if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
      (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
    [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
  }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
              viewControllerForLocation:(CGPoint)location
{
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
  NYPLCatalogLaneCell *cell = (NYPLCatalogLaneCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  
  UIViewController *vc = [[UIViewController alloc] init];
  vc.view.tag = cell.laneIndex;
  
  for (UIButton *button in cell.buttons) {
    CGPoint referencePoint = [[button superview] convertPoint:location fromView:self.tableView];
    if (CGRectContainsPoint(button.frame, referencePoint)) {
      UIImageView *imgView = [[UIImageView alloc] initWithImage:button.imageView.image];
      imgView.contentMode = UIViewContentModeScaleAspectFill;
      [vc.view addSubview:imgView];
      [imgView autoPinEdgesToSuperviewEdges];
      vc.preferredContentSize = CGSizeZero;
      previewingContext.sourceRect = [self.tableView convertRect:button.frame fromView:[button superview]];
      
      self.tempBookPosition = (int)button.tag;
      
      return vc;
    }
  }
  return nil;
}

- (void)previewingContext:(__unused id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit
{
  NYPLCatalogLane *const lane = self.feed.lanes[viewControllerToCommit.view.tag];
  NYPLBook *const feedBook = lane.books[self.tempBookPosition];
  NYPLBook *const localBook = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:feedBook.identifier];
  NYPLBook *const book = (localBook != nil) ? localBook : feedBook;
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark -

- (void)downloadImages
{
  if(self.indexOfNextLaneRequiringImageDownload >= self.feed.lanes.count) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    return;
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NYPLCatalogLane *const lane = self.feed.lanes[self.indexOfNextLaneRequiringImageDownload];
  
  [[NYPLBookRegistry sharedRegistry]
   thumbnailImagesForBooks:[NSSet setWithArray:lane.books]
   handler:^(NSDictionary *const bookIdentifiersToImages) {
     [self.bookIdentifiersToImages addEntriesFromDictionary:bookIdentifiersToImages];
     
     // We update this before reloading so that the delegate accurately knows which lanes already
     // have had their covers downloaded.
     ++self.indexOfNextLaneRequiringImageDownload;
     
     [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:
                                     (self.indexOfNextLaneRequiringImageDownload - 1)]
                   withRowAnimation:UITableViewRowAnimationNone];
     
     [self downloadImages];
   }];
}

- (void)didSelectCategory:(UIButton *const)button
{
  NYPLCatalogLane *const lane = self.feed.lanes[button.tag];
  
  UIViewController *const viewController = [[NYPLCatalogFeedViewController alloc]
                                            initWithURL:lane.subsectionURL];
  
  viewController.title = lane.title;

  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc]
                       initWithOpenSearchDescription:self.searchDescription]
   animated:YES];
}

- (void)fetchOpenSearchDescription
{
  [NYPLOpenSearchDescription
   withURL:self.feed.openSearchURL
   completionHandler:^(NYPLOpenSearchDescription *const description) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.searchDescription = description;
       self.navigationItem.rightBarButtonItem.enabled = YES;
     }];
   }];
}

@end
