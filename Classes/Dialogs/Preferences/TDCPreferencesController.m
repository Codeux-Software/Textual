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
@property (nonatomic, assign) BOOL navgiationTreeIsAnimating;
@property (nonatomic, strong) NSMutableArray *navigationTreeMatrix;
@property (nonatomic, assign) NSInteger lastSelectedNavigationItem;
@property (nonatomic, assign) NSInteger currentSelectedNavigationItem;

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
	_scriptsController = [TDCPreferencesScriptWrapper new];

	_alertSounds = [NSMutableArray new];

	// _alertSounds treats anything that is not a TDCPreferencesSoundWrapper as
	// an indicator that a [NSMenuItem separatorItem] should be placed in our menu.
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationAddressBookMatchType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationConnectType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationDisconnectType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationHighlightType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationInviteType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationKickType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelMessageType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelNoticeType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationNewPrivateMessageType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateMessageType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateNoticeType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveRequestedType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendSuccessfulType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveSuccessfulType]];
	[_alertSounds addObject:NSStringWhitespacePlaceholder];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendFailedType]];
	[_alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveFailedType]];

	// Build navigation tree.
	_navigationTreeMatrix = [NSMutableArray array];

	[_navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1016][1]"),
	   @"children" : @[
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][2]"),	@"view" : _contentViewStyle},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][3]"),	@"view" : _contentViewInlineMedia},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][4]"),	@"view" : _contentViewInterface},
			@{@"name" : TXTLS(@"TDCPreferencesController[1016][5]"),	@"view" : _contentViewUserListColors}
		]
	   }];

	[_navigationTreeMatrix addObject:@{
	   @"blockCollapse" : @(YES),
	   @"name" : TXTLS(@"TDCPreferencesController[1017][1]"),
	   @"children" : @[
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][2]"),	@"view" : _contentViewGeneral},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][3]"),	@"view" : _contentViewChannelManagement},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][4]"),	@"view" : _contentViewCommandScope},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][5]"),	@"view" : _contentViewHighlights},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][6]"),	@"view" : _contentViewIncomingData},
			  @{@"name" : TXTLS(@"TDCPreferencesController[1017][7]"),	@"view" : _contentViewAlerts}
		]
	   }];

	[_navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1018][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][2]"),	@"view" : _contentViewDefaultIdentity},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1018][3]"),	@"view" : _contentViewIRCopMessages}
		]
	   }];

	[_navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1019][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][2]"),	@"view" : _contentViewKeyboardAndMouse},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1019][3]"),	@"view" : _contentViewMainTextField}
		]
	   }];

	// ----------------- //

	NSMutableArray *pluginNavigationItems = [NSMutableArray array];

	[pluginNavigationItems addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][2]"), @"view" : _contentViewInstalledAddons}
	];

	NSArray *bundles = [sharedPluginManager() pluginsWithPreferencePanes];

	for (THOPluginItem *plugin in bundles) {
		NSString *name = [plugin pluginPreferencesPaneMenuItemName];

		NSView *view = [plugin pluginPreferenesPaneView];

		[pluginNavigationItems addObject:@{@"name" : name, @"view" : view}];
	}

	[_navigationTreeMatrix addObject:
		@{@"name" : TXTLS(@"TDCPreferencesController[1020][1]"), @"children" : pluginNavigationItems}
	 ];

	// ----------------- //

	[_navigationTreeMatrix addObject:@{
	   @"name" : TXTLS(@"TDCPreferencesController[1021][1]"),
	   @"children" : @[
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][2]"),	@"view" : _contentViewExperimentalSettings},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][3]"),	@"view" : _contentViewFileTransfers},
			   @{@"name" : TXTLS(@"TDCPreferencesController[1021][4]"),	@"view" : _contentViewFloodControl},

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
				@{@"name" : TXTLS(@"TDCPreferencesController[1021][5]"),	@"view" : _contentViewICloud, @"iCloudSyncingNavigationItem" : @(YES)},
#endif

				@{@"name" : TXTLS(@"TDCPreferencesController[1021][6]"),	@"view" : _contentViewLogLocation}
		]
	   }];

	[_navigationOutlineview setDataSource:self];
	[_navigationOutlineview setDelegate:self];

	[_navigationOutlineview reloadData];

	[_navigationOutlineview expandItem:_navigationTreeMatrix[0]];
	[_navigationOutlineview expandItem:_navigationTreeMatrix[1]];
	[_navigationOutlineview expandItem:_navigationTreeMatrix[3]];

	_lastSelectedNavigationItem = 6;
	_currentSelectedNavigationItem = 6;

	[_navigationOutlineview selectItemAtIndex:6];

	/* Growl check. */
	BOOL growlRunning = [GrowlApplicationBridge isGrowlRunning];

	/* We only have notification center on mountain lion or newer so we have to
	 check what OS we are running on before we even doing anything. */
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion] == NO || growlRunning) {
		if (growlRunning) {
			[_alertNotificationDestinationTextField setStringValue:TXTLS(@"TDCPreferencesController[1005]")];
		} else {
			[_alertNotificationDestinationTextField setStringValue:TXTLS(@"TDCPreferencesController[1007]")];
		}
	} else {
		[_alertNotificationDestinationTextField setStringValue:TXTLS(@"TDCPreferencesController[1006]")];
	}

	// Complete startup of preferences.
	[_scriptsController populateData];

	[_installedScriptsTable setDataSource:_scriptsController];
	
	[_installedScriptsTable reloadData];

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
	
	[_syncPreferencesToTheCloudButton setState:[TPCPreferences syncPreferencesToTheCloud]];
#endif
	
	[_setAsDefaultIRCClientButton setHidden:[TPCApplicationInfo isDefaultIRCClient]];

	[[self window] restoreWindowStateForClass:[self class]];
	
	[[self window] makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark NSOutlineViewDelegate Delegates

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(NSDictionary *)item
{
	if (item) {
		return [item[@"children"] count];
	} else {
		return [_navigationTreeMatrix count];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(NSDictionary *)item
{
	if (item) {
		return item[@"children"][index];
	} else {
		return _navigationTreeMatrix[index];
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
	if (_navgiationTreeIsAnimating) {
		return NO;
	} else {
		return ([item containsKey:@"children"] == NO);
	}
}

- (id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSDictionary *)item
{
	NSTableCellView *newView = [outlineView makeViewWithIdentifier:@"navEntry" owner:self];

	[[newView textField] setStringValue:item[@"name"]];

	return newView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedRow = [_navigationOutlineview selectedRow];

	NSDictionary *navItem = [_navigationOutlineview itemAtRow:selectedRow];

	_lastSelectedNavigationItem = _currentSelectedNavigationItem;
	
	_currentSelectedNavigationItem = selectedRow;

	[self presentPreferencesPane:navItem[@"view"]];
}

- (NSRect)currentWindowFrame
{
	return [[self window] frame];
}

- (void)presentPreferencesPane:(NSView *)newView
{
	/* Determine direction. */
	BOOL isGoingDown = NO;

	if (_currentSelectedNavigationItem > _lastSelectedNavigationItem) {
		isGoingDown = YES;
	}

	BOOL invertedScrollingDirection = [RZUserDefaults() boolForKey:@"com.apple.swipescrolldirection"];

	if (invertedScrollingDirection) {
		if (isGoingDown) {
			isGoingDown = NO;
		} else {
			isGoingDown = YES;
		}
	}

	_navgiationTreeIsAnimating = YES;

	/* Set view frame. */
	NSRect newViewFinalFrame = [newView frame];

	newViewFinalFrame.origin.x = 0;
	newViewFinalFrame.origin.y = 0;

	newViewFinalFrame.size.width = _forcedPreferencePaneViewFrameWidth;

	if (newViewFinalFrame.size.height < _forcedPreferencePaneViewFrameHeight) {
		newViewFinalFrame.size.height = _forcedPreferencePaneViewFrameHeight;
	}

	/* Set frame animation will start at. */
	NSRect newViewAnimationFrame = newViewFinalFrame;

	if (isGoingDown) {
		newViewAnimationFrame.origin.y += newViewAnimationFrame.size.height;
	} else {
		newViewAnimationFrame.origin.y -= newViewAnimationFrame.size.height;
	}

	[newView setFrame:newViewAnimationFrame];

	/* Update window size. */
	NSRect contentViewFrame = [_contentView frame];

	BOOL contentSizeDidntChange =  (contentViewFrame.size.height == newViewFinalFrame.size.height);
	BOOL windowWillBecomeSmaller = (contentViewFrame.size.height >  newViewFinalFrame.size.height);

	/* Special condition to allow for smoother animations when going up
	 with a window which is resizing to a smaller size. */
	if (isGoingDown && windowWillBecomeSmaller) {
		isGoingDown = NO;
	}

	/* Set window frame. */
	NSRect windowFrame = [self currentWindowFrame];

	if (contentSizeDidntChange == NO) {
		windowFrame.size.height = (_preferencePaneViewFramePadding + newViewFinalFrame.size.height);

		windowFrame.origin.y = (NSMaxY([self currentWindowFrame]) - windowFrame.size.height);

		[[self window] setFrame:windowFrame display:YES animate:YES];
	}

	/* Add new frame. */
	[_contentView addSubview:newView];

	/* Update content frame. */
	if (contentSizeDidntChange == NO) {
		contentViewFrame.size.height = newViewFinalFrame.size.height;
	}

	/* Cancel any previous animation resets. */
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timedRemoveFrame:) object:newView];

	/* Begin animation. */
	[RZAnimationCurrentContext() setDuration:0.7];

	/* Find existing views. */
	/* If count is 0, then that means preferences just launched
	 and we have not added anything to our window yet. */
	NSArray *subviews = [_contentView subviews];

	NSInteger subviewCount = [subviews count];

	if (subviewCount > 1) {
		NSView *oldView = [_contentView subviews][0];

		/* If the number of visible views is more than 2 (the one we added and the old),
		 then we erase the old views because the user could be clicking the navigation
		 list fast which means the old views would stick until animations complete. */
		if (subviewCount > 2) {
			for (NSInteger i = 2; i < subviewCount; i++) {
				[subviews[i] removeFromSuperview];
			}
		}

		NSRect oldViewAnimationFrame = [oldView frame]; // Set frame animation will end at.

		if (isGoingDown) {
			oldViewAnimationFrame.origin.y = -(windowFrame.size.height); // No way anything will be there…
		} else {
			oldViewAnimationFrame.origin.y =   windowFrame.size.height; // No way anything will be there…
		}

		[oldView.animator setAlphaValue:0.0];
		[oldView.animator setFrame:oldViewAnimationFrame];

		[newView.animator setAlphaValue:1.0];
		[newView.animator setFrame:newViewFinalFrame];

		[self performSelector:@selector(timedRemoveFrame:) withObject:oldView afterDelay:0.3];
	} else {
		[newView setFrame:newViewFinalFrame];

		_navgiationTreeIsAnimating = NO;
	}

	[[self window] recalculateKeyViewLoop];
}

- (void)timedRemoveFrame:(NSView *)oldView
{
	_navgiationTreeIsAnimating = NO;

	[oldView removeFromSuperview];
}

#pragma mark -
#pragma mark KVC Properties

- (NSInteger)maxLogLines
{
	return [TPCPreferences scrollbackLimit];
}

- (void)setMaxLogLines:(NSInteger)value
{
	[TPCPreferences setScrollbackLimit:value];
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

- (void)setThemeChannelViewFontName:(id)value
{
	return;
}

- (void)setThemeChannelViewFontSize:(id)value
{
	return;
}

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
	[_alertSoundChoiceButton removeAllItems];

	NSArray *alertSounds = [self availableSounds];

    for (NSString *alertSound in alertSounds) {
        NSMenuItem *item = [NSMenuItem new];

        [item setTitle:alertSound];

        [[_alertSoundChoiceButton menu] addItem:item];
    }

    [_alertSoundChoiceButton selectItemAtIndex:0];

	// ---- //

    [_alertTypeChoiceButton removeAllItems];

    NSMutableArray *alerts = _alertSounds;

    for (id alert in alerts) {
		if ([alert isKindOfClass:[TDCPreferencesSoundWrapper class]]) {
			NSMenuItem *item = [NSMenuItem new];

			[item setTitle:[alert displayName]];
			[item setTag:[alert eventType]];

			[[_alertTypeChoiceButton menu] addItem:item];
		} else {
			[[_alertTypeChoiceButton menu] addItem:[NSMenuItem separatorItem]];
		}
    }

    [_alertTypeChoiceButton selectItemAtIndex:0];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[_alertSpeakEventButton setState:[alert speakEvent]];
    [_alertPushNotificationButton setState:[alert pushNotification]];
    [_alertDisableWhileAwayButton setState:[alert disabledWhileAway]];
    [_alertBounceDockIconButton setState:[alert bounceDockIcon]];

	NSInteger soundObject = [[self availableSounds] indexOfObject:[alert alertSound]];
	
	if (soundObject == NSNotFound) {
		[_alertSoundChoiceButton selectItemAtIndex:0];
	} else {
		[_alertSoundChoiceButton selectItemAtIndex:soundObject];
	}
}

- (void)onChangedAlertNotification:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    [alert setPushNotification:[_alertPushNotificationButton state]];
	
	alert = nil;
}

- (void)onChangedAlertSpoken:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setSpeakEvent:[_alertSpeakEventButton state]];
	
	alert = nil;
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setDisabledWhileAway:[_alertDisableWhileAwayButton state]];
	
	alert = nil;
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];
    
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
	[alert setBounceDockIcon:[_alertBounceDockIconButton state]];
	
	alert = nil;
}

- (void)onChangedAlertSound:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[_alertTypeChoiceButton selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setAlertSound:[_alertSoundChoiceButton titleOfSelectedItem]];
	
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
	
	NSMenuItem *item = [_fileTransferDownloadDestinationButton itemAtIndex:0];
	
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

	if ([_fileTransferDownloadDestinationButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];
		
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:BLS(1225)];
		
		[d beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
			[_fileTransferDownloadDestinationButton selectItemAtIndex:0];
			
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
	else if ([_fileTransferDownloadDestinationButton selectedTag] == 3)
	{
		[_fileTransferDownloadDestinationButton selectItemAtIndex:0];

		[transferController setDownloadDestinationFolder:nil];

		[self updateFileTransferDownloadDestinationFolder];
	}
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSURL *path = [TPCPathInfo logFileFolderLocation];

	NSMenuItem *item = [_transcriptFolderButton itemAtIndex:0];

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
	if ([_transcriptFolderButton selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:BLS(1225)];

		[d beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
			[_transcriptFolderButton selectItemAtIndex:0];

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
	else if ([_transcriptFolderButton selectedTag] == 3)
	{
		[_transcriptFolderButton selectItemAtIndex:0];
		
		[TPCPathInfo setLogFileFolderLocation:nil];
		
		[self updateTranscriptFolder];
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeSelection
{
	[_themeSelectionButton removeAllItems];
	
	/* The order of the path array defines which theme will take priority
	 over one that already exists. Those at the top are highest priority. */
	NSString *bundledThemePath = [TPCPathInfo bundledThemeFolderPath];

	NSArray *paths = [TPCPathInfo buildPathArray:
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
					  [TPCPathInfo cloudCustomThemeCachedFolderPath],
#endif
					  
					  [TPCPathInfo customThemeFolderPath],
					  bundledThemePath
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
						[themeChoices setObject:TPCThemeControllerBundledStyleNameBasicPrefix forKey:file];
					} else {
						[themeChoices setObject:TPCThemeControllerCustomStyleNameBasicPrefix forKey:file];
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
		
		[[_themeSelectionButton menu] addItem:cell];
	}
	
	/* Select whatever theme matches current name. */
	[_themeSelectionButton selectItemWithTitle:[themeController() name]];
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem *item = [_themeSelectionButton selectedItem];

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

	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction];
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];

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
        [_highlightNicknameButton setEnabled:NO];
    } else {
        [_highlightNicknameButton setEnabled:YES];
    }
	
	[_addExcludeKeywordButton setEnabled:YES];
	[_excludeKeywordsTable setEnabled:YES];
}

- (void)editTable:(NSTableView *)table
{
	NSInteger row = ([table numberOfRows] - 1);

	[table scrollRowToVisible:row];
	[table editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
	[_matchKeywordsArrayController add:nil];

	[self performSelector:@selector(editTable:) withObject:_keywordsTable afterDelay:0.3];
}

- (void)onAddExcludeKeyword:(id)sender
{
	[_excludeKeywordsArrayController add:nil];

	[self performSelector:@selector(editTable:) withObject:_excludeKeywordsTable afterDelay:0.3];
}

- (void)onResetUserListModeColorsToDefaults:(id)sender
{
	TVCMemberList *memberList = mainWindowMemberList();

	NSData *modeycolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_YDefault]];
	NSData *modeqcolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_QDefault]];
	NSData *modeacolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_ADefault]];
	NSData *modeocolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_ODefault]];
	NSData *modehcolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_HDefault]];
	NSData *modevcolor = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_VDefault]];

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

	[worldController() executeScriptCommandOnAllViews:@"sidebarInversionPreferenceChanged" arguments:@[] onQueue:NO];
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
	
	[_fileTransferManuallyEnteredIPAddressField setEnabled:(detectionMethod == TXFileTransferIPAddressManualDetectionMethod)];
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
		
		[popup sheetWindowWithQuestion:[self window]
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

- (void)setTextualAsDefaultIRCClient:(id)sender
{
	[TPCApplicationInfo defaultIRCClientPrompt:YES];
}

- (void)onManageiCloudButtonClicked:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	for (NSDictionary *subdic in _navigationTreeMatrix) {
		for (NSDictionary *chldic in subdic[@"children"]) {
			if ([chldic boolForKey:@"iCloudSyncingNavigationItem"]) {
				if ([_navigationOutlineview isItemExpanded:subdic] == NO) {
					[_navigationOutlineview expandItem:subdic];

					[self onManageiCloudButtonClicked:sender];
				} else {
					NSInteger icrow = [_navigationOutlineview rowForItem:chldic];

					[_navigationOutlineview selectItemAtIndex:icrow];
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

		[popup sheetWindowWithQuestion:[self window]
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
		/* Poll server for latest. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		[sharedCloudManager() synchronizeFromCloud];
	}
#endif
}

- (void)onChangedCloudSyncingServicesServersOnly:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud] && [TPCPreferences syncPreferencesToTheCloudLimitedToServers] == NO) {
		/* Poll server for latest. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		[sharedCloudManager() synchronizeFromCloud];
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
	
	[popup sheetWindowWithQuestion:[self window]
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

	[popup sheetWindowWithQuestion:[self window]
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
		
		[ps startWithWindow:[self window]];
		
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
				_tcopyStyleFilesProgressIndicator = ps;
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
				
				[prompt sheetWindowWithQuestion:[self window]
										 target:[TLOPopupPrompts class]
										 action:@selector(popupPromptNilSelector:withOriginalAlert:)
										   body:TXTLS(@"BasicLanguage[1102][2]")
										  title:TXTLS(@"BasicLanguage[1102][1]")
								  defaultButton:BLS(1186)
								alternateButton:nil
									otherButton:nil
								 suppressionKey:nil
								suppressionText:nil];
			}
			
			return;
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
	if ( _tcopyStyleFilesProgressIndicator) {
		[_tcopyStyleFilesProgressIndicator stop];
		 _tcopyStyleFilesProgressIndicator = nil;
		
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
	[[self window] setAlphaValue:0.0];

	NSRect windowFrame = [self currentWindowFrame];

	windowFrame.size.height = _forcedPreferencePaneViewFrameHeight;

	[[self window] setFrame:windowFrame display:NO animate:NO];

	[[self window] saveWindowStateForClass:[self class]];

	/* Clean up highlight keywords. */
	[TPCPreferences cleanUpHighlightKeywords];

	if ([[self delegate] respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[[self delegate] preferencesDialogWillClose:self];
	}
}

@end
