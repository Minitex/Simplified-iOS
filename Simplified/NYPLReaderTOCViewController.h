@class NYPLReaderRendererOpaqueLocation;
@class NYPLReaderTOCViewController;
@class RDNavigationElement;

@protocol NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation;

@end

@interface NYPLReaderTOCViewController : UIViewController

@property (nonatomic, weak) id<NYPLReaderTOCViewControllerDelegate> delegate;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle NS_UNAVAILABLE;

- (instancetype)initWithTOCElements:(NSArray *)TOCElements;
- (instancetype)initWithTOCElements:(NSArray *)TOCElements andBookmarkElements:(NSArray *)bookmarkElements;

@end
