typedef NS_ENUM(NSInteger, NYPLCatalogSubsectionLinkType) {
  NYPLCatalogSubsectionLinkTypeAcquisition,
  NYPLCatalogSubsectionLinkTypeNavigation
};

@interface NYPLCatalogSubsectionLink : NSObject

@property (nonatomic, readonly) NYPLCatalogSubsectionLinkType type;
@property (nonatomic, readonly) NSURL *URL;

// designated initializer
- (instancetype)initWithType:(NYPLCatalogSubsectionLinkType)type URL:(NSURL *)URL;

@end