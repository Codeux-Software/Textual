/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, strong) NSDictionary *serverList;
@property (nonatomic, strong) NSMutableArray *tabViewList;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSView *generalView;
@property (nonatomic, strong) NSView *identityView;
@property (nonatomic, strong) NSView *messagesView;
@property (nonatomic, strong) NSView *encodingView;
@property (nonatomic, strong) NSView *autojoinView;
@property (nonatomic, strong) NSView *ignoresView;
@property (nonatomic, strong) NSView *commandsView;
@property (nonatomic, strong) NSView *floodControlView;
@property (nonatomic, strong) NSView *floodControlToolView;
@property (nonatomic, strong) NSView *proxyServerView;
@property (nonatomic, strong) NSButton *outgoingFloodControl;
@property (nonatomic, strong) NSSlider *floodControlMessageCount;
@property (nonatomic, strong) NSSlider *floodControlDelayTimer;
@property (nonatomic, strong) TVCListView *tabView;
@property (nonatomic, strong) NSTextField *nameText;
@property (nonatomic, strong) NSButton *prefersIPv6Check;
@property (nonatomic, strong) NSButton *autoReconnectCheck;
@property (nonatomic, strong) NSButton *autoConnectCheck;
@property (nonatomic, strong) NSComboBox *hostCombo;
@property (nonatomic, strong) NSButton *sslCheck;
@property (nonatomic, strong) NSTextField *portText;
@property (nonatomic, strong) NSTextField *nickText;
@property (nonatomic, strong) NSTextField *passwordText;
@property (nonatomic, strong) NSTextField *usernameText;
@property (nonatomic, strong) NSTextField *realNameText;
@property (nonatomic, strong) NSTextField *nickPasswordText;
@property (nonatomic, strong) NSTextField *altNicksText;
@property (nonatomic, strong) NSTextView *sleepQuitMessageText;
@property (nonatomic, strong) NSTextView *leavingCommentText;
@property (nonatomic, strong) NSPopUpButton *encodingCombo;
@property (nonatomic, strong) NSPopUpButton *fallbackEncodingCombo;
@property (nonatomic, strong) NSPopUpButton *proxyCombo;
@property (nonatomic, strong) NSTextField *proxyHostText;
@property (nonatomic, strong) NSTextField *proxyPortText;
@property (nonatomic, strong) NSTextField *proxyUserText;
@property (nonatomic, strong) NSTextField *proxyPasswordText;
@property (nonatomic, strong) TVCListView *channelTable;
@property (nonatomic, strong) NSButton *addChannelButton;
@property (nonatomic, strong) NSButton *editChannelButton;
@property (nonatomic, strong) NSButton *deleteChannelButton;
@property (nonatomic, strong) NSTextView *loginCommandsText;
@property (nonatomic, strong) NSButton *invisibleCheck;
@property (nonatomic, strong) TVCListView *ignoreTable;
@property (nonatomic, strong) NSButton *addIgnoreButton;
@property (nonatomic, strong) NSButton *editIgnoreButton;
@property (nonatomic, strong) NSButton *deleteIgnoreButton;
@property (nonatomic, strong) NSMenu *addIgnoreMenu;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;

- (void)startWithIgnoreTab:(NSString *)imask;

- (void)show;
- (void)showWithDefaultView:(NSView *)view andSegment:(NSInteger)segment;

- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)hostComboChanged:(id)sender;
- (void)encodingChanged:(id)sender;
- (void)proxyChanged:(id)sender;
- (void)floodControlChanged:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;
- (void)showAddIgnoreMenu:(id)sender;
@end

@interface NSObject (TXServerSheetDelegate)
- (void)serverSheetOnOK:(TDCServerSheet *)sender;
- (void)serverSheetWillClose:(TDCServerSheet *)sender;
@end
