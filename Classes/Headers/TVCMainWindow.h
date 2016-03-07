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

#define TVCMainWindowDefaultFrameWidth		800
#define TVCMainWindowDefaultFrameHeight		474

typedef NS_ENUM(NSUInteger, TVCServerListNavigationMovementType) {
	TVCServerListNavigationMovementAllType,     // Move to next item.
	TVCServerListNavigationMovementActiveType,  // Move to next active item.
	TVCServerListNavigationMovementUnreadType,  // Move to next unread item.
};

typedef NS_ENUM(NSUInteger, TVCServerListNavigationSelectionType) {
	TVCServerListNavigationSelectionAnyType,		// Move to next item.
	TVCServerListNavigationSelectionChannelType,	// Move to next channel item.
	TVCServerListNavigationSelectionServerType,		// Move to next server item.
};

#import "TVCMemberList.h" // @protocol
#import "TVCServerList.h" // @protocol

@interface TVCMainWindow : NSWindow <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, TVCServerListDelegate, TVCMemberListDelegate>
@property (nonatomic, strong) TLOKeyEventHandler *keyEventHandler;
@property (nonatomic, copy) NSValue *cachedSwipeOriginPoint;
@property (nonatomic, weak) IBOutlet NSBox *channelViewBox;
@property (nonatomic, weak) IBOutlet TVCMainWindowTitlebarAccessoryViewLockButton *titlebarAccessoryViewLockButton;
@property (nonatomic, weak) IBOutlet TVCMainWindowTitlebarAccessoryViewController *titlebarAccessoryViewController;
@property (nonatomic, weak) IBOutlet TVCMainWindowTitlebarAccessoryView *titlebarAccessoryView;
@property (nonatomic, strong) IBOutlet TXMenuControllerMainWindowProxy *mainMenuProxy;
@property (nonatomic, strong) IBOutlet TVCTextViewIRCFormattingMenu *formattingMenu;
@property (nonatomic, unsafe_unretained) IBOutlet TVCMainWindowTextView *inputTextField;
@property (nonatomic, weak) IBOutlet TVCMainWindowSplitView *contentSplitView;
@property (nonatomic, weak) IBOutlet TVCMainWindowLoadingScreenView *loadingScreen;
@property (nonatomic, weak) IBOutlet TVCMemberList *memberList;
@property (nonatomic, weak) IBOutlet TVCServerList *serverList;
@property (nonatomic, strong) IRCTreeItem *selectedItem; // Please don't directy modify this without calling -adjustSelection
@property (nonatomic, copy) NSString *previousSelectedClientId; // There are no reasons to modify this.
@property (nonatomic, copy) NSString *previousSelectedChannelId; // There are no reasons to modify this.
@property (nonatomic, assign) BOOL temporarilyDisablePreviousSelectionUpdates;
@property (nonatomic, assign) BOOL temporarilyIgnoreOutlineViewSelectionChanges;

@property (readonly) IRCClient *selectedClient;
@property (readonly) IRCChannel *selectedChannel;
@property (readonly) TVCLogController *selectedViewController;
@property (readonly) IRCTreeItem *previouslySelectedItem;

- (void)prepareForApplicationTermination;

- (void)setupTree;

- (BOOL)reloadLoadingScreen;

- (void)updateTitle;
- (void)updateTitleFor:(id)item;

- (void)reloadTree;
- (void)reloadTreeItem:(id)item; // Can be either IRCClient or IRCChannel
- (void)reloadTreeGroup:(id)item; // Will do not unless item is a IRCClient

- (void)adjustSelection;

- (void)select:(id)item;
- (void)selectPreviousItem;

- (void)expandClient:(IRCClient *)client;

- (IRCChannel *)selectedChannelOn:(IRCClient *)c;

- (void)maybeToggleFullscreenAfterLaunch;

- (void)updateAlphaValueToReflectPreferences;

@property (getter=isOccluded, readonly) BOOL occluded;
@property (getter=isInactive, readonly) BOOL inactive;
@property (getter=isActiveForDrawing, readonly) BOOL activeForDrawing;

@property (getter=isUsingVibrantDarkAppearance) BOOL usingVibrantDarkAppearance; // On Mavericks and earlier, this is always NO.

- (void)navigateChannelEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType;
- (void)navigateServerEntries:(BOOL)isMovingDown withNavigationType:(TVCServerListNavigationMovementType)navigationType;
- (void)navigateToNextEntry:(BOOL)isMovingDown;

- (void)updateBackgroundColor;

- (void)textEntered;

- (void)inputText:(id)str command:(NSString *)command; // Do not call this directly unless you must.

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

- (void)redirectKeyDown:(NSEvent *)e;

@property (getter=isMemberListVisible, readonly) BOOL memberListVisible;
@property (getter=isServerListVisible, readonly) BOOL serverListVisible;

- (NSRect)defaultWindowFrame;

- (void)setKeyHandlerTarget:(id)target;

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
@end
