/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@interface TXMasterController : NSObject <NSSplitViewDelegate>
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, assign) BOOL ghostMode;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, assign) BOOL debugModeOn;
@property (nonatomic, assign) BOOL skipTerminateSave;
@property (nonatomic, assign) BOOL isInFullScreenMode;
@property (nonatomic, assign) BOOL mainWindowIsActive;
@property (nonatomic, nweak) NSBox *channelViewBox;
@property (nonatomic, nweak) NSMenu *addServerMenu;
@property (nonatomic, nweak) NSMenu *channelViewMenu;
@property (nonatomic, nweak) NSMenu *tcopyURLMenu;
@property (nonatomic, nweak) NSMenu *joinChannelMenu;
@property (nonatomic, nweak) NSMenu *userControlMenu;
@property (nonatomic, nweak) NSMenu *segmentedControllerMenu;
@property (nonatomic, nweak) NSMenuItem *channelMenuItem;
@property (nonatomic, nweak) NSMenuItem *serverMenuItem;
@property (nonatomic, nweak) NSMenuItem *closeWindowMenuItem;
@property (nonatomic, strong) THOPluginManager *pluginManager;
@property (nonatomic, strong) TLOGrowlController *growlController;
@property (nonatomic, strong) TLONickCompletionStatus *completionStatus;
@property (nonatomic, strong) TPCThemeController *themeController;
@property (nonatomic, strong) TLOInputHistory *inputHistory;
@property (nonatomic, nweak) TVCMemberList *memberList;
@property (nonatomic, nweak) TVCServerList *serverList;
@property (nonatomic, nweak) TVCThinSplitView *memberSplitView;
@property (nonatomic, nweak) TVCThinSplitView *serverSplitView;
@property (nonatomic, nweak) TXMenuController *menuController;
@property (nonatomic, uweak) TVCInputTextField *inputTextField;
@property (nonatomic, nweak) TVCTextFormatterMenu *formattingMenu;
@property (nonatomic, uweak) TVCMainWindow *mainWindow;
@property (nonatomic, nweak) TVCMainWindowLoadingScreenView *mainWindowLoadingScreen;
@property (nonatomic, nweak) TVCMainWindowSegmentedCell *mainWindowButtonControllerCell;
@property (nonatomic, nweak) TVCMainWindowSegmentedControl *mainWindowButtonController;
@property (nonatomic, nweak) TVCMemberListUserInfoPopover *memberListUserInfoPopover;
@property (nonatomic, strong) TLOSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, assign) NSInteger memberSplitViewOldPosition;

@property (assign) NSInteger terminatingClientCount;

- (void)loadWindowState:(BOOL)honorFullscreen;
- (void)saveWindowState;

- (void)showMemberListSplitView:(BOOL)showList;

- (void)openWelcomeSheet:(id)sender;

- (void)textEntered;

- (void)updateSegmentedController;
- (void)reloadSegmentedControllerOrigin;

- (void)selectNextServer:(NSEvent *)e;
- (void)selectNextChannel:(NSEvent *)e;
- (void)selectNextSelection:(NSEvent *)e;
- (void)selectPreviousServer:(NSEvent *)e;
- (void)selectPreviousChannel:(NSEvent *)e;
- (void)selectNextActiveServer:(NSEvent *)e;
- (void)selectNextUnreadChannel:(NSEvent *)e;
- (void)selectNextActiveChannel:(NSEvent *)e;
- (void)selectPreviousSelection:(NSEvent *)e;
- (void)selectPreviousActiveServer:(NSEvent *)e;
- (void)selectPreviousUnreadChannel:(NSEvent *)e;
- (void)selectPreviousActiveChannel:(NSEvent *)e;
- (void)selectPreviousWindow:(NSEvent *)e;
@end

@interface NSObject (TXMasterControllerObjectExtension)
- (TXMasterController *)masterController;
+ (TXMasterController *)masterController;

- (IRCWorld *)worldController;
+ (IRCWorld *)worldController;
@end
