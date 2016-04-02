/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
#import "TLOLicenseManager.h"
#endif

#import "TVCMainWindowPrivate.h"

#define _treeDragItemType		@"tree"
#define _treeDragItemTypes		[NSArray arrayWithObject:_treeDragItemType]

@implementation TVCMainWindow

#pragma mark -
#pragma mark Awakening

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if ((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])) {
		self.keyEventHandler = [TLOKeyEventHandler new];
	}
	
	return self;
}

- (void)awakeFromNib
{
	/* -awakeFromNib is called multiple times because of reloads. */
	static BOOL _awakeFromNibCalled = NO;
	
	if (_awakeFromNibCalled == NO) {
		_awakeFromNibCalled = YES;
		
		[masterController() performAwakeningBeforeMainWindowDidLoad];

		[self setDelegate:self];
		
		[self setAllowsConcurrentViewDrawing:NO];
		
		[self setAlphaValue:[TPCPreferences themeTransparency]];
		
		[self.loadingScreen hideAll:NO];
		[self.loadingScreen popLoadingConfigurationView];
		
		[self makeMainWindow];
		[self makeKeyAndOrderFront:nil];
		
		[self loadWindowState];

		[self addAccessoryViewsToTitlebar];
		
		[themeController() load];
		
		[menuController() setupOtherServices];
		
		[self.inputTextField redrawOriginPoints:YES];
		[self.inputTextField updateTextDirection];
		
		[self.inputTextField setBackgroundColor:[NSColor clearColor]];
		
		[self registerKeyHandlers];

		[worldController() setupConfiguration];
		[worldController() setupOtherServices];
		
		[self.memberList setKeyDelegate:self];
		[self.serverList setKeyDelegate:self];
		
		[self updateBackgroundColor];
		
		[self setupTree];
		
		[self.memberList setTarget:menuController()];
		[self.memberList setDoubleAction:@selector(memberInMemberListDoubleClicked:)];

		[masterController() performAwakeningAfterMainWindowDidLoad];

		[self observeNotifications];
	}
}

- (void)dealloc
{
	[self.memberList setKeyDelegate:nil];

	[self.serverList setDelegate:nil];
	[self.serverList setDataSource:nil];
	
	[self.serverList setKeyDelegate:nil];
}

- (void)observeNotifications
{
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(accessibilityDisplayOptionsDidChange:) name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification object:nil];
	}
}

- (void)maybeToggleFullscreenAfterLaunch
{
	NSDictionary *dic = [RZUserDefaults() dictionaryForKey:@"Window -> Main Window Window State"];
	
	if ([dic boolForKey:@"fullscreen"]) {
		[self performSelector:@selector(toggleFullscreenAfterLaunch) withObject:nil afterDelay:1.0];
	}
}

- (void)toggleFullscreenAfterLaunch
{
	if ([self isInFullscreenMode] == NO) {
		[self toggleFullScreen:nil];
	}
}

- (void)accessibilityDisplayOptionsDidChange:(NSNotification *)aNote
{
	[self updateBackgroundColor];
}

- (void)updateBackgroundColor
{
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		self.usingVibrantDarkAppearance = [TPCPreferences invertSidebarColors];
		
		if ([TPCPreferences invertSidebarColors]) {
			[self.channelView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		} else {
			[self.channelView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
		}

		[self.contentSplitView setNeedsDisplay:YES];
	}
	
	[self.memberList updateBackgroundColor];
	[self.serverList updateBackgroundColor];
	
	[self.inputTextField updateBackgroundColor];

	[self.contentView setNeedsDisplay:YES];
}

- (void)updateAlphaValueToReflectPreferences
{
	[self updateAlphaValueToReflectPreferencesAnimiated:NO];
}

- (void)updateAlphaValueToReflectPreferencesAnimiated:(BOOL)animate
{
	if ([self isInFullscreenMode] == NO) {
		double alphaValue = [TPCPreferences themeTransparency];

		if (animate) {
			[[self animator] setAlphaValue:alphaValue];
		} else {
			[self setAlphaValue:alphaValue];
		}
	}
}

- (void)loadWindowState
{
	[self restoreWindowStateUsingKeyword:@"Main Window"];

	[self restoreSavedContentSplitViewState];
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setBool:[self isInFullscreenMode] forKey:@"fullscreen"];
	
	[self saveWindowStateUsingKeyword:@"Main Window"];
	
	[RZUserDefaults() setObject:dic forKey:@"Window -> Main Window Window State"];

	[self saveContentSplitViewState];
}

- (void)prepareForApplicationTermination
{
	[RZNotificationCenter() removeObserver:self];

	[self saveWindowState];

	[self setDelegate:nil];
	
	[self close];
}

#pragma mark -
#pragma mark Item Update

- (void)reloadMainWindowFrameOnScreenChange
{
	NSAssertReturn([masterController() applicationIsTerminating] == NO);
	
	[TVCDockIcon resetCachedCount];
	[TVCDockIcon updateDockIcon];
	
	[self updateBackgroundColor];
}

- (void)resetSelectedItemState
{
	NSAssertReturn([masterController() applicationIsTerminating] == NO);
	
	id sel = [self selectedItem];
	
	if (sel) {
		[sel resetState];
	}
	
	[TVCDockIcon updateDockIcon];
}

- (void)reloadSubviewDrawings
{
	[self.inputTextField windowDidChangeKeyState];
	
	[self.serverList windowDidChangeKeyState];
	
	[self.memberList windowDidChangeKeyState];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidChangeScreen:(NSNotification *)notification
{
	[self reloadMainWindowFrameOnScreenChange];
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification
{
	if ([self isOccluded] == NO) {
		if (self.lastKeyWindowRedrawFailedBecauseOfOcclusion) {
			[self reloadSubviewDrawings];
			
			self.lastKeyWindowRedrawFailedBecauseOfOcclusion = NO;
		} else {
			/* We keep track of the last subview redraw so that we do
			 not draw too often. Current maximum is 1.0 second. */
			NSTimeInterval timeDifference = ([NSDate unixTime] - [self lastKeyWindowStateChange]);
			
			if (timeDifference > 1.0f) {
				[self reloadSubviewDrawings];
			}
		}
	}
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	self.lastKeyWindowStateChange = [NSDate unixTime];
	
	[self resetSelectedItemState];

	if ([self isOccluded]) {
		self.lastKeyWindowRedrawFailedBecauseOfOcclusion = YES;
	} else {
		[self reloadSubviewDrawings];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	self.lastKeyWindowStateChange = [NSDate unixTime];

	[self reloadSubviewDrawings];

	[self.memberList destroyUserInfoPopoverOnWindowKeyChange];
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu
{
	return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard
{
	return NO;
}

- (void)windowDidResize:(NSNotification *)notification
{
	[self.inputTextField resetTextFieldCellSize:YES];
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	return ([self isInFullscreenMode] == NO);
}

- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize
{
	return proposedSize;
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
	return (NSApplicationPresentationFullScreen | NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar);
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[self updateAlphaValueToReflectPreferencesAnimiated:YES];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
	[[self animator] setAlphaValue:1.0];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
	static BOOL formattingMenuSet;
	
	if (formattingMenuSet == NO) {
		NSMenu *editorMenu = [self.inputTextField menu];
		
		NSMenuItem *formatMenu = [self.formattingMenu formatterMenu];
		
		if (formatMenu) {
			NSInteger fmtrIndex = [editorMenu indexOfItemWithTitle:[formatMenu title]];
			
			if (fmtrIndex == -1) {
				[editorMenu addItem:[NSMenuItem separatorItem]];
				[editorMenu addItem:formatMenu];
			}
			
			[self.inputTextField setMenu:editorMenu];
		}
		
		formattingMenuSet = YES;
	}
	
	return self.inputTextField;
}

#pragma mark -
#pragma mark Keyboard Shortcuts

- (void)setKeyHandlerTarget:(id)target
{
	[self.keyEventHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[self.keyEventHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[self.keyEventHandler registerSelector:selector character:c modifiers:mods];
}

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == NSKeyDown) {
		if ([self.keyEventHandler processKeyEvent:e]) {
			return;
		}
	}

	[super sendEvent:e];
}

- (void)redirectKeyDown:(NSEvent *)e
{
	[mainWindowTextField() focus];

	if ([e keyCode] == TXKeyReturnCode ||
		[e keyCode] == TXKeyEnterCode)
	{
		return;
	}

	[mainWindowTextField() keyDown:e];
}

#pragma mark -
#pragma mark Nick Completion

- (void)completeNickname:(BOOL)forward
{
	[[TXSharedApplication sharedNicknameCompletionStatus] completeNickname:forward];
}

#pragma mark -
#pragma mark Navigation

- (void)navigateServerListEntries:(NSArray *)scannedRows
					   entryCount:(NSInteger)entryCount
					startingPoint:(NSInteger)startingPoint
					 isMovingDown:(BOOL)isMovingDown
				   navigationType:(TVCServerListNavigationMovementType)navigationType
					selectionType:(TVCServerListNavigationSelectionType)selectionType
{
	NSInteger currentPosition = startingPoint;
	
	while (1 == 1) {
		/* Move to next selection. */
		if (isMovingDown) {
			currentPosition += 1;
		} else {
			currentPosition -= 1;
		}
		
		/* Make sure selection is within our bounds. */
		if (currentPosition >= entryCount || currentPosition < 0) {
			if (isMovingDown == NO && currentPosition < 0) {
				currentPosition = (entryCount - 1);
			} else {
				currentPosition = 0;
			}
		}
		
		/* Once we scanned everything, break. */
		if (currentPosition == startingPoint) {
			break;
		}
		
		/* Get next selection depending on data source. */
		id i;
		
		if (scannedRows == nil) {
			i = [self.serverList itemAtRow:currentPosition];
		} else {
			i = scannedRows[currentPosition];
		}
		
		/* Skip entries depending on navigation type. */
		if (selectionType == TVCServerListNavigationSelectionChannelType)
		{
			if ([i isClient]) {
				continue;
			}
		}
		else if (selectionType == TVCServerListNavigationSelectionServerType)
		{
			if ([i isChannel]) {
				continue;
			}
		}
		
		/* Select current item if it is matched by our condition. */
		if (navigationType == TVCServerListNavigationMovementAllType)
		{
			[self select:i];
			
			break;
		}
		else if (navigationType == TVCServerListNavigationMovementActiveType)
		{
			if ([i isActive]) {
				[self select:i];
				
				break;
			}
		}
		else if (navigationType == TVCServerListNavigationMovementUnreadType)
		{
			if ([i isUnread]) {
				[self select:i];
				
				break;
			}
		}
	}
}

- (void)navigateChannelEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
	if ([TPCPreferences channelNavigationIsServerSpecific]) {
		[self navigateChannelEntriesWithinServerScope:isMovingDown withNavigationType:navigationType];
	} else {
		[self navigateChannelEntriesOutsideServerScope:isMovingDown withNavigationType:navigationType];
	}
}

- (void)navigateChannelEntriesOutsideServerScope:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
	NSInteger entryCount = [self.serverList numberOfRows];
	
	NSInteger startingPoint = [self.serverList rowForItem:self.selectedItem];
	
	[self navigateServerListEntries:nil
						 entryCount:entryCount
					  startingPoint:startingPoint
					   isMovingDown:isMovingDown
					 navigationType:navigationType
					  selectionType:TVCServerListNavigationSelectionChannelType];
}

- (void)navigateChannelEntriesWithinServerScope:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
	NSArray *scannedRows = [self.serverList rowsFromParentGroup:self.selectedClient];
	
	/* We add selected server so navigation falls within its scope if its the selected item. */
	scannedRows = [scannedRows arrayByAddingObject:self.selectedClient];
	
	[self navigateServerListEntries: scannedRows
						 entryCount:[scannedRows count]
					  startingPoint:[scannedRows indexOfObject:self.selectedItem]
					   isMovingDown:isMovingDown
					 navigationType:navigationType
					  selectionType:TVCServerListNavigationSelectionChannelType];
}

- (void)navigateServerEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
	NSArray *scannedRows = [self.serverList groupItems];
	
	[self navigateServerListEntries: scannedRows
						 entryCount:[scannedRows count]
					  startingPoint:[scannedRows indexOfObject:self.selectedClient]
					   isMovingDown:isMovingDown
					 navigationType:navigationType
					  selectionType:TVCServerListNavigationSelectionServerType];
}

- (void)navigateToNextEntry:(BOOL)isMovingDown
{
	NSInteger entryCount = [self.serverList numberOfRows];
	
	NSInteger startingPoint = [self.serverList rowForItem:self.selectedItem];
	
	[self navigateServerListEntries:nil
						 entryCount:entryCount
					  startingPoint:startingPoint
					   isMovingDown:isMovingDown
					 navigationType:TVCServerListNavigationMovementAllType
					  selectionType:TVCServerListNavigationSelectionAnyType];
}

- (void)selectPreviousChannel:(NSEvent *)e
{
	[self navigateChannelEntries:NO withNavigationType:TVCServerListNavigationMovementAllType];
}

- (void)selectNextChannel:(NSEvent *)e
{
	[self navigateChannelEntries:YES withNavigationType:TVCServerListNavigationMovementAllType];
}

- (void)selectPreviousUnreadChannel:(NSEvent *)e
{
	[self navigateChannelEntries:NO withNavigationType:TVCServerListNavigationMovementUnreadType];
}

- (void)selectNextUnreadChannel:(NSEvent *)e
{
	[self navigateChannelEntries:YES withNavigationType:TVCServerListNavigationMovementUnreadType];
}

- (void)selectPreviousActiveChannel:(NSEvent *)e
{
	[self navigateChannelEntries:NO withNavigationType:TVCServerListNavigationMovementActiveType];
}

- (void)selectNextActiveChannel:(NSEvent *)e
{
	[self navigateChannelEntries:YES withNavigationType:TVCServerListNavigationMovementActiveType];
}

- (void)selectPreviousServer:(NSEvent *)e
{
	[self navigateServerEntries:NO withNavigationType:TVCServerListNavigationMovementAllType];
}

- (void)selectNextServer:(NSEvent *)e
{
	[self navigateServerEntries:YES withNavigationType:TVCServerListNavigationMovementAllType];
}

- (void)selectPreviousActiveServer:(NSEvent *)e
{
	[self navigateServerEntries:NO withNavigationType:TVCServerListNavigationMovementActiveType];
}

- (void)selectNextActiveServer:(NSEvent *)e
{
	[self navigateServerEntries:YES withNavigationType:TVCServerListNavigationMovementActiveType];
}

- (void)selectPreviousSelection:(NSEvent *)e
{
	[self selectPreviousItem];
}

- (void)selectNextWindow:(NSEvent *)e
{
	[self navigateToNextEntry:YES];
}

- (void)selectPreviousWindow:(NSEvent *)e
{
	[self navigateToNextEntry:NO];
}

#pragma mark -
#pragma mark Actions

- (void)tab:(NSEvent *)e
{
	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];
	
	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNickname:YES];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self navigateChannelEntries:YES withNavigationType:TVCServerListNavigationMovementUnreadType];
	}
}

- (void)shiftTab:(NSEvent *)e
{
	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];
	
	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNickname:NO];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self navigateChannelEntries:NO withNavigationType:TVCServerListNavigationMovementUnreadType];
	}
}

- (void)sendControlEnterMessageMaybe:(NSEvent *)e
{
	if ([TPCPreferences controlEnterSnedsMessage]) {
		[self textEntered];
	} else {
		[self.inputTextField keyDownToSuper:e];
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	if ([TPCPreferences commandReturnSendsMessageAsAction]) {
		[self sendText:IRCPrivateCommandIndex("action")];
	} else {
		[self textEntered];
	}
}

- (void)moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
	if (scroll) {
		NSInteger nol = [self.inputTextField numberOfLines];
		
		if (nol >= 2) {
			BOOL atTop = [self.inputTextField isAtTopOfView];
			BOOL atBottom = [self.inputTextField isAtBottomOfView];
			
			if ((atTop			&& [event keyCode] == TXKeyDownArrowCode) ||
				(atBottom		&& [event keyCode] == TXKeyUpArrowCode) ||
				(atTop == NO	&& atBottom == NO))
			{
				[self.inputTextField keyDownToSuper:event];
				
				return;
			}
		}
	}
	
	NSAttributedString *s = [self.inputTextField attributedStringValue];
	
	if (up) {
		s = [[TXSharedApplication sharedInputHistoryManager] up:s];
	} else {
		s = [[TXSharedApplication sharedInputHistoryManager] down:s];
	}
	
	if (s) {
		[self.inputTextField setAttributedStringValue:s];
		[self.inputTextField focus];
	}
}

- (void)inputHistoryUp:(NSEvent *)e
{
	[self moveInputHistory:YES checkScroller:NO event:e];
}

- (void)inputHistoryDown:(NSEvent *)e
{
	[self moveInputHistory:NO checkScroller:NO event:e];
}

- (void)inputHistoryUpWithScrollCheck:(NSEvent *)e
{
	[self moveInputHistory:YES checkScroller:YES event:e];
}

- (void)inputHistoryDownWithScrollCheck:(NSEvent *)e
{
	[self moveInputHistory:NO checkScroller:YES event:e];
}

- (void)textFormattingBold:(NSEvent *)e
{
	if ([self.formattingMenu textIsBold]) {
		[self.formattingMenu removeBoldCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertBoldCharIntoTextBox:nil];
	}
}

- (void)textFormattingItalic:(NSEvent *)e
{
	if ([self.formattingMenu textIsItalicized]) {
		[self.formattingMenu removeItalicCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertItalicCharIntoTextBox:nil];
	}
}

- (void)textFormattingStrikethrough:(NSEvent *)e
{
	if ([self.formattingMenu textIsStruckthrough]) {
		[self.formattingMenu removeStrikethroughCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertStrikethroughCharIntoTextBox:nil];
	}
}

- (void)textFormattingUnderline:(NSEvent *)e
{
	if ([self.formattingMenu textIsUnderlined]) {
		[self.formattingMenu removeUnderlineCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertUnderlineCharIntoTextBox:nil];
	}
}

- (void)textFormattingForegroundColor:(NSEvent *)e
{
	if ([self.formattingMenu textHasForegroundColor]) {
		[self.formattingMenu removeForegroundColorCharFromTextBox:nil];
	} else {
		NSRect fieldRect = [self.inputTextField frame];
		
		fieldRect.origin.y -= 200;
		fieldRect.origin.x += 100;
		
		[[self.formattingMenu foregroundColorMenu] popUpMenuPositioningItem:nil atLocation:fieldRect.origin inView:self.inputTextField];
	}
}

- (void)textFormattingBackgroundColor:(NSEvent *)e
{
	if ([self.formattingMenu textHasForegroundColor] == NO) {
		return;
	}

	if ([self.formattingMenu textHasBackgroundColor]) {
		[self.formattingMenu removeForegroundColorCharFromTextBox:nil];
	} else {
		NSRect fieldRect = [self.inputTextField frame];
		
		fieldRect.origin.y -= 200;
		fieldRect.origin.x += 100;
		
		[[self.formattingMenu backgroundColorMenu] popUpMenuPositioningItem:nil atLocation:fieldRect.origin inView:self.inputTextField];
	}
}

- (void)exitFullscreenMode:(NSEvent *)e
{
	if ([self isInFullscreenMode]) {
		[self toggleFullScreen:nil];
	} else {
		[self.inputTextField keyDown:e];
	}
}

- (void)speakPendingNotifications:(NSEvent *)e
{
	[[TXSharedApplication sharedSpeechSynthesizer] stopSpeakingAndMoveForward];
}

- (void)focusWebview
{
	if ([self attachedSheet] == nil) {
		TVCLogController *logController = self.selectedViewController;

		NSView *webView = [[logController backingView] webView];

		[self makeFirstResponder:webView];
	}
}

- (void)handler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self registerKeyHandler:sel character:c modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self.inputTextField registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self.inputTextField registerKeyHandler:sel character:c modifiers:mods];
}

- (void)registerKeyHandlers
{
	[self setKeyHandlerTarget:self];
	
	[self.inputTextField setKeyHandlerTarget:self];
	
	/* Window keyboard shortcuts. */
	[self handler:@selector(exitFullscreenMode:)				code:TXKeyEscapeCode mods:0];
	
	[self handler:@selector(tab:)								code:TXKeyTabCode mods:0];
	[self handler:@selector(shiftTab:)							code:TXKeyTabCode mods:NSShiftKeyMask];
	
	[self handler:@selector(selectPreviousSelection:)			code:TXKeyTabCode mods:NSAlternateKeyMask];
	
	[self handler:@selector(textFormattingBold:)				char:'b' mods: NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:)			char:'u' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingItalic:)				char:'i' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingForegroundColor:)		char:'c' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:)		char:'h' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[self handler:@selector(speakPendingNotifications:)			char:'.' mods:NSCommandKeyMask];
	
	[self handler:@selector(inputHistoryUp:)					char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:)					char:'n' mods:NSControlKeyMask];
	
	/* Text field keyboard shortcuts. */
	[self inputHandler:@selector(sendControlEnterMessageMaybe:) code:TXKeyEnterCode mods:NSControlKeyMask];
	
	[self inputHandler:@selector(sendMsgAction:) code:TXKeyReturnCode mods:NSCommandKeyMask];
	[self inputHandler:@selector(sendMsgAction:) code:TXKeyEnterCode mods:NSCommandKeyMask];
	
	[self inputHandler:@selector(focusWebview) char:'l' mods:(NSAlternateKeyMask | NSCommandKeyMask)];
	
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:NSAlternateKeyMask];
	
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:NSAlternateKeyMask];
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString *)command
{
	NSAttributedString *as = [self.inputTextField attributedStringValue];
	
	[self.inputTextField setAttributedStringValue:[NSAttributedString attributedString]];
	
	if ([as length] > 0) {
		[[TXSharedApplication sharedInputHistoryManager] add:as];
		
		[self inputText:as command:command];
	}
	
	[[TXSharedApplication sharedNicknameCompletionStatus] clear];
}

- (void)inputText:(id)str command:(NSString *)command
{
	if (self.selectedItem) {
		str = [sharedPluginManager() processInterceptedUserInput:str command:command];
	
		[self.selectedClient inputText:str command:command];
	}
}

- (void)textEntered
{
	[self sendText:IRCPrivateCommandIndex("privmsg")];
}

#pragma mark -
#pragma mark Swipe Events

/* Three Finger Swipe Event
	This event will only work if 
		System Preferences -> Trackpad -> More Gestures -> Swipe between full-screen apps
	is not set to "Swipe left or right with three fingers"
 */
- (void)swipeWithEvent:(NSEvent *)event
{
    CGFloat x = [event deltaX];

	BOOL invertedScrollingDirection = [RZUserDefaults() boolForKey:@"com.apple.swipescrolldirection"];
	
	if (invertedScrollingDirection) {
		x = (x * (-1));
	}
	
    if (x > 0) {
        [self selectNextWindow:nil];
    } else if (x < 0) {
        [self selectPreviousWindow:nil];
    }
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
	CGFloat TVCSwipeMinimumLength = [TPCPreferences swipeMinimumLength];
	
	NSAssertReturn(TVCSwipeMinimumLength > 0);

	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
	
	NSAssertReturn([touches count] == 2);

	NSArray *touchArray = [touches allObjects];

	self.cachedSwipeOriginPoint = [self touchesToPoint:touchArray[0] fingerB:touchArray[1]];
}

- (NSValue *)touchesToPoint:(NSTouch *)fingerA fingerB:(NSTouch *)fingerB
{
	PointerIsEmptyAssertReturn(fingerA, nil);
	PointerIsEmptyAssertReturn(fingerB, nil);
	
	NSSize deviceSize = [fingerA deviceSize];
	
	CGFloat x = (([fingerA normalizedPosition].x + [fingerB normalizedPosition].x) / 2 * deviceSize.width);
	CGFloat y = (([fingerA normalizedPosition].y + [fingerB normalizedPosition].y) / 2 * deviceSize.height);
	
	return [NSValue valueWithPoint:NSMakePoint(x, y)];
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	CGFloat TVCSwipeMinimumLength = [TPCPreferences swipeMinimumLength];
	
	NSAssertReturn(TVCSwipeMinimumLength > 0);

	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil];

	if (self.cachedSwipeOriginPoint == nil || NSDissimilarObjects([touches count], 2)) {
		self.cachedSwipeOriginPoint = nil;

		return;
	}

	NSArray *touchArray = [touches allObjects];

	NSPoint origin = [self.cachedSwipeOriginPoint pointValue];
	
	NSPoint dest = [[self touchesToPoint:touchArray[0] fingerB:touchArray[1]] pointValue];

	self.cachedSwipeOriginPoint = nil;

    NSPoint delta = NSMakePoint((origin.x - dest.x),
								(origin.y - dest.y));

	if (fabs(delta.y) > fabs(delta.x)) {
		return;
	}
	
	if (fabs(delta.x) < TVCSwipeMinimumLength) {
		return;
	}
	
	CGFloat x = delta.x;
	
	BOOL invertedScrollingDirection = [RZUserDefaults() boolForKey:@"com.apple.swipescrolldirection"];
	
	if (invertedScrollingDirection) {
		x = (x * (-1));
	}

	if (x > 0) {
		[self selectPreviousWindow:nil];
	} else {
		[self selectNextWindow:nil];
	}
}

#pragma mark -
#pragma mark Misc.

- (void)endEditingFor:(id)object
{
	/* WebHTMLView results in this method being called.
	 *
	 * The documentation states "The endEditingFor: method should be used only as a
	 * last resort if the field editor refuses to resign first responder status."
	 *
	 * The documentation then goes to say how you should try setting makeFirstResponder first.
	 */

	if ([self makeFirstResponder:self] == NO) {
		[super endEditingFor:object];
	}
}

- (BOOL)isOccluded
{
	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		return (([self occlusionState] & NSWindowOcclusionStateVisible) == 0);
	} else {
		return NO;
	}
}

- (BOOL)isInactive
{
	return ([self isKeyWindow] == NO && [self isMainWindow] == NO);
}

- (BOOL)isActiveForDrawing
{
	if ([self isInFullscreenMode]) {
		return YES;
	} else {
		BOOL isActive = [masterController() applicationIsActive];
		
		BOOL isVisible = [self isVisible];
		BOOL isMainWindow = [self isMainWindow];
		BOOL isOnActiveSpace = [self isOnActiveSpace];
		
		BOOL hasNoModal = ([NSApp modalWindow] == nil);
		
		return (isVisible && isActive && isMainWindow && isOnActiveSpace && hasNoModal);
	}
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (NSRect)defaultWindowFrame
{
	NSRect windowFrame = [self frame];
	
	windowFrame.size.width = TVCMainWindowDefaultFrameWidth;
	windowFrame.size.height = TVCMainWindowDefaultFrameHeight;
	
	return windowFrame;
}

#pragma mark -
#pragma mark Channel View Box

- (BOOL)multipleItemsSelected
{
	return ([self.selectedItems count] > 1);
}

- (void)channelViewSelectionChangeTo:(IRCTreeItem *)selectedItem
{
	(void)[self selectItemInSelectedItems:selectedItem refreshChannelView:NO];
}

- (void)updateChannelViewBoxContentViewSelection
{
	[self.channelView populateSubviews];
}

- (BOOL)isItemSelected:(IRCTreeItem *)item
{
	return (self.selectedItems && [self.selectedItems containsObject:item]);
}

- (void)selectionDidChangeToRows:(NSIndexSet *)selectedRows
{
	[self selectionDidChangeToRows:selectedRows selectedItem:nil];
}

- (void)selectionDidChangeToRows:(NSIndexSet *)selectedRows selectedItem:(IRCTreeItem *)selectedItem
{
	/* Prepare next item */
	NSInteger selectedRowsCount = [selectedRows count];

	/* Create list of selected items and notify those newly selected items
	 that they are now visible + part of a stacked view */
	NSMutableArray *selectedItems = nil;

	if (selectedRowsCount > 0) {
		selectedItems = [NSMutableArray arrayWithCapacity:selectedRowsCount];

		for (NSNumber *row in [selectedRows arrayFromIndexSet]) {
			NSInteger rowInt = [row integerValue];

			IRCTreeItem *rowObject = [mainWindowServerList() itemAtRow:rowInt];

			[selectedItems addObject:rowObject];
		}
	}

	/* Check whether arrays match */
	if (NSObjectsAreEqual(selectedItems, self.selectedItems)) {
		/* Update selected item even if group hasn't changed */
		(void)[self selectItemInSelectedItems:selectedItem];

		/* Do nothing else if they match */
		return;
	}

	/* Store previous selection */
	[self storePreviousSelection];

	/* Update properties */
	NSArray *selectedItemsPrevious = nil;

	if (self.selectedItems) {
		selectedItemsPrevious = [self.selectedItems copy];
	}

	if (selectedItems) {
		self.selectedItems = selectedItems;

		if (selectedItem == nil) {
			selectedItem = self.selectedItem;
		}

		if ([self isItemSelected:selectedItem]) {
			self.selectedItem = selectedItem;
		} else {
			self.selectedItem = [selectedItems objectAtIndex:(selectedRowsCount - 1)];
		}
	} else {
		self.selectedItem = nil;
		self.selectedItems = nil;
	}

	/* Update split view */
	[self updateChannelViewBoxContentViewSelection];

	/* Inform views that are currently selected that no longer will be that they
	 are now hidden. We wait until after -updateChannelViewBoxContentViewSelection
	 is called to do this so that the views that are hidden are actually hidden
	 before informing the views of this fact. */
	if (selectedItemsPrevious) {
		for (IRCTreeItem *item in selectedItemsPrevious) {
			if (selectedItems == nil || [selectedItems containsObject:item] == NO) {
				[[item viewController] notifyDidBecomeHidden];
			}
		}
	}

	/* Inform new views that they are visible now that they are visible. */
	if (selectedItems) {
		for (IRCTreeItem *item in selectedItems) {
			if (selectedItemsPrevious == nil || [selectedItemsPrevious containsObject:item] == NO) {
				[[item viewController] notifyDidBecomeVisible];

				if (item != self.selectedItem) {
					[[item viewController] notifySelectionChanged];
				}
			}
		}
	}

	selectedItems = nil;
	selectedItemsPrevious = nil;

	/* Perform postflight routines */
	[self selectionDidChangePostflight];
}

- (void)selectionDidChangePostflight
{
	/* If the selection hasn't changed, then do nothing. */
	IRCTreeItem *itemChangedTo = self.selectedItem;

	IRCTreeItem *itemChangedFrom = self.previouslySelectedItem;

	if (itemChangedTo == itemChangedFrom) {
		return;
	}

	/* Reset state of selections */
	if ( itemChangedFrom) {
		[itemChangedFrom resetState];
	}

	if (itemChangedTo) {
		if ([self multipleItemsSelected]) {
			[self.serverList updateMessageCountForItem:itemChangedTo];
		}

		[itemChangedTo resetState];
	}

	/* Notify WebKit its selection status has changed. */
	if (  itemChangedFrom) {
		[[itemChangedFrom viewController] notifySelectionChanged];
	}

	/* Destroy any floating popup */
	[self.memberList destroyUserInfoPopoverOnWindowKeyChange];

	/* Destroy member list if we have no selection */
	if (itemChangedTo == nil) {
		self.memberList.delegate = nil;
		self.memberList.dataSource = nil;

		[self.memberList reloadData];

		self.serverList.menu = [menuController() addServerMenu];

		[self updateTitle];

		return; // Nothing more to do for empty selections.
	}

	/* Prepare the member list for the selection */
	BOOL isClient = ([itemChangedTo isClient]);

	BOOL isPrivateMessage = ([itemChangedTo isPrivateMessage]);

	/* The right click menu follows selection so let's update
	 the menu we will show depending on the selection. */
	if (isClient) {
		self.serverList.menu = [[menuController() serverMenuItem] submenu];
	} else {
		self.serverList.menu = [[menuController() channelMenuItem] submenu];
	}

	/* Update table view data sources */
	if (isClient || isPrivateMessage) {
		/* Private messages and the client console
		 do not have a member list. */
		self.memberList.delegate = nil;
		self.memberList.dataSource = nil;

		[self.memberList reloadData];
	} else {
		self.memberList.delegate = (id)itemChangedTo;
		self.memberList.dataSource = (id)itemChangedTo;

		[self.memberList deselectAll:nil];
		[self.memberList scrollRowToVisible:0];

		[(id)self.selectedItem reloadDataForTableView];
	}

	/* Begin work on text field */
	BOOL autoFocusInputTextField = [RZUserDefaults() boolForKey:@"Main Input Text Field -> Focus When Changing Views"];

	if (autoFocusInputTextField && [XRAccessibility isVoiceOverEnabled] == NO) {
		[self.inputTextField focus];
	}

	[self.inputTextField updateSegmentedController];

	/* Setup text field value with history item when we have
	 history setup to be channel specific. */
	[[TXSharedApplication sharedInputHistoryManager] moveFocusTo:itemChangedTo];

	/* Reset spelling for text field */
	if ([self.inputTextField hasModifiedSpellingDictionary]) {
		[RZSpellChecker() setIgnoredWords:@[] inSpellDocumentWithTag:[self.inputTextField spellCheckerDocumentTag]];
	}

	/* Update splitter view depending on selection */
	if (isClient || isPrivateMessage) {
		[self.contentSplitView collapseMemberList];
	} else {
		if (self.memberList.isHiddenByUser == NO) {
			[self.contentSplitView expandMemberList];
		}
	}

	/* Notify WebKit its selection status has changed. */
	[[itemChangedTo viewController] notifySelectionChanged];

	/* Update client specific data */
	[self storeLastSelectedChannel];

	/* Dimiss notification center */
	[sharedGrowlController() dismissNotificationsInNotificationCenterForClient:self.selectedClient channel:self.selectedChannel];

	/* Finish up */
	[menuController() mainWindowSelectionDidChange];

	[TVCDockIcon updateDockIcon];
	
	[self updateTitle];
}

#pragma mark -
#pragma mark Split View

- (void)saveContentSplitViewState
{
	[RZUserDefaults() setBool:[self isServerListVisible]
					   forKey:@"Window -> Main Window -> Server List is Visible"];

	[RZUserDefaults() setBool:([self.memberList isHiddenByUser] == NO)
					   forKey:@"Window -> Main Window -> Member List is Visible"];
}

- (void)restoreSavedContentSplitViewState
{
	/* Make server list and member list visible + restore saved position. */
	[self.contentSplitView restorePositions];

	/* Collapse one or more items if they were collapsed when closing Textual. */
	id makeServerListVisible = [RZUserDefaults() objectForKey:@"Window -> Main Window -> Server List is Visible"];

	id makeMemberListVisible = [RZUserDefaults() objectForKey:@"Window -> Main Window -> Member List is Visible"];

	if (makeServerListVisible && [makeServerListVisible boolValue] == NO) {
		[self.contentSplitView collapseServerList];
	}

	if (makeMemberListVisible && [makeMemberListVisible boolValue] == NO) {
		[self.memberList setIsHiddenByUser:YES];

		[self.contentSplitView collapseMemberList];
	}
}

- (BOOL)isMemberListVisible
{
	return ([self.contentSplitView isMemberListCollapsed] == NO);
}

- (BOOL)isServerListVisible
{
	return ([self.contentSplitView isServerListCollapsed] == NO);
}

#pragma mark -
#pragma mark Loading Screen

- (BOOL)reloadLoadingScreen
{
	/* This method returns YES (success) if the loading screen is dismissed
	 when called. NO indicates an error that resulted in it staying on screen. */

	if ([worldController() isPopulatingSeeds] == NO) {

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
		if (TLOLicenseManagerTextualIsRegistered() == NO && TLOLicenseManagerIsTrialExpired()) {
			[self.loadingScreen hideAll:NO];
			[self.loadingScreen popTrialExpiredView];
		} else
#endif

		if ([worldController() clientCount] <= 0) {
			[self.loadingScreen hideAll:NO];
			[self.loadingScreen popWelcomeAddServerView];
		} else {
			[self.loadingScreen hideAll:YES];

			return YES;
		}
	}

	return NO;
}

#pragma mark -
#pragma mark Window Extras

- (void)presentCertificateTrustInformation:(id)sender
{
	IRCClient *u = self.selectedClient;

	if ( u) {
		[u presentCertificateTrustInformation];
	}
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)titlebarAccessoryViewLockButtonClicked:(id)sender
{
	NSMenu *statusMenu = [menuController() encryptionManagerStatusMenu];

	[statusMenu popUpMenuPositioningItem:nil
							  atLocation:self.titlebarAccessoryViewLockButton.frame.origin
								  inView:self.titlebarAccessoryViewLockButton];
}
#endif

- (void)updateAccessoryViewLockButton
{
	IRCClient *u = self.selectedClient;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	IRCChannel *c = self.selectedChannel;

	BOOL updateEncryption = ([c isPrivateMessage] && [u encryptionAllowedForNickname:[c name]]);

	if (updateEncryption) {
		[self.titlebarAccessoryViewLockButton setAction:@selector(titlebarAccessoryViewLockButtonClicked:)];

		[self.titlebarAccessoryViewLockButton enableDrawingCustomBackgroundColor];
		[self.titlebarAccessoryViewLockButton positionImageOnLeftSide];

		[sharedEncryptionManager() updateLockIconButton:self.titlebarAccessoryViewLockButton
											withStateOf:[u encryptionAccountNameForUser:[c name]]
												   from:[u encryptionAccountNameForLocalUser]];

		[self.titlebarAccessoryView setHidden:NO];
	} else {
#endif

		[self.titlebarAccessoryViewLockButton setAction:@selector(presentCertificateTrustInformation:)];

		[self.titlebarAccessoryViewLockButton disableDrawingCustomBackgroundColor];
		[self.titlebarAccessoryViewLockButton positionImageOverContent];

		[self.titlebarAccessoryViewLockButton setTitle:NSStringEmptyPlaceholder];

		if ([u connectionIsSecured]) {
			[self.titlebarAccessoryView setHidden:NO];

			[self.titlebarAccessoryViewLockButton setIconAsLocked];
		} else {
			[self.titlebarAccessoryView setHidden:YES];
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	}
#endif

	if ([self.titlebarAccessoryView isHidden] == NO) {
		[self.titlebarAccessoryViewLockButton sizeToFit];
	}
}

- (void)addAccessoryViewsToTitlebar
{
	NSThemeFrame *themeFrame = [[self contentView] superview];

	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[themeFrame setUsesCustomTitlebarTitlePositioning:YES];

		NSTitlebarAccessoryViewController *accessoryView = [self titlebarAccessoryViewController];

		[accessoryView setLayoutAttribute:NSLayoutAttributeRight];

		[self addTitlebarAccessoryViewController:accessoryView];
	} else {
		NSView *accessoryView = [self titlebarAccessoryView];

		[themeFrame addSubview:accessoryView];

		NSLayoutConstraint *topConstraint =
		[NSLayoutConstraint constraintWithItem:accessoryView
									 attribute:NSLayoutAttributeTop
									 relatedBy:NSLayoutRelationEqual
										toItem:themeFrame
									 attribute:NSLayoutAttributeTop
									multiplier:1
									  constant:0];

		NSLayoutConstraint *rightConstraint =
		[NSLayoutConstraint constraintWithItem:accessoryView
									 attribute:NSLayoutAttributeTrailing
									 relatedBy:NSLayoutRelationEqual
										toItem:themeFrame
									 attribute:NSLayoutAttributeTrailing
									multiplier:1
									  constant:0];

		[themeFrame addConstraints:@[topConstraint, rightConstraint]];
	}
}

- (void)updateTitleFor:(IRCTreeItem *)item
{
	if (self.selectedItem == item) {
		[self updateTitle];
	}
}

- (void)updateTitle
{
	/* Establish base pair. */
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	/* Update accessory view. */
	[self updateAccessoryViewLockButton];

	/* Set default window title if there is none. */
	if (u == nil && c == nil) {
		[self setTitle:[TPCApplicationInfo applicationName]];
		
		return;
	}
	
	/* Begin building title. */
	NSMutableString *title = [NSMutableString string];
	
	if (u && c == nil) { // = Client
		/* Append basic info. */
		[title appendString:BLS(1008, [u localNickname], [u altNetworkName])];
		
		/* If we have the actual server that the client is connected
		 to, then we we append that. Otherwise, we just leave it blank. */
		NSString *networkAddress = [u networkAddress];
		
		if (NSObjectIsNotEmpty(networkAddress)) {
			[title appendString:BLS(1005)];
			[title appendString:networkAddress];
		}
	} else {
		/* Append basic info. */
		[title appendString:BLS(1008, [u localNickname], [u altNetworkName])];
		[title appendString:BLS(1005)];
		
		if ([c isPrivateMessage]) {
			/* Textual defines the topic of a private message as the user host. */
			/* If it is not defined yet, then we just use the channel name 
			 which is equal to the nickname of the private message owner. */
			NSString *hostmask = [c topic];
			
			if ([hostmask isHostmask] == NO) {
				[title appendString:[c name]];
			} else {
				[title appendString:hostmask];
			}
		}
		
		if ([c isChannel]) {
			/* We always want the channel name and user count. */
			NSString *userCount = TXFormattedNumber([c numberOfMembers]);

			[title appendString:[c name]];
			[title appendString:BLS(1007, userCount)];
			
			/* If we are aware of the channel modes, then we append that. */
			NSString *modes = [[c modeInfo] titleString];
			
			if ([modes length] > 1) {
				[title appendString:BLS(1006, modes)];
			}
		}
	}
	
	/* Set final title. */
	[self setTitle:title];

	[XRAccessibility setAccessibilityTitle:TXTLS(@"BasicLanguage[1281]") forObject:self];
}

#pragma mark -
#pragma mark Server List

- (void)setupTree
{
	/* Set double click action. */
	[self.serverList setDelegate:self];
	[self.serverList setDataSource:self];
	
	[self.serverList setTarget:self];
	[self.serverList setDoubleAction:@selector(outlineViewDoubleClicked:)];
	
	/* Inform the table we want drag events. */
	[self.serverList registerForDraggedTypes:_treeDragItemTypes];
	
	/* Prepare our first selection. */
	IRCClient *firstSelection = nil;
	
	for (IRCClient *e in [worldController() clientList]) {
		if (e.config.sidebarItemExpanded) {
			[self expandClient:e];
			
			if (e.config.autoConnect) {
				if (firstSelection == nil) {
					firstSelection = e;
				}
			}
		}
	}
	
	/* Find firt selection and select it. */
	if (firstSelection) {
		NSInteger n = [self.serverList rowForItem:firstSelection];
		
		if ([firstSelection channelCount] > 0) {
			++n;
		}
		
		[self.serverList selectItemAtIndex:n];
	} else {
		[self.serverList selectItemAtIndex:0];
	}
	
	/* Fake the delegate call. */
	[self outlineViewSelectionDidChange:nil];
	
	/* Draw default icon as soon as we setup... */
	/* This is done to apply birthday icon as soon as we start. */
	[TVCDockIcon drawWithoutCount];
	
	/* Populate navigation list. */
	[menuController() populateNavgiationChannelList];
}

- (IRCClient *)selectedClient
{
	if (	   self.selectedItem) {
		return self.selectedItem.associatedClient;
	} else {
		return nil;
	}
}

- (IRCChannel *)selectedChannel
{
	if (	 self.selectedItem) {
		if ([self.selectedItem isClient]) {
			return nil;
		} else {
			return (id)self.selectedItem;
		}
	} else {
		return nil;
	}
}

- (IRCChannel *)selectedChannelOn:(IRCClient *)c
{
	if (self.selectedClient == c) {
		return self.selectedChannel;
	} else {
		return nil;
	}
}

- (TVCLogController *)selectedViewController
{
	if (	   self.selectedChannel) {
		return self.selectedChannel.viewController;
	} else if (self.selectedClient) {
		return self.selectedClient.viewController;
	} else {
		return nil;
	}
}

- (void)reloadTreeItem:(id)item
{
	[self.serverList updateDrawingForItem:item];
}

- (void)reloadTreeGroup:(id)item
{
	if ([item isClient]) {
		[self reloadTreeItem:item];
		
		for (IRCChannel *channel in [item channelList]) {
			[self reloadTreeItem:channel];
		}
	}
}

- (void)reloadTree
{
	[self.serverList reloadAllDrawings];
}

- (void)expandClient:(IRCClient *)client
{
	[[self.serverList animator] expandItem:client];
}

- (void)adjustSelection
{
	[self adjustSelectionWithItems:self.selectedItems selectedItem:self.selectedItem];
}

- (void)adjustSelectionWithItems:(NSArray<IRCTreeItem *> *)selectedItems selectedItem:(IRCTreeItem *)selectedItem
{
	NSMutableIndexSet *itemRows = [NSMutableIndexSet indexSet];

	for (IRCTreeItem *item in selectedItems) {
		/* Expand the parent of the item if its not already expanded. */
		if ([item isClient] == NO) {
			IRCClient *itemClient = [item associatedClient];

			[self.serverList expandItem:itemClient];
		}

		/* Find the row of the item */
		NSInteger itemRow = [self.serverList rowForItem:item];

		if ( itemRow >= 0) {
			[itemRows addIndex:itemRow];
		}
	}

	/* If the selected rows have not changed, then only select the one item */
	NSIndexSet *selectedRows = [self.serverList selectedRowIndexes];

	if ([selectedRows isEqual:itemRows] == NO) {
		/* Selection updates are disabled and selection changes are faked so that
		 the correct next item is selected when moving to previous group. */
		self.ignoreNextOutlineViewSelectionChange = YES;

		[self.serverList selectRowIndexes:itemRows byExtendingSelection:NO];
	}

	/* Perform selection logic */
	[self selectionDidChangeToRows:itemRows selectedItem:selectedItem];
}

- (void)storePreviousSelection
{
	self.previousSelectedItemId = [self.selectedItem treeUUID];

	[self storePreviousSelections];
}

- (void)storePreviousSelections
{
	NSMutableArray *previousSelectedItems = nil;

	for (IRCTreeItem *item in self.selectedItems) {
		if (previousSelectedItems == nil) {
			previousSelectedItems = [NSMutableArray array];
		}

		[previousSelectedItems addObject:[item treeUUID]];
	}

	self.previousSelectedItemsId = previousSelectedItems;
}

- (void)storeLastSelectedChannel
{
	if ( self.selectedClient) {
		[self.selectedClient setLastSelectedChannel:self.selectedChannel];
	}
}

- (IRCTreeItem *)previouslySelectedItem
{
	NSString *itemIdentifier = self.previousSelectedItemId;

	if (itemIdentifier) {
		return [worldController() findItemByTreeId:itemIdentifier];
	}

	return nil;
}

- (void)selectPreviousItem
{
	/* Do not try to browse backwards without these items */
	if (self.previousSelectedItemId == nil ||
		self.previousSelectedItemsId == nil)
	{
		return;
	}

	/* Get previously selected item and canel if its missing */
	IRCTreeItem *itemPrevious = self.previouslySelectedItem;

	if (itemPrevious == nil) {
		return;
	}

	/* Build list of rows in the table view that contain previous group */
	NSMutableArray *itemsPrevious = [NSMutableArray array];

	for (NSString *itemIdentifier in self.previousSelectedItemsId) {
		IRCTreeItem *item = [worldController() findItemByTreeId:itemIdentifier];

		if ( item) {
			[itemsPrevious addObject:item];
		}
	}

	[self adjustSelectionWithItems:itemsPrevious selectedItem:itemPrevious];
}

- (BOOL)selectItemInSelectedItems:(IRCTreeItem *)selectedItem
{
	return [self selectItemInSelectedItems:selectedItem refreshChannelView:YES];
}

- (BOOL)selectItemInSelectedItems:(IRCTreeItem *)selectedItem refreshChannelView:(BOOL)refreshChannelView
{
	/* Do nothing if items are the same */
	if (self.selectedItem == selectedItem) {
		return NO;
	}

	/* Select item if its in the current group */
	if ([self isItemSelected:selectedItem]) {
		[self storePreviousSelection];

		self.selectedItem = selectedItem;

		if (refreshChannelView) {
			[self updateChannelViewBoxContentViewSelection];
		}

		[self selectionDidChangePostflight];

		return YES;
	}

	return NO;
}

- (void)select:(IRCTreeItem *)item
{
	/* Try to select the item in the current group first */
	if ([self selectItemInSelectedItems:item]) {
		return;
	}

	/* There is nothing to do if we are already selected */
	if (self.selectedItem == item) {
		return;
	}
	
	/* We do support selecting nothing */
	if (item == nil) {
		[self storePreviousSelection];

		self.selectedItem = nil;
		self.selectedItems = nil;

		[self selectionDidChangePostflight];
		
		return;
	}

	/* Perform some formal validation */
	if ([item isKindOfClass:[IRCTreeItem class]] == NO) {
		return;
	}

	/* Begin selection process */
	IRCClient *u = [item associatedClient];
	
	/* If we are selecting a channel, then we expand the 
	 client list if it was not already expanded. */
	if ([item isClient] == NO) {
		[[self.serverList animator] expandItem:u];
	}

	/* We now move the actual selection */
	NSInteger i = [self.serverList rowForItem:item];

	if (i >= 0) {
		[self.serverList selectItemAtIndex:i];
	}
}

#pragma mark -
#pragma mark Server List Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
	PointerIsEmptyAssert(self.selectedItem);
	
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;
	
	if (c == nil) {
		if (u.isConnecting) {
			if ([TPCPreferences disconnectOnDoubleclick]) {
				[u disconnect]; // Forcefully breaks connection.
				[u cancelReconnect];
			}
		} else if (u.isConnected || u.isLoggedIn) {
			if ([TPCPreferences disconnectOnDoubleclick]) {
				[u quit]; // Breaks connection with some grace.
			}
		} else if (u.isQuitting) {
			; // Don't do anything under this condition
		} else {
			if ([TPCPreferences connectOnDoubleclick]) {
				[u connect];
			}
		}
		
		[self expandClient:u];
	} else {
		if (u.isLoggedIn) {
			if (c.isActive) {
				if ([TPCPreferences leaveOnDoubleclick]) {
					[u partChannel:c];
				}
			} else {
				if ([TPCPreferences joinOnDoubleclick]) {
					[u joinChannel:c];
				}
			}
		}
	}
}

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(id)item
{
	if (item) {
		return [item numberOfChildren];
	} else {
		return [worldController() clientCount];
	}
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return ([item numberOfChildren] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IRCTreeItem *)item
{
	if (item) {
		return [item childAtIndex:index];
	} else {
		return [worldController() clientList][index];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item label];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(IRCTreeItem *)item
{
	id userInterfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	if (item == nil || [item isClient]) {
		return [userInterfaceObjects serverCellRowHeight];
	} else {
		return [userInterfaceObjects channelCellRowHeight];
	}
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	TVCServerListRowCell *rowView = [[TVCServerListRowCell alloc] initWithFrame:NSZeroRect];

	return rowView;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(IRCTreeItem *)item
{
	/* Ask our view controller what we are. */
	if ([item isClient]) {
		/* We are a group item. A client. */
		NSView *newView = [outlineView makeViewWithIdentifier:@"GroupView" owner:self];
		
		if ([newView isKindOfClass:[TVCServerListCellGroupItem class]]) {
			TVCServerListCellGroupItem *groupItem = (TVCServerListCellGroupItem *)newView;
			
			[groupItem setCellItem:item];
		}
		
		return newView;
	} else {
		/* We are a child item. A channel. */
		NSView *newView = [outlineView makeViewWithIdentifier:@"ChildView" owner:self];
		
		if ([newView isKindOfClass:[TVCServerListCellChildItem class]]) {
			TVCServerListCellChildItem *childItem = (TVCServerListCellChildItem *)newView;
			
			[childItem setCellItem:item];
		}
		
		return newView;
	}
	
	return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	[self.serverList updateDrawingForRow:row];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	id itemBeingCollapsed = [notification userInfo][@"NSObject"];
	
	IRCClient *u = [itemBeingCollapsed associatedClient];
	
	[[u config] setSidebarItemExpanded:NO];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id itemBeingCollapsed = [notification userInfo][@"NSObject"];
	
	IRCClient *u = [itemBeingCollapsed associatedClient];
	
	[[u config] setSidebarItemExpanded:YES];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(IRCTreeItem *)item
{
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(IRCTreeItem *)item
{
	return YES;
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
#define _maximumSelectedRows	6

	if ([proposedSelectionIndexes count] > _maximumSelectedRows) {
		/* If the user has already selected the maximum, then return the current index set.
		 This prevents the user clicking one item up and having the entire selection shift
		 because the following logic works from highest to lowest. */
		if ([outlineView numberOfSelectedRows] == _maximumSelectedRows) {
			return [outlineView selectedRowIndexes];
		}

		/* Pick first six rows to use as selection */
		NSMutableIndexSet *limitedSelectionIndexes = [NSMutableIndexSet indexSet];

		NSInteger indexCount = 0;

		NSUInteger currentIndex = [proposedSelectionIndexes firstIndex];

		while (indexCount < _maximumSelectedRows) {
			[limitedSelectionIndexes addIndex:currentIndex];

			currentIndex = [proposedSelectionIndexes indexGreaterThanIndex:currentIndex];

			indexCount += 1;
		}

		return limitedSelectionIndexes;
	}

	return proposedSelectionIndexes;

#undef _maximumSelectedRows
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	if (self.ignoreOutlineViewSelectionChanges) {
		return;
	}

	if (self.ignoreNextOutlineViewSelectionChange) {
		self.ignoreNextOutlineViewSelectionChange = NO;

		return;
	}

	NSIndexSet *selectedRows = [mainWindowServerList() selectedRowIndexes];

	IRCTreeItem *selectedItem = nil;

	NSUInteger keyboardKeys = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

	if (keyboardKeys == NSCommandKeyMask) {
		NSInteger clickedRow = [self.serverList rowUnderMouse];

		if (clickedRow >= 0 && [selectedRows containsIndex:clickedRow]) {
			selectedItem = [self.serverList itemAtRow:clickedRow];
		}
	}

	if (selectedItem) {
		[self selectionDidChangeToRows:selectedRows selectedItem:selectedItem];
	} else {
		[self selectionDidChangeToRows:selectedRows];
	}
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	NSObjectIsEmptyAssertReturn(items, NO);

	/* TODO (March 27, 2016): Support dragging multiple items */
	if ([items count] == 1) {
		IRCTreeItem *i = items[0];
		
		NSString *s = [worldController() pasteboardStringForItem:i];
		
		[pboard declareTypes:_treeDragItemTypes owner:self];
		
		[pboard setPropertyList:s forType:_treeDragItemType];
	}
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if (index < 0) {
		return NSDragOperationNone;
	}

	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ([pboard availableTypeFromArray:_treeDragItemTypes] == nil) {
		return NSDragOperationNone;
	}

	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
	
	if (infoStr == nil) {
		return NSDragOperationNone;
	}

	IRCTreeItem *i = [worldController() findItemFromPasteboardString:infoStr];
	
	if (i == nil) {
		return NSDragOperationNone;
	}
	
	if ([i isClient]) {
		if (item) {
			return NSDragOperationNone;
		}
	} else {
		if (item == nil) {
			return NSDragOperationNone;
		}
		
		IRCChannel *c = (IRCChannel *)i;

		if (NSDissimilarObjects(item, [c associatedClient])) {
			return NSDragOperationNone;
		}
		
		IRCClient *toClient = (IRCClient *)item;
		
		NSArray *ary = [toClient channelList];

		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];

		[low removeObjectIdenticalTo:c];
		[high removeObjectIdenticalTo:c];

		IRCChannel *nextItem = nil;
		IRCChannel *previousItem = nil;

		if ([low count] > 0) {
			previousItem = [low lastObject];
		}

		if ([high count] > 0) {
			nextItem = high[0];
		}

		if ([c isChannel]) {
			if (previousItem && [previousItem isChannel] == NO) {
				return NSDragOperationNone;
			}
		} else {
			if ([nextItem isChannel]) {
				return NSDragOperationNone;
			}
		}
	}

	return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
	if (index < 0) {
		return NSDragOperationNone;
	}

	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ([pboard availableTypeFromArray:_treeDragItemTypes] == nil) {
		return NSDragOperationNone;
	}

	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
	
	if (infoStr == nil) {
		return NSDragOperationNone;
	}

	IRCTreeItem *i = [worldController() findItemFromPasteboardString:infoStr];
	
	if (i == nil) {
		return NSDragOperationNone;
	}

	if ([i isClient]) {
		if (item) {
			return NO;
		}

		NSArray *ary = [worldController() clientList];

		NSMutableArray *mutary = [ary mutableCopy];
		
		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];

		NSInteger originalIndex = [ary indexOfObject:i];

		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];

		[mutary removeAllObjects];

		[mutary addObjectsFromArray:low];
		[mutary addObject:i];
		[mutary addObjectsFromArray:high];
		
		[worldController() setClientList:mutary];

		if (originalIndex < index) {
			[self.serverList moveItemAtIndex:originalIndex inParent:nil toIndex:(index - 1) inParent:nil];
		} else {
			[self.serverList moveItemAtIndex:originalIndex inParent:nil toIndex: index inParent:nil];
		}
	}
	else
	{
		if (item == nil || NSDissimilarObjects(item, [i associatedClient])) {
			return NO;
		}

		IRCClient *u = (IRCClient *)item;

		NSArray *ary = [u channelList];
		
		NSMutableArray *mutary = [ary mutableCopy];

		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];

		NSInteger originalIndex = [ary indexOfObject:i];

		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];

		[mutary removeAllObjects];
		
		[mutary addObjectsFromArray:low];
		[mutary addObject:i];
		[mutary addObjectsFromArray:high];
		
		[u setChannelList:mutary];

		if (originalIndex < index) {
			[self.serverList moveItemAtIndex:originalIndex inParent:u toIndex:(index - 1) inParent:u];
		} else {
			[self.serverList moveItemAtIndex:originalIndex inParent:u toIndex: index inParent:u];
		}
	}

	NSInteger n = [self.serverList rowForItem:self.selectedItem];
	
	if (n > -1) {
		[self.serverList selectItemAtIndex:n];
	}

	[menuController() populateNavgiationChannelList];

	return YES;
}

- (void)memberListViewKeyDown:(NSEvent *)e
{
	[self redirectKeyDown:e];
}

- (void)serverListKeyDown:(NSEvent *)e
{
	[self redirectKeyDown:e];
}

@end
