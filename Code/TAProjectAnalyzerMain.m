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


@interface TAProjectAnalyzerMain () <TAProjectScannerDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, retain, readwrite) TAProjectScanner*              scanner;
@property (nonatomic, retain, readwrite) NSArray*                       lastResultItems;
@property (nonatomic, retain, readwrite) IBOutlet NSWindow*             sheet;
@property (nonatomic, retain, readwrite) IBOutlet NSProgressIndicator*  progressIndicator;
@property (nonatomic, retain, readwrite) IBOutlet NSScrollView*         scrollTableView;
@property (nonatomic, retain, readwrite) IBOutlet NSTableView*          tableView;

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
        self.scanner = [[[TAProjectScanner alloc] init] autorelease];
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
    [_lastResultItems release], _lastResultItems = nil;
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


#pragma mark - Interface Actions

- (void) showProjectStats:(id)origin
{
    // Get path to current focused document/project
    NSDocument* document = [[NSDocumentController sharedDocumentController] currentDocument];
    NSString* pathToProjectRoot = [[document fileURL] path];
    
    if ([self.scanner scanProjectInPath:pathToProjectRoot])
    {
        // Show sheet with activity indicator and for results later

        NSWindow* currentWindow = [document windowForSheet];
        if (currentWindow != nil)
        {
            if ([NSBundle loadNibNamed:@"AnalyzerSheet" owner:self])
            {
                [NSApp beginSheet:self.sheet
                   modalForWindow:currentWindow
                    modalDelegate:self
                   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
                
                [self.progressIndicator startAnimation:nil];
                [self.scrollTableView setHidden:YES];
                self.lastResultItems = nil;
            }
        }
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

- (void) sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
}


#pragma mark - TAProjectScannerDelegate

- (void) scanner:(TAProjectScanner*)scanner didFinishWithResult:(NSString*)result
{
    if (self.tableView.tableColumns.count == 0)
    {
        // Configure table view
        NSDictionary* columns = @{TAScanResultItemKeyLanguage: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleLanguage"),
                                  TAScanResultItemKeyFiles: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleFiles"),
                                  TAScanResultItemKeyCode: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleCode"),
                                  TAScanResultItemKeyComment: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleComments"),
                                  TAScanResultItemKeyBlank: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleBlank")};
        
        NSArray* columnKeys = @[TAScanResultItemKeyLanguage, TAScanResultItemKeyFiles, TAScanResultItemKeyCode, TAScanResultItemKeyComment, TAScanResultItemKeyBlank];
        for (NSString* key in columnKeys)
        {
            NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:key];
            [column.headerCell setStringValue:[columns objectForKey:key]];
            [self.tableView addTableColumn:column];
            [column release];
        }
    }

    self.lastResultItems = [TAScanResultItem parseItemsFromCSVString:result];
    
    [self.progressIndicator stopAnimation:nil];
    [self.scrollTableView setHidden:NO];
    [self.tableView reloadData];
}

- (void) scanner:(TAProjectScanner*)scanner didFailWithError:(NSString*)error
{
    [NSApp endSheet:self.sheet];

    LogDebug(@"%@", error);

    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:TALocalize(@"TAProjectAnalyzerPluginGeneralErrorMessage")];
    [alert runModal];
}


#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
    return self.lastResultItems.count;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
    TAScanResultItem* item = [self.lastResultItems objectAtIndex:rowIndex];
    
    return [item valueForKey:aTableColumn.identifier];
}


#pragma mark - NSTableViewDelegate

- (BOOL) tableView:(NSTableView*)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row;
{
    return NO;
}

@end
