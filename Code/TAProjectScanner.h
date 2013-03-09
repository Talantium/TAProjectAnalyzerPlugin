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
@property (nonatomic, retain, readwrite) NSURL*                         scanPath;
@property (nonatomic, assign, readonly)  BOOL                           isScanning;

- (BOOL) scan;
- (void) abortScan;

@end


@protocol TAProjectScannerDelegate <NSObject>

@optional
    - (void) scanner:(TAProjectScanner*)scanner didFinishWithResult:(NSString*)result;
    - (void) scanner:(TAProjectScanner*)scanner didFailWithError:(NSString*)error;

@end