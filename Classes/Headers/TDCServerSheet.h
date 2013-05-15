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

@interface TDCServerSheet : TDCSheetBase
@property (nonatomic, strong) NSString *clientID;
@property (nonatomic, strong) NSArray *tabViewList;
@property (nonatomic, strong) NSDictionary *serverList;
@property (nonatomic, strong) NSDictionary *encodingList;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, nweak) NSButton *addChannelButton;
@property (nonatomic, nweak) NSButton *addIgnoreButton;
@property (nonatomic, nweak) NSButton *addHighlightButton;
@property (nonatomic, nweak) NSButton *autoConnectCheck;
@property (nonatomic, nweak) NSButton *autoDisconnectOnSleepCheck;
@property (nonatomic, nweak) NSButton *autoReconnectCheck;
@property (nonatomic, nweak) NSButton *connectionUsesSSLCheck;
@property (nonatomic, nweak) NSButton *deleteChannelButton;
@property (nonatomic, nweak) NSButton *deleteIgnoreButton;
@property (nonatomic, nweak) NSButton *deleteHighlightButton;
@property (nonatomic, nweak) NSButton *editChannelButton;
@property (nonatomic, nweak) NSButton *editIgnoreButton;
@property (nonatomic, nweak) NSButton *editHighlightButton;
@property (nonatomic, nweak) NSButton *floodControlCheck;
@property (nonatomic, nweak) NSButton *invisibleModeCheck;
@property (nonatomic, nweak) NSButton *prefersIPv6Check;
@property (nonatomic, nweak) NSButton *pongTimerCheck;
@property (nonatomic, nweak) NSComboBox *serverAddressCombo;
@property (nonatomic, nweak) NSMenu *addIgnoreMenu;
@property (nonatomic, nweak) NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, nweak) NSPopUpButton *primaryEncodingButton;
@property (nonatomic, nweak) NSPopUpButton *proxyTypeButton;
@property (nonatomic, nweak) NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, nweak) NSSlider *floodControlMessageCountSlider;
@property (nonatomic, nweak) NSTextField *alternateNicknamesField;
@property (nonatomic, nweak) NSTextField *nicknameField;
@property (nonatomic, nweak) NSTextField *awayNicknameField;
@property (nonatomic, nweak) NSTextField *nicknamePasswordField;
@property (nonatomic, nweak) NSTextField *proxyAddressField;
@property (nonatomic, nweak) NSTextField *proxyPortField;
@property (nonatomic, nweak) NSTextField *proxyPasswordField;
@property (nonatomic, nweak) NSTextField *proxyUsernameField;
@property (nonatomic, nweak) NSTextField *realnameField;
@property (nonatomic, nweak) NSTextField *serverNameField;
@property (nonatomic, nweak) NSTextField *serverPortField;
@property (nonatomic, nweak) NSTextField *serverPasswordField;
@property (nonatomic, nweak) NSTextField *usernameField;
@property (nonatomic, nweak) NSTextField *normalLeavingCommentField;
@property (nonatomic, nweak) NSTextField *sleepModeQuitMessageField;
@property (nonatomic, uweak) NSTextView *loginCommandsField;
@property (nonatomic, nweak) NSView *autojoinView;
@property (nonatomic, nweak) NSView *commandsView;
@property (nonatomic, nweak) NSView *contentView;
@property (nonatomic, nweak) NSView *encodingView;
@property (nonatomic, nweak) NSView *floodControlToolView;
@property (nonatomic, nweak) NSView *floodControlView;
@property (nonatomic, nweak) NSView *generalView;
@property (nonatomic, nweak) NSView *identityView;
@property (nonatomic, nweak) NSView *ignoresView;
@property (nonatomic, nweak) NSView *messagesView;
@property (nonatomic, nweak) NSView *proxyServerView;
@property (nonatomic, nweak) NSView *highlightsView;
@property (nonatomic, nweak) TVCListView *tabView;
@property (nonatomic, nweak) TVCListView *channelTable;
@property (nonatomic, nweak) TVCListView *ignoreTable;
@property (nonatomic, nweak) TVCListView *highlightsTable;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;
@property (nonatomic, strong) TDCHighlightEntrySheet *highlightSheet;

- (void)start:(NSString *)viewToken withContext:(NSString *)context;

- (void)close;

- (void)floodControlChanged:(id)sender;
- (void)proxyTypeChanged:(id)sender;
- (void)serverAddressChanged:(id)sender;
- (void)toggleAdvancedEncodings:(id)sender;
- (void)toggleAdvancedSettings:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

- (void)addHighlight:(id)sender;
- (void)editHighlight:(id)sender;
- (void)deleteHighlight:(id)sender;

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;

- (void)showAddIgnoreMenu:(id)sender;
@end

@interface NSObject (TDCServerSheetDelegate)
- (void)serverSheetOnOK:(TDCServerSheet *)sender;
- (void)serverSheetWillClose:(TDCServerSheet *)sender;
@end
