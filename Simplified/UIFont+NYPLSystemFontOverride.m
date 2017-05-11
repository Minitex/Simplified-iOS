#import "NYPLConfiguration.h"

#import "UIFont+NYPLSystemFontOverride.h"

@implementation UIFont (NYPLSystemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
  return [UIFont fontWithName:[NYPLConfiguration boldSystemFontName] size:fontSize];
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
  return [UIFont fontWithName:[NYPLConfiguration systemFontName] size:fontSize];
}

#pragma clang diagnostic pop

+ (UIFont *)customFontForTextStyle:(UIFontTextStyle)style {
  UIFont *preferredFont = [UIFont preferredFontForTextStyle:style];
  NSDictionary *traitDict = [(NSDictionary *)preferredFont.fontDescriptor objectForKey:UIFontDescriptorTraitsAttribute];
  NSNumber *weight = traitDict[UIFontWeightTrait];
  
  NSDictionary *attributes = @{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:weight}};
  UIFontDescriptor *newDescriptor = [[[UIFontDescriptor fontDescriptorWithName:preferredFont.fontName
                                                                          size:preferredFont.pointSize]
                                                      fontDescriptorWithFamily:[NYPLConfiguration systemFontFamilyName]]
                                              fontDescriptorByAddingAttributes:attributes];
  
  return [UIFont fontWithDescriptor:newDescriptor size:preferredFont.pointSize];
}

+ (UIFont *)customBoldFontForTextStyle:(UIFontTextStyle)style {
  UIFont *preferredFont = [UIFont preferredFontForTextStyle:style];
  NSDictionary *attributes = @{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightBold)}};
  UIFontDescriptor *newDescriptor = [[[UIFontDescriptor fontDescriptorWithName:preferredFont.fontName
                                                                          size:preferredFont.pointSize]
                                      fontDescriptorWithFamily:[NYPLConfiguration systemFontFamilyName]]
                                     fontDescriptorByAddingAttributes:attributes];
  
  return [UIFont fontWithDescriptor:newDescriptor size:preferredFont.pointSize];
}

@end
