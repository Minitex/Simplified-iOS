//
//  NYPLReaderBookmarkElement.m
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#import "NYPLReaderBookmarkElement.h"

@interface NYPLReaderBookmarkElement ()

@property (nonatomic) NSString *CFI;
@property (nonatomic) NSUInteger annotationId;  // this will be used to identify which bookmark to delete


// properties that we will set in NYPLReaderBookmarkCell
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *excerpt;
@property (nonatomic) NSString *pageNumber;

@end

@implementation  NYPLReaderBookmarkElement


- (instancetype)initWithCFI:(NSString *)CFI
{
    self = [super init];
    if(!self) return nil;
    
    self.CFI = CFI;
    self.annotationId = 0;
    
    self.title = @"";
    self.excerpt = @"";
    self.pageNumber = @"";
    
    return self;
}

@end
