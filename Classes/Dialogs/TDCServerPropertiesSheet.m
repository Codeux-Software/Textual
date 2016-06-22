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

#define _tableRowType		@"row"
#define _tableRowTypes		[NSArray arrayWithObject:_tableRowType]

#define _preferencePaneViewFramePadding				47

#define _forcedPreferencePaneViewFrameHeight		304
#define _forcedPreferencePaneViewFrameWidth			529

@interface TDCServerPropertiesSheet ()
@property (nonatomic, copy) NSArray *navigationTreeMatrix;
@property (nonatomic, copy) NSDictionary *encodingList;
@property (nonatomic, copy) NSDictionary *serverList;
@property (nonatomic, weak) IBOutlet NSButton *addChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *addHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *addIgnoreButton;
@property (nonatomic, weak) IBOutlet NSButton *autoConnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *autoDisconnectOnSleepCheck;
@property (nonatomic, weak) IBOutlet NSButton *autoReconnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *autojoinWaitsForNickServCheck;
@property (nonatomic, weak) IBOutlet NSButton *prefersSecuredConnectionCheck;
@property (nonatomic, weak) IBOutlet NSButton *deleteChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteIgnoreButton;
@property (nonatomic, weak) IBOutlet NSButton *disconnectOnReachabilityChangeCheck;
@property (nonatomic, weak) IBOutlet NSButton *editChannelButton;
@property (nonatomic, weak) IBOutlet NSButton *editHighlightButton;
@property (nonatomic, weak) IBOutlet NSButton *editIgnoreButton;
@property (nonatomic, weak) IBOutlet NSButton *excludedFromCloudSyncingCheck;
@property (nonatomic, weak) IBOutlet NSButton *setInvisibleModeOnConnectCheck;
@property (nonatomic, weak) IBOutlet NSButton *pongTimerCheck;
@property (nonatomic, weak) IBOutlet NSButton *performDisconnectOnPongTimerCheck;
@property (nonatomic, weak) IBOutlet NSButton *connectionPrefersIPv6heck;
@property (nonatomic, weak) IBOutlet NSButton *connectionPrefersModernCiphersCheck;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateChangeCertificateButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateMD5FingerprintCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateResetCertificateButton;
@property (nonatomic, weak) IBOutlet NSButton *clientCertificateSHA1FingerprintCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *validateServerCertificateChainCheck;
@property (nonatomic, weak) IBOutlet NSButton *zncIgnoreConfiguredAutojoinCheck;
@property (nonatomic, weak) IBOutlet NSButton *zncIgnorePlaybackNotificationsCheck;
@property (nonatomic, weak) IBOutlet NSImageView *erroneousInputErrorImageView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *primaryEncodingButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *proxyTypeButton;
@property (nonatomic, weak) IBOutlet NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, weak) IBOutlet NSSlider *floodControlMessageCountSlider;
@property (nonatomic, weak) IBOutlet NSTextField *alternateNicknamesTextField;
@property (nonatomic, weak) IBOutlet NSTextField *erroneousInputErrorTextField;
@property (nonatomic, weak) IBOutlet NSTextField *nicknamePasswordTextField;
@property (nonatomic, weak) IBOutlet NSTextField *proxyPasswordTextField;
@property (nonatomic, weak) IBOutlet NSTextField *proxyUsernameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *serverPasswordTextField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateCommonNameField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateMD5FingerprintField;
@property (nonatomic, weak) IBOutlet NSTextField *clientCertificateSHA1FingerprintField;
@property (nonatomic, weak) IBOutlet TVCAnimatedContentNavigationOutlineView *navigationOutlineview;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *channelTable;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *highlightsTable;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *ignoreTable;
@property (nonatomic, weak) IBOutlet TVCTextFieldComboBoxWithValueValidation *serverAddressComboBox;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *awayNicknameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *nicknameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *normalLeavingCommentTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *proxyAddressTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *proxyPortTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *realNameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *connectionNameTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *serverPortTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *sleepModeQuitMessageTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *usernameTextField;
@property (nonatomic, strong) IBOutlet NSMenu *addIgnoreMenu;
@property (nonatomic, strong) IBOutlet NSView *contentViewAddressBook;
@property (nonatomic, strong) IBOutlet NSView *contentViewAutojoin;
@property (nonatomic, strong) IBOutlet NSView *contentViewConnectCommands;
@property (nonatomic, strong) IBOutlet NSView *contentViewEncoding;
@property (nonatomic, strong) IBOutlet NSView *contentViewDisconnectMessages;
@property (nonatomic, strong) IBOutlet NSView *contentViewFloodControl;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneral;
@property (nonatomic, strong) IBOutlet NSView *contentViewHighlights;
@property (nonatomic, strong) IBOutlet NSView *contentViewIdentity;
@property (nonatomic, strong) IBOutlet NSView *contentViewNetworkSocket;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServer;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerInputView;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerSystemSocksView;
@property (nonatomic, strong) IBOutlet NSView *contentViewProxyServerTorBrowserView;
@property (nonatomic, strong) IBOutlet NSView *contentViewClientCertificate;
@property (nonatomic, strong) IBOutlet NSView *contentViewZncBouncer;
@property (nonatomic, strong) NSMutableArray *mutableChannelList;
@property (nonatomic, strong) NSMutableArray *mutableHighlightList;
@property (nonatomic, strong) NSMutableArray *mutableIgnoreList;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;
@property (nonatomic, strong) TDCHighlightEntrySheet *highlightSheet;
@property (nonatomic, strong) TDChannelPropertiesSheet *channelSheet;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextView *connectCommandsField;
@property (nonatomic, assign) NSInteger floodControlDelayTimerSliderTempValue;
@property (nonatomic, assign) NSInteger floodControlMessageCountSliderTempValue;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@property (nonatomic, assign) BOOL requestCloudDeletionOnClose;
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

- (IBAction)addIgnore:(id)sender;
- (IBAction)editIgnore:(id)sender;
- (IBAction)deleteIgnore:(id)sender;

- (IBAction)showAddIgnoreMenu:(id)sender;

- (IBAction)useSSLCheckChanged:(id)sender;

- (IBAction)onClientCertificateResetRequested:(id)sender;
- (IBAction)onClientCertificateChangeRequested:(id)sender;
- (IBAction)onClientCertificateFingerprintSHA1CopyRequested:(id)sender;
- (IBAction)onClientCertificateFingerprintMD5CopyRequested:(id)sender;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TDCServerPropertiesSheet

- (instancetype)init
{
	if ((self = [super init])) {
		/* Load our views. */
		[RZMainBundle() loadNibNamed:@"TDCServerPropertiesSheet" owner:self topLevelObjects:nil];
		
		/* Load the list of available IRC networks. */
		self.serverList = [TPCResourceManager loadContentsOfPropertyListInResources:@"IRCNetworks"];

		/* Populate the navigation tree. */
		[self populateTabViewList];
		
		/* Populate the server address field with the IRC network list. */
		NSArray *unsortedServerListKeys = [self.serverList allKeys];

		/* We are sorting keys. They are NSString values. */
		/* Sort without case so that "freenode" is under servers with a capital F. */
		NSArray *sortedServerListKeys = [unsortedServerListKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
		}];
		
		for (NSString *key in sortedServerListKeys) {
			[self.serverAddressComboBox addItemWithObjectValue:key];
		}

		/* Create temporary stores. */
		self.mutableChannelList = [NSMutableArray array];
		self.mutableHighlightList = [NSMutableArray array];
		self.mutableIgnoreList = [NSMutableArray array];
		
		/* Connect commands text box better font. */
		NSFont *goodFont = [NSFont fontWithName:@"Lucida Grande" size:13.0];
		
		[self.connectCommandsField setTextContainerInset:NSMakeSize(1, 3)];
		[self.connectCommandsField setFont:goodFont];
		
		/* Build how input is validated. */
		/* Away nickname. */
		[self.awayNicknameTextField setTextDidChangeCallback:self];
		
		[self.awayNicknameTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.awayNicknameTextField setStringValueIsInvalidOnEmpty:NO];
		[self.awayNicknameTextField setStringValueIsTrimmed:YES];
		[self.awayNicknameTextField setStringValueUsesOnlyFirstToken:YES];
		
		[self.awayNicknameTextField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isHostmaskNickname];
		}];
		
		/* Nickname. */
		[self.nicknameTextField setTextDidChangeCallback:self];
		
		[self.nicknameTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.nicknameTextField setStringValueIsInvalidOnEmpty:YES];
		[self.nicknameTextField setStringValueIsTrimmed:YES];
		[self.nicknameTextField setStringValueUsesOnlyFirstToken:YES];
		
		[self.nicknameTextField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isHostmaskNickname];
		}];
		
		/* Username. */
		[self.usernameTextField setTextDidChangeCallback:self];
		
		[self.usernameTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.usernameTextField setStringValueIsInvalidOnEmpty:YES];
		[self.usernameTextField setStringValueIsTrimmed:YES];
		[self.usernameTextField setStringValueUsesOnlyFirstToken:YES];
		
		[self.usernameTextField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isHostmaskUsername];
		}];

		/* Real name. */
		[self.realNameTextField setTextDidChangeCallback:self];
		
		[self.realNameTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.realNameTextField setStringValueIsInvalidOnEmpty:YES];
		[self.realNameTextField setStringValueIsTrimmed:YES];
		[self.realNameTextField setStringValueUsesOnlyFirstToken:NO];
		
		/* Normal leaving comment. */
		[self.normalLeavingCommentTextField setTextDidChangeCallback:self];
		
		[self.normalLeavingCommentTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.normalLeavingCommentTextField setStringValueIsInvalidOnEmpty:NO];
		[self.normalLeavingCommentTextField setStringValueIsTrimmed:YES];
		[self.normalLeavingCommentTextField setStringValueUsesOnlyFirstToken:NO];
		
		[self.normalLeavingCommentTextField setValidationBlock:^BOOL(NSString *currentValue) {
			if ([currentValue containsCharactersFromCharacterSet:[NSCharacterSet newlineCharacterSet]]) {
				return NO;
			}
			
			return ([currentValue length] < 390);
		}];
		
		/* Sleep mode leaving comment. */
		[self.sleepModeQuitMessageTextField setTextDidChangeCallback:self];
		
		[self.sleepModeQuitMessageTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.sleepModeQuitMessageTextField setStringValueIsInvalidOnEmpty:NO];
		[self.sleepModeQuitMessageTextField setStringValueIsTrimmed:YES];
		[self.sleepModeQuitMessageTextField setStringValueUsesOnlyFirstToken:NO];
		
		[self.sleepModeQuitMessageTextField setValidationBlock:^BOOL(NSString *currentValue) {
			if ([currentValue containsCharactersFromCharacterSet:[NSCharacterSet newlineCharacterSet]]) {
				return NO;
			}
			
			return ([currentValue length] < 390);
		}];
		
		/* Connection name. */
		[self.connectionNameTextField setTextDidChangeCallback:self];
		
		[self.connectionNameTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.connectionNameTextField setStringValueIsInvalidOnEmpty:YES];
		[self.connectionNameTextField setStringValueIsTrimmed:YES];
		[self.connectionNameTextField setStringValueUsesOnlyFirstToken:NO];
		
		/* Server address. */
		[self.serverAddressComboBox setTextDidChangeCallback:self];
		
		[self.serverAddressComboBox setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.serverAddressComboBox setStringValueIsInvalidOnEmpty:YES];
		[self.serverAddressComboBox setStringValueIsTrimmed:YES];
		[self.serverAddressComboBox setStringValueUsesOnlyFirstToken:YES];

		[self.serverAddressComboBox setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isValidInternetAddress];
		}];

		/* Server port. */
		[self.serverPortTextField setTextDidChangeCallback:self];
		
		[self.serverPortTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.serverPortTextField setStringValueIsInvalidOnEmpty:YES];
		[self.serverPortTextField setStringValueIsTrimmed:YES];
		[self.serverPortTextField setStringValueUsesOnlyFirstToken:NO];
		
		[self.serverPortTextField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isValidInternetPort];
		}];
		
		/* Proxy address. */
		[self.proxyAddressTextField setTextDidChangeCallback:self];
		
		[self.proxyAddressTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.proxyAddressTextField setStringValueIsInvalidOnEmpty:NO];
		[self.proxyAddressTextField setStringValueIsTrimmed:YES];
		[self.proxyAddressTextField setStringValueUsesOnlyFirstToken:YES];
		
		[self.proxyAddressTextField setPerformValidationWhenEmpty:YES];
		
		[self.proxyAddressTextField setValidationBlock:^BOOL(NSString *currentValue) {
			NSInteger proxyType = [self.proxyTypeButton selectedTag];
			
			if (proxyType == IRCConnectionSocketSocks4ProxyType ||
				proxyType == IRCConnectionSocketSocks5ProxyType ||
				proxyType == IRCConnectionSocketHTTPProxyType ||
				proxyType == IRCConnectionSocketHTTPSProxyType)
			{
				return [currentValue isValidInternetAddress];
			} else {
				return YES;
			}
		}];
		
		/* Proxy port. */
		[self.proxyPortTextField setTextDidChangeCallback:self];
		
		[self.proxyPortTextField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.proxyPortTextField setStringValueIsInvalidOnEmpty:NO];
		[self.proxyPortTextField setStringValueIsTrimmed:YES];
		[self.proxyPortTextField setStringValueUsesOnlyFirstToken:NO];
		
		[self.proxyPortTextField setPerformValidationWhenEmpty:YES];

		[self.proxyPortTextField setDefualtValue:[NSString stringWithInteger:IRCConnectionDefaultProxyPort]];
		
		[self.proxyPortTextField setValidationBlock:^BOOL(NSString *currentValue) {
			NSInteger proxyType = [self.proxyTypeButton selectedTag];
			
			if (proxyType == IRCConnectionSocketSocks4ProxyType ||
				proxyType == IRCConnectionSocketSocks5ProxyType ||
				proxyType == IRCConnectionSocketHTTPProxyType ||
				proxyType == IRCConnectionSocketHTTPSProxyType)
			{
				return [currentValue isValidInternetPort];
			} else {
				return YES;
			}
		}];
	}
	
	return self;
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
		]
	}];

	[self.navigationOutlineview setNavigationTreeMatrix:navigationTreeMatrix];
	
	[self.navigationOutlineview setContentViewPadding:_preferencePaneViewFramePadding];
	[self.navigationOutlineview setContentViewPreferredWidth:_forcedPreferencePaneViewFrameWidth];
	[self.navigationOutlineview setContentViewPreferredHeight:_forcedPreferencePaneViewFrameHeight];
	
	[self.navigationOutlineview reloadData];
	
	[self.navigationOutlineview expandItem:navigationTreeMatrix[0]];
	[self.navigationOutlineview expandItem:navigationTreeMatrix[1]];
	[self.navigationOutlineview expandItem:navigationTreeMatrix[2]];
}

- (void)populateEncodings
{
	[self.primaryEncodingButton removeAllItems];
	[self.fallbackEncodingButton removeAllItems];
	
	/* Build list of encodings. */
	self.encodingList = [NSString supportedStringEncodingsWithTitle:NO];
	
	NSArray *encodingNames = [self.encodingList sortedDictionaryKeys];
	
	/* What we are basically doing now is sorting all the encodings, then removing
	 UTF-8 from the sorted list and inserting it at the top of the list. */
	NSString *utf8title = [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding];
	
	NSMutableArray *encodingAdditions = [encodingNames mutableCopy];
	
	[encodingAdditions removeObject:utf8title];
	
	[self.primaryEncodingButton addItemWithTitle:utf8title];
	[self.fallbackEncodingButton addItemWithTitle:utf8title];
	
	/* Add the encodings to the popup list. This for loop will find the first
	 parentheses opening and compare everything before it to the one found for
	 the previous encoding. If the prefix has changed, then a separator is
	 inserted. This groups the encodings.
	 
	 We do this two times. The first time setups up preferred encodings at
	 the top of the list. The next handles everything else. */
	NSArray *favoredEncodings = @[@"Unicode", @"Western", @"Central European"];
	
	[self populateEncodingPopup:encodingAdditions preferredEncodings:favoredEncodings ignoreFavored:NO];

	if ([RZUserDefaults() boolForKey:@"Server Properties Window Sheet -> Include Advanced Encodings"]) {
		[self populateEncodingPopup:encodingAdditions preferredEncodings:favoredEncodings ignoreFavored:YES];
	}
}

- (void)populateEncodingPopup:(NSArray *)encodingAdditions preferredEncodings:(NSArray *)favoredEncodings ignoreFavored:(BOOL)favoredIgnored
{
	NSString *previosEncodingPrefix = nil;
	
	for (NSString *encodingTitle in encodingAdditions) {
		NSInteger parePos = [encodingTitle stringPosition:@" ("];
		
		if (parePos == -1) {
			continue;
		}
		
		NSString *encodingPrefix = [encodingTitle substringToIndex:parePos];
		
		if (favoredIgnored && [favoredEncodings containsObject:encodingPrefix]) {
			continue;
		} else if (favoredIgnored == NO && [favoredEncodings containsObject:encodingPrefix] == NO) {
			continue;
		}
		
		if ([encodingPrefix isEqualToString:previosEncodingPrefix] == NO) {
			[[self.primaryEncodingButton menu] addItem:[NSMenuItem separatorItem]];
			[[self.fallbackEncodingButton menu] addItem:[NSMenuItem separatorItem]];
			
			previosEncodingPrefix = encodingPrefix;
		}
		
		[self.primaryEncodingButton addItemWithTitle:encodingTitle];
		[self.fallbackEncodingButton addItemWithTitle:encodingTitle];
	}
}

#pragma mark -
#pragma mark Server List Factory

- (NSString *)nameMatchesServerInList:(NSString *)name
{
	for (NSString *key in self.serverList) {
		if ([name isEqualIgnoringCase:key]) {
			return key;
		}
	}
	
	return nil;
}

- (NSString *)hostFoundInServerList:(NSString *)hosto
{
	for (NSString *key in self.serverList) {
		NSString *host = self.serverList[key];
		
		if ([hosto isEqualIgnoringCase:host]) {
			return key;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start:(TDCServerPropertiesSheetNavigationSelection)viewToken withContext:(NSString *)context
{
	[self.channelTable setTarget:self];
	[self.channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[self.channelTable registerForDraggedTypes:_tableRowTypes];
	
	[self.ignoreTable setTarget:self];
	[self.ignoreTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	
	[self.highlightsTable setTarget:self];
	[self.highlightsTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	
	[self populateEncodings];
	
	[self load];
	
	if (viewToken == TDCServerPropertiesSheetFloodControlNavigationSelection) {
		[self showWithDefaultView:_navigationIndexForFloodControl];
	} else if (viewToken == TDCServerPropertiesSheetAddressBookNavigationSelection) {
		[self showWithDefaultView:_navigationIndexForAddressBook];
	} else if (viewToken == TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection) {
		[self showWithDefaultView:_navigationIndexForAddressBook];

		IRCAddressBookEntry *newIgnore = [IRCAddressBookEntry newIgnoreEntry];

		if (context) {
			newIgnore.hostmask = context;
		}

		self.ignoreSheet = [TDCAddressBookSheet new];
		
		self.ignoreSheet.delegate = self;
		self.ignoreSheet.window = self.sheet;

		self.ignoreSheet.newItem = YES;

		self.ignoreSheet.ignore = newIgnore;

		[self.ignoreSheet start];
	} else {
		[self showWithDefaultView:_navigationIndexForGeneral];
	}

	[self addConfigurationDidChangeObserver];
}

- (void)showWithDefaultView:(NSInteger)viewIndex
{
	[self.navigationOutlineview startAtSelectionIndex:viewIndex];

	[self startSheet];
}

- (void)closeChildSheets
{
	if (self.channelSheet) {
		[self.channelSheet cancel:nil];
	} else if (self.highlightSheet) {
		[self.highlightSheet cancel:nil];
	} else if (self.ignoreSheet) {
		[self.ignoreSheet cancel:nil];
	}
}

- (void)close
{
	[self cancel:nil];
}

- (IRCClient *)clientObjectByProperties
{
	return [worldController() findClientById:self.clientID];
}

- (void)addConfigurationDidChangeObserver
{
	IRCClient *client = [self clientObjectByProperties];

	if (client) {
		[RZNotificationCenter() addObserver:self
								   selector:@selector(underlyingConfigurationChanged:)
									   name:IRCClientConfigurationWasUpdatedNotification
									 object:client];
	}
}

- (void)removeConfigurationDidChangeObserver
{
	IRCClient *client = [self clientObjectByProperties];

	if (client) {
		[RZNotificationCenter() removeObserver:self
										  name:IRCClientConfigurationWasUpdatedNotification
										object:client];
	}
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	NSWindow *sheetWindow = self.sheet;
	
	if (self.channelSheet) {
		sheetWindow = [self.channelSheet sheet];
	} else if (self.highlightSheet) {
		sheetWindow = [self.highlightSheet sheet];
	} else if (self.ignoreSheet) {
		sheetWindow = [self.ignoreSheet sheet];
	}

	IRCClient *client = [notification object];

	[TLOPopupPrompts sheetWindowWithWindow:sheetWindow
									  body:TXTLS(@"Prompts[1116][2]")
									 title:TXTLS(@"Prompts[1116][1]")
							 defaultButton:TXTLS(@"Prompts[0001]")
						   alternateButton:TXTLS(@"Prompts[0002]")
							   otherButton:nil
							suppressionKey:nil
						   suppressionText:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnPrimaryType) {
								   [self closeChildSheets];
								   [self endSheet];

								   [self setConfig:[client copyOfStoredConfig]];

								   [self load];
								   [self showWithDefaultView:_navigationIndexForGeneral];
							   }
						   }];
}

- (void)load
{
	/* General */
	[self.connectionNameTextField setStringValue:self.config.connectionName];
	
	NSString *networkName = [self hostFoundInServerList:self.config.serverAddress];
	
	if (networkName == nil) {
		[self.serverAddressComboBox setStringValue:self.config.serverAddress];
	} else {
		[self.serverAddressComboBox setStringValue:networkName];
	}

	[self.serverPortTextField setIntegerValue:self.config.serverPort];

	[self.prefersSecuredConnectionCheck setState:self.config.prefersSecuredConnection];

	[self.serverPasswordTextField setStringValue:self.config.serverPassword];

	[self.autoConnectCheck setState:self.config.autoConnect];
	[self.autoReconnectCheck setState:self.config.autoReconnect];
	[self.autoDisconnectOnSleepCheck setState:self.config.autoSleepModeDisconnect];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[self.excludedFromCloudSyncingCheck setState:self.config.excludedFromCloudSyncing];
#endif

	/* ZNC Bouncer */
	[self.zncIgnoreConfiguredAutojoinCheck setState:self.config.zncIgnoreConfiguredAutojoin];
	[self.zncIgnorePlaybackNotificationsCheck setState:self.config.zncIgnorePlaybackNotifications];

	/* Network Socket */
	[self.connectionPrefersIPv6heck setState:self.config.connectionPrefersIPv6];

	[self.pongTimerCheck setState:self.config.performPongTimer];
	[self.performDisconnectOnPongTimerCheck setState:self.config.performDisconnectOnPongTimer];

	[self.disconnectOnReachabilityChangeCheck setState:self.config.performDisconnectOnReachabilityChange];

	[self.validateServerCertificateChainCheck setState:self.config.validateServerCertificateChain];

	[self.connectionPrefersModernCiphersCheck setState:self.config.connectionPrefersModernCiphers];

	/* Identity */
	if (NSObjectIsEmpty(self.config.nickname)) {
		[self.nicknameTextField setStringValue:[TPCPreferences defaultNickname]];
	} else {
		[self.nicknameTextField setStringValue:self.config.nickname];
	}

	[self.awayNicknameTextField setStringValue:self.config.awayNickname];

	if (NSObjectIsEmpty(self.config.username)) {
		[self.usernameTextField setStringValue:[TPCPreferences defaultUsername]];
	} else {
		[self.usernameTextField setStringValue:self.config.username];
	}

	if (NSObjectIsEmpty(self.config.realName)) {
		[self.realNameTextField setStringValue:[TPCPreferences defaultRealName]];
	} else {
		[self.realNameTextField setStringValue:self.config.realName];
	}

	NSString *nicknames = [self.config.alternateNicknames componentsJoinedByString:NSStringWhitespacePlaceholder];
		
	[self.alternateNicknamesTextField setStringValue:nicknames];

	[self.nicknamePasswordTextField setStringValue:self.config.nicknamePassword];

	[self.autojoinWaitsForNickServCheck setState:self.config.autojoinWaitsForNickServ];

	/* Messages */
	[self.normalLeavingCommentTextField setStringValue:self.config.normalLeavingComment];
	[self.sleepModeQuitMessageTextField setStringValue:self.config.sleepModeLeavingComment];

	/* Encoding */
	NSString *primaryEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.primaryEncoding)];
	NSString *fallbackEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.fallbackEncoding)];
	
	[self.primaryEncodingButton selectItemWithTitle:primaryEncodingTitle];
	[self.fallbackEncodingButton selectItemWithTitle:fallbackEncodingTitle];

	/* Proxy Server */
	[self.proxyTypeButton selectItemWithTag:self.config.proxyType];
	[self.proxyAddressTextField setStringValue:self.config.proxyAddress];
	[self.proxyUsernameTextField setStringValue:self.config.proxyUsername];
	[self.proxyPasswordTextField setStringValue:self.config.proxyPassword];
	[self.proxyPortTextField setIntegerValue:self.config.proxyPort];

	/* Connect Commands */
	[self.setInvisibleModeOnConnectCheck setState:self.config.setInvisibleModeOnConnect];

	NSString *loginCommands = [self.config.loginCommands componentsJoinedByString:NSStringNewlinePlaceholder];
	
	[self.connectCommandsField setString:loginCommands];

	/* Flood Control */
	self.floodControlDelayTimerSliderTempValue = self.config.floodControlDelayTimerInterval;
	self.floodControlMessageCountSliderTempValue = self.config.floodControlMaximumMessages;

	/* Mutable Stores */
	[self.mutableChannelList setArray:self.config.channelList];
	[self.mutableHighlightList setArray:self.config.highlightList];
	[self.mutableIgnoreList setArray:self.config.ignoreList];
	
	/* Update window based on new configuration. */
	[self updateChannelsPage];
	[self updateConnectionPage];
	[self updateHighlightsPage];
	[self updateIgnoresPage];
	[self updateClientCertificatePage];

	[self proxyTypeChanged:nil];

	[self reloadChannelTable];
	[self reloadHighlightsTable];
	[self reloadIgnoreTable];
}

- (void)save
{
	/* General */
	self.config.connectionName = [self.connectionNameTextField value];

	NSString *serverAddressComboBoxValue = [self.serverAddressComboBox value];

	NSString *serverAddressMatchedHost = [self nameMatchesServerInList:serverAddressComboBoxValue];

	if (serverAddressMatchedHost == nil) {
		self.config.serverAddress = [serverAddressComboBoxValue lowercaseString];
	} else {
		self.config.serverAddress = self.serverList[serverAddressMatchedHost];
	}

	self.config.serverPort = [self.serverPortTextField integerValue];

	self.config.prefersSecuredConnection = [self.prefersSecuredConnectionCheck state];

	self.config.serverPassword = [self.serverPasswordTextField trimmedStringValue];

	self.config.autoConnect	= [self.autoConnectCheck state];
	self.config.autoReconnect = [self.autoReconnectCheck state];
	self.config.autoSleepModeDisconnect = [self.autoDisconnectOnSleepCheck state];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	self.config.excludedFromCloudSyncing = [self.excludedFromCloudSyncingCheck state];
#endif

	/* ZNC Bouncer */
	self.config.zncIgnoreConfiguredAutojoin = [self.zncIgnoreConfiguredAutojoinCheck state];
	self.config.zncIgnorePlaybackNotifications = [self.zncIgnorePlaybackNotificationsCheck state];
	
	/* Network Socket */
	self.config.connectionPrefersIPv6 = [self.connectionPrefersIPv6heck state];

	self.config.performPongTimer = [self.pongTimerCheck state];
	self.config.performDisconnectOnPongTimer = [self.performDisconnectOnPongTimerCheck state];

	self.config.performDisconnectOnReachabilityChange = [self.disconnectOnReachabilityChangeCheck state];

	self.config.validateServerCertificateChain = [self.validateServerCertificateChainCheck state];

	self.config.connectionPrefersModernCiphers = [self.connectionPrefersModernCiphersCheck state];

	/* Identity */
	self.config.nickname = [self.nicknameTextField value];
	self.config.username = [self.usernameTextField value];
	self.config.realName = [self.realNameTextField value];
	
	self.config.awayNickname = [self.awayNicknameTextField value];
	
	self.config.nicknamePassword = [self.nicknamePasswordTextField trimmedStringValue];

	self.config.autojoinWaitsForNickServ = [self.autojoinWaitsForNickServCheck state];

	/* Alternate nicknames. */
	NSString *alternateNicknames = [self.alternateNicknamesTextField stringValue];
	
	NSArray *alternateNicknameArray = [alternateNicknames componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSMutableArray *newAlternateNicknameList = [NSMutableArray array];
	
	for (NSString *s in alternateNicknameArray) {
		if ([s length] > 0) {
			[newAlternateNicknameList addObject:s];
		}
	}
	
	self.config.alternateNicknames = newAlternateNicknameList;

	/* Messages */
	self.config.sleepModeLeavingComment	= [self.sleepModeQuitMessageTextField value];
	self.config.normalLeavingComment = [self.normalLeavingCommentTextField value];
	
	/* Encoding */
	NSInteger primaryEncoding = [self.encodingList integerForKey:[self.primaryEncodingButton title]];
	NSInteger fallbackEncoding = [self.encodingList integerForKey:[self.fallbackEncodingButton title]];
	
	self.config.primaryEncoding	= primaryEncoding;
	self.config.fallbackEncoding = fallbackEncoding;
	
	/* Proxy Server */
	self.config.proxyType = [self.proxyTypeButton selectedTag];
	self.config.proxyAddress = [self.proxyAddressTextField lowercaseValue];
	self.config.proxyPort = [self.proxyPortTextField integerValue];
	self.config.proxyUsername = [self.proxyUsernameTextField trimmedFirstTokenStringValue];
	self.config.proxyPassword = [self.proxyPasswordTextField trimmedStringValue];

	/* Connect Commands */
	self.config.setInvisibleModeOnConnect = [self.setInvisibleModeOnConnectCheck state];

	NSString *connectCommands = [self.connectCommandsField string];
	
	NSArray *connectCommandsArray = [connectCommands componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSMutableArray *newConnectCommandsList = [NSMutableArray array];
	
	for (NSString *s in connectCommandsArray) {
		NSString *ts = [s trim];
		
		if ([ts length] > 0) {
			[newConnectCommandsList addObject:ts];
		}
	}
	
	self.config.loginCommands = newConnectCommandsList;

	/* Flood Control */
	self.config.floodControlMaximumMessages = [self.floodControlMessageCountSlider integerValue];
	self.config.floodControlDelayTimerInterval = [self.floodControlDelayTimerSlider integerValue];
	
	/* Mutable stores. */
	self.config.channelList = self.mutableChannelList;
	self.config.highlightList = self.mutableHighlightList;
	self.config.ignoreList = self.mutableIgnoreList;
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self updateConnectionPage];
}

- (void)updateConnectionPage
{
	/* This array is not saved as static because it would have to be cleared
	 out anytime that the sheet closes. */
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

	for (NSDictionary *fieldToCheck in fieldsToValidate) {
		id field = fieldToCheck[@"field"];

		if ([field valueIsValid] == NO) {
			errorReason = [NSString stringWithFormat:@"TDCServerPropertiesSheet[1007][%@]", fieldToCheck[@"errorLocalizationNumeric"]];

			break;
		}
	}

	if (errorReason) {
		[self.okButton setEnabled:NO];

		[self.erroneousInputErrorImageView setHidden:NO];
		[self.erroneousInputErrorTextField setHidden:NO];

		[self.erroneousInputErrorTextField setStringValue:TXTLS(errorReason)];
	} else {
		[self.okButton setEnabled:YES];

		[self.erroneousInputErrorImageView setHidden:YES];
		[self.erroneousInputErrorTextField setHidden:YES];

		[self.erroneousInputErrorTextField setStringValue:NSStringEmptyPlaceholder];
	}
}

- (void)updateChannelsPage
{
	NSInteger i = [self.channelTable selectedRow];
	
	[self.editChannelButton	setEnabled:(i > -1)];
	[self.deleteChannelButton setEnabled:(i > -1)];
}

- (void)reloadChannelTable
{
	[self.channelTable reloadData];
}

- (void)updateIgnoresPage
{
	NSInteger i = [self.ignoreTable selectedRow];
	
	[self.editIgnoreButton setEnabled:(i > -1)];
	[self.deleteIgnoreButton setEnabled:(i > -1)];
}

- (void)reloadIgnoreTable
{
	[self.ignoreTable reloadData];
}

- (void)updateHighlightsPage
{
	NSInteger i = [self.highlightsTable selectedRow];
	
	[self.editHighlightButton setEnabled:(i > -1)];
	[self.deleteHighlightButton setEnabled:(i > -1)];
}

- (void)reloadHighlightsTable
{
	[self.highlightsTable reloadData];
}

- (void)useSSLCheckChanged:(id)sender
{
	NSInteger serverPort = [self.serverPortTextField integerValue];
	
	BOOL useSSL = ([self.prefersSecuredConnectionCheck state] == NSOnState);
	
	if (useSSL) {
		if (serverPort == 6667) {
			[self.serverPortTextField setStringValue:@"6697"];
		}
	} else {
		if (serverPort == 6697) {
			[self.serverPortTextField setStringValue:@"6667"];
		}
	}
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self removeConfigurationDidChangeObserver];

	[self closeChildSheets];

	[self save];

	if ([self.delegate respondsToSelector:@selector(serverPropertiesSheetOnOK:)]) {
		[self.delegate serverPropertiesSheetOnOK:self];
	}
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (self.requestCloudDeletionOnClose) {
		if ([self.delegate respondsToSelector:@selector(serverPropertiesSheetRequestedCloudExclusionByDeletion:)]) {
			[self.delegate serverPropertiesSheetRequestedCloudExclusionByDeletion:self];
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

- (void)releaseTableViewDataSourceBeforeSheetClosure
{
	self.ignoreTable.delegate = nil;
	self.channelTable.delegate = nil;
	self.highlightsTable.delegate = nil;
	
	self.ignoreTable.dataSource = nil;
	self.channelTable.dataSource = nil;
	self.highlightsTable.dataSource = nil;
}

- (void)serverAddressChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)proxyTypeChanged:(id)sender
{
	NSInteger tag = [self.proxyTypeButton selectedTag];

	BOOL isSystemSocksProxyEnabled = (tag == IRCConnectionSocketSystemSocksProxyType);
	bool isTorBrowserProxyEnabled = (tag == IRCConnectionSocketTorBrowserType);

	BOOL supportsAuthentication = (tag == IRCConnectionSocketSocks5ProxyType);

	BOOL httpsEnabled = (tag == IRCConnectionSocketHTTPProxyType || tag == IRCConnectionSocketHTTPSProxyType);
	BOOL socksEnabled = (tag == IRCConnectionSocketSocks4ProxyType || tag == IRCConnectionSocketSocks5ProxyType);
	
	BOOL enabled = (httpsEnabled || socksEnabled);

	[self.contentViewProxyServerTorBrowserView setHidden:(isTorBrowserProxyEnabled == NO)];
	[self.contentViewProxyServerSystemSocksView setHidden:(isSystemSocksProxyEnabled == NO)];
	[self.contentViewProxyServerInputView setHidden:(httpsEnabled == NO && socksEnabled == NO)];

	[self.proxyAddressTextField	setEnabled:enabled];
	[self.proxyPortTextField setEnabled:enabled];

	[self.proxyUsernameTextField setEnabled:(socksEnabled && supportsAuthentication)];
	[self.proxyPasswordTextField setEnabled:(socksEnabled && supportsAuthentication)];
	
	[self.proxyAddressTextField performValidation];
	[self.proxyPortTextField performValidation];
	
	[self updateConnectionPage];
}

- (void)toggleAdvancedEncodings:(id)sender
{
	NSString *selectedPrimary = [self.primaryEncodingButton titleOfSelectedItem];
	NSString *selectedFallback = [self.fallbackEncodingButton titleOfSelectedItem];
	
	[self populateEncodings];
	
	NSMenuItem *primaryItem = nil;
	NSMenuItem *fallbackItem = nil;
	
	if (selectedPrimary) {
		primaryItem = [self.primaryEncodingButton itemWithTitle:selectedPrimary];
	}
	
	if (selectedFallback) {
		fallbackItem = [self.fallbackEncodingButton itemWithTitle:selectedFallback];
	}
	
	if (primaryItem == nil) {
		selectedPrimary = [NSString localizedNameOfStringEncoding:TXDefaultPrimaryStringEncoding];
	}
	
	if (fallbackItem == nil) {
		selectedFallback = [NSString localizedNameOfStringEncoding:TXDefaultFallbackStringEncoding];
	}
	
	/* Select items. */
	[self.primaryEncodingButton selectItemWithTitle:selectedPrimary];
	[self.fallbackEncodingButton selectItemWithTitle:selectedFallback];
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)toggleCloudSyncExclusion:(id)sender
{
	if (self.clientID == nil) {
		return;
	}

	if ([self.excludedFromCloudSyncingCheck state] == NSOnState) {
		[TLOPopupPrompts sheetWindowWithWindow:self.sheet
										  body:TXTLS(@"TDCServerPropertiesSheet[1002][2]")
										 title:TXTLS(@"TDCServerPropertiesSheet[1002][1]")
								 defaultButton:TXTLS(@"Prompts[0001]")
							   alternateButton:TXTLS(@"Prompts[0002]")
								   otherButton:nil
								suppressionKey:nil
							   suppressionText:nil
							   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
								   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
									   self.requestCloudDeletionOnClose = NO;
								   } else {
									   self.requestCloudDeletionOnClose = YES;
								   }
							   }];
	} else {
		self.requestCloudDeletionOnClose = NO;
	}
}
#endif

#pragma mark -
#pragma mark SSL Certificate

- (void)onClientCertificateFingerprintSHA1CopyRequested:(id)sender
{
	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", [self.clientCertificateSHA1FingerprintField stringValue]];
	
	[RZPasteboard() setStringContent:command];
}

- (void)onClientCertificateFingerprintMD5CopyRequested:(id)sender
{
	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", [self.clientCertificateMD5FingerprintField stringValue]];
	
	[RZPasteboard() setStringContent:command];
}

- (void)updateClientCertificatePage
{
	NSString *commonName = nil;
	
	NSString *sha1fingerprint = nil;
	NSString *md5fingerprint = nil;

	if (self.config.identityClientSideCertificate) {
		SecKeychainItemRef cert;
		
		CFDataRef rawCertData = (__bridge CFDataRef)(self.config.identityClientSideCertificate);
		
		OSStatus status = SecKeychainItemCopyFromPersistentReference(rawCertData, &cert);
		
		if (status == noErr) {
			CFStringRef commName;
			
			status = SecCertificateCopyCommonName((SecCertificateRef)cert, &commName);
			
			if (status == noErr){
				commonName = (__bridge NSString *)(commName);

				CFDataRef data = SecCertificateCopyData((SecCertificateRef)cert);

				if (data) {
					NSData *certNormData = [NSData dataWithBytes:CFDataGetBytePtr(data) length:CFDataGetLength(data)];

					sha1fingerprint = [certNormData sha1];
					md5fingerprint = [certNormData md5];

					CFRelease(data);
				}

				CFRelease(commName);
			}

			CFRelease(cert);
		}
	}

	BOOL hasNoCert = NSObjectIsEmpty(commonName);
	
	if (hasNoCert) {
		[self.clientCertificateCommonNameField setStringValue:TXTLS(@"TDCServerPropertiesSheet[1008]")];
		
		[self.clientCertificateSHA1FingerprintField setStringValue:TXTLS(@"TDCServerPropertiesSheet[1008]")];
		[self.clientCertificateMD5FingerprintField setStringValue:TXTLS(@"TDCServerPropertiesSheet[1008]")];
	} else {
		[self.clientCertificateCommonNameField setStringValue:commonName];
		
		[self.clientCertificateSHA1FingerprintField setStringValue:[sha1fingerprint uppercaseString]];
		[self.clientCertificateMD5FingerprintField setStringValue:[md5fingerprint uppercaseString]];
	}
	
	[self.clientCertificateResetCertificateButton setEnabled:(hasNoCert == NO)];

	[self.clientCertificateSHA1FingerprintCopyButton setEnabled:(hasNoCert == NO)];
	[self.clientCertificateMD5FingerprintCopyButton setEnabled:(hasNoCert == NO)];
}

- (void)onClientCertificateResetRequested:(id)sender
{
	self.config.identityClientSideCertificate = nil;

	[self updateClientCertificatePage];
}

- (void)onClientCertificateChangeRequested:(id)sender
{
	/* Before we can present a list of certificates to the end user, we must first
	 query the keychain and build a list of all of them that exist in there first. */
	CFArrayRef identities = NULL;
	
	NSDictionary *query = @{
		(id)kSecClass		: (id)kSecClassIdentity,
		(id)kSecMatchLimit	: (id)kSecMatchLimitAll,
		(id)kSecReturnRef	: (id)kCFBooleanTrue
	};
	
	OSStatus querystatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);

	if (querystatus == noErr) {
		SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
		
		[panel setInformativeText:TXTLS(@"TDCServerPropertiesSheet[1009][2]")];
		
		[panel setAlternateButtonTitle:TXTLS(@"Prompts[0004]")];
		
		NSInteger returnCode = [panel runModalForIdentities:(__bridge NSArray *)(identities)
													message:TXTLS(@"TDCServerPropertiesSheet[1009][1]")];

		if (returnCode == NSModalResponseOK) {
			SecIdentityRef identity = [panel identity];
			
			CFDataRef certData;
			
			if (identity == NULL) {
				LogToConsole(@"We have no identity."); // Does that even make sense? What did they select?
			} else {
				SecCertificateRef identityCert;
				
				OSStatus copystatus = SecIdentityCopyCertificate(identity, &identityCert);
				
				if (copystatus == noErr) {
					copystatus = SecKeychainItemCreatePersistentReference((SecKeychainItemRef)identityCert, &certData);
					
					if (copystatus == noErr) {
						self.config.identityClientSideCertificate = (__bridge NSData *)(certData);
						
						/* Force enable SSL. */
						if ([self.prefersSecuredConnectionCheck state] == NSOffState) {
							[self.prefersSecuredConnectionCheck setState:NSOnState];
							
							[self useSSLCheckChanged:nil];
						}
					}
					
					CFRelease(identityCert);
					CFRelease(certData);
				}
			}
		}
	} else {
		LogToConsole(@"Failed to build list of identities from keychain.");
	}

	if (identities) {
		CFRelease(identities);
	}

	[self updateClientCertificatePage];
}

#pragma mark -
#pragma mark Highlight Actions

- (void)addHighlight:(id)sender
{
	self.highlightSheet = nil;
	self.highlightSheet = [TDCHighlightEntrySheet new];

	self.highlightSheet.newItem = YES;

	self.highlightSheet.delegate = self;
	self.highlightSheet.window = self.sheet;

	self.highlightSheet.config = [IRCHighlightMatchCondition new];

	[self.highlightSheet startWithChannels:self.mutableChannelList];
}

- (void)editHighlight:(id)sender
{
	NSInteger sel = [self.highlightsTable selectedRow];
	
	NSAssertReturn(sel > -1);
	
	self.highlightSheet = nil;
	self.highlightSheet = [TDCHighlightEntrySheet new];
	
	self.highlightSheet.newItem = NO;

	self.highlightSheet.delegate = self;
	self.highlightSheet.window = self.sheet;

	self.highlightSheet.config = self.mutableHighlightList[sel];
	
	[self.highlightSheet startWithChannels:self.mutableChannelList];
}

- (void)highlightEntrySheetOnOK:(TDCHighlightEntrySheet *)sender
{
	IRCHighlightMatchCondition *match = [sender config];
	
	BOOL emptyKeyword = NSObjectIsEmpty([match matchKeyword]);
	
	if ([sender newItem]) {
		if (emptyKeyword == NO) {
			[self.mutableHighlightList addObject:match];
		}
	} else {
		__block NSInteger matchedIndex = -1;

		[self.mutableHighlightList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([[obj uniqueIdentifier] isEqualToString:[match uniqueIdentifier]]) {
				matchedIndex = idx;

				*stop = YES;
			}
		}];

		if (matchedIndex > -1) {
			if (emptyKeyword) {
				[self.mutableHighlightList removeObjectAtIndex:matchedIndex];
			} else {
				(self.mutableHighlightList)[matchedIndex] = match;
			}
		}
	}
	
	[self reloadHighlightsTable];
}

- (void)highlightEntrySheetWillClose:(TDCHighlightEntrySheet *)sender
{
	self.highlightSheet = nil;
}

- (void)deleteHighlight:(id)sender
{
	NSInteger sel = [self.highlightsTable selectedRow];
	
	NSAssertReturn(sel > -1);
	
	[self.mutableHighlightList removeObjectAtIndex:sel];
	
	NSInteger count = [self.mutableHighlightList count];
	
	if (count) {
		if (count <= sel) {
			[self.highlightsTable selectItemAtIndex:(count - 1)];
		} else {
			[self.highlightsTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadHighlightsTable];
}

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
	IRCChannelConfig *config = [IRCChannelConfig new];
	
	self.channelSheet = nil;
	self.channelSheet = [TDChannelPropertiesSheet new];
	
	self.channelSheet.newItem = YES;
	self.channelSheet.observeChanges = NO;
	
	self.channelSheet.delegate = self;
	self.channelSheet.window = self.sheet;

	self.channelSheet.config = config;
	self.channelSheet.clientID = nil;
	self.channelSheet.channelID = nil;
	
	[self.channelSheet start];
}

- (void)editChannel:(id)sender
{
	NSInteger sel = [self.channelTable selectedRow];
	
	NSAssertReturn(sel > -1);
	
	IRCChannelConfig *c = self.mutableChannelList[sel];
	
	self.channelSheet = nil;
	self.channelSheet = [TDChannelPropertiesSheet new];
	
	self.channelSheet.newItem = NO;
	self.channelSheet.observeChanges = NO;

	self.channelSheet.delegate = self;
	self.channelSheet.window = self.sheet;

	self.channelSheet.config = c;
	self.channelSheet.clientID = nil;
	self.channelSheet.channelID = nil;
	
	[self.channelSheet start];
}

- (void)channelPropertiesSheetOnOK:(TDChannelPropertiesSheet *)sender
{
	IRCChannelConfig *config = [sender config];
	
	BOOL emptyName = ([config.channelName length] < 2); // For the # in front.
	
	if ([sender newItem]) {
		if (emptyName == NO) {
			[self.mutableChannelList addObject:config];
		}
	} else {
		__block NSInteger matchedIndex = -1;

		[self.mutableChannelList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([[obj itemUUID] isEqualToString:[config itemUUID]]) {
				matchedIndex = idx;

				*stop = YES;
			}
		}];

		if (matchedIndex > -1) {
			if (emptyName) {
				[self.mutableChannelList removeObjectAtIndex:matchedIndex];
			} else {
				(self.mutableChannelList)[matchedIndex] = config;
			}
		}
	}
	
	[self reloadChannelTable];
}

- (void)channelPropertiesSheetWillClose:(TDChannelPropertiesSheet *)sender
{
	self.channelSheet = nil;
}

- (void)deleteChannel:(id)sender
{
	NSInteger sel = [self.channelTable selectedRow];
	
	NSAssertReturn(sel > -1);
	
	[self.mutableChannelList removeObjectAtIndex:sel];
	
	NSInteger count = [self.mutableChannelList count];
	
	if (count) {
		if (count <= sel) {
			[self.channelTable selectItemAtIndex:(count - 1)];
		} else {
			[self.channelTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadChannelTable];
}

#pragma mark -
#pragma mark Ignore Actions

- (void)showAddIgnoreMenu:(id)sender
{
	[self.addIgnoreMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:sender];
}

- (void)addIgnore:(id)sender
{
	self.ignoreSheet = nil;
	self.ignoreSheet = [TDCAddressBookSheet new];
	
	IRCAddressBookEntry *newIgnore = nil;

	if ([sender tag] == 4) {
		newIgnore = [IRCAddressBookEntry newUserTrackingEntry];
	} else {
		newIgnore = [IRCAddressBookEntry newIgnoreEntry];
	}
	
	self.ignoreSheet.newItem = YES;

	self.ignoreSheet.delegate = self;
	self.ignoreSheet.window = self.sheet;

	self.ignoreSheet.ignore = newIgnore;
	
	[self.ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
	NSInteger sel = [self.ignoreTable selectedRow];
	
	NSAssertReturn(sel > -1);
	
	IRCAddressBookEntry *c = self.mutableIgnoreList[sel];
	
	self.ignoreSheet = nil;
	self.ignoreSheet = [TDCAddressBookSheet new];
	
	self.ignoreSheet.newItem = NO;

	self.ignoreSheet.delegate = self;
	self.ignoreSheet.window = self.sheet;

	self.ignoreSheet.ignore = c;
	
	[self.ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
	NSInteger sel = self.ignoreTable.selectedRow;
	
	NSAssertReturn(sel > -1);
	
	[self.mutableIgnoreList removeObjectAtIndex:sel];
	
	NSInteger count = [self.mutableIgnoreList count];
	
	if (count) {
		if (count <= sel) {
			[self.ignoreTable selectItemAtIndex:(count - 1)];
		} else {
			[self.ignoreTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadIgnoreTable];
}

- (void)ignoreItemSheetOnOK:(TDCAddressBookSheet *)sender
{
	IRCAddressBookEntry *ignore = [sender ignore];
	
	BOOL emptyHost = NSObjectIsEmpty([ignore hostmask]);
	
	if ([sender newItem]) {
		if (emptyHost == NO) {
			[self.mutableIgnoreList addObject:ignore];
		}
	} else {
		__block NSInteger matchedIndex = -1;

		[self.mutableIgnoreList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([[obj itemUUID] isEqualToString:[ignore itemUUID]]) {
				matchedIndex = idx;

				*stop = YES;
			}
		}];

		if (matchedIndex > -1) {
			if (emptyHost) {
				[self.mutableIgnoreList removeObjectAtIndex:matchedIndex];
			} else {
				(self.mutableIgnoreList)[matchedIndex] = ignore;
			}
		}
	}
	
	[self reloadIgnoreTable];
}

- (void)ignoreItemSheetWillClose:(TDCAddressBookSheet *)sender
{
	self.ignoreSheet = nil;
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == self.channelTable) {
		return [self.mutableChannelList count];
	} else if (sender == self.highlightsTable) {
		return [self.mutableHighlightList count];
	} else if (sender == self.ignoreTable) {
		return [self.mutableIgnoreList count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSString *columnId = [column identifier];
	
	if (sender == self.channelTable)
	{
		IRCChannelConfig *c = self.mutableChannelList[row];
		
		if ([columnId isEqualToString:@"name"]) {
			return [c channelName];
		} else if ([columnId isEqualToString:@"pass"]) {
			NSString *secretKeyValue = [c secretKey];
			
			if (NSObjectIsNotEmpty(secretKeyValue)) {
				return secretKeyValue;
			} else {
				return NSStringEmptyPlaceholder;
			}
		} else if ([columnId isEqualToString:@"join"]) {
			return @([c autoJoin]);
		}
	}
	else if (sender == self.highlightsTable)
	{
		/* Highlight Table. */
		IRCHighlightMatchCondition *c = self.mutableHighlightList[row];

		if ([columnId isEqualToString:@"keyword"]) {
			return [c matchKeyword];
		} else if ([columnId isEqualToString:@"channel"]) {
			if ([c matchChannelId] == nil) {
				return TXTLS(@"TDCServerPropertiesSheet[1003]");
			} else {
				IRCChannelConfig *channel = nil;
				
				for (IRCChannelConfig *cc in self.mutableChannelList) {
					if ([[cc itemUUID] isEqualToString:[c matchChannelId]]) {
						channel = cc;
					}
				}
				
				if (channel) {
					return [channel channelName];
				} else {
					return TXTLS(@"TDCServerPropertiesSheet[1003]");
				}
			}
		} else if ([columnId isEqualToString:@"type"]) {
			if ([c matchIsExcluded]) {
				return TXTLS(@"TDCServerPropertiesSheet[1004]");
			} else {
				return TXTLS(@"TDCServerPropertiesSheet[1005]");
			}
		}
	}
	else if (sender == self.ignoreTable)
	{
		/* Address Book Table. */
		IRCAddressBookEntry *g = self.mutableIgnoreList[row];
		
		if ([columnId isEqualToString:@"type"]) {
			if ([g entryType] == IRCAddressBookIgnoreEntryType) {
				return TXTLS(@"TDCServerPropertiesSheet[1000]");
			} else {
				return TXTLS(@"TDCServerPropertiesSheet[1001]");
			}
		} else {
			return [g hostmask];
		}
	}
	
	return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return YES;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == self.channelTable) {
		IRCChannelConfig *c = self.mutableChannelList[row];
		
		NSString *columnId = [column identifier];
		
		if ([columnId isEqualToString:@"join"]) {
			c.autoJoin = (([obj integerValue] == 0) == NO);
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	id sender = [note object];
	
	if (sender == self.channelTable) {
		[self updateChannelsPage];
	} else if (sender == self.highlightsTable) {
		[self updateHighlightsPage];
	} else if (sender == self.ignoreTable) {
		[self updateIgnoresPage];
	}
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == self.channelTable) {
		[self editChannel:nil];
	} else if (sender == self.highlightsTable) {
		[self editHighlight:nil];
	} else if (sender == self.ignoreTable) {
		[self editIgnore:nil];
	}
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (sender == self.channelTable) {
		[pboard declareTypes:_tableRowTypes owner:self];
		
		[pboard setPropertyList:@[@([rows firstIndex])] forType:_tableRowType];
	}
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == self.channelTable) {
		NSPasteboard *pboard = [info draggingPasteboard];
		
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:_tableRowTypes]) {
			return NSDragOperationGeneric;
		} else {
			return NSDragOperationNone;
		}
	} else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	if (sender == self.channelTable)
	{
		NSPasteboard *pboard = [info draggingPasteboard];
		
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:_tableRowTypes]) {
			NSMutableArray *ary = self.mutableChannelList;
			
			NSArray *selectedRows = [pboard propertyListForType:_tableRowType];
			
			NSInteger selectedRow = [selectedRows integerAtIndex:0];
			
			IRCChannelConfig *target = ary[selectedRow];
			
			NSMutableArray *low  = [ary mutableSubarrayWithRange:NSMakeRange(0, row)];
			NSMutableArray *high = [ary mutableSubarrayWithRange:NSMakeRange(row, ([ary count] - row))];
			
			[low removeObjectIdenticalTo:target];
			[high removeObjectIdenticalTo:target];
			
			[ary removeAllObjects];
			
			[ary addObjectsFromArray:low];
			[ary addObject:target];
			[ary addObjectsFromArray:high];
			
			[self reloadChannelTable];
			
			selectedRow = [ary indexOfObjectIdenticalTo:target];
			
			if (0 <= selectedRow) {
				[self.channelTable selectItemAtIndex:selectedRow];
			}
			
			return YES;
		}
	}
	
	return NO;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self releaseTableViewDataSourceBeforeSheetClosure];

	[self.sheet makeFirstResponder:nil];

	[self.channelTable unregisterDraggedTypes];
	
	if ([self.delegate respondsToSelector:@selector(serverPropertiesSheetWillClose:)]) {
		[self.delegate serverPropertiesSheetWillClose:self];
	}
}

@end
