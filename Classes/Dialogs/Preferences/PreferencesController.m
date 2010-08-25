// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "PreferencesController.h"
#import "Preferences.h"
#import "ViewTheme.h"
#import "SoundWrapper.h"
#import "ScriptsWrapper.h"

#define LINES_MIN			100
#define LINES_MAX			5000
#define PORT_MIN			1024
#define PORT_MAX			65535

#define WINDOW_TOOLBAR_HEIGHT 56

@interface PreferencesController (Private)
- (void)updateTranscriptFolder;
- (void)updateTheme;
@end

@implementation PreferencesController

@synthesize delegate;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[sounds release];
	[transcriptFolderOpenPanel release];
	[logFont release];
	
	[highlightView release];
	[interfaceView release];
	[alertsView release];
	[stylesView release];
	[transfersView release];
	[logView release];
	[generalView release];
	[scriptsView release];
	[identityView release];
	[floodControlView release];
	[IRCopServicesView release];
	
	[scriptsController release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	scriptsController = [[ScriptsWrapper alloc] init];
	installedScriptsTable.dataSource = scriptsController;
	
	scriptsController.world = world;
	[scriptsController populateData];
	[installedScriptsTable reloadData];
	
	[self updateTranscriptFolder];
	[self updateTheme];
	
	[scriptLocationField setStringValue:[Preferences whereApplicationSupportPath]];
	
	[logFont release];
	logFont = [[NSFont fontWithName:[Preferences themeLogFontName] size:[Preferences themeLogFontSize]] retain];
	
	if (![self.window isVisible]) {
		[self.window center];
	}
	
	[preferenceSelectButton selectItemAtIndex:0];
	
	[self.window makeKeyAndOrderFront:nil];
	[self firstPane:generalView];
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onWindowsWantsClosure:(id)sender {
	[self.window close];
}

- (void)onPrefPaneSelected:(id)sender {
	switch ([sender indexOfSelectedItem]) {
		case 0:
			[self firstPane:generalView];
			break;
		case 1:
			[self firstPane:highlightView];
			break;
		case 2:
			[self firstPane:interfaceView];
			break;
		case 3:
			[self firstPane:alertsView];
			break;
		case 4:
			[self firstPane:stylesView];
			break;
		case 5:
			[self firstPane:transfersView];
			break;
		case 6:
			[self firstPane:logView];
			break;
		case 7:
			[self firstPane:floodControlView];
			break;
		case 8:
			[self firstPane:IRCopServicesView];
			break;
		case 10:
			[self firstPane:identityView];
			break;
		case 11:
			[self firstPane:scriptsView];
			break;
		default:
			[self firstPane:generalView];
			break;
	}
} 

- (void)firstPane:(NSView *)view {
	[self.window setTitle:[NSString stringWithFormat:TXTLS(@"TEXTUAL_PREFERENCES_WINDOW_TITLE"),  [preferenceSelectButton titleOfSelectedItem]]];
																				   
	NSRect windowFrame = [self.window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([self.window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[self.window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}

#pragma mark -
#pragma mark KVC Properties

- (void)setFontDisplayName:(NSString*)value
{
	[Preferences setThemeLogFontName:value];
}

- (NSString*)fontDisplayName
{
	return [Preferences themeLogFontName];
}

- (void)setFontPointSize:(CGFloat)value
{
	[Preferences setThemeLogFontSize:value];
}

- (CGFloat)fontPointSize
{
	return [Preferences themeLogFontSize];
}

- (NSInteger)dccFirstPort
{
	return [Preferences dccFirstPort];
}

- (void)setDccFirstPort:(NSInteger)value
{
	[Preferences setDccFirstPort:value];
}

- (NSInteger)dccLastPort
{
	return [Preferences dccLastPort];
}

- (void)setDccLastPort:(NSInteger)value
{
	[Preferences setDccLastPort:value];
}

- (NSInteger)maxLogLines
{
	return [Preferences maxLogLines];
}

- (void)setMaxLogLines:(NSInteger)value
{
	[Preferences setMaxLogLines:value];
}

- (NSString *)completionSuffix
{
	return [Preferences completionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[Preferences setCompletionSuffix:value];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if ([key isEqualToString:@"maxLogLines"]) {
		NSInteger n = [*value integerValue];
		if (n < LINES_MIN) {
			*value = [NSNumber numberWithInteger:LINES_MIN];
		} else if (n > LINES_MAX) {
			*value = [NSNumber numberWithInteger:LINES_MAX];
		}
	} else if ([key isEqualToString:@"dccFirstPort"]) {
		NSInteger n = [*value integerValue];
		if (n < PORT_MIN) {
			*value = [NSNumber numberWithInteger:PORT_MIN];
		} else if (PORT_MAX < n) {
			*value = [NSNumber numberWithInteger:PORT_MAX];
		}
	} else if ([key isEqualToString:@"dccLastPort"]) {
		NSInteger n = [*value integerValue];
		if (n < PORT_MIN) {
			*value = [NSNumber numberWithInteger:PORT_MIN];
		} else if (PORT_MAX < n) {
			*value = [NSNumber numberWithInteger:PORT_MAX];
		}
	}
	return YES;
}

#pragma mark -
#pragma mark Sounds

- (NSArray*)availableSounds
{
	static NSArray* ary;
	if (!ary) {
		ary = [[NSArray arrayWithObjects:@"-", @"Beep", @"Basso", @"Blow", @"Bottle", @"Frog", @"Funk", @"Glass", @"Hero", @"Morse", @"Ping", @"Pop", @"Purr", @"Sosumi", @"Submarine", @"Tink", nil] retain];
	}
	return ary;
}

- (NSMutableArray*)sounds
{
	if (!sounds) {
		NSMutableArray* ary = [NSMutableArray new];
		SoundWrapper* e;
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_LOGIN];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_DISCONNECT];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_HIGHLIGHT];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_NEW_TALK];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_KICKED];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_INVITED];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_MSG];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_NOTICE];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_TALK_MSG];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_TALK_NOTICE];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_ADDRESS_BOOK_MATCH];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_REQUEST];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_SUCCESS];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_ERROR];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_SEND_SUCCESS];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_SEND_ERROR];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_ADDRESS_BOOK_MATCH];
		[ary addObject:e];
		
		sounds = ary;
	}
	return sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString* path = [Preferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString* dirName = [path lastPathComponent];
	
	NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[icon setSize:NSMakeSize(16, 16)];
	
	NSMenuItem* item = [transcriptFolderButton itemAtIndex:0];
	[item setTitle:dirName];
	[item setImage:icon];
}

- (void)transcriptFolderPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	[transcriptFolderButton selectItem:[transcriptFolderButton itemAtIndex:0]];
	
	if (returnCode == NSOKButton) {
		NSString* path = [[panel filenames] safeObjectAtIndex:0];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		BOOL isDir;
		if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
			[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		[Preferences setTranscriptFolder:[path stringByAbbreviatingWithTildeInPath]];
		[self updateTranscriptFolder];
	}
		
	[transcriptFolderOpenPanel autorelease];
	transcriptFolderOpenPanel = nil;
}	

- (void)onTranscriptFolderChanged:(id)sender
{
	if ([transcriptFolderButton selectedTag] != 2) return;
	
	NSString* path = [Preferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString* parentPath = [path stringByDeletingLastPathComponent];
	
	NSOpenPanel* d = [NSOpenPanel openPanel];
	[d setCanChooseFiles:NO];
	[d setCanChooseDirectories:YES];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:NO];
	[d setCanCreateDirectories:YES];
	[d beginForDirectory:parentPath file:nil types:nil modelessDelegate:self didEndSelector:@selector(transcriptFolderPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	[transcriptFolderOpenPanel release];
	transcriptFolderOpenPanel = [d retain];
}

#pragma mark -
#pragma mark Theme

- (void)updateTheme
{
	[themeButton removeAllItems];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* ary = [NSArray arrayWithObjects:[Preferences whereThemesLocalPath], [Preferences whereThemesPath], nil];
	NSInteger tag = 0;
	
	for (NSString* path in ary) {
		NSMutableSet* set = [NSMutableSet set];
		NSArray* files = [fm contentsOfDirectoryAtPath:path error:NULL];
		for (NSString* file in files) {
			if ([path isEqualToString:[Preferences whereThemesLocalPath]]) {
				if ([fm fileExistsAtPath:[[Preferences whereThemesPath] stringByAppendingPathComponent:[file lastPathComponent]]]) {
					continue;
				}
			}
			
			if ([fm fileExistsAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/design.css", file]]]) {
				NSString* baseName = [file stringByDeletingPathExtension];
				[set addObject:baseName];
			}
		}
		
		files = [[set allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		if (files.count) {
			NSInteger i = 0;
			for (NSString* f in files) {
				NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:@""] autorelease];
				[item setTag:tag];
				[themeButton.menu addItem:item];
				++i;
			}
		}
		
		++tag;
	}
	
	NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
	if (!kindAndName) {
		[themeButton selectItemAtIndex:0];
		return;
	}
	
	NSString* kind = [kindAndName safeObjectAtIndex:0];
	NSString* name = [kindAndName safeObjectAtIndex:1];
	
	NSInteger targetTag = 0;
	if (![kind isEqualToString:@"resource"]) {
		targetTag = 1;
	}
	
	NSInteger count = [themeButton numberOfItems];
	for (NSInteger i=0; i<count; i++) {
		NSMenuItem* item = [themeButton itemAtIndex:i];
		if ([item tag] == targetTag && [[item title] isEqualToString:name]) {
			[themeButton selectItemAtIndex:i];
			break;
		}
	}
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem* item = [themeButton selectedItem];
	NSString* name = [item title];
	if (item.tag == 0) {
		[Preferences setThemeName:[ViewTheme buildResourceFileName:name]];
	} else {
		[Preferences setThemeName:[ViewTheme buildUserFileName:name]];
	}
	[self onLayoutChanged:nil];
}

- (void)onSelectFont:(id)sender
{
	NSFontManager* fm = [NSFontManager sharedFontManager];
	[fm setSelectedFont:logFont isMultiple:NO];
	[fm orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
	[logFont autorelease];
	logFont = [[sender convertFont:logFont] retain];
	
	[self setValue:logFont.fontName forKey:@"fontDisplayName"];
	[self setValue:[NSNumber numberWithDouble:logFont.pointSize] forKey:@"fontPointSize"];
	
	[self onLayoutChanged:nil];
}

- (void)onOverrideFontChanged:(id)sender
{
	[self onLayoutChanged:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[self onLayoutChanged:nil];
}

- (void)onTimestampFormatChanged:(id)sender
{
	[self onLayoutChanged:nil];
}

- (void)onHnagingTextChange:(id)sender 
{
	[self onLayoutChanged:nil];
}

- (void)onTextDirectionChanged:(id)sender
{
	[self onLayoutChanged:nil];
}

#pragma mark -
#pragma mark Actions

- (void)editTable:(NSTableView*)table
{
	NSInteger row = [table numberOfRows] - 1;
	[table scrollRowToVisible:row];
	[table editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
	[keywordsArrayController add:nil];
	[self performSelector:@selector(editTable:) withObject:keywordsTable afterDelay:0];
}

- (void)onAddExcludeWord:(id)sender
{
	[excludeWordsArrayController add:nil];
	[self performSelector:@selector(editTable:) withObject:excludeWordsTable afterDelay:0];
}

- (void)onLayoutChanged:(id)sender
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

- (void)onOpenPathToThemes:(id)sender;
{
	[[NSWorkspace sharedWorkspace] openFile:[Preferences whereThemesPath]];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[Preferences cleanUpWords];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[delegate preferencesDialogWillClose:self];
	}
}

@synthesize contentView;
@synthesize highlightView;
@synthesize interfaceView;
@synthesize alertsView;
@synthesize stylesView;
@synthesize transfersView;
@synthesize logView;
@synthesize generalView;
@synthesize scriptsView;
@synthesize identityView;
@synthesize keywordsTable;
@synthesize excludeWordsTable;
@synthesize keywordsArrayController;
@synthesize excludeWordsArrayController;
@synthesize transcriptFolderButton;
@synthesize themeButton;
@synthesize scriptLocationField;
@synthesize preferenceSelectButton;
@synthesize transcriptFolderOpenPanel;
@synthesize logFont;
@synthesize floodControlView;
@synthesize IRCopServicesView;
@synthesize world;
@synthesize installedScriptsTable;
@synthesize scriptsController;
@end