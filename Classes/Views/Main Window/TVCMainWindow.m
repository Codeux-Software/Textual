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

#define _treeDragItemType		@"tree"
#define _treeDragItemTypes		[NSArray arrayWithObject:_treeDragItemType]

@interface TVCMainWindow ()
@property (nonatomic, assign) NSTimeInterval lastKeyWindowStateChange;
@property (nonatomic, assign) BOOL lastKeyWindowRedrawFailedBecauseOfOcclusion;
@end

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
		
		[self.contentSplitView restorePositions];
		
		[self registerKeyHandlers];
		
		[self.formattingMenu enableWindowField:self.inputTextField];
		
		[worldController() setupConfiguration];
		[worldController() setupOtherServices];
		
		[self.memberList setKeyDelegate:self];
		[self.serverList setKeyDelegate:self];
		
		[self updateBackgroundColor];
		
		[self setupTree];
		
		[self.memberList setTarget:menuController()];
		[self.memberList setDoubleAction:@selector(memberInMemberListDoubleClicked:)];

		[masterController() performAwakeningAfterMainWindowDidLoad];
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

- (void)updateBackgroundColor
{
#ifdef TXSystemIsMacOSYosemiteOrNewer
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		self.usingVibrantDarkAppearance = [TPCPreferences invertSidebarColors];
		
		if ([TPCPreferences invertSidebarColors]) {
			[self.channelViewBox setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		} else {
			[self.channelViewBox setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
		}

		[self.contentSplitView setNeedsDisplay:YES];
	}
#else
	self.usingVibrantDarkAppearance = NO;
#endif
	
	[self.memberList updateBackgroundColor];
	[self.serverList updateBackgroundColor];
	
	[self.inputTextField updateBackgroundColor];

	[self.contentView setNeedsDisplay:YES];
}

- (void)loadWindowState
{
	[self restoreWindowStateUsingKeyword:@"Main Window"];
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setBool:[self isInFullscreenMode] forKey:@"fullscreen"];
	
	[self saveWindowStateUsingKeyword:@"Main Window"];
	
	[RZUserDefaults() setObject:dic forKey:@"Window -> Main Window Window State"];
}

- (void)prepareForApplicationTermination
{
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
	TVCMainWindowNegateActionWithAttachedSheet();
	
	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];
	
	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNickname:YES];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self navigateChannelEntries:YES withNavigationType:TVCServerListNavigationMovementUnreadType];
	}
}

- (void)shiftTab:(NSEvent *)e
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
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
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([TPCPreferences commandReturnSendsMessageAsAction]) {
		[self sendText:IRCPrivateCommandIndex("action")];
	} else {
		[self textEntered];
	}
}

- (void)moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
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
		[self.inputTextField resetTextFieldCellSize:NO];
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
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([self.formattingMenu boldSet]) {
		[self.formattingMenu removeBoldCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertBoldCharIntoTextBox:nil];
	}
}

- (void)textFormattingItalic:(NSEvent *)e
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([self.formattingMenu italicSet]) {
		[self.formattingMenu removeItalicCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertItalicCharIntoTextBox:nil];
	}
}

- (void)textFormattingUnderline:(NSEvent *)e
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([self.formattingMenu underlineSet]) {
		[self.formattingMenu removeUnderlineCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertUnderlineCharIntoTextBox:nil];
	}
}

- (void)textFormattingForegroundColor:(NSEvent *)e
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([self.formattingMenu foregroundColorSet]) {
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
	TVCMainWindowNegateActionWithAttachedSheet();
	
	if ([self.formattingMenu foregroundColorSet]) {
		if ([self.formattingMenu backgroundColorSet]) {
			[self.formattingMenu removeForegroundColorCharFromTextBox:nil];
		} else {
			NSRect fieldRect = [self.inputTextField frame];
			
			fieldRect.origin.y -= 200;
			fieldRect.origin.x += 100;
			
			[[self.formattingMenu backgroundColorMenu] popUpMenuPositioningItem:nil atLocation:fieldRect.origin inView:self.inputTextField];
		}
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
	TVCMainWindowNegateActionWithAttachedSheet();

	[self makeFirstResponder:[[self selectedViewController] webView]];
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
	
	[self.inputTextField setAttributedStringValue:[NSAttributedString emptyString]];
	
	if ([as length] > 0) {
		[[TXSharedApplication sharedInputHistoryManager] add:as];
		
		[self inputText:as command:command];
	}
	
	[[TXSharedApplication sharedNicknameCompletionStatus] clear:YES];
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
		x = (x * -(1));
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
		x = (x * -(1));
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
#pragma mark Split View

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

- (void)reloadLoadingScreen
{
	if ([worldController() isPopulatingSeeds] == NO) {
		if ([worldController() clientCount] <= 0) {
			[self.loadingScreen hideAll:NO];
			[self.loadingScreen popWelcomeAddServerView];
		} else {
			[self.loadingScreen hideAll:YES];
		}
	}
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

- (void)addAccessoryViewsToTitlebar
{
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		NSTitlebarAccessoryViewController *accessoryView = [self titlebarAccessoryViewController];

		[accessoryView setLayoutAttribute:NSLayoutAttributeRight];

		[self addTitlebarAccessoryViewController:accessoryView];
	} else {
		NSView *themeFrame = [[self contentView] superview];

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
	if (u) {
		[self.titlebarAccessoryView setHidden:([u connectionIsSecured] == NO)];
	} else {
		[self.titlebarAccessoryView setHidden:YES];
	}

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
			[title appendString:[c name]];
			[title appendString:BLS(1007, [c numberOfMembers])];
			
			/* If we are aware of the channel modes, then we append that. */
			NSString *modes = [[c modeInfo] titleString];
			
			if ([modes length] > 1) {
				[title appendString:BLS(1006, modes)];
			}
		}
	}
	
	/* Set final title. */
	[self setTitle:title];
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
	
	/* Draw default icon as soon as we setup… */
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
	NSInteger selectedRow = [self.serverList selectedRow];
	NSInteger selectionRow = [self.serverList rowForItem:self.selectedItem];
	
	if (0 <= selectedRow && NSDissimilarObjects(selectedRow, selectionRow)) {
		[self.serverList selectItemAtIndex:selectionRow];
	}
}

- (void)storePreviousSelection
{
	if (self.temporarilyDisablePreviousSelectionUpdates == NO) {
		self.previousSelectedClientId = self.selectedClient.treeUUID;
		self.previousSelectedChannelId = self.selectedChannel.treeUUID;
	}
}

- (void)storeLastSelectedChannel
{
	if (self.temporarilyDisablePreviousSelectionUpdates == NO) {
		if (self.selectedClient) {
			self.selectedClient.lastSelectedChannel = self.selectedChannel;
		}
	}
}

- (IRCTreeItem *)previouslySelectedItem
{
	NSObjectIsEmptyAssertReturn(self.previousSelectedClientId, nil);
	
	NSString *uid = self.previousSelectedClientId;
	NSString *cid = self.previousSelectedChannelId;
	
	IRCTreeItem *item = nil;
	
	if (NSObjectIsEmpty(cid)) {
		item = [worldController() findClientById:uid];
	} else {
		item = [worldController() findChannelByClientId:uid channelId:cid];
	}
	
	return item;
}

- (void)selectPreviousItem
{
	IRCTreeItem *item = [self previouslySelectedItem];
	
	if (item) {
		[self select:item];
	}
}

- (void)select:(id)item
{
	/* There is nothing to do if we are already selected. */
	if (self.selectedItem == item) {
		return;
	}
	
	/* We do support selecting nothing. */
	if (item == nil) {
		[self storePreviousSelection]; // -outlineViewSelectionDidChange: would normally do this

		 self.selectedItem = nil;
		
		[self.channelViewBox setContentView:nil];
		
		[self.memberList setDataSource:nil];
		[self.memberList reloadData];
		
		return;
	}
	
	/* Begin selection process. */
	BOOL isClient = [item isClient];
	
	IRCClient *u = [item associatedClient];
	
	/* If we are selecting a channel, then we expand the 
	 client list if it was not already expanded. */
	if (isClient == NO) {
		[[self.serverList animator] expandItem:u];
	}

	/* We now move the actual selection. */
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
	/* If the item being collapsed is the one our selected channel is on,
	 then move selection to the console of the collapsed server. */
	id itemBeingCollapsed = [notification userInfo][@"NSObject"];
	
	if ([itemBeingCollapsed isClient]) {
		if (itemBeingCollapsed == self.selectedClient) {
			[self select:self.selectedClient];
		}
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	/* Do nothing under special circumstances. */
	if (self.temporarilyIgnoreOutlineViewSelectionChanges) {
		return;
	}
	
	/* Store previous selection. */
	[self storePreviousSelection];
	
	/* Reset spelling for text field. */
	if ([self.inputTextField hasModifiedSpellingDictionary]) {
		[RZSpellChecker() setIgnoredWords:@[] inSpellDocumentWithTag:[self.inputTextField spellCheckerDocumentTag]];
	}
	
	/* Prepare next item. */
	NSUInteger selectedRow = [self.serverList selectedRow];

	id nextItem = [self.serverList itemAtRow:selectedRow];
	
	[self.selectedItem resetState]; // Reset state of old item.
	 self.selectedItem = nextItem;
	
	[self.selectedItem resetState]; // Reset state of new item.
	
	/* Destroy any floating popup. */
	[self.memberList destroyUserInfoPopoverOnWindowKeyChange];
	
	/* Destroy member list if we have no selection. */
	if (self.selectedItem == nil) {
		[self.channelViewBox setContentView:nil];
		
		 self.memberList.delegate = nil;
		 self.memberList.dataSource = nil;
		
		[self.memberList reloadData];
		
		self.serverList.menu = [menuController() addServerMenu];
		
		[self updateTitle];
		
		return; // Nothing more to do for empty selections.
	}
	
	/* Setup WebKit. */
	TVCLogController *log = self.selectedViewController;
	
	/* Set content view to WebView. */
	[self.channelViewBox setContentView:[log webView]];

	/* Prepare the member list for the selection. */
	BOOL isClient = ([self.selectedItem isClient]);
	BOOL isQuery = ([self.selectedItem isPrivateMessage]);
	
	/* The right click menu follows selection so let's update
	 the menu we will show depending on the selection. */
	if (isClient) {
		self.serverList.menu = [[menuController() serverMenuItem] submenu];
	} else {
		self.serverList.menu = [[menuController() channelMenuItem] submenu];
	}
	
	/* Update table view data sources. */
	if (isClient || isQuery) {
		/* Private messages and the client console
		 do not have a member list. */
		 self.memberList.delegate = nil;
		 self.memberList.dataSource = nil;
		
		[self.memberList reloadData];
	} else {
		 self.memberList.delegate = (id)self.selectedItem;
		 self.memberList.dataSource = (id)self.selectedItem;
		
		[self.memberList deselectAll:nil];
		[self.memberList scrollRowToVisible:0];
		
		[(id)self.selectedItem reloadDataForTableView];
	}
	
	/* Begin work on text field. */
	[self.inputTextField focus];
	[self.inputTextField updateSegmentedController];
	
	/* Setup text field value with history item when we have
	 history setup to be channel specific. */
	[[TXSharedApplication sharedInputHistoryManager] moveFocusTo:self.selectedItem];
	
	/* Update splitter view depending on selection. */
	if (isClient || isQuery) {
		[self.contentSplitView collapseMemberList];
	} else {
		if (self.memberList.isHiddenByUser == NO) {
			[self.contentSplitView expandMemberList];
		}
	}

	/* Update client specific data. */
	[self storeLastSelectedChannel];

	/* Allow selected WebView time to update. */
	[log notifyDidBecomeVisible];
	
	/* Dimiss notification center. */
	[sharedGrowlController() dismissNotificationsInNotificationCenterForClient:self.selectedClient channel:self.selectedChannel];
	
	/* Finish up. */
	[menuController() mainWindowSelectionDidChange];
	
	[TVCDockIcon updateDockIcon];
	
	[self updateTitle];
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	NSObjectIsEmptyAssertReturn(items, NO);
	
	IRCTreeItem *i = items[0];
	
	NSString *s = [worldController() pasteboardStringForItem:i];
	
	[pboard declareTypes:_treeDragItemTypes owner:self];
	
	[pboard setPropertyList:s forType:_treeDragItemType];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	/* Validate dragging index. */
	if (index < 0) {
		return NSDragOperationNone;
	}
	
	/* Validate pasteboard types. */
	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ([pboard availableTypeFromArray:_treeDragItemTypes] == nil) {
		return NSDragOperationNone;
	}
	
	/* Validate pasteboard contents. */
	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
	
	if (infoStr == nil) {
		return NSDragOperationNone;
	}
	
	/* Validate selection. */
	IRCTreeItem *i = [worldController() findItemFromPasteboardString:infoStr];
	
	if (i == nil) {
		return NSDragOperationNone;
	}
	
	if ([i isClient]) {
		if (item) {
			return NSDragOperationNone;
		}
	} else {
		/* Validate input. */
		if (item == nil) {
			return NSDragOperationNone;
		}
		
		IRCChannel *c = (IRCChannel *)i;
		
		/* Do not allow dragging between clients. */
		if (NSDissimilarObjects(item, [c associatedClient])) {
			return NSDragOperationNone;
		}
		
		IRCClient *toClient = (IRCClient *)item;
		
		NSArray *ary = [toClient channelList];
		
		/* Get list of items below and above insertion point. */
		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];
		
		/* Remove item from copies. */
		[low removeObjectIdenticalTo:c];
		[high removeObjectIdenticalTo:c];
		
		/* Validate drop positions based on simple logic. */
		if ([c isChannel]) {
			if ([low count] > 0) {
				IRCChannel *prev = [low lastObject];
				
				if ([prev isChannel] == NO) {
					return NSDragOperationNone;
				}
			}
		} else {
			if ([high count] > 0) {
				IRCChannel *next = high[0];
				
				if ([next isChannel]) {
					return NSDragOperationNone;
				}
			}
		}
	}
	
	return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
	/* Validate dragging index. */
	if (index < 0) {
		return NSDragOperationNone;
	}
	
	/* Validate pasteboard types. */
	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ([pboard availableTypeFromArray:_treeDragItemTypes] == nil) {
		return NSDragOperationNone;
	}
	
	/* Validate pasteboard contents. */
	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
	
	if (infoStr == nil) {
		return NSDragOperationNone;
	}
	
	/* Validate selection. */
	IRCTreeItem *i = [worldController() findItemFromPasteboardString:infoStr];
	
	if (i == nil) {
		return NSDragOperationNone;
	}
	
	if ([i isClient]) {
		if (item) {
			return NO;
		}
		
		/* Get client list as we are rearranging servers. */
		NSArray *ary = [worldController() clientList];
		
		/* Split array up. */
		NSMutableArray *mutary = [ary mutableCopy];
		
		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];
		
		/* Log important info. */
		NSInteger originalIndex = [ary indexOfObject:i];
		
		/* Remove any mentions of object. */
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		/* Clear the butter. */
		[mutary removeAllObjects];
		
		/* Build new array. */
		[mutary addObjectsFromArray:low];
		[mutary addObject:i];
		[mutary addObjectsFromArray:high];
		
		[worldController() setClientList:mutary];

		/* Move the item. */
		[self.serverList moveItemAtIndex:originalIndex inParent:nil toIndex: index inParent:nil];
	}
	else
	{
		/* Perform some basic validation. */
		if (item == nil || NSDissimilarObjects(item, [i associatedClient])) {
			return NO;
		}
		
		/* We are client. */
		IRCClient *u = (IRCClient *)item;
		
		/* Some comment that is supposed to tell you whats happening. */
		NSArray *ary = [u channelList];
		
		NSMutableArray *mutary = [ary mutableCopy];
		
		/* Another comment talking about stuff nobody cares about. */
		NSMutableArray *low = [ary mutableSubarrayWithRange:NSMakeRange(0, index)];
		NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(index, ([ary count] - index))];
		
		/* :) */
		NSInteger originalIndex = [ary indexOfObject:i];
		
		/* Something, something… */
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		/* Clinteger if you are reading this, then I hope France
		 flops hard in the World Cup. Go Germany? */
		[mutary removeAllObjects];
		
		[mutary addObjectsFromArray:low];
		[mutary addObject:i];
		[mutary addObjectsFromArray:high];
		
		[u setChannelList:mutary];
		
		/* And I just want this refacotring to be over with. */
		if (originalIndex < index) {
			[self.serverList moveItemAtIndex:originalIndex inParent:u toIndex:(index - 1) inParent:u];
		} else {
			[self.serverList moveItemAtIndex:originalIndex inParent:u toIndex: index inParent:u];
		}
	}
	
	/* Update selection. */
	NSInteger n = [self.serverList rowForItem:self.selectedItem];
	
	if (n > -1) {
		[self.serverList selectItemAtIndex:n];
	}
	
	/* Order changed so should our keyboard shortcuts. */
	[menuController() populateNavgiationChannelList];
	
	/* Conclude drag operation. */
	return YES;
}

- (void)memberListViewKeyDown:(NSEvent *)e
{
	[worldController() logKeyDown:e];
}

- (void)serverListKeyDown:(NSEvent *)e
{
	[worldController() logKeyDown:e];
}

@end
