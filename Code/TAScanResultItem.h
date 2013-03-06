//
//  TAScanResultItem.h
//  TAProjectAnalyzerPlugin
//
//  Created by Andreas Hanft on 06.03.13.
//  Copyright (c) 2013 talantium.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TAScanResultItem : NSObject

@property (nonatomic, retain, readwrite) NSString*      language;
@property (nonatomic, retain, readwrite) NSNumber*      files;
@property (nonatomic, retain, readwrite) NSNumber*      code;
@property (nonatomic, retain, readwrite) NSNumber*      comment;
@property (nonatomic, retain, readwrite) NSNumber*      blank;

+ (id) item;
+ (NSArray*) parseItemsFromCSVString:(NSString*)csv;

@end
