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
@property (nonatomic, assign) BOOL ghostMode;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, assign) BOOL skipTerminateSave;
@property (nonatomic, strong) NSBox *logBase;
@property (nonatomic, strong) TXMenuController *menu;
@property (nonatomic, strong) TVCMainWindow *window;
@property (nonatomic, strong) TVCMainWindowLoadingScreenView *loadingScreen;
@property (nonatomic, strong) TVCMainWindowSegmentedControl *windowButtonController;
@property (nonatomic, strong) TVCMainWindowSegmentedCell *windowButtonControllerCell;
@property (nonatomic, strong) TVCInputTextField *text;
@property (nonatomic, strong) TVCServerList *serverList;
@property (nonatomic, strong) TVCMemberList *memberList;
@property (nonatomic, strong) TVCThinSplitView *serverSplitView;
@property (nonatomic, strong) TVCThinSplitView *memberSplitView;
@property (nonatomic, strong) TVCTextFormatterMenu *formattingMenu;
@property (nonatomic, strong) NSMenuItem *serverMenu;
@property (nonatomic, strong) NSMenuItem *channelMenu;
@property (nonatomic, strong) NSMenu *logMenu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *treeMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, strong) IRCExtras *extrac;
@property (nonatomic, strong) TPCViewTheme *viewTheme;
@property (nonatomic, strong) TDCWelcomeSheet *welcomeSheet;
@property (nonatomic, strong) TLOGrowlController *growl;
@property (nonatomic, strong) TLOInputHistory *inputHistory;
@property (nonatomic, strong) TLONickCompletionStatus *completionStatus;
@property (nonatomic, assign) NSInteger memberSplitViewOldPosition;

- (void)loadWindowState TEXTUAL_DEPRECATED;
- (void)loadWindowState:(BOOL)honorFullscreen;
- (void)saveWindowState;
- (void)showMemberListSplitView:(BOOL)showList;

- (void)updateSegmentedController;

- (void)openWelcomeSheet:(id)sender;

- (void)textEntered;

- (void)themeStyleDidChange;
- (void)transparencyDidChange;
- (void)inputHistorySchemeDidChange;
- (void)sidebarColorInversionDidChange;

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
@end