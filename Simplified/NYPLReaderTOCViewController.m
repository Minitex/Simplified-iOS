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
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)didSelectSegment:(id)sender;

@end

static NSString *const reuseIdentifierTOC = @"contentCell";
static NSString *const reuseIdentifierBookmark = @"bookmarkCell";


@implementation NYPLReaderTOCViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
  
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  
    self.title = NSLocalizedString(@"ReaderTOCViewControllerTitle", nil);
    
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

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
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  NSUInteger numRows = 0;
  
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:
      numRows = self.tableOfContents.count;
      break;
    case 1:
      numRows = self.bookmarks.count;
      break;
    default:
      break;
  }
  
  return numRows;
}

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:{
      NYPLReaderTOCCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifierTOC];
      NYPLReaderTOCElement *const toc = self.tableOfContents[indexPath.row];
      
      cell.nestingLevel = toc.nestingLevel;
      cell.titleLabel.text = toc.title;

      return cell;
    }
    case 1:{
      NYPLReaderBookmarkCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifierBookmark];
      
      // line below is a hack for now, so table doesn't crash
      if ((NSInteger)indexPath.row < (NSInteger)self.bookmarks.count)
      {
        NYPLReaderBookmarkElement *const bookmarkElement = self.bookmarks[indexPath.row];
        
        cell.titleLabel.text = @"Bookmark Title";
        cell.excerptLabel.text = @"Bookmark Excerpt";
        cell.pageNumberLabel.text = bookmarkElement.contentCFI;
      }
      return cell;
    }
    default:
      return nil;
  }
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *const)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:{
      NYPLReaderTOCElement *const TOCElement = self.tableOfContents[indexPath.row];
      
      [self.delegate TOCViewController:self
               didSelectOpaqueLocation:TOCElement.opaqueLocation];
      break;
    }
    case 1:{
      // bookmark selected
        NYPLReaderBookmarkElement *const bookmark = self.bookmarks[indexPath.row];
        
        [self.delegate TOCViewController:self
                 didSelectBookmark:bookmark];
        break;
      
    }
    default:
      break;
  }
}

-(CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:
      return 56;
    case 1:
      return 100;
    default:
      return 44;
  }

}


- (IBAction)didSelectSegment:(UISegmentedControl*)sender
{
  NSLog(@"Selected %@", [sender titleForSegmentAtIndex:[sender selectedSegmentIndex]]);
  
  
  switch (sender.selectedSegmentIndex) {
    case 0:
    {
      NSLog(@"Table of Contents are:\n");
      for (NYPLReaderTOCElement *element in self.tableOfContents)
      {
        NSLog(@"element: %@, %lu, %@", element.opaqueLocation, (unsigned long)element.nestingLevel, element.title);
      }
      break;
    }
    case 1:
    {
      NSLog(@"Bookmarks are: %@,", self.bookmarks);
      for (NYPLReaderBookmarkElement *element in self.bookmarks)
      {
        NSLog(@"element CFI: %@, annotationId: %@", element.contentCFI, element.annotationId);
      }
      
    }
    default:
      break;
  }
  
  [self.tableView reloadData];
}
@end
