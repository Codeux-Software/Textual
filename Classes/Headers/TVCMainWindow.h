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

#define TVCMainWindowDefaultFrameWidth		800
#define TVCMainWindowDefaultFrameHeight		474

#define TVCMainWindowNegateActionWithAttachedSheet()		if ([mainWindow() attachedSheet]) { return; }
#define TVCMainWindowNegateActionWithAttachedSheetR(r)		if ([mainWindow() attachedSheet]) { return r; }

typedef enum TVCServerListNavigationMovementType : NSInteger {
	TVCServerListNavigationMovementAllType,     // Move to next item.
	TVCServerListNavigationMovementActiveType,  // Move to next active item.
	TVCServerListNavigationMovementUnreadType,  // Move to next unread item.
} TVCServerListNavigationMovementType;

typedef enum TVCServerListNavigationSelectionType : NSInteger {
	TVCServerListNavigationSelectionAnyType,		// Move to next item.
	TVCServerListNavigationSelectionChannelType,	// Move to next channel item.
	TVCServerListNavigationSelectionServerType,		// Move to next server item.
} TVCServerListNavigationSelectionType;

@interface TVCMainWindow : NSWindow <NSSplitViewDelegate, NSWindowDelegate>
@property (nonatomic, strong) TLOKeyEventHandler *keyEventHandler;
@property (nonatomic, strong) NSValue *cachedSwipeOriginPoint;
@property (nonatomic, nweak) IBOutlet NSBox *channelViewBox;
@property (nonatomic, nweak) IBOutlet TVCTextViewIRCFormattingMenu *formattingMenu;
@property (nonatomic, uweak) IBOutlet TVCMainWindowTextView *inputTextField;
@property (nonatomic, nweak) IBOutlet TVCMainWindowSplitView *contentSplitView;
@property (nonatomic, nweak) IBOutlet TVCMainWindowLoadingScreenView *loadingScreen;
@property (nonatomic, nweak) IBOutlet TVCMemberList *memberList;
@property (nonatomic, nweak) IBOutlet TVCServerList *serverList;

- (void)prepareForApplicationTermination;

- (void)maybeToggleFullscreenAfterLaunch;

- (BOOL)isInactive;

- (void)navigateChannelEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType;
- (void)navigateServerEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType;
- (void)navigateToNextEntry:(BOOL)isMovingDown;

- (void)textEntered;

- (void)selectNextServer:(NSEvent *)e;
- (void)selectNextChannel:(NSEvent *)e;
- (void)selectNextWindow:(NSEvent *)e;
- (void)selectPreviousServer:(NSEvent *)e;
- (void)selectPreviousChannel:(NSEvent *)e;
- (void)selectPreviousWindow:(NSEvent *)e;
- (void)selectNextActiveServer:(NSEvent *)e;
- (void)selectNextUnreadChannel:(NSEvent *)e;
- (void)selectNextActiveChannel:(NSEvent *)e;
- (void)selectPreviousSelection:(NSEvent *)e;
- (void)selectPreviousActiveServer:(NSEvent *)e;
- (void)selectPreviousUnreadChannel:(NSEvent *)e;
- (void)selectPreviousActiveChannel:(NSEvent *)e;

- (NSRect)defaultWindowFrame;

- (void)setKeyHandlerTarget:(id)target;

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
@end
