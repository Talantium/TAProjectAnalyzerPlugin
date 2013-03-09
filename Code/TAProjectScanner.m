//
//  TAProjectScanner.m
//  TAProjectAnalyzerPlugin
//
//  Created by Andreas Hanft on 06.03.13.
//  Copyright (c) 2013 talantium.net. All rights reserved.
//

#import "TAProjectScanner.h"


NSString*   const   TAProjectScannerPathToPerl          = @"/usr/bin/perl";
NSString*   const   TAProjectScannerClocName            = @"cloc-1.56";


@interface TAProjectScanner ()

@property (nonatomic, retain, readwrite) NSString*      pathToPerlScript;
@property (nonatomic, retain, readwrite) NSTask*        task;
@property (nonatomic, assign, readwrite) BOOL           abortedManually;

@end


@implementation TAProjectScanner

@dynamic isScanning;


- (id) init
{
    self = [super init];
    if (self)
    {
        self.pathToPerlScript = [[NSBundle bundleForClass:[self class]] pathForResource:TAProjectScannerClocName ofType:@"pl"];
    }
    
    return self;
}

- (void) dealloc
{
    [_pathToPerlScript release], _pathToPerlScript = nil;
    [_scanPath release], _scanPath = nil;
    [_task release], _task = nil;
    
    [super dealloc];
}

- (BOOL) isScanning
{
    return (self.task != nil && [self.task isRunning]);
}

- (BOOL) scan
{
    NSString* path = [self.scanPath path];
    
    if (self.pathToPerlScript.length > 0
        && path.length > 0)
    {
        self.abortedManually = NO;

        NSTask* task = [[NSTask alloc] init];
        {            
            [task setStandardOutput:[NSPipe pipe]];
            [task setStandardError:[NSPipe pipe]];
            [task setLaunchPath:TAProjectScannerPathToPerl];
            [task setArguments:@[self.pathToPerlScript, path, @"--quiet", @"--csv", @"--exclude-dir=build", @"--force-lang=Objective C,m"]];
            [task setTerminationHandler:^(NSTask* task)
            {
                self.task = nil;

                if ([task terminationStatus] == 0)
                {
                    NSPipe* outPipe = task.standardOutput;
                    NSData* output = [[outPipe fileHandleForReading] readDataToEndOfFile];
                    NSString* result = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                    
                    dispatch_sync(dispatch_get_main_queue(),
                    ^{
                        if ([self.delegate respondsToSelector:@selector(scanner:didFinishWithResult:)])
                        {
                            [self.delegate scanner:self didFinishWithResult:result];
                        }
                    });
                    
                    [result release];
                }
                else
                {
                    if (self.abortedManually == NO)
                    {
                        NSPipe* errorPipe = task.standardError;
                        NSData* error = [[errorPipe fileHandleForReading] readDataToEndOfFile];
                        NSString* result = [[NSString alloc] initWithData:error encoding:NSUTF8StringEncoding];
                        
                        dispatch_sync(dispatch_get_main_queue(),
                                      ^{
                                          if ([self.delegate respondsToSelector:@selector(scanner:didFailWithError:)])
                                          {
                                              [self.delegate scanner:self didFailWithError:result];
                                          }
                                      });
                        
                        [result release];
                    }
                }
            }];
            
        }
        [task launch];
        self.task = task;
        [task release];
        
        return YES;
    }
    
    return NO;
}

- (void) abortScan
{
    self.abortedManually = YES;
    [self.task terminate];
    self.task = nil;
}

@end
