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

#define _fileTransferPortRangeMin			1024
#define _fileTransferPortRangeMax			65535

#define _preferencePaneViewFramePadding				38

#define _forcedPreferencePaneViewFrameHeight		406
#define _forcedPreferencePaneViewFrameWidth			567

#define _addonsToolbarItemMultiplier		65

@interface TDCPreferencesController ()
@property (nonatomic, strong) NSMutableArray *navigationTreeMatrix;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, strong) TDCProgressInformationSheet *tcopyStyleFilesProgressIndicator;
#endif
@end

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
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveRequestedType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendSuccessfulType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveSuccessfulType]];
	[self.alertSounds addObject:NSStringWhitespacePlaceholder];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendFailedType]];
	[self.alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveFailedType]];

	// Build navigation tree.
	self.navigationTreeMatrix = [NSMutableArray array];

	[self.navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1016][1]"),
	   @"children" : @[
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][2]"),	@"view" : self.contentViewStyle},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][3]"),	@"view" : self.contentViewInlineMedia},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][4]"),	@"view" : self.contentViewInterface},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][5]"),	@"view" : self.contentViewUserListColors}
		]
	   }];

	[self.navigationTreeMatrix addObject:@{
	   @"blockCollapse" : @(YES),
	   @"name" : TXTLS(@"TDCPreferencesController[1017][1]"),
	   @"children" : @[
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][2]"),	@"view" : self.contentViewGeneral},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][3]"),	@"view" : self.contentViewChannelManagement},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][4]"),	@"view" : self.contentViewCommandScope},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][5]"),	@"view" : self.contentViewHighlights},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][6]"),	@"view" : self.contentViewIncomingData},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][7]"),	@"view" : self.contentViewAlerts}
		]
	   }];

	[self.navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1018][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][2]"),	@"view" : self.contentViewDefaultIdentity},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][3]"),	@"view" : self.contentViewIRCopMessages}
		]
	   }];

	[self.navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1019][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][2]"),	@"view" : self.contentViewKeyboardAndMouse},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][3]"),	@"view" : self.contentViewKeyboardNavigation},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][4]"),	@"view" : self.contentViewMainTextField}
		]
	   }];

	// ----------------- //

	NSMutableArray *pluginNavigationItems = [NSMutableArray array];

	[pluginNavigationItems addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][2]"), @"view" : self.contentViewInstalledAddons}
	];

	NSArray *bundles = [THOPluginManagerSharedInstance() pluginsWithPreferencePanes];

	for (THOPluginItem *plugin in bundles) {
		NSString *name = [[plugin primaryClass] preferencesMenuItemName];

		NSView *view = [[plugin primaryClass] preferencesView];

		[pluginNavigationItems addObject:@{@"name" : name, @"view" : view}];
	}

	[self.navigationTreeMatrix addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][1]"), @"children" : pluginNavigationItems}
	 ];

	// ----------------- //

	[self.navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1021][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][2]"),	@"view" : self.contentViewExperimentalSettings},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][3]"),	@"view" : self.contentViewFileTransfers},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][4]"),	@"view" : self.contentViewFloodControl},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][5]"),	@"view" : self.contentViewICloud, @"iCloudSyncingNavigationItem" : @(YES)},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][6]"),	@"view" : self.contentViewLogLocation}
		]
	   }];

	 self.navigationOutlineview.dataSource = self;
	 self.navigationOutlineview.delegate = self;

	[self.navigationOutlineview reloadData];

	[self.navigationOutlineview expandItem:self.navigationTreeMatrix[0]];
	[self.navigationOutlineview expandItem:self.navigationTreeMatrix[1]];
	[self.navigationOutlineview expandItem:self.navigationTreeMatrix[3]];

	[self.navigationOutlineview selectItemAtIndex:6];

	// Complete startup of preferences.
	[self.scriptsController populateData];

	 self.installedScriptsTable.dataSource = self.scriptsController;
	[self.installedScriptsTable reloadData];

	[self updateThemeSelection];
    [self updateAlertSelection];
	[self updateTranscriptFolder];
	[self updateFileTransferDownloadDestinationFolder];

	[self onChangedAlertType:nil];
	[self onChangedHighlightType:nil];
	[self onFileTransferIPAddressDetectionMethodChanged:nil];
	
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
}

#pragma mark -
#pragma mark NSOutlineViewDelegate Delegates

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(NSDictionary *)item
{
	if (item) {
		return [item[@"children"] count];
	} else {
		return [self.navigationTreeMatrix count];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(NSDictionary *)item
{
	if (item) {
		return item[@"children"][index];
	} else {
		return self.navigationTreeMatrix[index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(NSDictionary *)item
{
	return ([item boolForKey:@"blockCollapse"] == NO);
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(NSDictionary *)item
{
	return [item containsKey:@"children"];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item
{
	return item[@"name"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ([item containsKey:@"children"] == NO);
}

- (id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSDictionary *)item
{
	NSTableCellView *newView = [outlineView makeViewWithIdentifier:@"navEntry" owner:self];

	[[newView textField] setStringValue:item[@"name"]];

	return newView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedRow = [self.navigationOutlineview selectedRow];

	NSDictionary *navItem = [self.navigationOutlineview itemAtRow:selectedRow];

	[self presentPreferencesPane:navItem[@"view"]];
}

- (void)presentPreferencesPane:(NSView *)newView
{
	/* Add view. */
	if (NSObjectIsNotEmpty(self.contentView.subviews)) {
		[self.contentView.subviews[0] removeFromSuperview];
	}

	[self.contentView addSubview:newView];

	/* Set view frame. */
	NSRect viewFrame = [newView frame];

	viewFrame.origin.x = 0;
	viewFrame.origin.y = 0;

	viewFrame.size.width = _forcedPreferencePaneViewFrameWidth;

	if (viewFrame.size.height < _forcedPreferencePaneViewFrameHeight) {
		viewFrame.size.height = _forcedPreferencePaneViewFrameHeight;
	}

	[newView setFrame:viewFrame];

	/* Set content view frame. */
	NSRect contentViewFrame = [self.contentView frame];

	contentViewFrame.size.height = viewFrame.size.height;

	[self.contentView setFrame:contentViewFrame];

	/* Set window frame. */
	NSRect windowFrame = [self.window frame];

	windowFrame.size.height = (_preferencePaneViewFramePadding + viewFrame.size.height);

	[self.window setFrame:windowFrame display:YES animate:YES];

	/* Fix tab key navigation. */
	[self.window recalculateKeyViewLoop];
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

- (NSInteger)fileTransferPortRangeStart
{
	return [TPCPreferences fileTransferPortRangeStart];
}

- (NSInteger)fileTransferPortRangeEnd
{
	return [TPCPreferences fileTransferPortRangeEnd];
}

- (void)setFileTransferPortRangeStart:(NSInteger)value
{
	[TPCPreferences setFileTransferPortRangeStart:value];
}

- (void)setFileTransferPortRangeEnd:(NSInteger)value
{
	[TPCPreferences setFileTransferPortRangeEnd:value];
}

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
	} else if ([key isEqualToString:@"fileTransferPortRangeStart"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeEnd];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSNumber numberWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSNumber numberWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n > t) {
			*value = [NSNumber numberWithInteger:t];
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeEnd"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeStart];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSNumber numberWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSNumber numberWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n < t) {
			*value = [NSNumber numberWithInteger:t];
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
#pragma mark File Transfer Destination Folder Popup

- (void)updateFileTransferDownloadDestinationFolder
{
	TDCFileTransferDialog *transferController = [self.menuController fileTransferController];

	NSURL *path = [transferController downloadDestination];
	
	NSMenuItem *item = [self.fileTransferDownloadDestinationButton itemAtIndex:0];
	
	if (NSObjectIsEmpty(path)) {
		[item setTitle:TXTLS(@"TDCPreferencesController[1004]")];
		
		[item setImage:nil];
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:[path path]];
		
		[icon setSize:NSMakeSize(16, 16)];
		
		[item setImage:icon];
		[item setTitle:[path lastPathComponent]];
	}
}

- (void)onFileTransferDownloadDestinationFolderChanged:(id)sender
{
	TDCFileTransferDialog *transferController = [self.menuController fileTransferController];

	if ([self.fileTransferDownloadDestinationButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];
		
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:TXTLS(@"BasicLanguage[1225]")];
		
		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.fileTransferDownloadDestinationButton selectItemAtIndex:0];
			
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
					[transferController setDownloadDestinationFolder:bookmark];
				}
				
				[self updateFileTransferDownloadDestinationFolder];
			}
		}];
	}
	else if ([self.fileTransferDownloadDestinationButton selectedTag] == 3)
	{
		[self.fileTransferDownloadDestinationButton selectItemAtIndex:0];

		[transferController setDownloadDestinationFolder:nil];

		[self updateFileTransferDownloadDestinationFolder];
	}
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSURL *path = [TPCPreferences transcriptFolder];

	NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];

	if (NSObjectIsEmpty(path)) {
		[item setTitle:TXTLS(@"TDCPreferencesController[1003]")];
		
		[item setImage:nil];
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:[path path]];

		[icon setSize:NSMakeSize(16, 16)];

		[item setImage:icon];
		[item setTitle:[path lastPathComponent]];
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
		
		[d setPrompt:TXTLS(@"BasicLanguage[1225]")];

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.transcriptFolderButton selectItemAtIndex:0];

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
	else if ([self.transcriptFolderButton selectedTag] == 3)
	{
		[self.transcriptFolderButton selectItemAtIndex:0];
		
		[TPCPreferences setTranscriptFolder:nil];
		
		[self updateTranscriptFolder];
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
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][1]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (NSObjectIsNotEmpty(self.themeController.customSettings.timestampFormat)) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][2]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (self.themeController.customSettings.channelViewFont) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][4]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (self.themeController.customSettings.forceInvertSidebarColors) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][3]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	NSString *tsf = sf.trim;

	NSObjectIsEmptyAssert(tsf);

	TLOPopupPrompts *prompt = [TLOPopupPrompts new];

	[prompt sheetWindowWithQuestion:[NSApp keyWindow]
							 target:[TLOPopupPrompts class]
							 action:@selector(popupPromptNilSelector:withOriginalAlert:)
							   body:TXTFLS(@"TDCPreferencesController[1014][2]", item.title, tsf)
							  title:TXTLS(@"TDCPreferencesController[1014][1]")
					  defaultButton:TXTLS(@"BasicLanguage[1186]")
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

- (void)onFileTransferIPAddressDetectionMethodChanged:(id)sender
{
	TXFileTransferIPAddressDetectionMethod detectionMethod = [TPCPreferences fileTransferIPAddressDetectionMethod];
	
	[self.fileTransferManuallyEnteredIPAddressField setEnabled:(detectionMethod == TXFileTransferIPAddressManualDetectionMethod)];
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
								  body:TXTLS(@"BasicLanguage[1102][2]")
								 title:TXTLS(@"BasicLanguage[1102][1]")
						 defaultButton:TXTLS(@"BasicLanguage[1186]")
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

- (void)onManageiCloudButtonClicked:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	for (NSDictionary *subdic in self.navigationTreeMatrix) {
		for (NSDictionary *chldic in subdic[@"children"]) {
			if ([chldic boolForKey:@"iCloudSyncingNavigationItem"]) {
				if ([self.navigationOutlineview isItemExpanded:subdic] == NO) {
					[self.navigationOutlineview expandItem:subdic];

					[self onManageiCloudButtonClicked:sender];
				} else {
					NSInteger icrow = [self.navigationOutlineview rowForItem:chldic];

					[self.navigationOutlineview selectItemAtIndex:icrow];
				}
			}
		}
	}
#endif
}

- (void)onChangedCloudSyncingServices:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];

		[popup sheetWindowWithQuestion:self.window
								target:[TLOPopupPrompts class]
								action:@selector(popupPromptNilSelector:withOriginalAlert:)
								  body:TXTLS(@"TDCPreferencesController[1000][2]")
								 title:TXTLS(@"TDCPreferencesController[1000][1]")
						 defaultButton:TXTLS(@"BasicLanguage[1186]")
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
							  body:TXTLS(@"TDCPreferencesController[1001][2]")
							 title:TXTLS(@"TDCPreferencesController[1001][1]")
					 defaultButton:TXTLS(@"BasicLanguage[1009]")
				   alternateButton:TXTLS(@"BasicLanguage[1017]")
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
							  body:TXTLS(@"TDCPreferencesController[1002][2]")
							 title:TXTLS(@"TDCPreferencesController[1002][1]")
					 defaultButton:TXTLS(@"BasicLanguage[1009]")
				   alternateButton:TXTLS(@"BasicLanguage[1017]")
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

		[originalAlert.window orderOut:nil];
		
		[ps startWithWindow:self.window];
		
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

		NSString *dialogMessage = @"TDCPreferencesController[1010]";
		NSString *copyButton = @"TDCPreferencesController[1008]";
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		if ([self.masterController.cloudSyncManager ubiquitousContainerIsAvailable]) {
			dialogMessage = @"TDCPreferencesController[1011]";
			copyButton = @"TDCPreferencesController[1009]";
		}
#endif
		
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:self
								 action:@selector(openPathToThemesCallback:withOriginalAlert:)
								   body:TXTLS(dialogMessage)
								  title:TXTLS(@"TDCPreferencesController[1013]")
						  defaultButton:TXTLS(@"BasicLanguage[1017]")
						alternateButton:TXTLS(@"BasicLanguage[1009]")
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
										   body:TXTLS(@"TDCPreferencesController[1012]")
										  title:TXTLS(@"TDCPreferencesController[1013]")
								  defaultButton:TXTLS(@"BasicLanguage[1017]")
								alternateButton:TXTLS(@"BasicLanguage[1009]")
									otherButton:TXTLS(@"TDCPreferencesController[1009]")
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
										   body:TXTLS(@"BasicLanguage[1102][2]")
										  title:TXTLS(@"BasicLanguage[1102][1]")
								  defaultButton:TXTLS(@"BasicLanguage[1186]")
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

	/* Forced save frame to use default size. */
	NSRect windowFrame = [self.window frame];

	windowFrame.size.height = _forcedPreferencePaneViewFrameHeight;

	[self.window setFrame:windowFrame display:NO animate:NO];
	[self.window saveWindowStateForClass:self.class];

	/* Clean up highlight keywords. */
	[TPCPreferences cleanUpHighlightKeywords];

	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end
