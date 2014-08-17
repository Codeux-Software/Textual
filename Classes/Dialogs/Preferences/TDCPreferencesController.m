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

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, strong) TDCProgressInformationSheet *tcopyStyleFilesProgressIndicator;
#endif
@end

@implementation TDCPreferencesController

- (instancetype)init
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

	NSMutableArray *alertSounds = [NSMutableArray new];

	// self.alertSounds treats anything that is not a TDCPreferencesSoundWrapper as
	// an indicator that a [NSMenuItem separatorItem] should be placed in our menu.
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationAddressBookMatchType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationConnectType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationDisconnectType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationHighlightType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationInviteType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationKickType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelNoticeType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationNewPrivateMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateNoticeType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveRequestedType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendSuccessfulType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveSuccessfulType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendFailedType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveFailedType]];

	self.alertSounds = alertSounds;
	
	// Build navigation tree.
	NSMutableArray *navigationTreeMatrix = [NSMutableArray array];

	[navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1016][1]"),
	   @"children" : @[
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][2]"),	@"view" : self.contentViewStyle},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][3]"),	@"view" : self.contentViewInlineMedia},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][4]"),	@"view" : self.contentViewInterface},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][5]"),	@"view" : self.contentViewUserListColors}
		]
	   }];

	[navigationTreeMatrix addObject:@{
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

	[navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1018][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][2]"),	@"view" : self.contentViewDefaultIdentity},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][3]"),	@"view" : self.contentViewIRCopMessages}
		]
	   }];

	[navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1019][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][2]"),	@"view" : self.contentViewKeyboardAndMouse},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][3]"),	@"view" : self.contentViewMainTextField}
		]
	   }];

	// ----------------- //

	NSMutableArray *pluginNavigationItems = [NSMutableArray array];

	[pluginNavigationItems addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][2]"), @"view" : self.contentViewInstalledAddons}
	];

	NSArray *bundles = [sharedPluginManager() pluginsWithPreferencePanes];

	for (THOPluginItem *plugin in bundles) {
		NSString *name = [plugin pluginPreferencesPaneMenuItemName];

		NSView *view = [plugin pluginPreferenesPaneView];

		[pluginNavigationItems addObject:@{@"name" : name, @"view" : view}];
	}

	[navigationTreeMatrix addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][1]"), @"children" : pluginNavigationItems}
	 ];

	// ----------------- //

	[navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1021][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][2]"),	@"view" : self.contentViewExperimentalSettings},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][3]"),	@"view" : self.contentViewFileTransfers},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][4]"),	@"view" : self.contentViewFloodControl},

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
				@{@"name" : TXTLS(@"TDCPreferencesController[1021][5]"),	@"view" : self.contentViewICloud, @"iCloudSyncingNavigationItem" : @(YES)},
#endif

				@{@"name" : TXTLS(@"TDCPreferencesController[1021][6]"),	@"view" : self.contentViewLogLocation}
		]
	   }];
	
	[self.navigationOutlineview setNavigationTreeMatrix:navigationTreeMatrix];

	[self.navigationOutlineview setContentViewPadding:_preferencePaneViewFramePadding];
	[self.navigationOutlineview setContentViewPreferredWidth:_forcedPreferencePaneViewFrameWidth];
	[self.navigationOutlineview setContentViewPreferredHeight:_forcedPreferencePaneViewFrameHeight];
	
	[self.navigationOutlineview reloadData];

	[self.navigationOutlineview expandItem:navigationTreeMatrix[0]];
	[self.navigationOutlineview expandItem:navigationTreeMatrix[1]];
	[self.navigationOutlineview expandItem:navigationTreeMatrix[3]];

	[self.navigationOutlineview startAtSelectionIndex:6];

	/* Growl check. */
	BOOL growlRunning = [GrowlApplicationBridge isGrowlRunning];

	/* We only have notification center on mountain lion or newer so we have to
	 check what OS we are running on before we even doing anything. */
	if (growlRunning) {
		[self.alertNotificationDestinationTextField setStringValue:TXTLS(@"TDCPreferencesController[1005]")];
	} else {
		[self.alertNotificationDestinationTextField setStringValue:TXTLS(@"TDCPreferencesController[1006]")];
	}

	// Complete startup of preferences.
	[self.scriptsController populateData];

	[self.installedScriptsTable setDataSource:_scriptsController];
	
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
	
	[self.window restoreWindowStateForClass:[self class]];
	
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark KVC Properties

- (id)userDefaultsValues
{
	return [TPCPreferencesUserDefaultsObjectProxy userDefaultValues];
}

- (id)localDefaultValues
{
	return [TPCPreferencesUserDefaultsObjectProxy localDefaultValues];
}

- (NSArray *)keywordsArrayControllerDataSource
{
	NSArray *values = [RZUserDefaultsValueProxy() valueForKey:@"Highlight List -> Primary Matches"];
	
	NSMutableArray *returnedValues = [NSMutableArray array];
	
	for (id object in values) {
		[returnedValues addObject:[object mutableCopy]];
	}
	
	return returnedValues;
}

- (NSArray *)excludeWordsArrayControllerDataSource
{
	NSArray *values = [RZUserDefaultsValueProxy() valueForKey:@"Highlight List -> Excluded Matches"];
	
	NSMutableArray *returnedValues = [NSMutableArray array];
	
	for (id object in values) {
		[returnedValues addObject:[object mutableCopy]];
	}
	
	return returnedValues;
}

- (void)setKeywordsArrayControllerDataSource:(id)value
{
	[RZUserDefaultsValueProxy() setValue:value forKey:@"Highlight List -> Primary Matches"];
}

- (void)setExcludeWordsArrayControllerDataSource:(id)value
{
	[RZUserDefaultsValueProxy() setValue:value forKey:@"Highlight List -> Excluded Matches"];
}

- (NSString *)maxLogLines
{
	return [NSString stringWithInteger:[TPCPreferences scrollbackLimit]];
}

- (void)setMaxLogLines:(NSString *)value
{
	[TPCPreferences setScrollbackLimit:[value integerValue]];
}

- (NSString *)completionSuffix
{
	return [TPCPreferences tabCompletionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[TPCPreferences setTabCompletionSuffix:value];
}

- (NSString *)inlineImageMaxWidth
{
	return [NSString stringWithInteger:[TPCPreferences inlineImagesMaxWidth]];
}

- (NSString *)inlineImageMaxHeight
{
	return [NSString stringWithInteger:[TPCPreferences inlineImagesMaxHeight]];;
}

- (void)setInlineImageMaxWidth:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxWidth:[value integerValue]];
}

- (void)setInlineImageMaxHeight:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxHeight:[value integerValue]];
}

- (NSString *)themeChannelViewFontName
{
	return [TPCPreferences themeChannelViewFontName];
}

- (double)themeChannelViewFontSize
{
	return [TPCPreferences themeChannelViewFontSize];
}

- (void)setThemeChannelViewFontName:(id)value
{
	return;
}

- (void)setThemeChannelViewFontSize:(id)value
{
	return;
}

- (NSString *)fileTransferPortRangeStart
{
	return [NSString stringWithInteger:[TPCPreferences fileTransferPortRangeStart]];
}

- (NSString *)fileTransferPortRangeEnd
{
	return [NSString stringWithInteger:[TPCPreferences fileTransferPortRangeEnd]];
}

- (void)setFileTransferPortRangeStart:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeStart:[value integerValue]];
}

- (void)setFileTransferPortRangeEnd:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeEnd:[value integerValue]];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if ([key isEqualToString:@"maxLogLines"]) {
		NSInteger n = [*value integerValue];

		if (n < _linesMin) {
			*value = [NSString stringWithInteger:_linesMin];
		} else if (n > _linesMax) {
			*value = [NSString stringWithInteger:_linesMax];
		}
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger n = [*value integerValue];

		if (n < _inlineImageWidthMin) {
			*value = [NSString stringWithInteger:_inlineImageWidthMin];
		} else if (_inlineImageWidthMax < n) {
			*value = [NSString stringWithInteger:_inlineImageWidthMax];
		}
	} else if ([key isEqualToString:@"inlineImageMaxHeight"]) {
		NSInteger n = [*value integerValue];

		if (n < _inlineImageHeightMin) {
			*value = [NSString stringWithInteger:_inlineImageHeightMin];
		} else if (_inlineImageHeightMax < n) {
			*value = [NSString stringWithInteger:_inlineImageHeightMax];
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeStart"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeEnd];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n > t) {
			*value = [NSString stringWithInteger:t];
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeEnd"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeStart];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n < t) {
			*value = [NSString stringWithInteger:t];
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

        [[self.alertSoundChoiceButton menu] addItem:item];
    }

    [self.alertSoundChoiceButton selectItemAtIndex:0];

	// ---- //

    [self.alertTypeChoiceButton removeAllItems];

    NSArray *alerts = self.alertSounds;

    for (id alert in alerts) {
		if ([alert isKindOfClass:[TDCPreferencesSoundWrapper class]]) {
			NSMenuItem *item = [NSMenuItem new];

			[item setTitle:[alert displayName]];
			[item setTag:[alert eventType]];

			[[self.alertTypeChoiceButton menu] addItem:item];
		} else {
			[[self.alertTypeChoiceButton menu] addItem:[NSMenuItem separatorItem]];
		}
    }

    [self.alertTypeChoiceButton selectItemAtIndex:0];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[self.alertSpeakEventButton setState:[alert speakEvent]];
    [self.alertPushNotificationButton setState:[alert pushNotification]];
    [self.alertDisableWhileAwayButton setState:[alert disabledWhileAway]];
    [self.alertBounceDockIconButton setState:[alert bounceDockIcon]];

	NSInteger soundObject = [[self availableSounds] indexOfObject:[alert alertSound]];
	
	if (soundObject == NSNotFound) {
		[self.alertSoundChoiceButton selectItemAtIndex:0];
	} else {
		[self.alertSoundChoiceButton selectItemAtIndex:soundObject];
	}
}

- (void)onChangedAlertNotification:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    [alert setPushNotification:[self.alertPushNotificationButton state]];
	
	alert = nil;
}

- (void)onChangedAlertSpoken:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setSpeakEvent:[self.alertSpeakEventButton state]];
	
	alert = nil;
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setDisabledWhileAway:[self.alertDisableWhileAwayButton state]];
	
	alert = nil;
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];
    
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
	[alert setBounceDockIcon:[self.alertBounceDockIconButton state]];
	
	alert = nil;
}

- (void)onChangedAlertSound:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[self.alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setAlertSound:[self.alertSoundChoiceButton titleOfSelectedItem]];
	
	alert = nil;
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

	NSString *userSoundFolder = [[userSoundFolderURL relativePath] stringByAppendingPathComponent:@"/Sounds"];

	NSArray *homeDirectoryContents = [RZFileManager() contentsOfDirectoryAtPath:userSoundFolder error:NULL];
	NSArray *systemDirectoryContents = [RZFileManager() contentsOfDirectoryAtPath:systemSoundFolder error:NULL];

	[soundList addObject:TXEmptySoundAlertLabel];
	[soundList addObject:@"Beep"];

	if ([systemDirectoryContents count] > 0) {
		for (__strong NSString *s in systemDirectoryContents) {
			if ([s contains:@"."]) {
				s = [s stringByDeletingPathExtension];
			}

			[soundList addObject:s];
		}
	}

	if ([homeDirectoryContents count] > 0) {
		[soundList addObject:TXEmptySoundAlertLabel];

		for (__strong NSString *s in homeDirectoryContents) {
			if ([s contains:@"."]) {
				s = [s stringByDeletingPathExtension];
			}
			
			[soundList addObject:s];
		}
	}

	return soundList;
}

#pragma mark -
#pragma mark File Transfer Destination Folder Popup

- (void)updateFileTransferDownloadDestinationFolder
{
	TDCFileTransferDialog *transferController = [menuController() fileTransferController];

	NSURL *path = [transferController downloadDestination];
	
	NSMenuItem *item = [self.fileTransferDownloadDestinationButton itemAtIndex:0];
	
	if (path == nil) {
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
	TDCFileTransferDialog *transferController = [menuController() fileTransferController];

	if ([self.fileTransferDownloadDestinationButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];
		
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:BLS(1225)];
		
		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.fileTransferDownloadDestinationButton selectItemAtIndex:0];
			
			if (returnCode == NSOKButton) {
				NSURL *pathURL = [d URLs][0];
				
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
	NSURL *path = [TPCPathInfo logFileFolderLocation];

	NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];

	if (path == nil) {
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
		
		[d setPrompt:BLS(1225)];

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.transcriptFolderButton selectItemAtIndex:0];

			if (returnCode == NSOKButton) {
				NSURL *pathURL = [d URLs][0];

				NSError *error = nil;

				NSData *bookmark = [pathURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
									 includingResourceValuesForKeys:nil
													  relativeToURL:nil
															  error:&error];

				if (error) {
					LogToConsole(@"Error creating bookmark for URL (%@): %@", pathURL, [error localizedDescription]);
				} else {
					[TPCPathInfo setLogFileFolderLocation:bookmark];
				}

				[self updateTranscriptFolder];
			}
		}];
	}
	else if ([self.transcriptFolderButton selectedTag] == 3)
	{
		[self.transcriptFolderButton selectItemAtIndex:0];
		
		[TPCPathInfo setLogFileFolderLocation:nil];
		
		[self updateTranscriptFolder];
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeSelection
{
	[self.themeSelectionButton removeAllItems];
	
	/* The order of the path array defines which theme will take priority
	 over one that already exists. Those at the top are highest priority. */
	NSString *bundledThemePath = [TPCPathInfo bundledThemeFolderPath];

	NSArray *paths = [TPCPathInfo buildPathArray:
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
					  [TPCPathInfo cloudCustomThemeCachedFolderPath],
#endif
					  
					  [TPCPathInfo customThemeFolderPath],
					  bundledThemePath,
					  nil
	];
	
	/* Build list of all theme names and the theme type (custom or bundled). */
	NSMutableDictionary *themeChoices = [NSMutableDictionary dictionary];
	
	for (NSString *path in paths) {
		NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

		for (NSString *file in files) {
			if ([themeChoices containsKey:file]) {
				; // Theme already exists somewhere else.
			} else {
				NSString *cssfilelocal = [path stringByAppendingPathComponent:[file stringByAppendingString:@"/design.css"]];
				
				/* Only add the theme if a design.css file exists. */
				if ([RZFileManager() fileExistsAtPath:cssfilelocal]) {
					
					
					
					
					
					
					
					if ([path isEqualToString:bundledThemePath]) {
						themeChoices[file] = TPCThemeControllerBundledStyleNameBasicPrefix;
					} else {
						themeChoices[file] = TPCThemeControllerCustomStyleNameBasicPrefix;
					}
				}
			}
		}
	}
	
	/* Sort theme choices and create menu item for each. */
	for (NSString *themeName in [themeChoices sortedDictionaryKeys]) {
		NSString *themeType = themeChoices[themeName];
		
		NSMenuItem *cell = [NSMenuItem menuItemWithTitle:themeName target:nil action:nil];
		
		[cell setUserInfo:themeType];
		
		[[self.themeSelectionButton menu] addItem:cell];
	}
	
	/* Select whatever theme matches current name. */
	[self.themeSelectionButton selectItemWithTitle:[themeController() name]];
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem *item = [self.themeSelectionButton selectedItem];

	NSString *newThemeName = nil;

	if ([[item userInfo] isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix]) {
		newThemeName = [TPCThemeController buildResourceFilename:[item title]];
	} else {
		newThemeName = [TPCThemeController buildUserFilename:[item title]];
	}
	
	NSString *oldThemeName = [TPCPreferences themeName];
	
	if ([oldThemeName isEqual:newThemeName]) {
		return;
	}

	[TPCPreferences setThemeName:newThemeName];

	[self onChangedStyle:nil];

	// ---- //

	NSMutableString *sf = [NSMutableString string];

	if (NSObjectIsNotEmpty([themeSettings() nicknameFormat])) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][1]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (NSObjectIsNotEmpty([themeSettings() timestampFormat])) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][2]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if ([themeSettings() channelViewFont]) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][4]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if ([themeSettings() forceInvertSidebarColors]) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][3]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	NSString *tsf = [sf trim];

	NSObjectIsEmptyAssert(tsf);

	TLOPopupPrompts *prompt = [TLOPopupPrompts new];

	[prompt sheetWindowWithQuestion:[NSApp keyWindow]
							 target:[TLOPopupPrompts class]
							 action:@selector(popupPromptNilSelector:withOriginalAlert:)
							   body:TXTLS(@"TDCPreferencesController[1014][2]", [item title], tsf)
							  title:TXTLS(@"TDCPreferencesController[1014][1]")
					  defaultButton:BLS(1186)
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
	[mainWindow() setAlphaValue:[TPCPreferences themeTransparency]];
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

	[self performSelector:@selector(editTable:) withObject:_keywordsTable afterDelay:0.3];
}

- (void)onAddExcludeKeyword:(id)sender
{
	[self.excludeKeywordsArrayController add:nil];

	[self performSelector:@selector(editTable:) withObject:_excludeKeywordsTable afterDelay:0.3];
}

- (void)onResetUserListModeColorsToDefaults:(id)sender
{
	TVCMemberList *memberList = mainWindowMemberList();

	NSColor *modeycolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_YDefault];
	NSColor *modeqcolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_QDefault];
	NSColor *modeacolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_ADefault];
	NSColor *modeocolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_ODefault];
	NSColor *modehcolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_HDefault];
	NSColor *modevcolor = [[memberList userInterfaceObjects] userMarkBadgeBackgroundColor_VDefault];

	[RZUserDefaults() setColor:modeycolor forKey:@"User List Mode Badge Colors —> +y"];
	[RZUserDefaults() setColor:modeqcolor forKey:@"User List Mode Badge Colors —> +q"];
	[RZUserDefaults() setColor:modeacolor forKey:@"User List Mode Badge Colors —> +a"];
	[RZUserDefaults() setColor:modeocolor forKey:@"User List Mode Badge Colors —> +o"];
	[RZUserDefaults() setColor:modehcolor forKey:@"User List Mode Badge Colors —> +h"];
	[RZUserDefaults() setColor:modevcolor forKey:@"User List Mode Badge Colors —> +v"];

	[self onChangedUserListModeColor:sender];
}

- (void)onChangedInputHistoryScheme:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadInputHistoryScopeAction];
}

- (void)onChangedSidebarColorInversion:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMainWindowAppearanceAction];

	[worldController() informViewsThatTheSidebarInversionPreferenceDidChange];
}

- (void)onChangedStyle:(id)sender
{
	[TPCPreferences performReloadActionForActionType:(TPCPreferencesKeyReloadStyleWithTableViewsAction | TPCPreferencesKeyReloadTextDirectionAction)];
}

- (void)onChangedMainWindowSegmentedController:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction];
}

- (void)onChangedUserListModeColor:(id)sender
{
	[TPCPreferences performReloadActionForActionType:(TPCPreferencesKeyReloadMemberListUserBadgesAction | TPCPreferencesKeyReloadMemberListAction)];
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
	if ([sharedCloudManager() ubiquitousContainerIsAvailable] == NO) {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];
		
		[popup sheetWindowWithQuestion:self.window
								target:[TLOPopupPrompts class]
								action:@selector(popupPromptNilSelector:withOriginalAlert:)
								  body:TXTLS(@"BasicLanguage[1102][2]")
								 title:TXTLS(@"BasicLanguage[1102][1]")
						 defaultButton:BLS(1186)
					   alternateButton:nil
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
	} else {
		NSString *path = [TPCPathInfo applicationUbiquitousContainerPath];
		
		[RZWorkspace() openFile:path];
	}
#endif
}

- (void)onOpenPathToScripts:(id)sender
{
	[RZWorkspace() openFile:[TPCPathInfo applicationSupportFolderPath]];
}

- (void)onManageiCloudButtonClicked:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	for (NSDictionary *subdic in [self.navigationOutlineview navigationTreeMatrix]) {
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
						 defaultButton:BLS(1186)
					   alternateButton:nil
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
	} else {
		[RZUbiquitousKeyValueStore() synchronize];
		
		[sharedCloudManager() syncEverythingNextSync];
		[sharedCloudManager() synchronizeFromCloud];
	}
#endif
}

- (void)onChangedCloudSyncingServicesServersOnly:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers] == NO) {
			[RZUbiquitousKeyValueStore() synchronize];
			
			[sharedCloudManager() syncEverythingNextSync];
			[sharedCloudManager() synchronizeFromCloud];
		}
	}
#endif
}

- (void)onPurgeOfCloudDataRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		[sharedCloudManager() purgeDataStoredWithCloud];
	}
#endif
}

- (void)onPurgeOfCloudFilesRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		NSString *path = [sharedCloudManager() ubiquitousContainerURLPath];
		
		/* Try to see if we even have a path… */
		if (path == nil) {
			LogToConsole(@"Cannot empty iCloud files at this time because iCloud is not available.");
			
			return;
		}
		
		/* Delete styles folder. */
		NSError *delError;
		
		[RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemeFolderPath] error:&delError];
		
		if (delError) {
			LogToConsole(@"Delete Error: %@", [delError localizedDescription]);
		}
		
		/* Delete local caches. */
		[RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemeCachedFolderPath] error:&delError];
		
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
					 defaultButton:BLS(1009)
				   alternateButton:BLS(1017)
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
					 defaultButton:BLS(1009)
				   alternateButton:BLS(1017)
					   otherButton:nil
					suppressionKey:nil
				   suppressionText:nil];
#endif
}

- (void)openPathToThemesCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	NSString *name = [themeController() name];

	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		return;
	}
	
	NSString *oldpath = [themeController() actualPath];
	
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		[RZWorkspace() openFile:oldpath];
	} else {
		BOOL copyingToCloud = NO;
		
		NSString *newpath = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:name];
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		/* Check to see if the cloud path exists first… */
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			newpath = [[TPCPathInfo cloudCustomThemeFolderPath] stringByAppendingPathComponent:name];
			
			copyingToCloud = YES;
		}
#endif
		
		/* Present progress sheet. */
		TDCProgressInformationSheet *ps = [TDCProgressInformationSheet new];

		[[originalAlert window] orderOut:nil];
		
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
    if ([themeController() isBundledTheme]) {
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];

		NSString *dialogMessage = @"TDCPreferencesController[1010]";
		NSString *copyButton = @"TDCPreferencesController[1008]";
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			dialogMessage = @"TDCPreferencesController[1011]";
			copyButton = @"TDCPreferencesController[1009]";
		}
#endif
		
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:self
								 action:@selector(openPathToThemesCallback:withOriginalAlert:)
								   body:TXTLS(dialogMessage)
								  title:TXTLS(@"TDCPreferencesController[1013]")
						  defaultButton:BLS(1017)
						alternateButton:BLS(1009)
							otherButton:TXTLS(copyButton)
						 suppressionKey:nil
						suppressionText:nil];
		
		return;
    } else {
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		BOOL containerAvlb = [sharedCloudManager() ubiquitousContainerIsAvailable];
		
		if (containerAvlb) {
			if ([themeController() storageLocation] == TPCThemeControllerStorageCustomLocation) {
				/* If the theme exists in app support folder, but cloud syncing is available,
				 then offer to sync it to the cloud. */
				
				TLOPopupPrompts *prompt = [TLOPopupPrompts new];
				
				[prompt sheetWindowWithQuestion:[NSApp keyWindow]
										 target:self
										 action:@selector(openPathToThemesCallback:withOriginalAlert:)
										   body:TXTLS(@"TDCPreferencesController[1012]")
										  title:TXTLS(@"TDCPreferencesController[1013]")
								  defaultButton:BLS(1017)
								alternateButton:BLS(1009)
									otherButton:TXTLS(@"TDCPreferencesController[1009]")
								 suppressionKey:nil
								suppressionText:nil];
				
				return;
			}
		} else {
			if ([themeController() storageLocation] == TPCThemeControllerStorageCloudLocation) {
				/* If the current theme is stored in the cloud, but our container is not available, then
				 we have to tell the user we can't open the files right now. */
				
				TLOPopupPrompts *prompt = [TLOPopupPrompts new];
				
				[prompt sheetWindowWithQuestion:self.window
										 target:[TLOPopupPrompts class]
										 action:@selector(popupPromptNilSelector:withOriginalAlert:)
										   body:TXTLS(@"BasicLanguage[1102][2]")
										  title:TXTLS(@"BasicLanguage[1102][1]")
								  defaultButton:BLS(1186)
								alternateButton:nil
									otherButton:nil
								 suppressionKey:nil
								suppressionText:nil];
				
				return;
			}
		}
#endif
		
		/* pathOfTheme… is called to ignore the cloud cache location. */
		NSString *filepath = [themeController() actualPath];
		
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
	if ( self.tcopyStyleFilesProgressIndicator) {
		[self.tcopyStyleFilesProgressIndicator stop];
		 self.tcopyStyleFilesProgressIndicator = nil;
		
		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
		
		/* pathOfTheme… is called to ignore the cloud cache location. */
		NSString *filepath = [themeController() actualPath];
		
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
	/* We set alpha to hide window but also change frame underneath user. */
	[self.window setAlphaValue:0.0];

	NSRect windowFrame = [self.window frame];

	windowFrame.size.height = _forcedPreferencePaneViewFrameHeight;

	[self.window setFrame:windowFrame display:NO animate:NO];

	[self.window saveWindowStateForClass:[self class]];

	/* Clean up highlight keywords. */
	[TPCPreferences cleanUpHighlightKeywords];

	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end
