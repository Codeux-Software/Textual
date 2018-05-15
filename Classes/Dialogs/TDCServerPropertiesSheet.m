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

#warning TODO: Fix server address auto completion only saving what is typed.

#import <SecurityInterface/SFChooseIdentityPanel.h>

#import "NSStringHelper.h"
#import "IRCClientConfig.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCHighlightMatchCondition.h"
#import "IRCNetworkList.h"
#import "IRCServer.h"
#import "TLOLanguagePreferences.h"
#import "TLOPopupPrompts.h"
#import "TPCPreferencesLocal.h"
#import "TPCPreferencesUserDefaults.h"
#import "TVCBasicTableView.h"
#import "TVCComboBoxWithValueValidation.h"
#import "TVCContentNavigationOutlineViewPrivate.h"
#import "TVCTextFieldWithValueValidation.h"
#import "TDCAddressBookSheetPrivate.h"
#import "TDCChannelPropertiesSheetPrivate.h"
#import "TDCHighlightEntrySheetPrivate.h"
#import "TDCServerEndpointListSheetPrivate.h"
#import "TDCServerPropertiesSheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _tableDragToken		@"TDCServerPropertiesSheetTableDragToken"

@interface TDCServerPropertiesSheet ()
@property (nonatomic, strong, readwrite, nullable) IRCClient *client;
@property (nonatomic, copy, readwrite, nullable) NSString *clientId;
@property (nonatomic, strong) IRCClientConfigMutable *config;
@property (nonatomic, copy) NSArray *navigationTreeMatrix;
@property (nonatomic, copy) NSDictionary *encodingList;
@property (nonatomic, strong) IRCNetworkList *networkList;
@property (nonatomic, strong) IBOutlet NSMenu *addAddressBookEntryMenu;
@property (nonatomic, strong) IBOutlet NSView *contentViewAddressBook;
@property (nonatomic, strong) IBOutlet NSView *contentViewAutojoin;
@property (nonatomic, strong) IBOutlet NSView *contentViewClientCertificate;
@property (nonatomic, strong) IBOutlet NSView *contentViewConnectCommands;
@property (nonatomic, strong) IBOutlet NSView *contentViewDisconnectMessages;
@property (nonatomic, strong) IBOutlet NSView *contentViewEncoding;
@property (nonatomic, strong) IBOutlet NSView *contentViewFloodControl;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneral;
@property (nonatomic, strong) IBOutlet NSView *contentViewHighlights;
@property (nonatomic, strong) IBOutlet NSView *contentViewIdentity;
@property (nonatomic, strong) IBOutlet NSView *contentViewNetworkSocket;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServer;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerInputView;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerSystemSocksView;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerTorBrowserView;
@property (nonatomic, strong) IBOutlet NSView *contentViewRedundancy;
@property (nonatomic, strong) IBOutlet NSView *contentViewZncBouncer;
@property (nonatomic, strong, nullable) TDCAddressBookSheet *addressBookSheet;
@property (nonatomic, strong, nullable) TDCHighlightEntrySheet *highlightSheet;
@property (nonatomic, strong, nullable) TDCChannelPropertiesSheet *channelSheet;
@property (nonatomic, strong, nullable) TDCServerEndpointListSheet *serverEndpointSheet;
@property (nonatomic, weak) IBOutlet NSButton *addAddressBookEntryButton;
@property (nonatomic, weak) IBOutlet NSButton *addChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *addHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *autoConnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *autoDisconnectOnSleepCheck;
@property (nonatomic, weak) IBOutlet NSButton *autoReconnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *autojoinWaitsForNickServCheck;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateChangeCertificateButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateResetCertificateButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateMD5FingerprintCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateSHA1FingerprintCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateSHA2FingerprintCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *connectionPrefersIPv4Check;
@property (nonatomic, weak) IBOutlet NSButton *deleteAddressBookEntryButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *disconnectOnReachabilityChangeCheck;
@property (nonatomic, weak) IBOutlet NSButton *editAddressBookEntryButton;
@property (nonatomic, weak) IBOutlet NSButton *editChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *editHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *excludedFromCloudSyncingCheck;
@property (nonatomic, weak) IBOutlet NSButton *hideAutojoinDelayedWarningsCheck;
@property (nonatomic, weak) IBOutlet NSButton *performDisconnectOnPongTimerCheck;
@property (nonatomic, weak) IBOutlet NSButton *pongTimerCheck;
@property (nonatomic, weak) IBOutlet NSButton *prefersSecuredConnectionCheck;
@property (nonatomic, weak) IBOutlet NSButton *setInvisibleModeOnConnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *validateServerCertificateChainCheck;
@property (nonatomic, weak) IBOutlet NSButton *viewListOfPreferredCipherSuitesButton;
@property (nonatomic, weak) IBOutlet NSButton *zncIgnoreConfiguredAutojoinCheck;
@property (nonatomic, weak) IBOutlet NSButton *zncIgnorePlaybackNotificationsCheck;
@property (nonatomic, weak) IBOutlet NSButton *zncOnlyPlaybackLatestCheck;
@property (nonatomic, weak) IBOutlet NSImageView *erroneousInputErrorImageView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *primaryEncodingButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *preferredCipherSuitesButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *proxyTypeButton;
@property (nonatomic, weak) IBOutlet NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, weak) IBOutlet NSSlider *floodControlMessageCountSlider;
@property (nonatomic, weak) IBOutlet NSTextField *alternateNicknamesTextField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateCommonNameField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateMD5FingerprintField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateSHA1FingerprintField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateSHA2FingerprintField;
@property (nonatomic, weak) IBOutlet NSTextField *erroneousInputErrorTextField;
@property (nonatomic, weak) IBOutlet NSTextField *nicknamePasswordTextField;
@property (nonatomic, weak) IBOutlet NSTextField *proxyPasswordTextField;
@property (nonatomic, weak) IBOutlet NSTextField *proxyUsernameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *serverPasswordTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *addressBookTable;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *channelListTable;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *highlightsTable;
@property (nonatomic, weak) IBOutlet TVCComboBoxWithValueValidation *serverAddressComboBox;
@property (nonatomic, weak) IBOutlet TVCContentNavigationOutlineView *navigationOutlineView;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *awayNicknameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *connectionNameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *nicknameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *normalLeavingCommentTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *proxyAddressTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *proxyPortTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *realNameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *serverPortTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *sleepModeQuitMessageTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *usernameTextField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextView *connectCommandsField;
@property (nonatomic, assign) NSUInteger floodControlDelayTimerSliderTempValue;
@property (nonatomic, assign) NSUInteger floodControlMessageCountSliderTempValue;
@property (nonatomic, weak) NSPanel *clientCertificateSelectCertificatePanel;
@property (nonatomic, strong) IBOutlet NSArrayController *addressBookArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *channelListArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *highlightListArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *serverListArrayController;
@property (readonly, copy) NSArray<IRCAddressBookEntry *> *addressBookList;
@property (readonly, copy) NSArray<IRCChannelConfig *> *channelList;
@property (readonly, copy) NSArray<IRCHighlightMatchCondition *> *highlightList;
@property (readonly, copy) NSArray<IRCServer *> *serverList;
@property (nonatomic, assign) BOOL populatingPrimaryServer;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@property (nonatomic, assign) BOOL requestRemovalFromCloudOnClose;
#endif

- (IBAction)proxyTypeChanged:(id)sender;
- (IBAction)toggleAdvancedEncodings:(id)sender;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (IBAction)toggleCloudSyncExclusion:(id)sender;
#endif

- (IBAction)addChannel:(id)sender;
- (IBAction)editChannel:(id)sender;
- (IBAction)deleteChannel:(id)sender;

- (IBAction)addHighlight:(id)sender;
- (IBAction)editHighlight:(id)sender;
- (IBAction)deleteHighlight:(id)sender;

- (IBAction)addAddressBookEntry:(id)sender;
- (IBAction)editAddressBookEntry:(id)sender;
- (IBAction)deleteAddressBookEntry:(id)sender;

- (IBAction)showAddAddressBookEntryMenu:(id)sender;

- (IBAction)editSeverEndpoints:(id)sender;

- (IBAction)useSSLCheckChanged:(id)sender;

- (IBAction)autojoinWaitsForNickServChanged:(id)sender;

- (IBAction)onClientCertificateResetRequested:(id)sender;
- (IBAction)onClientCertificateChangeRequested:(id)sender;
- (IBAction)onClientCertificateFingerprintSHA2CopyRequested:(id)sender;
- (IBAction)onClientCertificateFingerprintSHA1CopyRequested:(id)sender;
- (IBAction)onClientCertificateFingerprintMD5CopyRequested:(id)sender;

- (IBAction)preferredCipherSuitesChanged:(id)sender;
- (IBAction)preferredCipherSuitesViewList:(id)sender;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TDCServerPropertiesSheet

- (instancetype)initWithClient:(nullable IRCClient *)client
{
	if ((self = [super init])) {
		if (client) {
			self.client = client;
			self.clientId = client.uniqueIdentifier;

			[client updateStoredConfiguration];

			self.config = [client.config mutableCopy];
		} else {
			self.config = [IRCClientConfigMutable new];
		}

		[self prepareInitialState];

		[self loadConfig];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCServerPropertiesSheet" owner:self topLevelObjects:nil];

	/* Populate server list combo box */
	self.networkList = [IRCNetworkList new];

	NSArray *listOfNetworks = self.networkList.listOfNetworks;

	for (IRCNetwork *network in listOfNetworks) {
		[self.serverAddressComboBox addItemWithObjectValue:network.networkName];
	}

	/* Connect commands text box better font */
	self.connectCommandsField.font = [NSFont fontWithName:@"Lucida Grande" size:13.0];

	self.connectCommandsField.textContainerInset = NSMakeSize(1, 3);

	/* Away nickname */
	self.awayNicknameTextField.textDidChangeCallback = self;

	self.awayNicknameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.awayNicknameTextField.stringValueIsInvalidOnEmpty = NO;
	self.awayNicknameTextField.stringValueIsTrimmed = YES;
	self.awayNicknameTextField.stringValueUsesOnlyFirstToken = YES;

	self.awayNicknameTextField.validationBlock = ^BOOL(NSString *currentValue) {
		return currentValue.isHostmaskNickname;
	};

	/* Nickname */
	self.nicknameTextField.textDidChangeCallback = self;

	self.nicknameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.nicknameTextField.stringValueIsInvalidOnEmpty = YES;
	self.nicknameTextField.stringValueIsTrimmed = YES;
	self.nicknameTextField.stringValueUsesOnlyFirstToken = YES;

	self.nicknameTextField.validationBlock = ^BOOL(NSString *currentValue) {
		return currentValue.isHostmaskNickname;
	};

	/* Username */
	self.usernameTextField.textDidChangeCallback = self;

	self.usernameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.usernameTextField.stringValueIsInvalidOnEmpty = YES;
	self.usernameTextField.stringValueIsTrimmed = YES;
	self.usernameTextField.stringValueUsesOnlyFirstToken = YES;

	self.usernameTextField.validationBlock = ^BOOL(NSString *currentValue) {
		return currentValue.isHostmaskUsername;
	};

	/* Real name */
	self.realNameTextField.textDidChangeCallback = self;

	self.realNameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.realNameTextField.stringValueIsInvalidOnEmpty = YES;
	self.realNameTextField.stringValueIsTrimmed = YES;
	self.realNameTextField.stringValueUsesOnlyFirstToken = NO;

	/* Normal leaving comment */
	self.normalLeavingCommentTextField.textDidChangeCallback = self;

	self.normalLeavingCommentTextField.onlyShowStatusIfErrorOccurs = YES;

	self.normalLeavingCommentTextField.stringValueIsInvalidOnEmpty = NO;
	self.normalLeavingCommentTextField.stringValueIsTrimmed = YES;
	self.normalLeavingCommentTextField.stringValueUsesOnlyFirstToken = NO;

	self.normalLeavingCommentTextField.validationBlock = ^BOOL(NSString *currentValue) {
		if ([currentValue containsCharactersFromCharacterSet:[NSCharacterSet newlineCharacterSet]]) {
			return NO;
		}

		return (currentValue.length < 390);
	};

	/* Sleep mode leaving comment */
	self.sleepModeQuitMessageTextField.textDidChangeCallback = self;

	self.sleepModeQuitMessageTextField.onlyShowStatusIfErrorOccurs = YES;

	self.sleepModeQuitMessageTextField.stringValueIsInvalidOnEmpty = NO;
	self.sleepModeQuitMessageTextField.stringValueIsTrimmed = YES;
	self.sleepModeQuitMessageTextField.stringValueUsesOnlyFirstToken = NO;

	self.sleepModeQuitMessageTextField.validationBlock = ^BOOL(NSString *currentValue) {
		if ([currentValue containsCharactersFromCharacterSet:[NSCharacterSet newlineCharacterSet]]) {
			return NO;
		}

		return (currentValue.length < 390);
	};

	/* Connection name */
	self.connectionNameTextField.textDidChangeCallback = self;

	self.connectionNameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.connectionNameTextField.stringValueIsInvalidOnEmpty = YES;
	self.connectionNameTextField.stringValueIsTrimmed = YES;
	self.connectionNameTextField.stringValueUsesOnlyFirstToken = NO;

	/* Server address */
	self.serverAddressComboBox.textDidChangeCallback = self;

	self.serverAddressComboBox.onlyShowStatusIfErrorOccurs = YES;

	self.serverAddressComboBox.stringValueIsInvalidOnEmpty = YES;
	self.serverAddressComboBox.stringValueIsTrimmed = YES;
	self.serverAddressComboBox.stringValueUsesOnlyFirstToken = YES;

	self.serverAddressComboBox.validationBlock = ^BOOL(NSString *currentValue) {
		return currentValue.isValidInternetAddress;
	};

	/* Server port */
	self.serverPortTextField.textDidChangeCallback = self;

	self.serverPortTextField.onlyShowStatusIfErrorOccurs = YES;

	self.serverPortTextField.stringValueIsInvalidOnEmpty = YES;
	self.serverPortTextField.stringValueIsTrimmed = YES;
	self.serverPortTextField.stringValueUsesOnlyFirstToken = NO;

	self.serverPortTextField.validationBlock = ^BOOL(NSString *currentValue) {
		return currentValue.isValidInternetPort;
	};

	/* Proxy address */
	self.proxyAddressTextField.textDidChangeCallback = self;

	self.proxyAddressTextField.onlyShowStatusIfErrorOccurs = YES;

	self.proxyAddressTextField.stringValueIsInvalidOnEmpty = NO;
	self.proxyAddressTextField.stringValueIsTrimmed = YES;
	self.proxyAddressTextField.stringValueUsesOnlyFirstToken = YES;

	self.proxyAddressTextField.performValidationWhenEmpty = YES;

	self.proxyAddressTextField.validationBlock = ^BOOL(NSString *currentValue) {
		NSInteger proxyType = self.proxyTypeButton.selectedTag;

		if (proxyType == IRCConnectionSocketSocks4ProxyType ||
			proxyType == IRCConnectionSocketSocks5ProxyType ||
			proxyType == IRCConnectionSocketHTTPProxyType ||
			proxyType == IRCConnectionSocketHTTPSProxyType)
		{
			return currentValue.isValidInternetAddress;
		}

		return YES;
	};

	/* Proxy port */
	self.proxyPortTextField.textDidChangeCallback = self;

	self.proxyPortTextField.onlyShowStatusIfErrorOccurs = YES;

	self.proxyPortTextField.stringValueIsInvalidOnEmpty = NO;
	self.proxyPortTextField.stringValueIsTrimmed = YES;
	self.proxyPortTextField.stringValueUsesOnlyFirstToken = NO;

	self.proxyPortTextField.performValidationWhenEmpty = YES;

	self.proxyPortTextField.defaultValue = [NSString stringWithUnsignedInteger:IRCConnectionDefaultProxyPort];

	self.proxyPortTextField.validationBlock = ^BOOL(NSString *currentValue) {
		NSInteger proxyType = self.proxyTypeButton.selectedTag;

		if (proxyType == IRCConnectionSocketSocks4ProxyType ||
			proxyType == IRCConnectionSocketSocks5ProxyType ||
			proxyType == IRCConnectionSocketHTTPProxyType ||
			proxyType == IRCConnectionSocketHTTPSProxyType)
		{
			return currentValue.isValidInternetPort;
		}

		return YES;
	};

	/* Setup others */
	[self addConfigurationDidChangeObserver];

	self.addressBookTable.doubleAction = @selector(tableViewDoubleClicked:);
	self.addressBookTable.target = self;

	[self.addressBookTable registerForDraggedTypes:@[_tableDragToken]];

	self.channelListTable.doubleAction = @selector(tableViewDoubleClicked:);
	self.channelListTable.target = self;

	[self.channelListTable registerForDraggedTypes:@[_tableDragToken]];

	self.highlightsTable.doubleAction = @selector(tableViewDoubleClicked:);
	self.highlightsTable.target = self;

	[self.highlightsTable registerForDraggedTypes:@[_tableDragToken]];

	[self populateEncodings];

	[self populateTabViewList];
}

- (void)dealloc
{
	self.connectCommandsField = nil;
}

- (void)populateTabViewList
{
#define _navigationIndexForAddressBook				1
#define _navigationIndexForConnectCommands			3
#define _navigationIndexForDisconnectMessages		8
#define _navigationIndexForFloodControl				13
#define _navigationIndexForGeneral					5
#define _navigationIndexForIdentity					6

	NSMutableArray *navigationTreeMatrix = [NSMutableArray array];

	[navigationTreeMatrix addObject:@{
		@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][15]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][07]"),	@"view" : self.contentViewAddressBook},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][01]"),	@"view" : self.contentViewAutojoin},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][02]"),	@"view" : self.contentViewConnectCommands},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][03]"),	@"view" : self.contentViewEncoding},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][05]"),	@"view" : self.contentViewGeneral},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][06]"),	@"view" : self.contentViewIdentity},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][12]"),	@"view" : self.contentViewHighlights},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][08]"),	@"view" : self.contentViewDisconnectMessages},
		]
	}];

	[navigationTreeMatrix addObject:@{
		@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][16]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][14]"),	@"view" : self.contentViewZncBouncer},
		]
	}];

	[navigationTreeMatrix addObject:@{
		@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][17]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][11]"),	@"view" : self.contentViewClientCertificate},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][04]"),	@"view" : self.contentViewFloodControl},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][13]"),	@"view" : self.contentViewNetworkSocket},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][10]"),	@"view" : self.contentViewProxyServer},
			@{@"name" : TXTLS(@"TDCServerPropertiesSheet[1006][18]"),	@"view" : self.contentViewRedundancy},
		]
	}];

	self.navigationOutlineView.navigationTreeMatrix = navigationTreeMatrix;

	/* Auto layout will grow view beyond these values.
	 We are just declaring the default which doesn't matter much. */
	self.navigationOutlineView.contentViewPreferredWidth = 100;
	self.navigationOutlineView.contentViewPreferredHeight = 100;

	self.navigationOutlineView.expandParentOnDoubleClick = YES;

	[self.navigationOutlineView reloadData];

	[self.navigationOutlineView expandItem:navigationTreeMatrix[0]];
}

- (void)populateEncodings
{
	[self.primaryEncodingButton removeAllItems];

	[self.fallbackEncodingButton removeAllItems];

	/* Build list of encodings */
	self.encodingList = [NSString supportedStringEncodingsWithTitle:NO];

	NSArray *encodingNames = self.encodingList.sortedDictionaryKeys;

	/* What we are basically doing now is sorting all the encodings, then removing
	 UTF-8 from the sorted list and inserting it at the top of the list. */
	NSString *utf8title = [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding];

	NSMutableArray *encodingsToAdd = [encodingNames mutableCopy];

	[encodingsToAdd removeObject:utf8title];

	[self.primaryEncodingButton addItemWithTitle:utf8title];

	[self.fallbackEncodingButton addItemWithTitle:utf8title];

	/* Add the encodings to the popup list. This for loop will find the first
	 parentheses opening and compare everything before it to the one found for
	 the previous encoding. If the prefix has changed, then a separator is
	 inserted. This groups the encodings.*/
	/* We do this two times. The first time setups up preferred encodings at
	 the top of the list. The next handles everything else. */
	NSArray *favoredEncodings = @[@"Unicode", @"Western", @"Central European"];

	[self populateEncodingPopup:encodingsToAdd preferredEncodings:favoredEncodings ignoreFavored:NO];

	if ([RZUserDefaults() boolForKey:@"Server Properties Window Sheet -> Include Advanced Encodings"]) {
		[self populateEncodingPopup:encodingsToAdd preferredEncodings:favoredEncodings ignoreFavored:YES];
	}
}

- (void)populateEncodingPopup:(NSArray<NSString *> *)encodingsToAdd preferredEncodings:(NSArray<NSString *> *)favoredEncodings ignoreFavored:(BOOL)ignoreFavored
{
	NSString *encodingPrefixPrevious = nil;

	for (NSString *encoding in encodingsToAdd) {
		NSInteger parenthesisPosition = [encoding stringPosition:@" ("];

		if (parenthesisPosition <= 0) {
			continue;
		}

		NSString *encodingPrefix = [encoding substringToIndex:parenthesisPosition];

		if (ignoreFavored && [favoredEncodings containsObject:encodingPrefix]) {
			continue;
		} else if (ignoreFavored == NO && [favoredEncodings containsObject:encodingPrefix] == NO) {
			continue;
		}

		if ([encodingPrefix isEqualToString:encodingPrefixPrevious] == NO) {
			encodingPrefixPrevious = encodingPrefix;

			[self.primaryEncodingButton.menu addItem:[NSMenuItem separatorItem]];

			[self.fallbackEncodingButton.menu addItem:[NSMenuItem separatorItem]];
		}

		[self.primaryEncodingButton addItemWithTitle:encoding];

		[self.fallbackEncodingButton addItemWithTitle:encoding];
	}
}

#pragma mark -
#pragma mark Initialization Handler

- (void)start
{
	[self startWithSelection:TDCServerPropertiesSheetDefaultNavigationSelection context:nil];
}

- (void)startWithSelection:(TDCServerPropertiesSheetNavigationSelection)selection context:(nullable id)context
{
	switch (selection) {
		case TDCServerPropertiesSheetFloodControlNavigationSelection:
		{
			[self startWithViewAtIndex:_navigationIndexForFloodControl];

			break;
		}
		case TDCServerPropertiesSheetAddressBookNavigationSelection:
		{
			[self startWithViewAtIndex:_navigationIndexForAddressBook];

			break;
		}
		case TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection:
		{
			[self startWithViewAtIndex:_navigationIndexForAddressBook];

			if ([context isKindOfClass:[NSString class]]) {
				[self addIgnoreAddressBookEntryWithHostmask:context];
			} else if ([context isKindOfClass:[IRCAddressBookEntry class]]) {
				[self editAddressBookEntryWithObject:context];
			}

			break;
		}
		default:
		{
			[self startWithViewAtIndex:_navigationIndexForGeneral];
		}
	}
}

- (void)startWithViewAtIndex:(NSUInteger)viewIndex
{
	[self.navigationOutlineView startAtSelectionIndex:viewIndex];

	[self startSheet];

	[self.sheet recalculateKeyViewLoop];
}

- (void)closeChildSheets
{
	if (self.addressBookSheet) {
		[self.addressBookSheet close];
	} else if (self.channelSheet) {
		[self.channelSheet close];
	} else if (self.highlightSheet) {
		[self.highlightSheet close];
	} else if (self.serverEndpointSheet) {
		[self.serverEndpointSheet close];
	} else if (self.clientCertificateSelectCertificatePanel) {
		[NSApp stopModalWithCode:NSModalResponseCancel];
	}
}

- (void)ok:(id)sender
{
	[self removeConfigurationDidChangeObserver];

	[self closeChildSheets];

	[self clearChannelListPredicate];

	[self saveConfig];

	if ([self.delegate respondsToSelector:@selector(serverPropertiesSheet:onOk:)]) {
		[self.delegate serverPropertiesSheet:self onOk:[self.config copy]];
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (self.requestRemovalFromCloudOnClose) {
		if ([self.delegate respondsToSelector:@selector(serverPropertiesSheet:removeClientFromCloud:)]) {
			[self.delegate serverPropertiesSheet:self removeClientFromCloud:self.clientId];
		}
	}
#endif

	[super ok:nil];
}

- (void)cancel:(id)sender
{
	[self removeConfigurationDidChangeObserver];

	[self closeChildSheets];

	[super cancel:nil];
}

- (void)addConfigurationDidChangeObserver
{
	if (self.client == nil) {
		return;
	}

	[RZNotificationCenter() addObserver:self
							   selector:@selector(underlyingConfigurationChanged:)
								   name:IRCClientConfigurationWasUpdatedNotification
								 object:self.client];
}

- (void)removeConfigurationDidChangeObserver
{
	[RZNotificationCenter() removeObserver:self];
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	IRCClient *client = notification.object;

	NSWindow *window = self.sheet.deepestWindow;

	[TLOPopupPrompts sheetWindowWithWindow:window
									  body:TXTLS(@"Prompts[1116][2]")
									 title:TXTLS(@"Prompts[1116][1]")
							 defaultButton:TXTLS(@"Prompts[0001]")
						   alternateButton:TXTLS(@"Prompts[0002]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked != TLOPopupPromptReturnPrimaryType) {
								   return;
							   }

							   [self close];

							   [client updateStoredConfiguration];

							   self.config = [client.config mutableCopy];

							   [self loadConfig];

							   [self start];
						   }];
}

- (void)loadConfig
{
	/* General */
	self.connectionNameTextField.stringValue = self.config.connectionName;

	self.autoConnectCheck.state = self.config.autoConnect;
	self.autoReconnectCheck.state = self.config.autoReconnect;
	self.autoDisconnectOnSleepCheck.state = self.config.autoSleepModeDisconnect;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	self.excludedFromCloudSyncingCheck.state = self.config.excludedFromCloudSyncing;
#endif

	/* ZNC Bouncer */
	self.zncIgnoreConfiguredAutojoinCheck.state = self.config.zncIgnoreConfiguredAutojoin;
	self.zncIgnorePlaybackNotificationsCheck.state = self.config.zncIgnorePlaybackNotifications;
	self.zncOnlyPlaybackLatestCheck.state = self.config.zncOnlyPlaybackLatest;

	/* Network Socket */
	self.connectionPrefersIPv4Check.state = self.config.connectionPrefersIPv4;

	self.pongTimerCheck.state = self.config.performPongTimer;
	self.performDisconnectOnPongTimerCheck.state = self.config.performDisconnectOnPongTimer;

	self.disconnectOnReachabilityChangeCheck.state = self.config.performDisconnectOnReachabilityChange;

	self.validateServerCertificateChainCheck.state = self.config.validateServerCertificateChain;

	[self.preferredCipherSuitesButton selectItemWithTag:self.config.cipherSuites];

	/* Identity */
	if (self.config.nickname.length > 0) {
		self.nicknameTextField.stringValue = self.config.nickname;
	} else {
		self.nicknameTextField.stringValue = [TPCPreferences defaultNickname];
	}

	self.awayNicknameTextField.stringValue = self.config.awayNickname;

	NSString *alternateNicknamesString = [self.config.alternateNicknames componentsJoinedByString:@" "];

	self.alternateNicknamesTextField.stringValue = alternateNicknamesString;

	if (self.config.username.length > 0) {
		self.usernameTextField.stringValue = self.config.username;
	} else {
		self.usernameTextField.stringValue = [TPCPreferences defaultUsername];
	}

	if (self.config.realName.length > 0) {
		self.realNameTextField.stringValue = self.config.realName;
	} else {
		self.realNameTextField.stringValue = [TPCPreferences defaultRealName];
	}

	self.nicknamePasswordTextField.stringValue = self.config.nicknamePassword;

	self.autojoinWaitsForNickServCheck.state = self.config.autojoinWaitsForNickServ;

	self.hideAutojoinDelayedWarningsCheck.state = (self.config.hideAutojoinDelayedWarnings == NO);

	/* Messages */
	self.normalLeavingCommentTextField.stringValue = self.config.normalLeavingComment;

	self.sleepModeQuitMessageTextField.stringValue = self.config.sleepModeLeavingComment;

	/* Encoding */
	NSString *primaryEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.primaryEncoding)];

	[self.primaryEncodingButton selectItemWithTitle:primaryEncodingTitle];

	NSString *fallbackEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.fallbackEncoding)];

	[self.fallbackEncodingButton selectItemWithTitle:fallbackEncodingTitle];

	/* Proxy Server */
	[self.proxyTypeButton selectItemWithTag:self.config.proxyType];

	self.proxyAddressTextField.stringValue = self.config.proxyAddress;
	self.proxyPortTextField.integerValue = self.config.proxyPort;
	self.proxyUsernameTextField.stringValue = self.config.proxyUsername;
	self.proxyPasswordTextField.stringValue = self.config.proxyPassword;

	/* Connect Commands */
	NSString *loginCommandsString = [self.config.loginCommands componentsJoinedByString:@"\n"];

	self.connectCommandsField.string = loginCommandsString;

	self.setInvisibleModeOnConnectCheck.state = self.config.setInvisibleModeOnConnect;

	/* Flood Control */
	self.floodControlDelayTimerSliderTempValue = self.config.floodControlDelayTimerInterval;
	self.floodControlMessageCountSliderTempValue = self.config.floodControlMaximumMessages;

	/* Mutable Stores */
	[self.addressBookArrayController addObjects:self.config.ignoreList];
	[self.channelListArrayController addObjects:self.config.channelList];
	[self.highlightListArrayController addObjects:self.config.highlightList];
	[self.serverListArrayController addObjects:self.config.serverList];

	/* Special loads */
	[self loadPrimaryServerEndpoint];

	[self loadConfigPostflight];
}

- (void)loadPrimaryServerEndpoint
{
	IRCServer *server = self.serverList.firstObject;

	if (server == nil) {
		self.serverAddressComboBox.stringValue = @"";

		self.serverPortTextField.integerValue = IRCConnectionDefaultServerPort;

		self.prefersSecuredConnectionCheck.state = NSOffState;

		self.serverPasswordTextField.stringValue = @"";

		return;
	}

	self.populatingPrimaryServer = YES;

	NSString *serverAddress = server.serverAddress;

	if (serverAddress) {
		IRCNetwork *serverAddressNetwork = [self.networkList networkWithServerAddress:serverAddress];

		if (serverAddressNetwork) {
			self.serverAddressComboBox.stringValue = serverAddressNetwork.networkName;
		} else {
			self.serverAddressComboBox.stringValue = serverAddress;
		}
	}

	self.serverPortTextField.integerValue = server.serverPort;

	self.prefersSecuredConnectionCheck.state = server.prefersSecuredConnection;

	self.serverPasswordTextField.stringValue = server.serverPassword;

	self.populatingPrimaryServer = NO;
}

- (void)loadConfigPostflight
{
	[self setChannelListPredicate];

	[self updateAddressBookPage];
	[self updateChannelListPage];
	[self updateClientCertificatePage];
	[self updateConnectionPage];
	[self updateHighlightsPage];
	[self updateIdentityPage];

	[self preferredCipherSuitesChanged:nil];

	[self proxyTypeChanged:nil];
}

- (void)saveConfig
{
	/* General */
	self.config.connectionName = self.connectionNameTextField.value;

	self.config.autoConnect	= (self.autoConnectCheck.state == NSOnState);
	self.config.autoReconnect = (self.autoReconnectCheck.state == NSOnState);
	self.config.autoSleepModeDisconnect = (self.autoDisconnectOnSleepCheck.state == NSOnState);

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	self.config.excludedFromCloudSyncing = (self.excludedFromCloudSyncingCheck.state == NSOnState);
#endif

	/* ZNC Bouncer */
	self.config.zncIgnoreConfiguredAutojoin = (self.zncIgnoreConfiguredAutojoinCheck.state == NSOnState);
	self.config.zncIgnorePlaybackNotifications = (self.zncIgnorePlaybackNotificationsCheck.state == NSOnState);
	self.config.zncOnlyPlaybackLatest = (self.zncOnlyPlaybackLatestCheck.state == NSOnState);

	/* Network Socket */
	self.config.connectionPrefersIPv4 = (self.connectionPrefersIPv4Check.state == NSOnState);

	self.config.performPongTimer = (self.pongTimerCheck.state == NSOnState);
	self.config.performDisconnectOnPongTimer = (self.performDisconnectOnPongTimerCheck.state == NSOnState);

	self.config.performDisconnectOnReachabilityChange = (self.disconnectOnReachabilityChangeCheck.state == NSOnState);

	self.config.validateServerCertificateChain = (self.validateServerCertificateChainCheck.state == NSOnState);

	self.config.cipherSuites = self.preferredCipherSuitesButton.selectedTag;

	/* Identity */
	self.config.nickname = self.nicknameTextField.value;
	self.config.username = self.usernameTextField.value;
	self.config.realName = self.realNameTextField.value;

	self.config.awayNickname = self.awayNicknameTextField.value;

	self.config.nicknamePassword = self.nicknamePasswordTextField.trimmedStringValue;

	self.config.autojoinWaitsForNickServ = (self.autojoinWaitsForNickServCheck.state == NSOnState);

	self.config.hideAutojoinDelayedWarnings = (self.hideAutojoinDelayedWarningsCheck.state != NSOnState);

	/* Alternate nicknames */
	NSString *alternateNicknamesString = self.alternateNicknamesTextField.stringValue;

	NSArray *alternateNicknames = [alternateNicknamesString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	self.config.alternateNicknames = [alternateNicknames arrayByRemovingEmptyValuesAndUniquing];

	/* Messages */
	self.config.sleepModeLeavingComment	= self.sleepModeQuitMessageTextField.value;
	self.config.normalLeavingComment = self.normalLeavingCommentTextField.value;

	/* Encoding */
	NSStringEncoding primaryEncoding = [self.encodingList unsignedIntegerForKey:self.primaryEncodingButton.title];

	self.config.primaryEncoding	= primaryEncoding;

	NSStringEncoding fallbackEncoding = [self.encodingList unsignedIntegerForKey:self.fallbackEncodingButton.title];

	self.config.fallbackEncoding = fallbackEncoding;

	/* Proxy Server */
	self.config.proxyType = self.proxyTypeButton.selectedTag;

	self.config.proxyAddress = self.proxyAddressTextField.lowercaseValue;
	self.config.proxyPort = self.proxyPortTextField.integerValue;
	self.config.proxyUsername = self.proxyUsernameTextField.trimmedFirstTokenStringValue;
	self.config.proxyPassword = self.proxyPasswordTextField.trimmedStringValue;

	/* Connect Commands */
	NSString *connectCommandsString = self.connectCommandsField.string;

	NSArray *connectCommands = [connectCommandsString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	self.config.loginCommands = [connectCommands arrayByRemovingEmptyValues:YES trimming:YES uniquing:NO];

	self.config.setInvisibleModeOnConnect = (self.setInvisibleModeOnConnectCheck.state == NSOnState);

	/* Flood Control */
	self.config.floodControlMaximumMessages = self.floodControlMessageCountSlider.integerValue;
	self.config.floodControlDelayTimerInterval = self.floodControlDelayTimerSlider.integerValue;

	/* Mutable stores. */
	self.config.channelList = self.channelListArrayController.arrangedObjects;
	self.config.highlightList = self.highlightListArrayController.arrangedObjects;
	self.config.ignoreList = self.addressBookArrayController.arrangedObjects;
	self.config.serverList = self.serverListArrayController.arrangedObjects;
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	NSControl *sender = obj.object;

	if (sender == self.serverPasswordTextField) {
		[self rebuildMutableServerEndpointListIfNeeded:sender];
	}
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self updateConnectionPage];

	if (sender == self.serverAddressComboBox) {
		[self populateDefaultsForPreconfiguredNetwork];

		[self rebuildMutableServerEndpointListIfNeeded:sender];
	} else if (sender == self.serverPortTextField) {
		[self rebuildMutableServerEndpointListIfNeeded:sender];
	}
}

- (void)populateDefaultsForPreconfiguredNetwork
{
	NSString *serverAddress = self.serverAddressComboBox.value;

	IRCNetwork *network = [self.networkList networkNamed:serverAddress];

	BOOL networkSetFromServerAddress = YES;

	if (network == nil) {
		network = [self.networkList networkWithServerAddress:serverAddress];
	}

	if (network == nil) {
		return;
	}

	/* If the combo box is set to a server address that matches a known
	 server address, then replace the combox box value with network name. */
	if (networkSetFromServerAddress) {
		self.serverAddressComboBox.doNotInformCallbackOfNextChange = YES;

		self.serverAddressComboBox.stringValue = network.networkName;
	}

	/* Populate other defaults */
	self.serverPortTextField.integerValue = network.serverPort;

	self.prefersSecuredConnectionCheck.state = network.prefersSecuredConnection;
}

- (void)updateConnectionPage
{
	/* This array is not saved as static because it would 
	 have to be cleared out anytime that the sheet closes. */
	NSArray *fieldsToValidate = @[
	   @{@"field" : self.nicknameTextField,					@"errorLocalizationNumeric" : @"01"},
	   @{@"field" : self.awayNicknameTextField,				@"errorLocalizationNumeric" : @"02"},
	   @{@"field" : self.usernameTextField,					@"errorLocalizationNumeric" : @"03"},
	   @{@"field" : self.realNameTextField,					@"errorLocalizationNumeric" : @"04"},
	   @{@"field" : self.connectionNameTextField,			@"errorLocalizationNumeric" : @"05"},
	   @{@"field" : self.serverAddressComboBox,				@"errorLocalizationNumeric" : @"06"},
	   @{@"field" : self.serverPortTextField,				@"errorLocalizationNumeric" : @"07"},
	   @{@"field" : self.proxyAddressTextField,				@"errorLocalizationNumeric" : @"08"},
	   @{@"field" : self.proxyPortTextField,				@"errorLocalizationNumeric" : @"09"},
	   @{@"field" : self.normalLeavingCommentTextField,		@"errorLocalizationNumeric" : @"10"},
	   @{@"field" : self.sleepModeQuitMessageTextField,		@"errorLocalizationNumeric" : @"11"}
	];

	NSString *errorReason = nil;

	for (NSDictionary *fieldToValidate in fieldsToValidate) {
		id field = fieldToValidate[@"field"];

		if ([field valueIsValid] == NO) {
			errorReason = [NSString stringWithFormat:@"TDCServerPropertiesSheet[1007][%@]", fieldToValidate[@"errorLocalizationNumeric"]];

			break;
		}
	}

	if (errorReason) {
		self.okButton.enabled = NO;

		self.erroneousInputErrorImageView.hidden = NO;
		self.erroneousInputErrorTextField.hidden = NO;

		self.erroneousInputErrorTextField.stringValue = TXTLS(errorReason);
	} else {
		self.okButton.enabled = YES;

		self.erroneousInputErrorImageView.hidden = YES;
		self.erroneousInputErrorTextField.hidden = YES;

		self.erroneousInputErrorTextField.stringValue = @"";
	}
}

- (void)updateChannelListPage
{
	NSInteger selectedRow = self.channelListTable.selectedRow;

	self.deleteChannelButton.enabled = (selectedRow >= 0);
	self.editChannelButton.enabled = (selectedRow >= 0);
}

- (void)clearChannelListPredicate
{
	self.channelListArrayController.filterPredicate = nil;
}

- (void)setChannelListPredicate
{
	self.channelListArrayController.filterPredicate =
	[NSPredicate predicateWithFormat:@"type == 0"]; // Is channel type
}

- (void)updateAddressBookPage
{
	NSInteger selectedRow = self.addressBookTable.selectedRow;

	self.deleteAddressBookEntryButton.enabled = (selectedRow >= 0);
	self.editAddressBookEntryButton.enabled = (selectedRow >= 0);
}

- (void)updateHighlightsPage
{
	NSInteger selectedRow = self.highlightsTable.selectedRow;

	self.deleteHighlightButton.enabled = (selectedRow >= 0);
	self.editHighlightButton.enabled = (selectedRow >= 0);
}

- (void)useSSLCheckChanged:(id)sender
{
	NSInteger serverPort = self.serverPortTextField.integerValue;

	BOOL useSSL = (self.prefersSecuredConnectionCheck.state == NSOnState);

	if (useSSL) {
		if (serverPort == 6667) {
			self.serverPortTextField.stringValue = @"6697";
		}
	} else {
		if (serverPort == 6697) {
			self.serverPortTextField.stringValue = @"6667";
		}
	}

	[self rebuildMutableServerEndpointListIfNeeded:sender];
}

- (void)updateIdentityPage
{
	self.hideAutojoinDelayedWarningsCheck.hidden =
	(self.autojoinWaitsForNickServCheck.state == NSOffState);
}

#pragma mark -
#pragma mark Properties

- (NSArray<IRCAddressBookEntry *> *)addressBookList
{
	return self.addressBookArrayController.arrangedObjects;
}

- (NSArray<IRCChannelConfig *> *)channelList
{
	return self.channelListArrayController.arrangedObjects;
}

- (NSArray<IRCHighlightMatchCondition *> *)highlightList
{
	return self.highlightListArrayController.arrangedObjects;
}

- (NSArray<IRCServer *> *)serverList
{
	return self.serverListArrayController.arrangedObjects;
}

#pragma mark -
#pragma mark Actions

- (void)autojoinWaitsForNickServChanged:(id)sender
{
	[self updateIdentityPage];

	if (self.autojoinWaitsForNickServCheck.state != NSOnState) {
		return;
	}

	if (self.nicknamePasswordTextField.stringValue.length > 0 ||
		self.clientCertificateResetCertificateButton.enabled)
	{
		return;
	}

	(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1136][2]")
											 title:TXTLS(@"Prompts[1136][1]")
									 defaultButton:TXTLS(@"Prompts[0005]")
								   alternateButton:nil];
}

- (void)serverAddressChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)preferredCipherSuitesChanged:(id)sender
{
	NSInteger cipherSuites = self.preferredCipherSuitesButton.selectedTag;

	self.viewListOfPreferredCipherSuitesButton.enabled =
	(cipherSuites != GCDAsyncSocketCipherSuiteNonePreferred);
}

- (void)preferredCipherSuitesViewList:(id)sender
{
	NSInteger cipherSuites = self.preferredCipherSuitesButton.selectedTag;

	NSArray *cipherSuitesDescriptions = [GCDAsyncSocket descriptionsForCipherListVersion:cipherSuites withProtocol:YES];

	NSString *cipherSuitesDescription = [cipherSuitesDescriptions componentsJoinedByString:@"\n"];

	NSString *cipherSuitesTitle = self.preferredCipherSuitesButton.titleOfSelectedItem;

	[TLOPopupPrompts sheetWindowWithWindow:self.sheet
									  body:TXTLS(@"TDCServerPropertiesSheet[1010][2]", cipherSuitesDescription)
									 title:TXTLS(@"TDCServerPropertiesSheet[1010][1]", cipherSuitesTitle)
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)proxyTypeChanged:(id)sender
{
	NSInteger proxyType = self.proxyTypeButton.selectedTag;

	BOOL isSystemSocksProxyEnabled = (proxyType == IRCConnectionSocketSystemSocksProxyType);
	BOOL isTorBrowserProxyEnabled = (proxyType == IRCConnectionSocketTorBrowserType);

	BOOL supportsAuthentication = (proxyType == IRCConnectionSocketSocks5ProxyType);

	BOOL httpsEnabled = (proxyType == IRCConnectionSocketHTTPProxyType || proxyType == IRCConnectionSocketHTTPSProxyType);
	BOOL socksEnabled = (proxyType == IRCConnectionSocketSocks4ProxyType || proxyType == IRCConnectionSocketSocks5ProxyType);

	BOOL enabled = (httpsEnabled || socksEnabled);

	self.contentViewProxyServerInputView.hidden = (httpsEnabled == NO && socksEnabled == NO);
	self.contentViewProxyServerTorBrowserView.hidden = (isTorBrowserProxyEnabled == NO);
	self.contentViewProxyServerSystemSocksView.hidden = (isSystemSocksProxyEnabled == NO);

	self.proxyAddressTextField.enabled = enabled;
	self.proxyPortTextField.enabled = enabled;

	self.proxyUsernameTextField.enabled = (socksEnabled && supportsAuthentication);
	self.proxyPasswordTextField.enabled = (socksEnabled && supportsAuthentication);

	[self.proxyAddressTextField performValidation];
	[self.proxyPortTextField performValidation];

	[self updateConnectionPage];
}

- (void)toggleAdvancedEncodings:(id)sender
{
	NSString *primaryEncoding = self.primaryEncodingButton.titleOfSelectedItem;

	NSString *fallbackEncoding = self.fallbackEncodingButton.titleOfSelectedItem;

	[self populateEncodings];

	NSMenuItem *primaryEncodingItem = nil;

	if (primaryEncoding) {
		primaryEncodingItem = [self.primaryEncodingButton itemWithTitle:primaryEncoding];
	}

	if (primaryEncodingItem == nil) {
		primaryEncoding = [NSString localizedNameOfStringEncoding:TXDefaultPrimaryStringEncoding];
	}

	NSMenuItem *fallbackEncodingItem = nil;

	if (fallbackEncoding) {
		fallbackEncodingItem = [self.fallbackEncodingButton itemWithTitle:fallbackEncoding];
	}

	if (fallbackEncodingItem == nil) {
		fallbackEncoding = [NSString localizedNameOfStringEncoding:TXDefaultFallbackStringEncoding];
	}

	[self.primaryEncodingButton selectItemWithTitle:primaryEncoding];

	[self.fallbackEncodingButton selectItemWithTitle:fallbackEncoding];
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)toggleCloudSyncExclusion:(id)sender
{
	if (self.clientId == nil) {
		return;
	}

	if (self.excludedFromCloudSyncingCheck.state == NSOnState)
	{
		NSWindow *window = self.sheet;

		[TLOPopupPrompts sheetWindowWithWindow:window
										  body:TXTLS(@"TDCServerPropertiesSheet[1002][2]")
										 title:TXTLS(@"TDCServerPropertiesSheet[1002][1]")
								 defaultButton:TXTLS(@"Prompts[0001]")
							   alternateButton:TXTLS(@"Prompts[0002]")
								   otherButton:nil
							   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
								   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
									   self.requestRemovalFromCloudOnClose = NO;
								   } else {
									   self.requestRemovalFromCloudOnClose = YES;
								   }
							   }];
	}
	else // state == NSOnState
	{
		self.requestRemovalFromCloudOnClose = NO;
	}
}
#endif

#pragma mark -
#pragma mark SSL Certificate

- (void)onClientCertificateFingerprintSHA2CopyRequested:(id)sender
{
	NSString *fingerprint = self.clientCertificateSHA2FingerprintField.stringValue;

	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", fingerprint];

	RZPasteboard().stringContent = command;
}

- (void)onClientCertificateFingerprintSHA1CopyRequested:(id)sender
{
	NSString *fingerprint = self.clientCertificateSHA1FingerprintField.stringValue;

	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", fingerprint];

	RZPasteboard().stringContent = command;
}

- (void)onClientCertificateFingerprintMD5CopyRequested:(id)sender
{
	NSString *fingerprint = self.clientCertificateMD5FingerprintField.stringValue;

	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", fingerprint];

	RZPasteboard().stringContent = command;
}

- (void)readClientCertificateCommonName:(NSString **)commonNameOut
						sha2Fingerprint:(NSString **)sha2FingerprintOut
						sha1Fingerprint:(NSString **)sha1FingerprintOut
						 md5Fingerprint:(NSString **)md5FingerprintOut
{
	NSData *certificateDataIn = self.config.identityClientSideCertificate;

	if (certificateDataIn == nil) {
		return;
	}

	/* ====================================== */

	SecKeychainItemRef certificateRef;

	CFDataRef certificateDataInRef = (__bridge CFDataRef)certificateDataIn;

	OSStatus status = SecKeychainItemCopyFromPersistentReference(certificateDataInRef, &certificateRef);

	if (status != noErr) {
		return;
	}

	/* ====================================== */

	CFStringRef commonNameRef;

	status = SecCertificateCopyCommonName((SecCertificateRef)certificateRef, &commonNameRef);

	if (status != noErr) {
		CFRelease(certificateRef);

		return;
	}

	*commonNameOut = (__bridge NSString *)(commonNameRef);

	CFRelease(commonNameRef);

	/* ====================================== */

	CFDataRef certificateDataRef = SecCertificateCopyData((SecCertificateRef)certificateRef);

	if (certificateDataRef) {
		NSData *certificateData = (__bridge NSData *)certificateDataRef;

		*sha2FingerprintOut = certificateData.sha256;
		*sha1FingerprintOut = certificateData.sha1;
		*md5FingerprintOut = certificateData.md5;

		CFRelease(certificateDataRef);
	}

	/* ====================================== */

	CFRelease(certificateRef);
}

- (void)saveClientCertificateWithIdentity:(SecIdentityRef)identityInRef
{
	if (identityInRef == NULL) {
		return;
	}

	/* ====================================== */

	SecCertificateRef certificateRef;

	OSStatus status = SecIdentityCopyCertificate(identityInRef, &certificateRef);

	if (status != noErr) {
		LogToConsoleError("Operation Failed (2): %i", status);

		return;
	}

	/* ====================================== */

	CFDataRef certificateDataRef;

	status = SecKeychainItemCreatePersistentReference((SecKeychainItemRef)certificateRef, &certificateDataRef);

	if (status != noErr) {
		CFRelease(certificateRef);

		LogToConsoleError("Operation Failed (3): %i", status);

		return;
	}

	/* ====================================== */

	self.config.identityClientSideCertificate = (__bridge NSData *)certificateDataRef;

	if (self.prefersSecuredConnectionCheck.state == NSOffState) {
		self.prefersSecuredConnectionCheck.state = NSOnState;

		[self useSSLCheckChanged:nil];
	}

	/* ====================================== */

	CFRelease(certificateRef);
	CFRelease(certificateDataRef);
}

- (void)updateClientCertificatePage
{
	NSString *commonName = nil;

	NSString *sha2Fingerprint = nil;
	NSString *sha1Fingerprint = nil;
	NSString *md5Fingerprint = nil;

	[self readClientCertificateCommonName:&commonName
						  sha2Fingerprint:&sha2Fingerprint
						  sha1Fingerprint:&sha1Fingerprint
						   md5Fingerprint:&md5Fingerprint];

	BOOL hasNoCertificate = NSObjectIsEmpty(commonName);

	if (hasNoCertificate) {
		self.clientCertificateCommonNameField.stringValue = TXTLS(@"TDCServerPropertiesSheet[1008]");

		self.clientCertificateSHA2FingerprintField.stringValue = TXTLS(@"TDCServerPropertiesSheet[1008]");
		self.clientCertificateSHA1FingerprintField.stringValue = TXTLS(@"TDCServerPropertiesSheet[1008]");
		self.clientCertificateMD5FingerprintField.stringValue = TXTLS(@"TDCServerPropertiesSheet[1008]");
	} else {
		self.clientCertificateCommonNameField.stringValue = commonName;

		self.clientCertificateSHA2FingerprintField.stringValue = sha2Fingerprint.uppercaseString;
		self.clientCertificateSHA1FingerprintField.stringValue = sha1Fingerprint.uppercaseString;
		self.clientCertificateMD5FingerprintField.stringValue = md5Fingerprint.uppercaseString;
	}

	self.clientCertificateResetCertificateButton.enabled = (hasNoCertificate == NO);

	self.clientCertificateSHA2FingerprintCopyButton.enabled = (hasNoCertificate == NO);
	self.clientCertificateSHA1FingerprintCopyButton.enabled = (hasNoCertificate == NO);
	self.clientCertificateMD5FingerprintCopyButton.enabled = (hasNoCertificate == NO);
}

- (void)onClientCertificateResetRequested:(id)sender
{
	self.config.identityClientSideCertificate = nil;

	[self updateClientCertificatePage];
}

- (void)onClientCertificateChangeRequested:(id)sender
{
	CFArrayRef identities = NULL;

	NSDictionary *queryFlags = @{
		(id)kSecClass		: (id)kSecClassIdentity,
		(id)kSecMatchLimit	: (id)kSecMatchLimitAll,
		(id)kSecReturnRef	: (id)kCFBooleanTrue
	};

	OSStatus queryStatus = SecItemCopyMatching((__bridge CFDictionaryRef)queryFlags, (CFTypeRef *)&identities);

	if (queryStatus != noErr) {
		LogToConsoleError("Operation Failed (1): %i", queryStatus);

		return;
	}

	SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];

	self.clientCertificateSelectCertificatePanel = panel;

	[panel setInformativeText:TXTLS(@"TDCServerPropertiesSheet[1009][2]")];

	[panel setAlternateButtonTitle:TXTLS(@"Prompts[0004]")];

	NSInteger panelResponse =
	[panel runModalForIdentities:(__bridge NSArray *)(identities)
						 message:TXTLS(@"TDCServerPropertiesSheet[1009][1]")];

	CFRelease(identities);

	if (panelResponse == NSModalResponseOK) {
		SecIdentityRef identity = [panel identity];

		[self saveClientCertificateWithIdentity:identity];

		[self updateClientCertificatePage];
	}

	self.clientCertificateSelectCertificatePanel = nil;
}

#pragma mark -
#pragma mark Redundancy

- (void)editSeverEndpoints:(id)sender
{
	TDCServerEndpointListSheet *sheet = [TDCServerEndpointListSheet new];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet startWithServerList:self.serverList];

	self.serverEndpointSheet = sheet;
}

- (void)serverEndpointListSheet:(TDCServerEndpointListSheet *)ender onOk:(NSArray<IRCServer *> *)serverList
{
	[self.serverListArrayController removeAllArrangedObjects];

	[self.serverListArrayController addObjects:serverList];

	[self loadPrimaryServerEndpoint];
}

- (void)serverEndpointListSheetWillClose:(TDCServerEndpointListSheet *)sender
{
	self.serverEndpointSheet = nil;
}

- (void)rebuildMutableServerEndpointList:(id)sender
{
	NSParameterAssert(sender != nil);

	if (self.populatingPrimaryServer) {
		return;
	}

	IRCServer *server = self.serverList.firstObject;

	IRCServerMutable *serverMutable = nil;

	if (server == nil) {
		serverMutable = [IRCServerMutable new];
	} else {
		serverMutable = [server mutableCopy];
	}

	{
		NSString *serverAddress = self.serverAddressComboBox.value;

		IRCNetwork *serverAddressNetwork = [self.networkList networkNamed:serverAddress];

		if (serverAddressNetwork) {
			serverMutable.serverAddress = serverAddressNetwork.serverAddress;
		} else {
			serverMutable.serverAddress = serverAddress.lowercaseString;
		}
	}

	serverMutable.serverPort = self.serverPortTextField.integerValue;

	serverMutable.prefersSecuredConnection = (self.prefersSecuredConnectionCheck.state == NSOnState);

	serverMutable.serverPassword = self.serverPasswordTextField.trimmedStringValue;

	server = [serverMutable copy];

	if (self.serverList.count == 0) {
		[self.serverListArrayController addObject:server];
	} else {
		[self.serverListArrayController replaceObjectAtArrangedObjectIndex:0 withObject:server];
	}
}

- (void)rebuildMutableServerEndpointListIfNeeded:(id)sender
{
	NSParameterAssert(sender != nil);

	/* We only want to rebuild the IRCServer at index 0 when the
	 user changes it. This method is invoked whenever something
	 changes related to that server. If it was not changed while
	 the server endpoint sheet was open, then we must update the
	 mutable server list to include the change. */
	if (self.serverEndpointSheet != nil) {
		return;
	}

	[self rebuildMutableServerEndpointList:sender];
}

#pragma mark -
#pragma mark Highlight Actions

- (void)addHighlight:(id)sender
{
	TDCHighlightEntrySheet *sheet =
	[[TDCHighlightEntrySheet alloc] initWithConfig:nil];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet startWithChannels:self.channelList];

	self.highlightSheet = sheet;
}

- (void)editHighlight:(id)sender
{
	NSInteger selectedRow = self.highlightsTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	IRCHighlightMatchCondition *config = self.highlightList[selectedRow];

	TDCHighlightEntrySheet *sheet =
	[[TDCHighlightEntrySheet alloc] initWithConfig:config];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet startWithChannels:self.channelList];

	self.highlightSheet = sheet;
}

- (void)highlightEntrySheet:(TDCHighlightEntrySheet *)sender onOk:(IRCHighlightMatchCondition *)config
{
	NSUInteger entryIndex =
	[self.highlightList indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
		if ([[object uniqueIdentifier] isEqualToString:config.uniqueIdentifier]) {
			return YES;
		} else {
			return NO;
		}
	}];

	if (entryIndex == NSNotFound) {
		[self.highlightListArrayController addObject:config];
	} else {
		[self.highlightListArrayController replaceObjectAtArrangedObjectIndex:entryIndex withObject:config];
	}
}

- (void)highlightEntrySheetWillClose:(TDCHighlightEntrySheet *)sender
{
	self.highlightSheet = nil;
}

- (void)deleteHighlight:(id)sender
{
	NSInteger selectedRow = self.highlightsTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	[self.highlightListArrayController removeObjectAtArrangedObjectIndex:selectedRow];

	NSUInteger listCount = self.highlightList.count;

	if (listCount > 0) {
		if (listCount <= selectedRow) {
			[self.highlightsTable selectItemAtIndex:(listCount - 1)];
		} else {
			[self.highlightsTable selectItemAtIndex:selectedRow];
		}
	}
}

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
	TDCChannelPropertiesSheet *sheet =
	[TDCChannelPropertiesSheet new];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet start];

	self.channelSheet = sheet;
}

- (void)editChannel:(id)sender
{
	NSInteger selectedRow = self.channelListTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	IRCChannelConfig *config = self.channelList[selectedRow];

	TDCChannelPropertiesSheet *sheet =
	[[TDCChannelPropertiesSheet alloc] initWithConfig:config];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet start];

	self.channelSheet = sheet;
}

- (void)channelPropertiesSheet:(TDCChannelPropertiesSheet *)sender onOk:(IRCChannelConfig *)config
{
	NSUInteger entryIndex =
	[self.channelList indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
		if ([[object uniqueIdentifier] isEqualToString:config.uniqueIdentifier]) {
			return YES;
		} else {
			return NO;
		}
	}];

	[self clearChannelListPredicate];

	if (entryIndex == NSNotFound) {
		[self.channelListArrayController addObject:config];
	} else {
		[self.channelListArrayController replaceObjectAtArrangedObjectIndex:entryIndex withObject:config];
	}

	[self setChannelListPredicate];
}

- (void)channelPropertiesSheetWillClose:(TDCChannelPropertiesSheet *)sender
{
	self.channelSheet = nil;
}

- (void)deleteChannel:(id)sender
{
	NSInteger selectedRow = self.channelListTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	[self clearChannelListPredicate];

	[self.channelListArrayController removeObjectAtArrangedObjectIndex:selectedRow];

	[self setChannelListPredicate];

	NSUInteger listCount = self.channelList.count;

	if (listCount > 0) {
		if (listCount <= selectedRow) {
			[self.channelListTable selectItemAtIndex:(listCount - 1)];
		} else {
			[self.channelListTable selectItemAtIndex:selectedRow];
		}
	}
}

#pragma mark -
#pragma mark Address Book Actions

- (void)showAddAddressBookEntryMenu:(id)sender
{
	[self.addAddressBookEntryMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:sender];
}

- (void)addIgnoreAddressBookEntry
{
	[self addIgnoreAddressBookEntryWithHostmask:nil];
}

- (void)addIgnoreAddressBookEntryWithHostmask:(nullable NSString *)hostmask
{
	TDCAddressBookSheet *sheet = nil;

	if (hostmask) {
		IRCAddressBookEntry *config =
		[IRCAddressBookEntry newIgnoreEntryForHostmask:hostmask];

		sheet = [[TDCAddressBookSheet alloc] initWithConfig:config];
	} else {
		sheet = [[TDCAddressBookSheet alloc] initWithEntryType:IRCAddressBookIgnoreEntryType];
	}

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet start];

	self.addressBookSheet = sheet;
}

- (void)addUserTrackingAddressBookEntry
{
	TDCAddressBookSheet *sheet =
	[[TDCAddressBookSheet alloc] initWithEntryType:IRCAddressBookUserTrackingEntryType];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet start];

	self.addressBookSheet = sheet;
}

- (void)addAddressBookEntry:(id)sender
{
	if ([sender tag] == 3) {
		[self addIgnoreAddressBookEntry];
	} else if ([sender tag] == 4) {
		[self addUserTrackingAddressBookEntry];
	}
}

- (void)editAddressBookEntryWithObject:(IRCAddressBookEntry *)entryObject
{
	NSInteger tableIndex = [self.addressBookList indexOfObject:entryObject];

	if (tableIndex == NSNotFound) {
		return;
	}

	[self.addressBookTable selectItemAtIndex:tableIndex];

	[self editAddressBookEntry:nil];
}

- (void)editAddressBookEntry:(id)sender
{
	NSInteger selectedRow = self.addressBookTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	IRCAddressBookEntry *config = self.addressBookList[selectedRow];

	TDCAddressBookSheet *sheet =
	[[TDCAddressBookSheet alloc] initWithConfig:config];

	sheet.delegate = self;

	sheet.window = self.sheet;

	[sheet start];

	self.addressBookSheet = sheet;
}

- (void)addressBookSheet:(TDCAddressBookSheet *)sender onOk:(IRCAddressBookEntry *)config
{
	NSUInteger entryIndex =
	[self.addressBookList indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
		if ([[object uniqueIdentifier] isEqualToString:config.uniqueIdentifier]) {
			return YES;
		} else {
			return NO;
		}
	}];

	if (entryIndex == NSNotFound) {
		[self.addressBookArrayController addObject:config];
	} else {
		[self.addressBookArrayController replaceObjectAtArrangedObjectIndex:entryIndex withObject:config];
	}
}

- (void)addressBookSheetWillClose:(TDCAddressBookSheet *)sender
{
	self.addressBookSheet = nil;
}

- (void)deleteAddressBookEntry:(id)sender
{
	NSInteger selectedRow = self.addressBookTable.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	[self.addressBookArrayController removeObjectAtArrangedObjectIndex:selectedRow];

	NSUInteger listCount = self.addressBookList.count;

	if (listCount > 0) {
		if (listCount <= selectedRow) {
			[self.addressBookTable selectItemAtIndex:(listCount - 1)];
		} else {
			[self.addressBookTable selectItemAtIndex:selectedRow];
		}
	}
}

#pragma mark -
#pragma mark NSTableView Delegate

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *columnId = tableColumn.identifier;

	if (tableView == self.channelListTable)
	{
		IRCChannelConfig *config = self.channelList[row];

		if ([columnId isEqualToString:@"name"])
		{
			return config.channelName;
		}
		else if ([columnId isEqualToString:@"pass"])
		{
			NSString *secretKeyValue = config.secretKey;

			if (secretKeyValue) {
				return secretKeyValue;
			}

			return @"";
		}
		else if ([columnId isEqualToString:@"join"])
		{
			return @(config.autoJoin);
		}
	}
	else if (tableView == self.highlightsTable)
	{
		IRCHighlightMatchCondition *config = self.highlightList[row];

		if ([columnId isEqualToString:@"keyword"])
		{
			return config.matchKeyword;
		}
		else if ([columnId isEqualToString:@"channel"])
		{
			NSString *matchChannelId = config.matchChannelId;

			if (matchChannelId) {
				for (IRCChannelConfig *channel in self.channelList) {
					if (NSObjectsAreEqual(channel.uniqueIdentifier, matchChannelId) == NO) {
						continue;
					}

					return channel.channelName;
				}
			}

			return TXTLS(@"TDCServerPropertiesSheet[1003]");
		}
		else if ([columnId isEqualToString:@"type"])
		{
			if (config.matchIsExcluded) {
				return TXTLS(@"TDCServerPropertiesSheet[1004]");
			} else {
				return TXTLS(@"TDCServerPropertiesSheet[1005]");
			}
		}
	}
	else if (tableView == self.addressBookTable)
	{
		IRCAddressBookEntry *config = self.addressBookList[row];

		if ([columnId isEqualToString:@"hostmask"])
		{
			return config.hostmask;
		}
		else if ([columnId isEqualToString:@"type"])
		{
			if (config.entryType == IRCAddressBookIgnoreEntryType) {
				return TXTLS(@"TDCServerPropertiesSheet[1000]");
			} else {
				return TXTLS(@"TDCServerPropertiesSheet[1001]");
			}
		}
	}

	return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(nullable id)object forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *columnId = tableColumn.identifier;

	if (tableView == self.channelListTable)
	{
		IRCChannelConfigMutable *config = [self.channelList[row] mutableCopy];

		if ([columnId isEqualToString:@"join"]) {
			config.autoJoin = [object boolValue];
		}

		[self.channelListArrayController replaceObjectAtArrangedObjectIndex:row withObject:[config copy]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNote
{
	NSTableView *tableView = aNote.object;

	if (tableView == self.channelListTable) {
		[self updateChannelListPage];
	} else if (tableView == self.highlightsTable) {
		[self updateHighlightsPage];
	} else if (tableView == self.addressBookTable) {
		[self updateAddressBookPage];
	}
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == self.channelListTable) {
		[self editChannel:sender];
	} else if (sender == self.highlightsTable) {
		[self editHighlight:sender];
	} else if (sender == self.addressBookTable) {
		[self editAddressBookEntry:sender];
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
	NSData *draggedData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];

	[pasteboard declareTypes:@[_tableDragToken] owner:self];

	[pasteboard setData:draggedData forType:_tableDragToken];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	return NSDragOperationGeneric;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];

	NSData *draggedData = [pasteboard dataForType:_tableDragToken];

	NSIndexSet *draggedRowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:draggedData];

	NSUInteger draggedRowIndex = draggedRowIndexes.firstIndex;

	if (tableView == self.channelListTable) {
		[self clearChannelListPredicate];

		[self.channelListArrayController moveObjectAtArrangedObjectIndex:draggedRowIndex toIndex:row];

		[self setChannelListPredicate];
	} else if (tableView == self.highlightsTable) {
		[self.highlightListArrayController moveObjectAtArrangedObjectIndex:draggedRowIndex toIndex:row];
	} else if (tableView == self.addressBookTable) {
		[self.addressBookArrayController moveObjectAtArrangedObjectIndex:draggedRowIndex toIndex:row];
	}

	return YES;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	self.addressBookTable.delegate = nil;
	self.channelListTable.delegate = nil;
	self.highlightsTable.delegate = nil;

	self.addressBookTable.dataSource = nil;
	self.channelListTable.dataSource = nil;
	self.highlightsTable.dataSource = nil;

	[self.addressBookTable unregisterDraggedTypes];
	[self.channelListTable unregisterDraggedTypes];
	[self.highlightsTable unregisterDraggedTypes];

	[self.sheet makeFirstResponder:nil];

	if ([self.delegate respondsToSelector:@selector(serverPropertiesSheetWillClose:)]) {
		[self.delegate serverPropertiesSheetWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
