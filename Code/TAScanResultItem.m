//
//  TAScanResultItem.m
//  TAProjectAnalyzerPlugin
//
//  Created by Andreas Hanft on 06.03.13.
//  Copyright (c) 2013 talantium.net. All rights reserved.
//

/*
 
 Example Result
 
 files,language,blank,comment,code,"http://cloc.sourceforge.net v 1.56  T=0.5 s (8.0 files/s, 17284.0 lines/s)"
 1,Perl,620,938,6953
 2,Objective C,17,14,85
 1,C/C++ Header,4,7,4
 
 */

#import "TAScanResultItem.h"


@implementation TAScanResultItem

- (void) dealloc
{
    [_language release], _language = nil;
    [_files release], _files = nil;
    [_code release], _code = nil;
    [_comment release], _comment = nil;
    [_blank release], _blank = nil;
    
    [super dealloc];
}

+ (id) item
{
    return [[[self alloc] init] autorelease];
}

+ (NSArray*) parseItemsFromCSVString:(NSString*)csv
{
    NSMutableArray* array = [NSMutableArray array];
    NSArray* lines = [csv componentsSeparatedByString:@"\n"];
    NSArray* keys = nil;
    NSUInteger keyCount = 0;
    
    for (NSString* line in lines)
    {
        if (line.length > 0)
        {
            // Is keys not set yet? If so, process first real line as list of keys
            if (keys == nil)
            {
                // Skip lines as long as we do not encounter the header line to
                // avoid garbage...
                if ([line hasPrefix:@"files,language,blank,comment,code"] == NO)
                {
                    continue;
                }
                
                keys = [line componentsSeparatedByString:@","];
                keyCount = keys.count;
            }
            else // A data line
            {
                id item = [self item];
                NSArray* values = [line componentsSeparatedByString:@","];
                
                for (int i = 0; i < keyCount && i < values.count; i++)
                {
                    NSString* key = [keys objectAtIndex:i];
                    NSString* value = [values objectAtIndex:i];
                    if (key && value.length > 0)
                    {
                        [item setValue:value forKey:key];
                    }
                }
                
                [array addObject:item];
            }
        }
    }

    return [NSArray arrayWithArray:array];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"Lang: %@, Files: %@, Code: %@, Comment: %@, Blank: %@", self.language, self.files, self.code, self.comment, self.blank];
}

@end

