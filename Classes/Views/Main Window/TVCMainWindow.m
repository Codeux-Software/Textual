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

@implementation TVCMainWindow

#pragma mark -
#pragma mark Awakening

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if ((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])) {
		self.keyEventHandler = [TLOKeyEventHandler new];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[masterController() performAwakeningBeforeMainWindowDidLoad];

	[self setDelegate:self];
	
	[self setAllowsConcurrentViewDrawing:NO];
	
	[self setAlphaValue:[TPCPreferences themeTransparency]];
	
	[self.loadingScreen hideAll:NO];
	[self.loadingScreen popLoadingConfigurationView];
	
	[self makeMainWindow];
	[self makeKeyAndOrderFront:nil];
	
	[self loadWindowState];
	
	[themeController() load];
	
	[menuController() setupOtherServices];
	
	[self.inputTextField redrawOriginPoints:YES];
	[self.inputTextField updateTextDirection];
	
	[self.inputTextField setBackgroundColor:[NSColor clearColor]];
	
	[self registerKeyHandlers];
	
	[self.contentSplitView setDelegate:self];
	
	[self.formattingMenu enableWindowField:self.inputTextField];
	
	[worldController() setupConfiguration];
	
	[self.serverList setDelegate:worldController()];
	[self.serverList setDataSource:worldController()];
	[self.memberList setKeyDelegate:worldController()];
	
	[self.memberList setKeyDelegate:worldController()];
	
	[self.serverList reloadData];
	
	[worldController() setupTree];
	[worldController() setupOtherServices];
	
	[self.memberList setTarget:menuController()];
	[self.memberList setDoubleAction:@selector(memberInMemberListDoubleClicked:)];

	[masterController() performAwakeningAfterMainWindowDidLoad];
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
	[self setDelegate:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidChangeScreen:(NSNotification *)notification
{
	[masterController() windowDidChangeScreen:notification];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self windowDidBecomeKey:notification];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	[self windowDidResignKey:notification];
	
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
	[mainWindowTextField() resetTextFieldCellSize:YES];
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	return ([mainWindow() isInFullscreenMode] == NO);
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
		NSMenu *editorMenu = [mainWindowTextField() menu];
		
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

- (void)navigateChannelEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
#warning Need to implement.
}

- (void)navigateServerEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType
{
#warning Need to implement.
}

- (void)navigateToNextEntry:(BOOL)isMovingDown
{
#warning Need to implement.
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
	[worldController() selectPreviousItem];
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
	if ([self isInFullscreenMode] && [self.inputTextField isFocused] == NO) {
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
	
	TVCLogController *currentCtrl = [worldController() selectedViewController];
	
	[self makeFirstResponder:[currentCtrl webView]];
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
		[worldController() inputText:as command:command];
		
		[[TXSharedApplication sharedInputHistoryManager] add:as];
	}
	
	[[TXSharedApplication sharedNicknameCompletionStatus] clear:YES];
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

	if (delta.x > 0) {
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

- (BOOL)isInactive
{
	return ([self isKeyWindow] == NO && [self isMainWindow] == NO);
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

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	if (dividerIndex == 0) {
		return [self.contentSplitView isServerListCollapsed];
	} else {
		if (dividerIndex == 1) {
			return [self.contentSplitView isMemberListCollapsed];
		} else {
			return NO;
		}
	}
}

@end
