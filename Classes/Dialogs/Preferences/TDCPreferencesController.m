/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#define _linesMin					100
#define _linesMax					15000
#define _inlineImageWidthMax		2000
#define _inlineImageWidthMin		40
#define _inlineImageHeightMax		6000
#define _inlineImageHeightMin		0

#define _TXWindowToolbarHeight				82

#define _addonsToolbarItemIndex				8
#define _addonsToolbarItemMultiplier		65

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@interface TDCPreferencesController ()
@property (nonatomic, strong) TDCProgressInformationSheet *tcopyStyleFilesProgressIndicator;
@end
#endif

@implementation TDCPreferencesController

- (id)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCPreferences" owner:self topLevelObjects:nil];
	}

	return self;
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	self.scriptsController = [TDCPreferencesScriptWrapper new];

	self.alertSounds = [NSMutableArray new];

	// self.alertSounds treats anything that is not a TDCPreferencesSoundWrapper as
	// an indicator that a [NSMenuItem separatorItem] should be placed in our menu.

	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationAddressBookMatchType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationConnectType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationDisconnectType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationHighlightType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationInviteType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationKickType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelMessageType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelNoticeType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationNewPrivateMessageType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateMessageType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateNoticeType]];

	[self.scriptsController populateData];

	self.installedScriptsTable.dataSource = self.scriptsController;
	[self.installedScriptsTable reloadData];

	[self setUpToolbarItemsAndMenus];

	[self updateThemeSelection];
    [self updateAlertSelection];
	[self updateTranscriptFolder];

	[self onChangedAlertType:nil];
	[self onChangedHighlightType:nil];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidRebuildContainerCache:)
								   name:TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification
								 object:nil];
	
	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidChangeThemeName:)
								   name:TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification
								 object:nil];
	
	[self.syncPreferencesToTheCloudButton setState:[TPCPreferences syncPreferencesToTheCloud]];
#endif
	
	[self.setAsDefaultIRCClientButton setHidden:[TPCPreferences isDefaultIRCClient]];

	[self.window restoreWindowStateForClass:self.class];

	[self.window makeKeyAndOrderFront:nil];

	[self firstPane:self.generalView selectedItem:0];
}

#pragma mark -
#pragma mark NSToolbar Delegates

/*
	 Toolbar Design:
	 [tag]: [label]

	 0: General

	 — Blank Space —

	 3: Alerts
	 1: Highlights
	 4: Style
	 2: Interface
	 9: Identity

	 — Blank Space —

	 13: Addons — Menu that includes list of preference
	 panes created by loaded extensions. Top item of
	 list is "Installed Addons" with tag 10. The tag
	 of each other item is dynamically determined based
	 on the _addonsToolbarItemMultiplier.

	 10: Addons — Button, "Installed Addons" — no menu. Used
	 if there are no extensions loaded that create
	 custom preference panes.

	 11: Advanced — Menu.

	 7:	IRCop Services
	 8:	Channel Management
	 12: Command Scope
	 6:	Flood Control
	 5:	Log Location
	 11: Experimental Settings

	 The tag of each toolbar item (and menu item) should not
	 conflict with any other in order to function with
	 onPrefPaneSelected: properly which each item calls.
 */

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	NSArray *bundles = [RZPluginManager() pluginsWithPreferencePanes];

	if (NSObjectIsEmpty(bundles)) {
		return @[@"0", NSToolbarFlexibleSpaceItemIdentifier, @"3", @"1", @"4", @"2", @"9", NSToolbarFlexibleSpaceItemIdentifier, @"10", @"11"];
	} else {
		return @[@"0", NSToolbarFlexibleSpaceItemIdentifier, @"3", @"1", @"4", @"2", @"9", NSToolbarFlexibleSpaceItemIdentifier, @"13", @"11"];
	}
}

- (void)setUpToolbarItemsAndMenus
{
	/* Growl check. */
	BOOL growlRunning = [GrowlApplicationBridge isGrowlRunning];

	/* We only have notification center on mountain lion or newer so we have to
	 check what OS we are running on before we even doing anything. */
	if ([TPCPreferences featureAvailableToOSXMountainLion] == NO || growlRunning) {
		/* Show growl icon if it is running or we are not on mountain lion. */
		
		[self.alertToolbarItem setImage:[NSImage imageNamed:@"TPWTB_Alerts"]];

		if (growlRunning) {
			self.alertNotificationDestinationTextField.stringValue = TXTFLS(@"PreferencesAlertSettingsGrowlIsDestination");
		} else {
			self.alertNotificationDestinationTextField.stringValue = TXTFLS(@"PreferencesAlertSettingsNoDestinationForNotifications");

		}
	} else {
		/* Show notification center icon if we are on ML and growl is not running. */

		[self.alertToolbarItem setImage:[NSImage imageNamed:@"TPWTB_Alerts_NC"]];
		
		self.alertNotificationDestinationTextField.stringValue = TXTFLS(@"PreferencesAlertSettingsNotificationCenterIsDestination");
	}

	/* Extensions. */
	NSArray *bundles = [RZPluginManager() pluginsWithPreferencePanes];

	for (THOPluginItem *plugin in bundles) {
		NSInteger tagIndex = ([bundles indexOfObject:plugin] + _addonsToolbarItemMultiplier);

		NSMenuItem *pluginMenu = [NSMenuItem menuItemWithTitle:[plugin.primaryClass preferencesMenuItemName]
														target:self
														action:@selector(onPrefPaneSelected:)];

		[pluginMenu setTag:tagIndex];

		[self.installedScriptsMenu addItem:pluginMenu];
	}
}

- (void)onPrefPaneSelected:(id)sender
{
	NSInteger pluginIndex = ([sender tag] - _addonsToolbarItemMultiplier);

	switch ([sender tag]) {
		case 0:		{ [self firstPane:self.generalView					selectedItem:0]; break; }
		case 1:		{ [self firstPane:self.highlightView				selectedItem:1]; break; }
		case 2:		{ [self firstPane:self.interfaceView				selectedItem:2]; break; }
		case 3:		{ [self firstPane:self.alertsView					selectedItem:3]; break; }
		case 4:		{ [self firstPane:self.stylesView					selectedItem:4]; break; }
		case 5:		{ [self firstPane:self.logLocationView				selectedItem:11]; break; }
		case 6:		{ [self firstPane:self.floodControlView				selectedItem:11]; break; }
		case 7:		{ [self firstPane:self.IRCopServicesView			selectedItem:11]; break; }
		case 8:		{ [self firstPane:self.channelManagementView		selectedItem:11]; break; }
		case 9:		{ [self firstPane:self.identityView					selectedItem:9]; break; }
		case 10:	{ [self firstPane:self.installedAddonsView			selectedItem:10]; break; }
		case 11:	{ [self firstPane:self.experimentalSettingsView		selectedItem:11]; break; }
		case 12:	{ [self firstPane:self.commandScopeSettingsView		selectedItem:11]; break; }
		case 13:	{ [self firstPane:self.iCloudSyncView				selectedItem:11]; break; }
		default:
		{
			THOPluginItem *plugin = [RZPluginManager() pluginsWithPreferencePanes][pluginIndex];

			if (plugin) {
				NSView *prefsView = [plugin.primaryClass preferencesView];

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
	NSRect windowFrame = self.window.frame;

	windowFrame.size.width = view.frame.size.width;
	windowFrame.size.height = (view.frame.size.height + _TXWindowToolbarHeight);

	windowFrame.origin.y = (NSMaxY(self.window.frame) - windowFrame.size.height);

	if (NSObjectIsNotEmpty(self.contentView.subviews)) {
		[self.contentView.subviews[0] removeFromSuperview];
	}

	[self.window setFrame:windowFrame display:YES animate:YES];

	[self.contentView setFrame:view.frame];
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
	return [TPCPreferences tabCompletionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[TPCPreferences setTabCompletionSuffix:value];
}

- (NSInteger)inlineImageMaxWidth
{
	return [TPCPreferences inlineImagesMaxWidth];
}

- (NSInteger)inlineImageMaxHeight
{
	return [TPCPreferences inlineImagesMaxHeight];
}

- (void)setInlineImageMaxWidth:(NSInteger)value
{
	[TPCPreferences setInlineImagesMaxWidth:value];
}

- (void)setInlineImageMaxHeight:(NSInteger)value
{
	[TPCPreferences setInlineImagesMaxHeight:value];
}

- (NSString *)themeChannelViewFontName
{
	return [TPCPreferences themeChannelViewFontName];
}

- (double)themeChannelViewFontSize
{
	return [TPCPreferences themeChannelViewFontSize];
}

- (void)setThemeChannelViewFontName:(id)value { return; }
- (void)setThemeChannelViewFontSize:(id)value { return; }

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

		if (n < _inlineImageWidthMin) {
			*value = NSNumberWithInteger(_inlineImageWidthMin);
		} else if (_inlineImageWidthMax < n) {
			*value = NSNumberWithInteger(_inlineImageWidthMax);
		}
	} else if ([key isEqualToString:@"inlineImageMaxHeight"]) {
		NSInteger n = [*value integerValue];

		if (n < _inlineImageHeightMin) {
			*value = NSNumberWithInteger(_inlineImageHeightMin);
		} else if (_inlineImageHeightMax < n) {
			*value = NSNumberWithInteger(_inlineImageHeightMax);
		}
	}

	return YES;
}

#pragma mark -
#pragma mark Sounds

- (void)updateAlertSelection
{
	[self.alertSoundChoiceButton removeAllItems];

	NSArray *alertSounds = [self availableSounds];

    for (NSString *alertSound in alertSounds) {
        NSMenuItem *item = [NSMenuItem new];

        [item setTitle:alertSound];

        [self.alertSoundChoiceButton.menu addItem:item];
    }

    [self.alertSoundChoiceButton selectItemAtIndex:0];

	// ---- //

    [self.alertTypeChoiceButton removeAllItems];

    NSMutableArray *alerts = self.alertSounds;

    for (id alert in alerts) {
		if ([alert isKindOfClass:[TDCPreferencesSoundWrapper class]]) {
			NSMenuItem *item = [NSMenuItem new];

			[item setTitle:[alert displayName]];
			[item setTag:[alert eventType]];

			[self.alertTypeChoiceButton.menu addItem:item];
		} else {
			[self.alertTypeChoiceButton.menu addItem:[NSMenuItem separatorItem]];
		}
    }

    [self.alertTypeChoiceButton selectItemAtIndex:0];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[self.alertSpeakEventButton setState:alert.speakEvent];
    [self.alertPushNotificationButton setState:alert.pushNotification];
    [self.alertDisableWhileAwayButton setState:alert.disabledWhileAway];
    [self.alertBounceDockIconButton setState:alert.bounceDockIcon];

	NSInteger soundObject = [self.availableSounds indexOfObject:alert.alertSound];
	
	if (soundObject == NSNotFound) {
		[self.alertSoundChoiceButton selectItemAtIndex:0];
	} else {
		[self.alertSoundChoiceButton selectItemAtIndex:soundObject];
	}
}

- (void)onChangedAlertNotification:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    [alert setPushNotification:self.alertPushNotificationButton.state];
}

- (void)onChangedAlertSpoken:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setSpeakEvent:self.alertSpeakEventButton.state];
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    [alert setDisabledWhileAway:self.alertDisableWhileAwayButton.state];
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
    TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;
    
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
    [alert setBounceDockIcon:self.alertBounceDockIconButton.state];
}

- (void)onChangedAlertSound:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedItem.tag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setAlertSound:self.alertSoundChoiceButton.titleOfSelectedItem];
}

- (NSArray *)availableSounds
{
	NSMutableArray *soundList = [NSMutableArray array];

	NSString *systemSoundFolder = @"/System/Library/Sounds";

	NSURL *userSoundFolderURL = [RZFileManager() URLForDirectory:NSLibraryDirectory
														inDomain:NSUserDomainMask
											   appropriateForURL:nil
														  create:YES
														   error:NULL];

	NSString *userSoundFolder = [userSoundFolderURL.relativePath stringByAppendingPathComponent:@"/Sounds"];

	NSArray *homeDirectoryContents = [RZFileManager() contentsOfDirectoryAtPath:userSoundFolder error:NULL];
	NSArray *systemDirectoryContents = [RZFileManager() contentsOfDirectoryAtPath:systemSoundFolder error:NULL];

	[soundList safeAddObject:TXEmptySoundAlertLabel];
	[soundList safeAddObject:@"Beep"];

	if (NSObjectIsNotEmpty(systemDirectoryContents)) {
		for (__strong NSString *s in systemDirectoryContents) {
			if ([s contains:@"."]) {
				s = [s safeSubstringToIndex:[s stringPosition:@"."]];
			}

			[soundList safeAddObject:s];
		}
	}

	if (NSObjectIsNotEmpty(homeDirectoryContents)) {
		[soundList safeAddObject:TXEmptySoundAlertLabel];

		for (__strong NSString *s in homeDirectoryContents) {
			if ([s contains:@"."]) {
				s = [s safeSubstringToIndex:[s stringPosition:@"."]];
			}

			[soundList safeAddObject:s];
		}
	}

	return soundList;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSURL *path = [TPCPreferences transcriptFolder];

	NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];

	if (NSObjectIsEmpty(path)) {
		[item setTitle:TXTLS(@"NoLogLocationDefinedMenuItem")];
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:[path path]];

		[icon setSize:NSMakeSize(16, 16)];

		[item setImage:icon];
		[item setTitle:[path.lastPathComponent decodeURIFragement]];
	}
}

- (void)onChangedTranscriptFolder:(id)sender
{
	if ([self.transcriptFolderButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.transcriptFolderButton selectItem:[self.transcriptFolderButton itemAtIndex:0]];

			if (returnCode == NSOKButton) {
				NSURL *pathURL = [d.URLs safeObjectAtIndex:0];

				NSError *error = nil;

				NSData *bookmark = [pathURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
									 includingResourceValuesForKeys:nil
													  relativeToURL:nil
															  error:&error];

				if (error) {
					LogToConsole(@"Error creating bookmark for URL (%@): %@", pathURL, [error localizedDescription]);
				} else {
					[TPCPreferences setTranscriptFolder:bookmark];
				}

				[self updateTranscriptFolder];
			}
		}];
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeSelection
{
	[self.themeSelectionButton removeAllItems];

	NSInteger tag = 0;

	NSArray *paths = @[[TPCPreferences bundledThemeFolderPath],
					   [TPCPreferences customThemeFolderPath],
					   
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
					   [TPCPreferences cloudCustomThemeCachedFolderPath],
#endif
					   
					   ];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* This path does not always exist right away. */
	BOOL cloudPathExists = ([paths[2] length] > 0);
#endif

	for (NSString *path in paths) {
		NSMutableSet *set = [NSMutableSet set];
		
		NSAssertReturnLoopContinue(path.length > 0);

		NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

		for (NSString *file in files) {
			NSString *filename = file.lastPathComponent;

			if ([path isEqualToString:paths[0]]) {
				/* If a custom theme with the same name of this bundled theme exists,
				 then ignore the bundled them. Custom themes always take priority. */
				NSString *cfip = [paths[1] stringByAppendingPathComponent:filename];

				if ([RZFileManager() fileExistsAtPath:cfip]) {
					continue;
				}
				
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
				if (cloudPathExists) {
					/* Perform same check for cloud based themes too. */
					cfip = [paths[2] stringByAppendingPathComponent:filename];

					if ([RZFileManager() fileExistsAtPath:cfip]) {
						continue;
					}
				}
			}
			
			/* Also select cloud styles over local ones. */
			if (cloudPathExists && [path isEqualToString:paths[1]]) {
				/* If a custom theme with the same name of this bundled theme exists,
				 then ignore the bundled them. Custom themes always take priority. */
				NSString *cfip = [paths[2] stringByAppendingPathComponent:filename];
				
				if ([RZFileManager() fileExistsAtPath:cfip]) {
					continue;
				}
#endif
				
			}

			NSString *cssfilelocal = [path stringByAppendingPathComponent:[file stringByAppendingString:@"/design.css"]];

			/* Only add the theme if a design.css file exists. */
			if ([RZFileManager() fileExistsAtPath:cssfilelocal]) {
				[set addObject:[file stringByDeletingPathExtension]];
			}
		}

		// ---- //

		files = [set.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

		for (NSString *f in files) {
			NSMenuItem *cell = [NSMenuItem menuItemWithTitle:f target:nil action:nil];

			[cell setTag:tag];

			[self.themeSelectionButton.menu addItem:cell];
		}

		/* Tag can only be 1 or 0. 0 for bundled. 1 for custom. */
		if (tag == 0) {
			tag = 1;
		}
	}

	// ---- //

	NSString *name = [self.themeController name];

	NSInteger targetTag = 0;

	if ([self.themeController isBundledTheme] == NO) {
		targetTag = 1;
	}

	NSInteger count = [self.themeSelectionButton numberOfItems];

	for (NSInteger i = 0; i < count; i++) {
		NSMenuItem *item = [self.themeSelectionButton itemAtIndex:i];

		if ([item tag] == targetTag && [item.title isEqualToString:name]) {
			[self.themeSelectionButton selectItemAtIndex:i];

			break;
		}
	}
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem *item = [self.themeSelectionButton selectedItem];

	NSString *newThemeName = nil;
	NSString *oldThemeName = [TPCPreferences themeName];

	if (item.tag == 0) {
		newThemeName = [TPCThemeController buildResourceFilename:item.title];
	} else {
		newThemeName = [TPCThemeController buildUserFilename:item.title];
	}

	if ([oldThemeName isEqual:newThemeName]) {
		return;
	}

	[TPCPreferences setThemeName:newThemeName];

	[self onChangedStyle:nil];

	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction];
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];

	// ---- //

	NSMutableString *sf = [NSMutableString string];

	if (NSObjectIsNotEmpty(self.themeController.customSettings.nicknameFormat)) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptNicknameFormat")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (NSObjectIsNotEmpty(self.themeController.customSettings.timestampFormat)) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptTimestampFormat")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (self.themeController.customSettings.channelViewFont) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptChannelFont")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (self.themeController.customSettings.forceInvertSidebarColors) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptWindowColors")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	NSString *tsf = sf.trim;

	NSObjectIsEmptyAssert(tsf);

	TLOPopupPrompts *prompt = [TLOPopupPrompts new];

	[prompt sheetWindowWithQuestion:[NSApp keyWindow]
							 target:[TLOPopupPrompts class]
							 action:@selector(popupPromptNilSelector:withOriginalAlert:)
							   body:TXTFLS(@"ThemeChangeOverridePromptMessage", item.title, tsf)
							  title:TXTLS(@"ThemeChangeOverridePromptTitle")
					  defaultButton:TXTLS(@"OkButton")
					alternateButton:nil
						otherButton:nil
					 suppressionKey:@"theme_override_info"
					suppressionText:nil];
}

- (void)onSelectNewFont:(id)sender
{
	NSFont *logfont = [TPCPreferences themeChannelViewFont];

	[RZFontManager() setSelectedFont:logfont isMultiple:NO];
	[RZFontManager() orderFrontFontPanel:self];
	[RZFontManager() setAction:@selector(changeItemFont:)];
}

- (void)changeItemFont:(NSFontManager *)sender
{
	NSFont *logfont = [TPCPreferences themeChannelViewFont];

	NSFont *newFont = [sender convertFont:logfont];

	[TPCPreferences setThemeChannelViewFontName:[newFont fontName]];
	[TPCPreferences setThemeChannelViewFontSize:[newFont pointSize]];

	[self setValue:  [newFont fontName]		forKey:@"themeChannelViewFontName"];
	[self setValue:@([newFont pointSize])	forKey:@"themeChannelViewFontSize"];

	[self onChangedStyle:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[self.masterController.mainWindow setAlphaValue:[TPCPreferences themeTransparency]];
}

#pragma mark -
#pragma mark Actions

- (void)onChangedHighlightType:(id)sender
{
    if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) {
        [self.highlightNicknameButton setEnabled:NO];
    } else {
        [self.highlightNicknameButton setEnabled:YES];
    }
	
	[self.addExcludeKeywordButton setEnabled:YES];
	[self.excludeKeywordsTable setEnabled:YES];
}

- (void)editTable:(NSTableView *)table
{
	NSInteger row = ([table numberOfRows] - 1);

	[table scrollRowToVisible:row];
	[table editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
	[self.matchKeywordsArrayController add:nil];

	[self performSelector:@selector(editTable:) withObject:self.keywordsTable afterDelay:0.3];
}

- (void)onAddExcludeKeyword:(id)sender
{
	[self.excludeKeywordsArrayController add:nil];

	[self performSelector:@selector(editTable:) withObject:self.excludeKeywordsTable afterDelay:0.3];
}

- (void)onResetUserListModeColorsToDefaults:(id)sender
{
	TVCMemberList *memberList = self.masterController.memberList;

	NSData *modeycolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_YDefault];
	NSData *modeqcolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_QDefault];
	NSData *modeacolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_ADefault];
	NSData *modeocolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_ODefault];
	NSData *modehcolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_HDefault];
	NSData *modevcolor = [NSArchiver archivedDataWithRootObject:memberList.userMarkBadgeBackgroundColor_VDefault];

	[RZUserDefaults() setObject:modeycolor forKey:@"User List Mode Badge Colors —> +y"];
	[RZUserDefaults() setObject:modeqcolor forKey:@"User List Mode Badge Colors —> +q"];
	[RZUserDefaults() setObject:modeacolor forKey:@"User List Mode Badge Colors —> +a"];
	[RZUserDefaults() setObject:modeocolor forKey:@"User List Mode Badge Colors —> +o"];
	[RZUserDefaults() setObject:modehcolor forKey:@"User List Mode Badge Colors —> +h"];
	[RZUserDefaults() setObject:modevcolor forKey:@"User List Mode Badge Colors —> +v"];

	[[RZUserDefaultsController() values] setValue:modeycolor forKey:@"User List Mode Badge Colors —> +y"];
	[[RZUserDefaultsController() values] setValue:modeqcolor forKey:@"User List Mode Badge Colors —> +q"];
	[[RZUserDefaultsController() values] setValue:modeacolor forKey:@"User List Mode Badge Colors —> +a"];
	[[RZUserDefaultsController() values] setValue:modeocolor forKey:@"User List Mode Badge Colors —> +o"];
	[[RZUserDefaultsController() values] setValue:modehcolor forKey:@"User List Mode Badge Colors —> +h"];
	[[RZUserDefaultsController() values] setValue:modevcolor forKey:@"User List Mode Badge Colors —> +v"];

	[self onChangedUserListModeColor:sender];
}

- (void)onChangedInputHistoryScheme:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadInputHistoryScopeAction];
}

- (void)onChangedSidebarColorInversion:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction];
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];

	[self.worldController executeScriptCommandOnAllViews:@"sidebarInversionPreferenceChanged" arguments:@[] onQueue:NO];
}

- (void)onChangedStyle:(id)sender
{
	//[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction]; // Text direction will reload it too.
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextDirectionAction];
}

- (void)onChangedMainWindowSegmentedController:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction];
}

- (void)onChangedUserListModeColor:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListUserBadgesAction];
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];
}

- (void)onChangedMainInputTextFieldFontSize:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldFontSizeAction];
}

- (void)onChangedHighlightLogging:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadHighlightLoggingAction];
}

- (void)onChangedUserListModeSortOrder:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListSortOrderAction];
}

- (void)onOpenPathToCloudFolder:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([self.masterController.cloudSyncManager ubiquitousContainerIsAvailable] == NO) {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];
		
		[popup sheetWindowWithQuestion:self.window
								target:[TLOPopupPrompts class]
								action:@selector(popupPromptNilSelector:withOriginalAlert:)
								  body:TXTLS(@"iCloudSyncServicesNotAvailableDialogMessage")
								 title:TXTLS(@"iCloudSyncServicesNotAvailableDialogTitle")
						 defaultButton:TXTLS(@"OkButton")
					   alternateButton:nil
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
	} else {
		NSString *path = [TPCPreferences applicationUbiquitousContainerPath];
		
		[RZWorkspace() openFile:path];
	}
#endif
}

- (void)onOpenPathToScripts:(id)sender
{
	[RZWorkspace() openFile:[TPCPreferences applicationSupportFolderPath]];
}

- (void)setTextualAsDefaultIRCClient:(id)sender
{
	[TPCPreferences defaultIRCClientPrompt:YES];
}

- (void)onChangedCloudSyncingServices:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];

		[popup sheetWindowWithQuestion:self.window
								target:[TLOPopupPrompts class]
								action:@selector(popupPromptNilSelector:withOriginalAlert:)
								  body:TXTLS(@"iCloudSyncServicesSupportDisabledDialogMessage")
								 title:TXTLS(@"iCloudSyncServicesSupportDisabledDialogTitle")
						 defaultButton:TXTLS(@"OkButton")
					   alternateButton:nil
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
	} else {
		/* Poll server for latest. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		[self.masterController.cloudSyncManager synchronizeFromCloud];
	}
#endif
}

- (void)onChangedCloudSyncingServicesServersOnly:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud] && [TPCPreferences syncPreferencesToTheCloudLimitedToServers] == NO) {
		/* Poll server for latest. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		[self.masterController.cloudSyncManager synchronizeFromCloud];
	}
#endif
}

- (void)onPurgeOfCloudDataRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		[self.masterController.cloudSyncManager purgeDataStoredWithCloud];
	}
#endif
}

- (void)onPurgeOfCloudFilesRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		NSString *path = [self.masterController.cloudSyncManager ubiquitousContainerURLPath];
		
		/* Try to see if we even have a path… */
		if (NSObjectIsEmpty(path)) {
			LogToConsole(@"Cannot empty iCloud files at this time because iCloud is not available.");
			
			return;
		}
		
		/* Delete styles folder. */
		NSError *delError;
		
		[RZFileManager() removeItemAtPath:[TPCPreferences cloudCustomThemeFolderPath] error:&delError];
		
		if (delError) {
			LogToConsole(@"Delete Error: %@", [delError localizedDescription]);
		}
		
		/* Delete local caches. */
		[RZFileManager() removeItemAtPath:[TPCPreferences cloudCustomThemeCachedFolderPath] error:&delError];
		
		if (delError) {
			LogToConsole(@"Delete Error: %@", [delError localizedDescription]);
		}
		
		// We do not call performValidationForKeyValues here because the
		// metadata query will do that for us once we change the direcoty by deleting.
	}
#endif
}

- (void)onPurgeOfCloudFilesRequested:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	TLOPopupPrompts *popup = [TLOPopupPrompts new];
	
	[popup sheetWindowWithQuestion:self.window
							target:self
							action:@selector(onPurgeOfCloudFilesRequestedCallback:withOriginalAlert:)
							  body:TXTLS(@"iCloudSyncDeleteAllFilesDialogMessage")
							 title:TXTLS(@"iCloudSyncDeleteAllFilesDialogTitle")
					 defaultButton:TXTLS(@"CancelButton")
				   alternateButton:TXTLS(@"ContinueButton")
					   otherButton:nil
					suppressionKey:nil
				   suppressionText:nil];
#endif
}

- (void)onPurgeOfCloudDataRequested:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	TLOPopupPrompts *popup = [TLOPopupPrompts new];

	[popup sheetWindowWithQuestion:self.window
							target:self
							action:@selector(onPurgeOfCloudDataRequestedCallback:withOriginalAlert:)
							  body:TXTLS(@"iCloudSyncDeleteAllDataDialogMessage")
							 title:TXTLS(@"iCloudSyncDeleteAllDataDialogTitle")
					 defaultButton:TXTLS(@"CancelButton")
				   alternateButton:TXTLS(@"ContinueButton")
					   otherButton:nil
					suppressionKey:nil
				   suppressionText:nil];
#endif
}

- (void)openPathToThemesCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	NSString *name = [self.themeController name];

	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		return;
	}
	
	NSString *oldpath = [self.themeController actualPath];
	
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		[RZWorkspace() openFile:oldpath];
	} else {
		BOOL copyingToCloud = NO;
		
		NSString *newpath = [[TPCPreferences customThemeFolderPath]	stringByAppendingPathComponent:name];
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		/* Check to see if the cloud path exists first… */
		if ([self.masterController.cloudSyncManager ubiquitousContainerIsAvailable]) {
			newpath = [[TPCPreferences cloudCustomThemeFolderPath] stringByAppendingPathComponent:name];
			
			copyingToCloud = YES;
		}
#endif
		
		/* Present progress sheet. */
		TDCProgressInformationSheet *ps = [TDCProgressInformationSheet new];
		
		ps.window = self.window;
		
		[originalAlert.window orderOut:nil];
		
		[ps start];
		
		/* Continue with a normal copy. */
		NSError *copyError;

		[RZFileManager() copyItemAtPath:oldpath toPath:newpath error:&copyError];

		if (copyError) {
			LogToConsole(@"%@", [copyError localizedDescription]);
			
			[ps stop];
		} else {
			if (copyingToCloud == NO) {
				[RZWorkspace() openFile:newpath];
			}
			
			NSString *newThemeLocal = [TPCThemeController buildUserFilename:name];

			[TPCPreferences setThemeName:newThemeLocal];
			
			if (copyingToCloud == NO) {
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
			}
			
			if (copyingToCloud == NO) {
				/* Notification for cloud cache rebuilds will do this for us. */
				[self updateThemeSelection];
				
				[ps stop];
			} else {
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
				self.tcopyStyleFilesProgressIndicator = ps;
#endif
			}
		}
	}
}

- (void)onOpenPathToThemes:(id)sender
{
    if ([self.themeController isBundledTheme]) {
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];

		NSString *dialogMessage = @"OpeningLocalStyleResourcesNormalMessage";
		NSString *copyButton = @"OpeningLocalStyleResourcesNormalCopyButton";
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		if ([self.masterController.cloudSyncManager ubiquitousContainerIsAvailable]) {
			dialogMessage = @"OpeningLocalStyleResourcesCloudMessage";
			copyButton = @"OpeningLocalStyleResourcesCloudCopyButton";
		}
#endif
		
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:self
								 action:@selector(openPathToThemesCallback:withOriginalAlert:)
								   body:TXTLS(dialogMessage)
								  title:TXTLS(@"OpeningLocalStyleResourcesTitle")
						  defaultButton:TXTLS(@"ContinueButton")
						alternateButton:TXTLS(@"CancelButton")
							otherButton:TXTLS(copyButton)
						 suppressionKey:nil
						suppressionText:nil];
    } else {
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		BOOL containerAvlb = [self.masterController.cloudSyncManager ubiquitousContainerIsAvailable];
		
		if (containerAvlb) {
			if ([self.themeController storageLocation] == TPCThemeControllerStorageCustomLocation) {
				/* If the theme exists in app support folder, but cloud syncing is available,
				 then offer to sync it to the cloud. */
				
				TLOPopupPrompts *prompt = [TLOPopupPrompts new];
				
				[prompt sheetWindowWithQuestion:[NSApp keyWindow]
										 target:self
										 action:@selector(openPathToThemesCallback:withOriginalAlert:)
										   body:TXTLS(@"OpeningLocalCustomStyleResourcesCloudMessage")
										  title:TXTLS(@"OpeningLocalStyleResourcesTitle")
								  defaultButton:TXTLS(@"ContinueButton")
								alternateButton:TXTLS(@"CancelButton")
									otherButton:TXTLS(@"OpeningLocalStyleResourcesCloudCopyButton")
								 suppressionKey:nil
								suppressionText:nil];
				
				return;
			}
		} else {
			if ([self.themeController storageLocation] == TPCThemeControllerStorageCloudLocation) {
				/* If the current theme is stored in the cloud, but our container is not available, then
				 we have to tell the user we can't open the files right now. */
				
				TLOPopupPrompts *prompt = [TLOPopupPrompts new];
				
				[prompt sheetWindowWithQuestion:self.window
										 target:[TLOPopupPrompts class]
										 action:@selector(popupPromptNilSelector:withOriginalAlert:)
										   body:TXTLS(@"iCloudSyncServicesNotAvailableDialogMessage")
										  title:TXTLS(@"iCloudSyncServicesNotAvailableDialogTitle")
								  defaultButton:TXTLS(@"OkButton")
								alternateButton:nil
									otherButton:nil
								 suppressionKey:nil
								suppressionText:nil];
			}
			
			return;
		}
#endif
		
		/* pathOfTheme… is called to ignore the cloud cache location. */
		NSString *filepath = [self.themeController actualPath];
		
		[RZWorkspace() openFile:filepath];
    }
}

#pragma mark -
#pragma mark Cloud Work

- (void)onCloudSyncControllerDidChangeThemeName:(NSNotification *)aNote
{
	[self updateThemeSelection];
}

- (void)onCloudSyncControllerDidRebuildContainerCache:(NSNotification *)aNote
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* This progress indicator existing means we have to open the path to the
	 current theme. */
	if (self.tcopyStyleFilesProgressIndicator) {
		[self.tcopyStyleFilesProgressIndicator stop];
		self.tcopyStyleFilesProgressIndicator = nil;
		
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
		
		/* pathOfTheme… is called to ignore the cloud cache location. */
		NSString *filepath = [self.themeController actualPath];
		
		[RZWorkspace() openFile:filepath];
	}
	
	[self updateThemeSelection];
#endif
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[RZNotificationCenter() removeObserver:self name:TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification object:nil];
	[RZNotificationCenter() removeObserver:self name:TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification object:nil];
#endif
	
	[self.window saveWindowStateForClass:self.class];

	[TPCPreferences cleanUpHighlightKeywords];

	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end
