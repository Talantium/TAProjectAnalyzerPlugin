//
//  TAProjectScanner.h
//  TAProjectAnalyzerPlugin
//
//  Created by Andreas Hanft on 06.03.13.
//  Copyright (c) 2013 talantium.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TAProjectScannerDelegate;


@interface TAProjectScanner : NSObject

@property (nonatomic, assign, readwrite) id<TAProjectScannerDelegate>   delegate;

- (BOOL) scanProjectInPath:(NSString*)path;

@end


@protocol TAProjectScannerDelegate <NSObject>

@optional
    - (void) scanner:(TAProjectScanner*)scanner didFinishWithResult:(NSString*)result;
    - (void) scanner:(TAProjectScanner*)scanner didFailWithError:(NSString*)error;

@end