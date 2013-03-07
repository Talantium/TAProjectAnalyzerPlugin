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

@end


@implementation TAProjectScanner

- (id) init
{
    self = [super init];
    if (self)
    {
        self.pathToPerlScript = [[NSBundle bundleForClass:[self class]] pathForResource:TAProjectScannerClocName ofType:@"pl"];
    }
    
    return self;
}

- (void)dealloc
{
    [_pathToPerlScript release], _pathToPerlScript = nil;
    
    [super dealloc];
}

- (BOOL) scanProjectInPath:(NSString*)path
{
    // Document root is the xcodeproj file that is inside the project or workspace
    // bundle, we must remove them first to get to the project root.
    while ([[path lastPathComponent] hasSuffix:@".xcworkspace"]
           || [[path lastPathComponent] hasSuffix:@".xcodeproj"])
    {
        path = [path stringByDeletingLastPathComponent];
    }
    
    if (self.pathToPerlScript.length > 0
        && path.length > 0)
    {        
        NSTask* task = [[[NSTask alloc] init] autorelease];
        {            
            [task setStandardOutput:[NSPipe pipe]];
            [task setStandardError:[NSPipe pipe]];
            [task setLaunchPath:TAProjectScannerPathToPerl];
            [task setArguments:@[self.pathToPerlScript, path, @"--quiet", @"--csv", @"--exclude-dir=build", @"--force-lang=\"Objective C\",m"]];
            [task setTerminationHandler:^(NSTask* task)
            {           
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
            }];
        }
        [task launch];
        
        return YES;
    }
    
    return NO;
}

@end
