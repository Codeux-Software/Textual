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

@interface TXMasterController : NSObject <NSSplitViewDelegate, NSApplicationDelegate, NSWindowDelegate>
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, assign) BOOL ghostMode;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, assign) BOOL debugModeOn;
@property (nonatomic, assign) BOOL skipTerminateSave;
@property (nonatomic, assign) BOOL mainWindowIsActive;
@property (nonatomic, assign) BOOL applicationIsActive;
@property (nonatomic, assign) BOOL applicationIsChangingActiveState;
@property (nonatomic, assign) BOOL applicationIsRunningInHighResMode;

#ifdef TEXTUAL_BUILT_WITH_APP_NAP_DISABLED
@property (nonatomic, strong) id appNapProgressInformation;
#endif

@property (nonatomic, assign) NSInteger memberSplitViewOldPosition;
@property (nonatomic, assign) NSInteger serverListSplitViewOldPosition;
@property (nonatomic, nweak) IBOutlet NSBox *channelViewBox;
@property (nonatomic, nweak) IBOutlet NSMenu *addServerMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *channelViewMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *dockMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *joinChannelMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *segmentedControllerMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *tcopyURLMenu;
@property (nonatomic, nweak) IBOutlet NSMenu *userControlMenu;
@property (nonatomic, nweak) IBOutlet NSMenuItem *channelMenuItem;
@property (nonatomic, nweak) IBOutlet NSMenuItem *closeWindowMenuItem;
@property (nonatomic, nweak) IBOutlet NSMenuItem *serverMenuItem;
@property (nonatomic, nweak) IBOutlet TVCMainWindowLoadingScreenView *mainWindowLoadingScreen;
@property (nonatomic, nweak) IBOutlet TVCMainWindowSegmentedCell *mainWindowButtonControllerCell;
@property (nonatomic, nweak) IBOutlet TVCMainWindowSegmentedControl *mainWindowButtonController;
@property (nonatomic, nweak) IBOutlet TVCMemberList *memberList;
@property (nonatomic, nweak) IBOutlet TVCMemberListUserInfoPopover *memberListUserInfoPopover;
@property (nonatomic, nweak) IBOutlet TVCServerList *serverList;
@property (nonatomic, nweak) IBOutlet TVCTextFormatterMenu *formattingMenu;
@property (nonatomic, nweak) IBOutlet TVCThinSplitView *memberSplitView;
@property (nonatomic, nweak) IBOutlet TVCThinSplitView *serverSplitView;
@property (nonatomic, nweak) TXMenuController *menuController;
@property (nonatomic, strong) TLOGrowlController *growlController;
@property (nonatomic, strong) TLONickCompletionStatus *completionStatus;
@property (nonatomic, strong) TLOSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) TPCThemeController *themeControllerPntr;
@property (nonatomic, uweak) IBOutlet TVCInputTextField *inputTextField;
@property (nonatomic, uweak) IBOutlet TVCMainWindow *mainWindow;

/* self.inputHistory may return the inputHistory controller of the selected view
 instead of _globalInputHistory if Textual is configured to use channel specific
 input history. In that case, _globalInputHistory does not exist. */
@property (nonatomic, strong) TLOInputHistory *globalInputHistory;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, strong) TPCPreferencesCloudSync *cloudSyncManager;
#endif

@property (assign) NSInteger terminatingClientCount;

- (void)showMemberListSplitView:(BOOL)showList;
- (void)showServerListSplitView:(BOOL)showList;

- (IBAction)openWelcomeSheet:(id)sender;

- (void)textEntered;

- (void)updateSegmentedController;
- (void)reloadSegmentedControllerOrigin;

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
@end

@interface NSObject (TXMasterControllerObjectExtension)
- (TXMasterController *)masterController;
+ (TXMasterController *)masterController;

- (IRCWorld *)worldController;
+ (IRCWorld *)worldController;

- (TPCThemeController *)themeController;
+ (TPCThemeController *)themeController;

- (TXMenuController *)menuController;
+ (TXMenuController *)menuController;
@end
