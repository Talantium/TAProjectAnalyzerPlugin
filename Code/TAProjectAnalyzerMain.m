//
//  TAProjectAnalyzerMain.m
//  TAProjectAnalyzerPlugin
//
//  Created by Andreas Hanft on 06.03.13.
//  Copyright (c) 2013 talantium.net. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "TAProjectAnalyzerMain.h"

#import "TAProjectScanner.h"
#import "TAScanResultItem.h"


@interface TAProjectAnalyzerMain () <TAProjectScannerDelegate>

@property (nonatomic, retain, readwrite) TAProjectScanner*      scanner;
@property (nonatomic, retain, readwrite) IBOutlet   NSWindow*   sheet;

@end


@implementation TAProjectAnalyzerMain

+ (void) pluginDidLoad:(NSBundle*)plugin
{
	static id sharedPlugin = nil;
	static dispatch_once_t once;
	dispatch_once(&once,
                  ^{
                      sharedPlugin = [[self alloc] init];
                  });
}

- (id) init
{
    self = [super init];
    if (self)
    {
        self.scanner = [[TAProjectScanner alloc] init];
        self.scanner.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [_scanner release], _scanner = nil;
    [_sheet release], _sheet = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
    NSMenuItem* parentMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (parentMenuItem)
    {
        [[parentMenuItem submenu] addItem:[NSMenuItem separatorItem]];

        NSMenuItem* newMenuItem = [[NSMenuItem alloc] initWithTitle:TALocalize(@"TAProjectAnalyzerPluginMenuItemTitle")
                                                             action:@selector(showProjectStats:)
                                                      keyEquivalent:@""];
        [newMenuItem setTarget:self];
        [newMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [[parentMenuItem submenu] addItem:newMenuItem];
        [newMenuItem release];
    }
}

- (void) showProjectStats:(id)origin
{
    NSString* pathToProjectRoot = [[[[NSDocumentController sharedDocumentController] currentDocument] fileURL] path];
    
    if ([self.scanner scanProjectInPath:pathToProjectRoot])
    {
        // Show activity
//        if ([NSBundle loadNibNamed:@"AnalyzerSheet" owner:self])
//        {
//            [NSApp beginSheet:self.sheet
//               modalForWindow:[NSApp mainWindow]
//                modalDelegate:self
//               didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
//                  contextInfo:nil];
//        }
    }
    else
    {
        NSAlert* alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:TALocalize(@"TAProjectAnalyzerPluginGeneralErrorMessage")];
        [alert runModal];
    }
}

- (IBAction) closeSheet:(id)sender
{
    [NSApp endSheet:self.sheet];
}

- (void) didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
}

- (void) scanner:(TAProjectScanner*)scanner didFinishWithResult:(NSString*)result
{
    NSArray* items = [TAScanResultItem parseItemsFromCSVString:result];
    
    LogDebug(@"%@", items);
    
    NSMutableString* string = [NSMutableString string];
    
    for (TAScanResultItem* item in items)
    {
        [string appendFormat:@"%@\n", item];
    }
        
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:string];
    [alert runModal];
}

- (void) scanner:(TAProjectScanner*)scanner didFailWithError:(NSString*)error
{
    LogDebug(@"%@", error);

    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:TALocalize(@"TAProjectAnalyzerPluginGeneralErrorMessage")];
    [alert runModal];
}

@end
