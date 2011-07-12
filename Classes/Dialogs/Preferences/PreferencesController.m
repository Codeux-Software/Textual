// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define LINES_MIN			100
#define LINES_MAX			5000
#define INLINE_IMAGE_MAX	5000
#define INLINE_IMAGE_MIN	40

#define WINDOW_TOOLBAR_HEIGHT		82
#define ADDONS_TOOLBAR_ITEM_INDEX	8

@interface PreferencesController (Private)
- (void)updateTranscriptFolder;
- (void)updateTheme;

- (void)setUpToolbarItemsAndMenus;

- (void)firstPane:(NSView *)view selectedItem:(NSInteger)key;
@end

@implementation PreferencesController

@synthesize alertsView;
@synthesize channelManagementView;
@synthesize contentView;
@synthesize delegate;
@synthesize excludeWordsArrayController;
@synthesize excludeWordsTable;
@synthesize floodControlView;
@synthesize generalView;
@synthesize highlightView;
@synthesize identityView;
@synthesize installedScriptsMenu;
@synthesize installedScriptsTable;
@synthesize interfaceView;
@synthesize IRCopServicesView;
@synthesize keywordsArrayController;
@synthesize keywordsTable;
@synthesize logFont;
@synthesize logView;
@synthesize preferenceSelectToolbar;
@synthesize scriptLocationField;
@synthesize scriptsController;
@synthesize scriptsView;
@synthesize stylesView;
@synthesize themeButton;
@synthesize highlightNicknameButton;
@synthesize transcriptFolderButton;
@synthesize addExcludeWordButton;
@synthesize transfersView;
@synthesize updatesView;
@synthesize world;

- (id)initWithWorldController:(IRCWorld *)word
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
		
		world = word;
		scriptsController = [ScriptsWrapper new];
	}
	
	return self;
}

- (void)dealloc
{
	[alertsView drain];
	[channelManagementView drain];
	[floodControlView drain];
	[generalView drain];
	[highlightView drain];
	[identityView drain];
	[interfaceView drain];
	[IRCopServicesView drain];
	[logFont drain];
	[logView drain];
	[scriptsController drain];
	[scriptsView drain];
	[sounds drain];
	[stylesView drain];
	[transfersView drain];
	[updatesView drain];	
	
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	scriptsController.world = world;
	[scriptsController populateData];
	
	installedScriptsTable.dataSource = scriptsController;
	[installedScriptsTable reloadData];
	
	[self updateTranscriptFolder];
	[self updateTheme];
	
	[scriptLocationField setStringValue:[Preferences whereApplicationSupportPath]];
	
	[logFont drain];
	logFont = [[NSFont fontWithName:[Preferences themeLogFontName] size:[Preferences themeLogFontSize]] retain];
	
	if ([self.window isVisible] == NO) {
		[self.window center];
	}
	
	[self.window makeKeyAndOrderFront:nil];
	
	[self setUpToolbarItemsAndMenus];
    [self onHighlightTypeChanged:nil];
	[self firstPane:generalView selectedItem:0];
}

- (void)onWindowsWantsClosure:(id)sender 
{
	[self.window close];
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{		
	NSString *addonID = ((NSObjectIsNotEmpty(world.bundlesWithPreferences)) ? @"13" : @"10");
	
	return [NSArray arrayWithObjects:@"0", NSToolbarFlexibleSpaceItemIdentifier, @"1", @"2", 
			@"3", @"4", @"9", NSToolbarFlexibleSpaceItemIdentifier, addonID, @"11", nil];
}

- (void)setUpToolbarItemsAndMenus
{
	if (NSObjectIsNotEmpty(world.bundlesWithPreferences)) {
		for (TextualPluginItem *plugin in world.bundlesWithPreferences) {
			NSInteger tagIndex = ([world.bundlesWithPreferences indexOfObject:plugin] + 20);
			
			NSMenuItem *pluginMenu = [NSMenuItem new];
			
			[pluginMenu setAction:@selector(onPrefPaneSelected:)];
			[pluginMenu setTarget:self];
			
			[pluginMenu setTitle:[plugin.pluginPrimaryClass preferencesMenuItemName]];
			[pluginMenu setTag:tagIndex];
			[pluginMenu autodrain];
			
			[installedScriptsMenu addItem:pluginMenu];
		}
	}
}

- (void)onPrefPaneSelected:(id)sender 
{
	switch ([sender tag]) {
		case 0:
			[self firstPane:generalView selectedItem:0];
			break;
		case 1:
			[self firstPane:highlightView selectedItem:1];
			break;
		case 2:
			[self firstPane:interfaceView selectedItem:2];
			break;
		case 3:
			[self firstPane:alertsView selectedItem:3];
			break;
		case 4:
			[self firstPane:stylesView selectedItem:4];
			break;
		case 5:
			[self firstPane:logView selectedItem:11];
			break;
		case 6:
			[self firstPane:floodControlView selectedItem:11];
			break;
		case 7:
			[self firstPane:IRCopServicesView selectedItem:11];
			break;
		case 8: 
			[self firstPane:channelManagementView selectedItem:11];
			break;
		case 9:
			[self firstPane:identityView selectedItem:9];
			break;
		case 10:
			[self firstPane:scriptsView selectedItem:10];
			break;
		default:
		{
			TextualPluginItem *plugin = [world.bundlesWithPreferences safeObjectAtIndex:([sender tag] - 20)];
			
			if (plugin) {
				NSView *prefsView = [plugin.pluginPrimaryClass preferencesView];
				
				if (prefsView) {
					[self firstPane:prefsView selectedItem:13];
				}
			} else {
				[self firstPane:generalView selectedItem:0];
			}
			
			break;
		}
	}
} 

- (void)firstPane:(NSView *)view selectedItem:(NSInteger)key
{							   
	NSRect windowFrame = [self.window frame];
	
	windowFrame.size.width = [view frame].size.width;
	windowFrame.size.height = ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	windowFrame.origin.y = NSMaxY([self.window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if (NSObjectIsNotEmpty([contentView subviews])) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[self.window setFrame:windowFrame display:YES animate:YES];
	
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
	
	[self.window recalculateKeyViewLoop];
	
	[preferenceSelectToolbar setSelectedItemIdentifier:[NSString stringWithInteger:key]];
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
			*value = NSNumberWithInteger(LINES_MIN);
		} else if (n > LINES_MAX) {
			*value = NSNumberWithInteger(LINES_MAX);
		}
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger n = [*value integerValue];
		
		if (n < INLINE_IMAGE_MIN) {
			*value = NSNumberWithInteger(INLINE_IMAGE_MIN);
		} else if (INLINE_IMAGE_MAX < n) {
			*value = NSNumberWithInteger(INLINE_IMAGE_MAX);
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Sounds

- (NSArray *)availableSounds
{
	NSMutableArray *sound_list = [NSMutableArray array];
	
	NSArray *directoryContents = [_NSFileManager() contentsOfDirectoryAtPath:@"/System/Library/Sounds" error:NULL];
	NSArray *homeDirectoryContents = [_NSFileManager() contentsOfDirectoryAtPath:[@"~/Library/Sounds/" stringByExpandingTildeInPath] error:NULL];
	
	[sound_list safeAddObject:EMPTY_SOUND];
	
	if (NSObjectIsNotEmpty(directoryContents)) {
		for (NSString *s in directoryContents) {	
			if ([s contains:@"."]) {
				[sound_list safeAddObject:[s safeSubstringToIndex:[s stringPosition:@"."]]];
			}
		}
	}
	
	if (NSObjectIsNotEmpty(homeDirectoryContents)) {
		[sound_list safeAddObject:EMPTY_SOUND];
		
		for (NSString *s in homeDirectoryContents) {	
			if ([s contains:@"."]) {
				[sound_list safeAddObject:[s safeSubstringToIndex:[s stringPosition:@"."]]];
			}
		}		
	}
	
	return sound_list;
}

- (NSMutableArray *)sounds
{
	if (NSObjectIsEmpty(sounds)) {
		NSMutableArray *ary = [NSMutableArray new];
		
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_LOGIN]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_DISCONNECT]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_HIGHLIGHT]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_NEW_TALK]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_KICKED]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_INVITED]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_MSG]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_NOTICE]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_TALK_MSG]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_TALK_NOTICE]];
		[ary safeAddObject:[SoundWrapper soundWrapperWithEventType:GROWL_ADDRESS_BOOK_MATCH]];
		
		sounds = ary;
	}
	
	return sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString *path = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	
	NSImage *icon = [_NSWorkspace() iconForFile:path];
	[icon setSize:NSMakeSize(16, 16)];
	
	NSMenuItem *item = [transcriptFolderButton itemAtIndex:0];
	
	[item setTitle:[[path lastPathComponent] decodeURIFragement]];
	[item setImage:icon];
}

- (void)onTranscriptFolderChanged:(id)sender
{
	if ([transcriptFolderButton selectedTag] != 2) return;
	
	NSOpenPanel *d = [NSOpenPanel openPanel];
	
	[d setCanChooseFiles:NO];
	[d setCanChooseDirectories:YES];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:NO];
	[d setCanCreateDirectories:YES];
	
	[d beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSInteger returnCode) {
		[transcriptFolderButton selectItem:[transcriptFolderButton itemAtIndex:0]];
		
		if (returnCode == NSOKButton) {
			NSURL *pathURL = [[d URLs] safeObjectAtIndex:0];
			NSString *path = [pathURL path];
			
			BOOL isDir;
			
			if ([_NSFileManager() fileExistsAtPath:path isDirectory:&isDir] == NO) {
				[_NSFileManager() createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
			}
			
			[Preferences setTranscriptFolder:[path stringByAbbreviatingWithTildeInPath]];
			
			[self updateTranscriptFolder];
		}
	}];
}

#pragma mark -
#pragma mark Theme

- (void)updateTheme
{
	[themeButton removeAllItems];
	
	NSInteger tag = 0;
	
	NSArray *ary = [NSArray arrayWithObjects:[Preferences whereThemesLocalPath], [Preferences whereThemesPath], nil];
	
	for (NSString *path in ary) {
		NSMutableSet *set = [NSMutableSet set];
		
		NSArray *files = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
		
		for (NSString *file in files) {
			if ([path isEqualToString:[Preferences whereThemesLocalPath]]) {
				if ([_NSFileManager() fileExistsAtPath:[[Preferences whereThemesPath] stringByAppendingPathComponent:[file lastPathComponent]]]) {
					continue;
				}
			}
			
			if ([_NSFileManager() fileExistsAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/design.css", file]]]) {
				[set addObject:[file stringByDeletingPathExtension]];
			}
		}
		
		files = [[set allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		if (files.count) {
			NSInteger i = 0;
			
			for (NSString *f in files) {
				NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:@""] autodrain];
				
				[item setTag:tag];
				[themeButton.menu addItem:item];
				
				++i;
			}
		}
		
		++tag;
	}
	
	NSString *kind = [ViewTheme extractThemeSource:[Preferences themeName]];
	NSString *name = [ViewTheme extractThemeName:[Preferences themeName]];
	
	NSInteger targetTag = 0;
	
	if ([kind isEqualToString:@"resource"] == NO) {
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
	
	NSString *newThemeName = nil;
	NSString *name = [item title];
	
	if (item.tag == 0) {
		newThemeName = [ViewTheme buildResourceFilename:name];
	} else {
		newThemeName = [ViewTheme buildUserFilename:name];
	}
	
	if ([[Preferences themeName] isEqual:newThemeName]) {
		return;
	}
	
	[Preferences setThemeName:newThemeName];
	
	[self onLayoutChanged:nil];
}

- (void)onSelectFont:(id)sender
{
	[_NSFontManager() setSelectedFont:logFont isMultiple:NO];
	[_NSFontManager() orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
	[logFont autodrain];
	logFont = [[sender convertFont:logFont] retain];
	
	[self setValue:logFont.fontName forKey:@"fontDisplayName"];
	[self setValue:NSNumberWithDouble(logFont.pointSize) forKey:@"fontPointSize"];
	
	[self onStyleChanged:nil];
}

- (void)onOverrideFontChanged:(id)sender
{
	[self onStyleChanged:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[_NSNotificationCenter() postNotificationName:TransparencyDidChangeNotification object:nil userInfo:nil];
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

- (void)onHighlightTypeChanged:(id)sender 
{
    if ([Preferences keywordMatchingMethod] == KEYWORD_MATCH_REGEX) {
        [highlightNicknameButton setEnabled:NO];
        [addExcludeWordButton setEnabled:YES];
        [excludeWordsTable setEnabled:YES];
    } else {
        [highlightNicknameButton setEnabled:YES];
        
        if ([Preferences keywordMatchingMethod] == KEYWORD_MATCH_PARTIAL) {
            [addExcludeWordButton setEnabled:YES];
            [excludeWordsTable setEnabled:YES];
        } else {
            [addExcludeWordButton setEnabled:NO];
            [excludeWordsTable setEnabled:NO];
        }
    }
}

- (void)editTable:(NSTableView *)table
{
	NSInteger row = ([table numberOfRows] - 1);
	
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
	[_NSNotificationCenter() postNotificationName:InputHistoryGlobalSchemeNotification object:nil userInfo:nil];
}

- (void)onLayoutChanged:(id)sender
{
	[_NSNotificationCenter() postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

- (void)onStyleChanged:(id)sender
{
	[_NSNotificationCenter() postNotificationName:ThemeStyleDidChangeNotification object:nil userInfo:nil];
}

- (void)onOpenPathToThemes:(id)sender
{
	[_NSWorkspace() openFile:[Preferences whereThemesPath]];
}

- (void)onOpenPathToScripts:(id)sender
{
	[_NSWorkspace() openFile:[Preferences whereApplicationSupportPath]];
}


#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[Preferences cleanUpWords];
	
	[_NSUserDefaults() synchronize];
	
	if ([delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[delegate preferencesDialogWillClose:self];
	}
}

@end