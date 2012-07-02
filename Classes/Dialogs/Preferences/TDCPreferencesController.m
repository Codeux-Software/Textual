// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define _linesMin			100
#define _linesMax			10000
#define _inlineImageMax		5000
#define _inlineImageMin		40

#define _TXWindowToolbarHeight		82
#define _addonsToolbarItemIndex		8

@implementation TDCPreferencesController

@synthesize scriptsView;

- (id)initWithWorldController:(IRCWorld *)word
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCPreferences" owner:self];
		
		self.world			   = word;
		self.scriptsController = [TDCPreferencesScriptWrapper new];
	}
	
	return self;
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	self.scriptsController.world = self.world;
	[self.scriptsController populateData];
	
	self.installedScriptsTable.dataSource = self.scriptsController;
	[self.installedScriptsTable reloadData];
	
	[self updateTheme];
    [self updateAlert];
	[self onChangeAlert:nil];
	
	[self.scriptLocationField setStringValue:[TPCPreferences whereApplicationSupportPath]];
	
	if ([self.window isVisible] == NO) {
		[self.window center];
	}
	
	[self.window makeKeyAndOrderFront:nil];
	
	[self updateTranscriptFolder];
	[self setUpToolbarItemsAndMenus];
	[self onHighlightTypeChanged:nil];

	[self.toggleDarkenedThemeCheck setTarget:self];
	[self.toggleDarkenedThemeCheck setAction:@selector(onStyleChanged:)];
	
	[self firstPane:self.generalView selectedItem:0];
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{		
	NSString *addonID = ((NSObjectIsNotEmpty(self.world.bundlesWithPreferences)) ? @"13" : @"10");
	
	return @[@"0", NSToolbarFlexibleSpaceItemIdentifier, @"3", @"1", 
	@"4", @"2", @"9", NSToolbarFlexibleSpaceItemIdentifier, addonID, @"11"];
}

- (void)setUpToolbarItemsAndMenus
{
	if (NSObjectIsNotEmpty(self.world.bundlesWithPreferences)) {
		for (THOTextualPluginItem *plugin in self.world.bundlesWithPreferences) {
			NSInteger tagIndex = ([self.world.bundlesWithPreferences indexOfObject:plugin] + 20);
			
			NSMenuItem *pluginMenu = [NSMenuItem new];
			
			[pluginMenu setAction:@selector(onPrefPaneSelected:)];
			[pluginMenu setTarget:self];
			
			[pluginMenu setTitle:[plugin.pluginPrimaryClass preferencesMenuItemName]];
			[pluginMenu setTag:tagIndex];
			
			[self.installedScriptsMenu addItem:pluginMenu];
		}
	}
}

- (void)onPrefPaneSelected:(id)sender 
{
	switch ([sender tag]) {
		case 0: [self firstPane:self.generalView selectedItem:0]; break;
		case 1: [self firstPane:self.highlightView selectedItem:1]; break;
		case 2: [self firstPane:self.interfaceView selectedItem:2]; break;
		case 3: [self firstPane:self.alertsView selectedItem:3]; break;
		case 4: [self firstPane:self.stylesView selectedItem:4]; break;
		case 5: [self firstPane:self.logView selectedItem:11]; break;
		case 6: [self firstPane:self.floodControlView selectedItem:11]; break;
		case 7: [self firstPane:self.IRCopServicesView selectedItem:11]; break;
		case 8: [self firstPane:self.channelManagementView selectedItem:11]; break;
		case 9: [self firstPane:self.identityView selectedItem:9]; break;
		case 10: [self firstPane:self.scriptsView selectedItem:10]; break;
		case 11: [self firstPane:self.experimentalSettingsView selectedItem:11]; break;
		default:
		{
			THOTextualPluginItem *plugin = [self.world.bundlesWithPreferences safeObjectAtIndex:([sender tag] - 20)];
			
			if (plugin) {
				NSView *prefsView = [plugin.pluginPrimaryClass preferencesView];
				
				if (prefsView) {
					[self firstPane:prefsView selectedItem:13];
				}
			} else {
				[self firstPane:self.generalView selectedItem:0];
			}
			
			break;
		}
	}
} 

- (void)firstPane:(NSView *)view selectedItem:(NSInteger)key
{							   
	NSRect windowFrame = [self.window frame];
	
	windowFrame.size.width	= [view frame].size.width;
	windowFrame.size.height = ([view frame].size.height + _TXWindowToolbarHeight);
	
	windowFrame.origin.y	= NSMaxY([self.window frame]) -
	([view frame].size.height + _TXWindowToolbarHeight);
	
	if (NSObjectIsNotEmpty([self.contentView subviews])) {
		[[self.contentView.subviews safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[self.window setFrame:windowFrame display:YES animate:YES];
	
	[self.contentView setFrame:[view frame]];
	[self.contentView addSubview:view];	
	
	[self.window recalculateKeyViewLoop];
	
	[self.preferenceSelectToolbar setSelectedItemIdentifier:[NSString stringWithInteger:key]];
}

#pragma mark -
#pragma mark KVC Properties

- (NSInteger)maxLogLines
{
	return [TPCPreferences maxLogLines];
}

- (void)setMaxLogLines:(NSInteger)value
{
	[TPCPreferences setMaxLogLines:value];
}

- (NSString *)completionSuffix
{
	return [TPCPreferences completionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[TPCPreferences setCompletionSuffix:value];
}

- (NSInteger)inlineImageMaxWidth
{
	return [TPCPreferences inlineImagesMaxWidth];
}

- (void)setInlineImageMaxWidth:(NSInteger)value
{
	[TPCPreferences setInlineImagesMaxWidth:value];
}

- (NSString *)themeChannelViewFontName
{
	return [TPCPreferences themeChannelViewFontName];
}

- (TXNSDouble)themeChannelViewFontSize
{
	return [TPCPreferences themeChannelViewFontSize];
}

- (void)setThemeChannelViewFontName:(id)value	{ return; }
- (void)setThemeChannelViewFontSize:(id)value	{ return; }

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if ([key isEqualToString:@"maxLogLines"]) {
		NSInteger n = [*value integerValue];
		
		if (n < _linesMin) {
			*value = NSNumberWithInteger(_linesMin);
		} else if (n > _linesMax) {
			*value = NSNumberWithInteger(_linesMax);
		}
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger n = [*value integerValue];
		
		if (n < _inlineImageMin) {
			*value = NSNumberWithInteger(_inlineImageMin);
		} else if (_inlineImageMax < n) {
			*value = NSNumberWithInteger(_inlineImageMax);
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Sounds

- (void)updateAlert 
{
	[self.alertSoundButton removeAllItems];
	
	NSArray *alertSounds = [self availableSounds];
	
    for (NSString *alertSound in alertSounds) {
        NSMenuItem *item = [NSMenuItem new];
		
        [item setTitle:alertSound];
        
        [self.alertSoundButton.menu addItem:item];
    }
	
    [self.alertSoundButton selectItemAtIndex:0];
    [self.alertButton removeAllItems];
	
    NSMutableArray *alerts = [self sounds];
	
    for (TDCPreferencesSoundWrapper *alert in alerts) {
        NSMenuItem *item = [NSMenuItem new];
		
        [item setTitle:alert.displayName];
        [item setTag:[alert eventType]];
		
        [self.alertButton.menu addItem:item];
    }
	
    [self.alertButton selectItemAtIndex:0];
}

- (void)onChangeAlert:(id)sender 
{
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:(TXNotificationType)self.alertButton.selectedItem.tag];
	
    [self.useGrowlButton				setState:alert.growl];
    [self.disableAlertWhenAwayButton	setState:alert.disableWhileAway];
	
	[self.alertSoundButton selectItemAtIndex:[self.availableSounds indexOfObject:alert.sound]];
}

- (void)onUseGrowl:(id)sender 
{
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:(TXNotificationType)self.alertButton.selectedItem.tag];
	
    [alert setGrowl:[self.useGrowlButton state]];
}

- (void)onAlertWhileAway:(id)sender 
{
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:(TXNotificationType)self.alertButton.selectedItem.tag];
	
    [alert setDisableWhileAway:[self.disableAlertWhenAwayButton state]];
}

- (void)onChangeAlertSound:(id)sender 
{
	TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:(TXNotificationType)self.alertButton.selectedItem.tag];
	
	[alert setSound:[self.alertSoundButton titleOfSelectedItem]];
}

- (NSArray *)availableSounds
{
	NSMutableArray *sound_list = [NSMutableArray array];
	
	NSString *userSoundFolder = [_NSFileManager() URLForDirectory:NSLibraryDirectory
														 inDomain:NSUserDomainMask
												appropriateForURL:nil
														   create:YES
															error:NULL].relativePath;
	
	NSArray *directoryContents		= [_NSFileManager() contentsOfDirectoryAtPath:@"/System/Library/Sounds"										error:NULL];
	NSArray *homeDirectoryContents	= [_NSFileManager() contentsOfDirectoryAtPath:[userSoundFolder stringByAppendingPathComponent:@"/Sounds"]	error:NULL];
	
	[sound_list safeAddObject:TXEmptySoundAlertLabel];
	[sound_list safeAddObject:@"Beep"];
	
	if (NSObjectIsNotEmpty(directoryContents)) {
		for (NSString *s in directoryContents) {	
			if ([s contains:@"."]) {
				[sound_list safeAddObject:[s safeSubstringToIndex:[s stringPosition:@"."]]];
			}
		}
	}
	
	if (NSObjectIsNotEmpty(homeDirectoryContents)) {
		[sound_list safeAddObject:TXEmptySoundAlertLabel];
		
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
	if (NSObjectIsEmpty(_sounds)) {
		NSMutableArray *ary = [NSMutableArray new];
		
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationConnectType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationDisconnectType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationHighlightType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationKickType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationInviteType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelMessageType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelNoticeType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationQueryMessageType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationNewQueryType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationQueryNoticeType]];
		[ary addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationAddressBookMatchType]];
		
		self.sounds = ary;
	}
	
	return _sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString *path = [[TPCPreferences transcriptFolder] stringByExpandingTildeInPath];

	if (NSObjectIsEmpty(path)) {
		NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];
		
		[item setTitle:TXTLS(@"NoLogLocationDefinedMenuItem")];
	} else {
		NSImage *icon = [_NSWorkspace() iconForFile:path];
		[icon setSize:NSMakeSize(16, 16)];
		
		NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];
		
		[item setTitle:[[path lastPathComponent] decodeURIFragement]];
		[item setImage:icon];
	}
}

- (void)onTranscriptFolderChanged:(id)sender
{
	if ([self.transcriptFolderButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];
		
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		[d setCanCreateDirectories:YES];

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.transcriptFolderButton selectItem:[self.transcriptFolderButton itemAtIndex:0]];
			
			if (returnCode == NSOKButton) {
				NSURL *pathURL = [d.URLs safeObjectAtIndex:0];

				if ([TPCPreferences sandboxEnabled] && [TPCPreferences securityScopedBookmarksAvailable]) {
					NSData *bookmark = nil;
					
					NSError *error = nil;
					
					bookmark = [pathURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							 includingResourceValuesForKeys:nil
											  relativeToURL:nil 
													  error:&error];
					if (error) {
						NSLog(@"Error creating bookmark for URL (%@): %@", pathURL, error);
					} else {
						[TPCPreferences setTranscriptFolder:bookmark];
					}
				} else {
					NSString *path = [pathURL path];
					
					[TPCPreferences setTranscriptFolder:[path stringByAbbreviatingWithTildeInPath]];
				}
				
				[self updateTranscriptFolder];
			}
		}];
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateTheme
{
	[self.themeButton removeAllItems];
	
	NSInteger tag = 0;
	
	NSArray *ary = @[[TPCPreferences whereThemesLocalPath], [TPCPreferences whereThemesPath]];
	
	for (NSString *path in ary) {
		NSMutableSet *set = [NSMutableSet set];
		
		NSArray *files = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
		
		for (NSString *file in files) {
			if ([path isEqualToString:[TPCPreferences whereThemesLocalPath]]) {
				if ([_NSFileManager() fileExistsAtPath:[[TPCPreferences whereThemesPath] stringByAppendingPathComponent:[file lastPathComponent]]]) {
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
				NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:NSStringEmptyPlaceholder];
				
				[item setTag:tag];
				
				[self.themeButton.menu addItem:item];
				
				++i;
			}
		}
		
		++tag;
	}
	
	NSString *kind = [TPCViewTheme extractThemeSource:[TPCPreferences themeName]];
	NSString *name = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	
	NSInteger targetTag = 0;
	
	if ([kind isEqualToString:@"resource"] == NO) {
		targetTag = 1;
	}
	
	NSInteger count = [self.themeButton numberOfItems];
	
	for (NSInteger i = 0; i < count; i++) {
		NSMenuItem *item = [self.themeButton itemAtIndex:i];
		
		if ([item tag] == targetTag && [[item title] isEqualToString:name]) {
			[self.themeButton selectItemAtIndex:i];
			
			break;
		}
	}
}

- (void)onChangedTheme:(id)sender
{
    TXNSDouble oldRenderVersion = self.world.viewTheme.other.renderingEngineVersion;
    TXNSDouble newRenderVersion = 0;
    
	NSMenuItem *item = [self.themeButton selectedItem];
	
	NSString *newThemeName = nil;
	NSString *name = [item title];
	
	if (item.tag == 0) {
		newThemeName = [TPCViewTheme buildResourceFilename:name];
	} else {
		newThemeName = [TPCViewTheme buildUserFilename:name];
	}
	
	if ([[TPCPreferences themeName] isEqual:newThemeName]) {
		return;
	}
	
	[TPCPreferences setThemeName:newThemeName];
	
	[self onStyleChanged:nil];
    
    newRenderVersion = self.world.viewTheme.other.renderingEngineVersion;
    
    if (NSDissimilarObjects(oldRenderVersion, newRenderVersion)) {
        for (IRCClient *u in self.world.clients) {
            [u sendCommand:@"CLEARALL"];
        }
    }
}

- (void)onSelectFont:(id)sender
{
	NSFont *logfont = self.world.viewTheme.other.channelViewFont;
	
	[_NSFontManager() setSelectedFont:logfont isMultiple:NO];
	[_NSFontManager() orderFrontFontPanel:self];
	[_NSFontManager() setAction:@selector(changeItemFont:)];
}

- (void)changeItemFont:(NSFontManager *)sender
{
	TPCOtherTheme *theme = self.world.viewTheme.other;
	
	NSFont *newFont = [sender convertFont:theme.channelViewFont];
	
	[TPCPreferences setThemeChannelViewFontName:[newFont fontName]];
	[TPCPreferences setThemeChannelViewFontSize:[newFont pointSize]];
	
	[self setValue:[newFont fontName]						forKey:@"themeChannelViewFontName"];
	[self setValue:@([newFont pointSize])	forKey:@"themeChannelViewFontSize"];
	
	[self onStyleChanged:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[_NSNotificationCenter() postNotificationName:TXTransparencyPreferenceChangedNotification object:nil userInfo:nil];
}

#pragma mark -
#pragma mark Actions

- (void)onHighlightTypeChanged:(id)sender 
{
    if ([TPCPreferences keywordMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) {
        [self.highlightNicknameButton setEnabled:NO];
        [self.addExcludeWordButton setEnabled:YES];
        [self.excludeWordsTable setEnabled:YES];
    } else {
        [self.highlightNicknameButton setEnabled:YES];
        
        if ([TPCPreferences keywordMatchingMethod] == TXNicknameHighlightPartialMatchType) {
            [self.addExcludeWordButton setEnabled:YES];
            [self.excludeWordsTable setEnabled:YES];
        } else {
            [self.addExcludeWordButton setEnabled:NO];
            [self.excludeWordsTable setEnabled:NO];
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
	[self.keywordsArrayController add:nil];
	
	[self performSelector:@selector(editTable:) withObject:self.keywordsTable afterDelay:0.3];
}

- (void)onAddExcludeWord:(id)sender
{
	[self.excludeWordsArrayController add:nil];
	
	[self performSelector:@selector(editTable:) withObject:self.excludeWordsTable afterDelay:0.3];
}

- (void)onInputHistorySchemeChanged:(id)sender
{
	[_NSNotificationCenter() postNotificationName:TXInputHistorySchemePreferenceChangedNotification object:nil userInfo:nil];
}

- (void)onStyleChanged:(id)sender
{
	[_NSNotificationCenter() postNotificationName:TXThemePreferenceChangedNotification object:nil userInfo:nil];
}

+ (void)openPathToThemesCallback:(NSNumber *)returnCode
{	
	NSString *name = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	
    NSInteger _returnCode = [returnCode integerValue];
	
	if (_returnCode == NSAlertSecondButtonReturn) {
		return;
	}
    
	if (_returnCode == NSAlertFirstButtonReturn) {
		NSString *path = [[TPCPreferences whereThemesLocalPath] stringByAppendingPathComponent:name];
		
		[_NSWorkspace() openFile:path];
	} else {
		NSString *newpath = [[TPCPreferences whereThemesPath]		stringByAppendingPathComponent:name];
		NSString *oldpath = [[TPCPreferences whereThemesLocalPath]	stringByAppendingPathComponent:name];
		
		[_NSFileManager() copyItemAtPath:oldpath toPath:newpath error:NULL];
		
		[_NSWorkspace() openFile:newpath];
	}
}

- (void)onOpenPathToThemes:(id)sender
{
	NSString *kind = [TPCViewTheme extractThemeSource:[TPCPreferences themeName]];
	NSString *name = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
    
    if ([kind isEqualNoCase:@"resource"]) {
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];
		
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:[TDCPreferencesController class]
								 action:@selector(openPathToThemesCallback:) 
								   body:TXTFLS(@"OpeningLocalStyleResourcesMessage", name)
								  title:TXTLS(@"OpeningLocalStyleResourcesTitle")
						  defaultButton:TXTLS(@"ContinueButton")
						alternateButton:TXTLS(@"CancelButton") 
							otherButton:TXTLS(@"OpeningLocalStyleResourcesCopyButton")
						 suppressionKey:@"opening_local_style" 
						suppressionText:nil];
    } else {
		NSString *path = [[TPCPreferences whereThemesPath] stringByAppendingPathComponent:name];
		
		[_NSWorkspace() openFile:path];
    }
}

- (void)onOpenPathToScripts:(id)sender
{
	[_NSWorkspace() openFile:[TPCPreferences whereApplicationSupportPath]];
}

- (void)onHighlightLoggingChanged:(id)sender
{
	if ([TPCPreferences logAllHighlightsToQuery] == NO) {
		for (IRCClient *u in self.world.clients) {
			[u.highlights removeAllObjects];
		}
	}
}

- (void)onDownloadExtraAddons:(id)sender
{
	NSString *version = @"No%20Sandbox";
	
	if ([TPCPreferences sandboxEnabled]) {
		if ([TPCPreferences featureAvailableToOSXLion]) {
			version = @"Lion";
		}
		
		if ([TPCPreferences featureAvailableToOSXMountainLion]) {
			version = @"Mountain%20Lion";
		}
	}
	
	NSMutableString *download = [NSMutableString string];
	
	[download appendString:@"https://github.com/Codeux/Textual/blob/master/Resources/All%20Scripts/Sandbox%20Exceptions/Installers/Textual%20Extras%20%28"];
	[download appendString:version];
	[download appendString:@"%29.pkg?raw=true"];

	[TLOpenLink openWithString:download];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[TPCPreferences cleanUpWords];
	[TPCPreferences sync];
	
	[_NSUserDefaults() synchronize];
	
	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end
