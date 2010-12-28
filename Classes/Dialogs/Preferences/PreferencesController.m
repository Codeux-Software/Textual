// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define LINES_MIN			100
#define LINES_MAX			5000
#define INLINE_IMAGE_MAX	5000
#define INLINE_IMAGE_MIN	40

#define WINDOW_TOOLBAR_HEIGHT 56

@interface PreferencesController (Private)
- (void)updateTranscriptFolder;
- (void)updateTheme;

- (void)firstPane:(NSView *)view;
@end

@implementation PreferencesController

@synthesize delegate;
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
@synthesize updatesView;
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
@synthesize channelManagementView;
@synthesize timestampSymbolsLinkButton;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
		scriptsController = [[ScriptsWrapper alloc] init];
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
	[updatesView release];
	[floodControlView release];
	[IRCopServicesView release];
	[channelManagementView release];
	
	[scriptsController release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
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
	
	timestampSymbolsLinkButton.urlString = @"http://opengroup.org/onlinepubs/007908799/xsh/strftime.html";
	
	[self.window makeKeyAndOrderFront:nil];
	[self firstPane:generalView];
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onWindowsWantsClosure:(id)sender 
{
	[self.window close];
}

- (void)onPrefPaneSelected:(id)sender 
{
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
			[self firstPane:logView];
			break;
		case 6:
			[self firstPane:floodControlView];
			break;
		case 7:
			[self firstPane:IRCopServicesView];
			break;
		case 8: 
			[self firstPane:channelManagementView];
			break;
		// 9 = divider
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

- (void)firstPane:(NSView *)view 
{
	[self.window setTitle:[preferenceSelectButton titleOfSelectedItem]];
																				   
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
	
	[self.window recalculateKeyViewLoop];
}

#pragma mark -
#pragma mark KVC Properties

- (void)setFontDisplayName:(NSString *)value
{
	[Preferences setThemeLogFontName:value];
}

- (NSString *)fontDisplayName
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

- (NSInteger)inlineImageMaxWidth
{
	return [Preferences inlineImagesMaxWidth];
}

- (void)setInlineImageMaxWidth:(NSInteger)value
{
	[Preferences setInlineImagesMaxWidth:value];
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
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger n = [*value integerValue];
		if (n < INLINE_IMAGE_MIN) {
			*value = [NSNumber numberWithInteger:INLINE_IMAGE_MIN];
		} else if (INLINE_IMAGE_MAX < n) {
			*value = [NSNumber numberWithInteger:INLINE_IMAGE_MAX];
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Sounds

- (NSArray *)availableSounds
{
	NSMutableArray *sound_list = [NSMutableArray array];
	NSArray *directoryContents = [TXNSFileManager() contentsOfDirectoryAtPath:@"/System/Library/Sounds" error:NULL];

	[sound_list addObject:EMPTY_SOUND];
	 
	if (directoryContents && [directoryContents count] > 0) {
		for (NSString *s in directoryContents) {	
			[sound_list addObject:[s safeSubstringToIndex:[s stringPosition:@"."]]];
		}
	}
	
	NSString *home_sounds = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Sounds"];
	NSArray *homeDirectoryContents = [TXNSFileManager() contentsOfDirectoryAtPath:home_sounds error:NULL];
	
	if (homeDirectoryContents && [homeDirectoryContents count] > 0) {
		[sound_list addObject:EMPTY_SOUND];
		
		for (NSString *s in homeDirectoryContents) {	
			[sound_list addObject:[s safeSubstringToIndex:[s stringPosition:@"."]]];
		}		
	}
		
	return sound_list;
}

- (NSMutableArray *)sounds
{
	if (!sounds) {
		NSMutableArray *ary = [NSMutableArray new];
		SoundWrapper *e;
		
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
		
		sounds = ary;
	}
	
	return sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString *path = [Preferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString *dirName = [path lastPathComponent];
	
	NSImage *icon = [TXNSWorkspace() iconForFile:path];
	
	[icon setSize:NSMakeSize(16, 16)];
	
	NSMenuItem *item = [transcriptFolderButton itemAtIndex:0];
	
	[item setTitle:dirName];
	[item setImage:icon];
}

- (void)transcriptFolderPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	[transcriptFolderButton selectItem:[transcriptFolderButton itemAtIndex:0]];
	
	if (returnCode == NSOKButton) {
		NSString *path = [[panel filenames] safeObjectAtIndex:0];
		
		BOOL isDir;
		
		if (![TXNSFileManager() fileExistsAtPath:path isDirectory:&isDir]) {
			[TXNSFileManager() createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
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
	
	NSString *path = [Preferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString *parentPath = [path stringByDeletingLastPathComponent];
	
	NSOpenPanel *d = [NSOpenPanel openPanel];
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
	
	NSArray *ary = [NSArray arrayWithObjects:[Preferences whereThemesLocalPath], [Preferences whereThemesPath], nil];
	NSInteger tag = 0;
	
	for (NSString *path in ary) {
		NSMutableSet *set = [NSMutableSet set];
		NSArray *files = [TXNSFileManager() contentsOfDirectoryAtPath:path error:NULL];
		
		for (NSString *file in files) {
			if ([path isEqualToString:[Preferences whereThemesLocalPath]]) {
				if ([TXNSFileManager() fileExistsAtPath:[[Preferences whereThemesPath] stringByAppendingPathComponent:[file lastPathComponent]]]) {
					continue;
				}
			}
			
			if ([TXNSFileManager() fileExistsAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/design.css", file]]]) {
				NSString *baseName = [file stringByDeletingPathExtension];
				
				[set addObject:baseName];
			}
		}
		
		files = [[set allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		if (files.count) {
			NSInteger i = 0;
			
			for (NSString *f in files) {
				NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:@""] autorelease];
				
				[item setTag:tag];
				[themeButton.menu addItem:item];
				
				++i;
			}
		}
		
		++tag;
	}
	
	NSArray *kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
	
	if (!kindAndName) {
		[themeButton selectItemAtIndex:0];
		return;
	}
	
	NSString *kind = [kindAndName safeObjectAtIndex:0];
	NSString *name = [kindAndName safeObjectAtIndex:1];
	
	NSInteger targetTag = 0;
	
	if (![kind isEqualToString:@"resource"]) {
		targetTag = 1;
	}
	
	NSInteger count = [themeButton numberOfItems];
	
	for (NSInteger i = 0; i < count; i++) {
		NSMenuItem *item = [themeButton itemAtIndex:i];
		
		if ([item tag] == targetTag && [[item title] isEqualToString:name]) {
			[themeButton selectItemAtIndex:i];
			break;
		}
	}
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem *item = [themeButton selectedItem];
	
	NSString *newThemeName;
	NSString *name = [item title];
	
	if (item.tag == 0) {
		newThemeName = [ViewTheme buildResourceFileName:name];
	} else {
		newThemeName = [ViewTheme buildUserFileName:name];
	}
	
	if ([[Preferences themeName] isEqual:newThemeName]) return;
	
	[Preferences setThemeName:newThemeName];
	[self onLayoutChanged:nil];
}

- (void)onSelectFont:(id)sender
{
	NSFontManager *fm = [NSFontManager sharedFontManager];
	[fm setSelectedFont:logFont isMultiple:NO];
	[fm orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
	[logFont autorelease];
	logFont = [[sender convertFont:logFont] retain];
	
	[self setValue:logFont.fontName forKey:@"fontDisplayName"];
	[self setValue:[NSNumber numberWithDouble:logFont.pointSize] forKey:@"fontPointSize"];
	
	[self onStyleChanged:nil];
}

- (void)onOverrideFontChanged:(id)sender
{
	[self onStyleChanged:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[TXNSNotificationCenter() postNotificationName:TransparencyDidChangeNotification object:nil userInfo:nil];
}

- (void)onTimestampFormatChanged:(id)sender
{
	[self onStyleChanged:nil];
}

- (void)onHnagingTextChange:(id)sender 
{
	[self onStyleChanged:nil];
}

- (void)onTextDirectionChanged:(id)sender
{
	[self onLayoutChanged:nil];
}

- (void)onNicknameColorsDisabled:(id)sender
{
	[self onLayoutChanged:nil];
}

#pragma mark -
#pragma mark Actions

- (void)editTable:(NSTableView *)table
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

- (void)onInputHistorySchemeChanged:(id)sender
{
	[TXNSNotificationCenter() postNotificationName:InputHistoryGlobalSchemeNotification object:nil userInfo:nil];
}

- (void)onLayoutChanged:(id)sender
{
	[TXNSNotificationCenter() postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

- (void)onStyleChanged:(id)sender
{
	[TXNSNotificationCenter() postNotificationName:ThemeStyleDidChangeNotification object:nil userInfo:nil];
}

- (void)onOpenPathToThemes:(id)sender
{
	[TXNSWorkspace() openFile:[Preferences whereThemesPath]];
}

- (void)onOpenPathToScripts:(id)sender
{
	[TXNSWorkspace() openFile:[Preferences whereScriptsPath]];
}


#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[Preferences cleanUpWords];
	
	[TXNSUserDefaults() synchronize];
	
	if ([delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[delegate preferencesDialogWillClose:self];
	}
}

@end