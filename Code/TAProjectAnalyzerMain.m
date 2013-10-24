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
@property (nonatomic, retain, readwrite) IBOutlet NSWindow*             sheet; // Retain top level NIB element
@property (nonatomic, assign, readwrite) IBOutlet NSProgressIndicator*  progressIndicator;
@property (nonatomic, assign, readwrite) IBOutlet NSScrollView*         scrollTableView;
@property (nonatomic, assign, readwrite) IBOutlet NSTableView*          tableView;
@property (nonatomic, assign, readwrite) IBOutlet NSTextField*          textFieldScannedFolder;
@property (nonatomic, assign, readwrite) IBOutlet NSTextField*          textFieldStaticInfo;
@property (nonatomic, assign, readwrite) IBOutlet NSButton*             buttonStartStopScan;
@property (nonatomic, assign, readwrite) IBOutlet NSButton*             buttonChooseFolder;

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
    self.scanner.scanPath = [self projectRootURL];
    if ([self.scanner scan])
    {
        // Show sheet with activity indicator and for results later
        NSDocument* document = [[NSDocumentController sharedDocumentController] currentDocument];
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
                
                [self startScan];
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
    [self.scanner abortScan];
    [NSApp endSheet:self.sheet];
}

- (IBAction) chooseFolderToScan:(id)sender
{    
    __block NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setDirectoryURL:self.scanner.scanPath];
    [panel beginSheetModalForWindow:self.sheet
                  completionHandler:
     ^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            NSURL* selectedURL = [[panel URLs] lastObject];
            if (selectedURL)
            {
                self.scanner.scanPath = selectedURL;
                [self startScan];
            }
        }
    }];
}

- (IBAction) startStopScan:(id)sender
{
    if (self.scanner.isScanning)
    {
        [self stopScan];
    }
    else
    {
        [self startScan];
    }
}

- (void) sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
}


#pragma mark - Scanning

- (NSURL*) projectRootURL
{
    NSDocument* document = [[NSDocumentController sharedDocumentController] currentDocument];
    NSURL* projectFileURL = [document fileURL];
        
    // Document root is the xcodeproj file that is inside the project or workspace
    // bundle, we must remove them first to get to the project root.
    while ([[projectFileURL lastPathComponent] hasSuffix:@".xcworkspace"]
           || [[projectFileURL lastPathComponent] hasSuffix:@".xcodeproj"])
    {
        projectFileURL = [projectFileURL URLByDeletingLastPathComponent];
    }
    
    return projectFileURL;
}

- (void) startScan
{
    BOOL scanning = self.scanner.isScanning;
    if (scanning == NO)
    {
        scanning = [self.scanner scan];
    }
    
    if (scanning)
    {
        // Clear last result
        self.lastResultItems = nil;
        
        [self.scrollTableView setHidden:YES];
        
        [self.progressIndicator startAnimation:nil];
        [self.textFieldScannedFolder setHidden:NO];
        [self.textFieldStaticInfo setHidden:NO];
        
        [self.buttonChooseFolder setEnabled:NO];
        [self.buttonStartStopScan setTitle:TALocalize(@"TAProjectAnalyzerPluginButtonAbortTitle")];
        [self.textFieldScannedFolder.cell setTitle:[self.scanner.scanPath path]];
    }
    else
    {
        // Some error message?
    }
}

- (void) stopScan
{
    [self.scanner abortScan];
    if (self.scanner.isScanning == NO)
    {
        [self.buttonChooseFolder setEnabled:YES];
        [self.buttonStartStopScan setTitle:TALocalize(@"TAProjectAnalyzerPluginButtonRescanTitle")];
    }
    
    [self.progressIndicator stopAnimation:nil];
    [self.textFieldScannedFolder setHidden:YES];
    [self.textFieldStaticInfo setHidden:YES];
    
    [self.scrollTableView setHidden:NO];
    [self.tableView reloadData];
}


#pragma mark - TAProjectScannerDelegate

- (void) scanner:(TAProjectScanner*)scanner didFinishWithResult:(NSString*)result
{
    [self configureTableView];

    self.lastResultItems = [TAScanResultItem parseItemsFromCSVString:result];
    
    [self stopScan];
}

- (void) scanner:(TAProjectScanner*)scanner didFailWithError:(NSString*)error
{
    [NSApp endSheet:self.sheet];

    LogDebug(@"%@", error);

    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:TALocalize(@"TAProjectAnalyzerPluginGeneralErrorMessage")];
    [alert runModal];
}

- (void)configureTableView
{
    if (self.tableView.tableColumns.count == 0)
    {
        // Configure table view
        NSDictionary* columns = @{TAScanResultItemKeyLanguage: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleLanguage"),
                                  TAScanResultItemKeyFiles: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleFiles"),
                                  TAScanResultItemKeyCode: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleCode"),
                                  TAScanResultItemKeyComment: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleComments"),
                                  TAScanResultItemKeyBlank: TALocalize(@"TAProjectAnalyzerPluginResultTableTitleBlank")};

        NSArray* columnKeys = @[TAScanResultItemKeyLanguage,
                                TAScanResultItemKeyFiles,
                                TAScanResultItemKeyCode,
                                TAScanResultItemKeyComment,
                                TAScanResultItemKeyBlank];

        for (NSString* key in columnKeys)
        {
            NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:key];

            if ([key isEqual:TAScanResultItemKeyLanguage])
            {
                [column setResizingMask:NSTableColumnAutoresizingMask];
            }
            else
            {
                [column.dataCell setAlignment:NSRightTextAlignment];
            }

            if ([key isEqual:TAScanResultItemKeyFiles])
            {
                CGFloat regularWidth = (self.tableView.frame.size.width/columnKeys.count);
                [column setMaxWidth:regularWidth - 24.0f];
            }

            [column.headerCell setStringValue:[columns objectForKey:key]];
            [self.tableView addTableColumn:column];
            [column release];
        }
    }
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
