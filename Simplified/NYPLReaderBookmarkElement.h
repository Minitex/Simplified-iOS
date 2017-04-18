//
//  NYPLReaderBookmarkElement.h
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

@interface  NYPLReaderBookmarkElement : NSObject

@property (nonatomic, readonly) NSString *contentCFI;
@property (nonatomic, readonly) NSString *annotationId;  // this will be used to identify which bookmark to delete
@property (nonatomic, readonly) NSString *idref;         // This is like the chapter


// properties that we will set in NYPLReaderBookmarkCell
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *excerpt;
@property (nonatomic, readonly) NSString *pageNumber;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCFI:(NSString *)CFI andId:(NSString *)annotationId andIdref:(NSString *)idref;

@end
