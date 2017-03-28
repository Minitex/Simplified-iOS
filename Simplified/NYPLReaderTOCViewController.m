#import "NYPLConfiguration.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCCell.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReaderBookmarkElement.h"
#import "NYPLReaderBookmarkCell.h"
#import "NYPLReadium.h"

#import "NYPLReaderTOCViewController.h"

@interface NYPLReaderTOCViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) RDNavigationElement *navigationElement;
@property (nonatomic) UITableView *tableView;
//@property (nonatomic) NSArray *selectedTextElements; // either Table of Contents, or bookmarks
@property (nonatomic) NSArray *TOCElements;          // we need to save off current TOCElements when we're switching whic data to point to
@property (nonatomic) NSArray *bookmarkElements;     // we need to save off current bookmarks when we're switching which data to point to
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) NSString *dataSource;

@end

static NSString *const reuseIdentifierTOC = @"ReaderTOCCell";
static NSString *const reuseIdentifierBookmark = @"ReaderBookmarkCell";
static NSString *const bookmarkDataSource = @"bookmarkDataSource";
static NSString *const TOCDataSource = @"TOCDataSource";


@implementation NYPLReaderTOCViewController

- (instancetype)initWithTOCElements:(NSArray *const)TOCElements
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"ReaderTOCViewControllerTitle", nil);
  
  self.preferredContentSize = CGSizeMake(320, 1024);
  
  self.TOCElements = TOCElements;
  self.dataSource = TOCDataSource;
    
  return self;
}

- (instancetype)initWithTOCElements:(NSArray *)TOCElements andBookmarkElements:(NSArray *)bookmarkElements
{
    self = [super init];
    if(!self) return nil;
    
    self.title = NSLocalizedString(@"ReaderTOCViewControllerTitle", nil);
    
    self.preferredContentSize = CGSizeMake(320, 1024);
    
    self.TOCElements = TOCElements;
    
    self.bookmarkElements = bookmarkElements;
    
    self.dataSource = TOCDataSource;
    
    // bookmarks should be set here as well. Grabbing bookmarks should also be called everytime we
    // switch to bookmarks in segment control because we don't know if it's been updated since
    
    return self;
}



#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
    
  self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Table of Contents", @"Bookmarks"] ];
    
  self.segmentedControl.frame = CGRectMake(0, 80, self.view.bounds.size.width, 50);
  self.segmentedControl.selectedSegmentIndex = 0;
  self.segmentedControl.tintColor = [UIColor blackColor];
  [self.segmentedControl addTarget:self action:@selector(didSelectSegment) forControlEvents: UIControlEventValueChanged];
  [self.view addSubview:self.segmentedControl];
  
    
  CGRect newTableFrame = self.view.bounds;
  newTableFrame.origin.y += 60;    // move tableview down
  newTableFrame.size.height += 60; // increase tableview height
    
  self.tableView = [[UITableView alloc] initWithFrame:newTableFrame];
  //self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
  self.tableView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
    
  [self.tableView registerClass:[NYPLReaderTOCCell class]
         forCellReuseIdentifier:reuseIdentifierTOC];
  [self.tableView registerClass:[NYPLReaderBookmarkCell class]
         forCellReuseIdentifier:reuseIdentifierBookmark];
    
  [self.view addSubview:self.tableView];
    
  //  [self.view insertSubview:self.tableView belowSubview:self.segmentedControl];
    
  [self.view bringSubviewToFront:self.segmentedControl];
}

- (void)viewWillAppear:(BOOL)animated
{
  switch([NYPLReaderSettings sharedSettings].colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundDarkColor];
      break;
  }
  
  [self.tableView reloadData];

  [super viewWillAppear:animated];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
    NSInteger numRows = self.TOCElements.count;
    
    if (self.dataSource == bookmarkDataSource)
    {
        numRows = self.bookmarkElements.count;
    }
    return numRows;
    
  //return self.selectedTextElements.count;
}

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLReaderTOCCell *const TOCCell = [[NYPLReaderTOCCell alloc]
                                   initWithReuseIdentifier:reuseIdentifierTOC];
    
  
    
  NYPLReaderTOCElement *const TOCElement = self.TOCElements[indexPath.row];
  
    
  TOCCell.nestingLevel = TOCElement.nestingLevel;
  TOCCell.title = TOCElement.title;
    
  NYPLReaderBookmarkCell *const bookmarkCell = [[NYPLReaderBookmarkCell alloc]
                                                  initWithReuseIdentifier:reuseIdentifierBookmark];
    
    // line below crashes the app for some reason. why is that?
  //NYPLReaderBookmarkElement *const bookmarkElement = self.bookmarkElements[indexPath.row];
    
  bookmarkCell.title = @"Bookmark Title";
  bookmarkCell.excerpt = @"Bookmark Excerpt";
  bookmarkCell.pageNumber = @"Bookmark PageNumber";
  //bookmarkCell.pageNumber = bookmarkElement.CFI;
    
  if (self.dataSource == bookmarkDataSource)
  {
      return bookmarkCell;
  }
  return TOCCell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *const)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLReaderTOCElement *const TOCElement = self.TOCElements[indexPath.row];
  
  [self.delegate TOCViewController:self
           didSelectOpaqueLocation:TOCElement.opaqueLocation];
}

- (void) didSelectSegment
{
    NSLog(@"Selected %@", [self.segmentedControl titleForSegmentAtIndex:[self.segmentedControl selectedSegmentIndex]]);
    
     if ([self.segmentedControl selectedSegmentIndex] == 1)
     {
         //NSLog(@"Selected Bookmarks");
         // let's do a get all bookmarks here
         
         // for now, we will display bookmark data to the console only
         NSLog(@"Bookmarks are: %@,", self.bookmarkElements);
         
         
         // For now, we've commented out the code below to prevent the app from crashing
          
          
         for (NYPLReaderBookmarkElement *element in self.bookmarkElements)
         {
             NSLog(@"element: %@", element.CFI);
         }
         
         //self.selectedTextElements = self.bookmarkElements;
        // [self.tableView reloadData];
         self.dataSource = bookmarkDataSource;
    }
    else
    {
        NSLog(@"Table of Contents are:\n");
        //NSLog(@"Table of contents are: %@,", self.TOCElements);
        for (NYPLReaderTOCElement *element in self.TOCElements)
        {
            NSLog(@"element: %@, %lu, %@", element.opaqueLocation, (unsigned long)element.nestingLevel, element.title);
        }
        self.dataSource = TOCDataSource;
    }
    
    [self.tableView reloadData];
    //NSLog(@"Selected something in segmented control");
    
}

@end
