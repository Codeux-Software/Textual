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

@interface TDCServerSheet : TDCSheetBase
@property (nonatomic, strong) NSString *clientID;
@property (nonatomic, strong) NSArray *tabViewList;
@property (nonatomic, strong) NSDictionary *serverList;
@property (nonatomic, strong) NSDictionary *encodingList;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, nweak) IBOutlet NSButton *addChannelButton;
@property (nonatomic, nweak) IBOutlet NSButton *addHighlightButton;
@property (nonatomic, nweak) IBOutlet NSButton *addIgnoreButton;
@property (nonatomic, nweak) IBOutlet NSButton *autoConnectCheck;
@property (nonatomic, nweak) IBOutlet NSButton *autoDisconnectOnSleepCheck;
@property (nonatomic, nweak) IBOutlet NSButton *autoReconnectCheck;
@property (nonatomic, nweak) IBOutlet NSButton *connectionUsesSSLCheck;
@property (nonatomic, nweak) IBOutlet NSButton *deleteChannelButton;
@property (nonatomic, nweak) IBOutlet NSButton *deleteHighlightButton;
@property (nonatomic, nweak) IBOutlet NSButton *deleteIgnoreButton;
@property (nonatomic, nweak) IBOutlet NSButton *disconnectOnReachabilityChangeCheck;
@property (nonatomic, nweak) IBOutlet NSButton *editChannelButton;
@property (nonatomic, nweak) IBOutlet NSButton *editHighlightButton;
@property (nonatomic, nweak) IBOutlet NSButton *editIgnoreButton;
@property (nonatomic, nweak) IBOutlet NSButton *excludedFromCloudSyncingCheck;
@property (nonatomic, nweak) IBOutlet NSButton *floodControlCheck;
@property (nonatomic, nweak) IBOutlet NSButton *invisibleModeCheck;
@property (nonatomic, nweak) IBOutlet NSButton *pongTimerCheck;
@property (nonatomic, nweak) IBOutlet NSButton *pongTimerDisconnectCheck;
@property (nonatomic, nweak) IBOutlet NSButton *prefersIPv6Check;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateChangeCertButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateFingerprintCopyButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateResetButton;
@property (nonatomic, nweak) IBOutlet NSButton *validateServerSSLCertificateCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnoreConfiguredAutojoinCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnorePlaybackNotificationsCheck;
@property (nonatomic, nweak) IBOutlet NSComboBox *serverAddressCombo;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *primaryEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *proxyTypeButton;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlMessageCountSlider;
@property (nonatomic, nweak) IBOutlet NSTextField *alternateNicknamesField;
@property (nonatomic, nweak) IBOutlet NSTextField *awayNicknameField;
@property (nonatomic, nweak) IBOutlet NSTextField *nicknameField;
@property (nonatomic, nweak) IBOutlet NSTextField *nicknamePasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *normalLeavingCommentField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyAddressField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyPortField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyUsernameField;
@property (nonatomic, nweak) IBOutlet NSTextField *realnameField;
@property (nonatomic, nweak) IBOutlet NSTextField *serverNameField;
@property (nonatomic, nweak) IBOutlet NSTextField *serverPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *serverPortField;
@property (nonatomic, nweak) IBOutlet NSTextField *sleepModeQuitMessageField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateCommonNameField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateFingerprintField;
@property (nonatomic, nweak) IBOutlet NSTextField *usernameField;
@property (nonatomic, nweak) IBOutlet NSView *contentView;
@property (nonatomic, nweak) IBOutlet TVCListView *channelTable;
@property (nonatomic, nweak) IBOutlet TVCListView *highlightsTable;
@property (nonatomic, nweak) IBOutlet TVCListView *ignoreTable;
@property (nonatomic, nweak) IBOutlet TVCListView *tabView;
@property (nonatomic, strong) IBOutlet NSView *autojoinView;
@property (nonatomic, strong) IBOutlet NSView *commandsView;
@property (nonatomic, strong) IBOutlet NSView *encodingView;
@property (nonatomic, strong) IBOutlet NSView *floodControlToolView;
@property (nonatomic, strong) IBOutlet NSView *floodControlView;
@property (nonatomic, strong) IBOutlet NSView *generalView;
@property (nonatomic, strong) IBOutlet NSView *highlightsView;
@property (nonatomic, strong) IBOutlet NSView *identityView;
@property (nonatomic, strong) IBOutlet NSView *ignoresView;
@property (nonatomic, strong) IBOutlet NSView *messagesView;
@property (nonatomic, strong) IBOutlet NSView *networkingView;
@property (nonatomic, strong) IBOutlet NSView *proxyServerView;
@property (nonatomic, strong) IBOutlet NSView *sslCertificateView;
@property (nonatomic, strong) IBOutlet NSView *zncBouncerView;
@property (nonatomic, uweak) IBOutlet NSTextView *loginCommandsField;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;
@property (nonatomic, strong) TDCHighlightEntrySheet *highlightSheet;

- (void)start:(NSString *)viewToken withContext:(NSString *)context;

- (void)close;

- (IBAction)floodControlChanged:(id)sender;
- (IBAction)proxyTypeChanged:(id)sender;
- (IBAction)serverAddressChanged:(id)sender;
- (IBAction)toggleAdvancedEncodings:(id)sender;
- (IBAction)toggleAdvancedSettings:(id)sender;

- (IBAction)toggleCloudSyncExclusion:(id)sender;

- (IBAction)addChannel:(id)sender;
- (IBAction)editChannel:(id)sender;
- (IBAction)deleteChannel:(id)sender;

- (IBAction)addHighlight:(id)sender;
- (IBAction)editHighlight:(id)sender;
- (IBAction)deleteHighlight:(id)sender;

- (IBAction)addIgnore:(id)sender;
- (IBAction)editIgnore:(id)sender;
- (IBAction)deleteIgnore:(id)sender;

- (IBAction)showAddIgnoreMenu:(id)sender;

- (IBAction)useSSLCheckChanged:(id)sender;

- (IBAction)onSSLCertificateResetRequested:(id)sender;
- (IBAction)onSSLCertificateChangeRequested:(id)sender;
- (IBAction)onSSLCertificateFingerprintCopyRequested:(id)sender;
@end

@interface NSObject (TDCServerSheetDelegate)
- (void)serverSheetOnOK:(TDCServerSheet *)sender;
- (void)serverSheetWillClose:(TDCServerSheet *)sender;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)serverSheetRequestedCloudExclusionByDeletion:(TDCServerSheet *)sender;
#endif
@end
