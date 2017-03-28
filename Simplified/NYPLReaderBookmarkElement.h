//
//  NYPLReaderBookmarkElement.h
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

@interface  NYPLReaderBookmarkElement : NSObject

@property (nonatomic, readonly) NSString *CFI;
@property (nonatomic, readonly) NSUInteger annotationId;  // this will be used to identify which bookmark to delete


// properties that we will set in NYPLReaderBookmarkCell
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *excerpt;
@property (nonatomic, readonly) NSString *pageNumber;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCFI:(NSString *)CFI;

@end
