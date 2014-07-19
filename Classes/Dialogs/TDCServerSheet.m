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

#define _tableRowType		@"row"
#define _tableRowTypes		[NSArray arrayWithObject:_tableRowType]

@interface TDCServerSheet ()
@property (nonatomic, copy) NSArray *navigationTreeMatrix;
@property (nonatomic, copy) NSDictionary *serverList;
@property (nonatomic, copy) NSDictionary *encodingList;
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
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateSHA1FingerprintCopyButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateMD5FingerprintCopyButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateResetButton;
@property (nonatomic, nweak) IBOutlet NSButton *validateServerSSLCertificateCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnoreConfiguredAutojoinCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnorePlaybackNotificationsCheck;
@property (nonatomic, nweak) IBOutlet TVCTextFieldComboBoxWithValueValidation *serverAddressCombo;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *primaryEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *proxyTypeButton;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlMessageCountSlider;
@property (nonatomic, nweak) IBOutlet NSTextField *alternateNicknamesField;
@property (nonatomic, nweak) IBOutlet NSTextField *nicknamePasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyUsernameField;
@property (nonatomic, nweak) IBOutlet NSTextField *serverPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateCommonNameField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateMD5FingerprintField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateSHA1FingerprintField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *awayNicknameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *nicknameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *normalLeavingCommentField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *proxyPortField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *proxyAddressField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *realnameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *serverNameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *serverPortField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *sleepModeQuitMessageField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *usernameField;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *channelTable;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *highlightsTable;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *ignoreTable;
@property (nonatomic, nweak) IBOutlet TVCAnimatedContentNavigationOutlineView *navigationOutlineview;
@property (nonatomic, nweak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *addressBookContentView;
@property (nonatomic, strong) IBOutlet NSView *autojoinContentView;
@property (nonatomic, strong) IBOutlet NSView *connectCommandsContentView;
@property (nonatomic, strong) IBOutlet NSView *contentEncodingContentView;
@property (nonatomic, strong) IBOutlet NSView *disconnectMessagesContentView;
@property (nonatomic, strong) IBOutlet NSView *floodControlContentView;
@property (nonatomic, strong) IBOutlet NSView *floodControlContentViewToolView;
@property (nonatomic, strong) IBOutlet NSView *generalContentView;
@property (nonatomic, strong) IBOutlet NSView *highlightsContentView;
@property (nonatomic, strong) IBOutlet NSView *identityContentView;
@property (nonatomic, strong) IBOutlet NSView *networkSocketContentView;
@property (nonatomic, strong) IBOutlet NSView *proxyServerContentView;
@property (nonatomic, strong) IBOutlet NSView *sslCertificateContentView;
@property (nonatomic, strong) IBOutlet NSView *zncBouncerContentView;
@property (nonatomic, uweak) IBOutlet NSTextView *connectCommandsField;
@property (nonatomic, strong) NSMutableArray *mutableChannelList;
@property (nonatomic, strong) NSMutableArray *mutableHighlightList;
@property (nonatomic, strong) NSMutableArray *mutableIgnoreList;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;
@property (nonatomic, strong) TDCHighlightEntrySheet *highlightSheet;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, assign) BOOL requestCloudDeletionOnClose;
#endif
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TDCServerSheet
@end
#pragma clang diagnostic pop
