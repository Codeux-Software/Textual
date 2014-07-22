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

#define _preferencePaneViewFramePadding				47

#define _forcedPreferencePaneViewFrameHeight		304
#define _forcedPreferencePaneViewFrameWidth			529

@interface TDCServerSheet ()
@property (nonatomic, copy) NSArray *navigationTreeMatrix;
@property (nonatomic, copy) NSDictionary *encodingList;
@property (nonatomic, copy) NSDictionary *serverList;
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
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateMD5FingerprintCopyButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateResetButton;
@property (nonatomic, nweak) IBOutlet NSButton *sslCertificateSHA1FingerprintCopyButton;
@property (nonatomic, nweak) IBOutlet NSButton *validateServerSSLCertificateCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnoreConfiguredAutojoinCheck;
@property (nonatomic, nweak) IBOutlet NSButton *zncIgnorePlaybackNotificationsCheck;
@property (nonatomic, nweak) IBOutlet NSImageView *erroneousInputErrorImageView;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *fallbackEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *primaryEncodingButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *proxyTypeButton;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlDelayTimerSlider;
@property (nonatomic, nweak) IBOutlet NSSlider *floodControlMessageCountSlider;
@property (nonatomic, nweak) IBOutlet NSTextField *alternateNicknamesField;
@property (nonatomic, nweak) IBOutlet NSTextField *erroneousInputErrorTextField;
@property (nonatomic, nweak) IBOutlet NSTextField *nicknamePasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *proxyUsernameField;
@property (nonatomic, nweak) IBOutlet NSTextField *serverPasswordField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateCommonNameField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateMD5FingerprintField;
@property (nonatomic, nweak) IBOutlet NSTextField *sslCertificateSHA1FingerprintField;
@property (nonatomic, nweak) IBOutlet TVCAnimatedContentNavigationOutlineView *navigationOutlineview;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *channelTable;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *highlightsTable;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *ignoreTable;
@property (nonatomic, nweak) IBOutlet TVCTextFieldComboBoxWithValueValidation *serverAddressCombo;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *awayNicknameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *nicknameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *normalLeavingCommentField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *proxyAddressField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *proxyPortField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *realnameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *serverNameField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *serverPortField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *sleepModeQuitMessageField;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *usernameField;
@property (nonatomic, strong) IBOutlet NSMenu *addIgnoreMenu;
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
@property (nonatomic, strong) NSMutableArray *mutableChannelList;
@property (nonatomic, strong) NSMutableArray *mutableHighlightList;
@property (nonatomic, strong) NSMutableArray *mutableIgnoreList;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;
@property (nonatomic, strong) TDCHighlightEntrySheet *highlightSheet;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, uweak) IBOutlet NSTextView *connectCommandsField;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
@property (nonatomic, assign) BOOL requestCloudDeletionOnClose;
#endif
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TDCServerSheet

- (id)init
{
	if ((self = [super init])) {
		/* Load our views. */
		[RZMainBundle() loadCustomNibNamed:@"TDCServerSheet" owner:self topLevelObjects:nil];
		
		/* Load the list of available IRC networks. */
		NSString *slp = [RZMainBundle() pathForResource:@"IRCNetworks" ofType:@"plist"];
		
		self.serverList = [NSDictionary dictionaryWithContentsOfFile:slp];
		
		/* Populate the navigation tree. */
		[self populateTabViewList];
		
		/* Populate the server address field with the IRC network list. */
		NSArray *sortedKeys = [self.serverList allKeys];
		
		sortedKeys = [sortedKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			/* We are sorting keys. They are NSString values. */
			/* Sort without case so that "freenode" is under servers with a capital F. */
			return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
		}];
		
		for (NSString *key in sortedKeys) {
			[self.serverAddressCombo addItemWithObjectValue:key];
		}
		
		/* Subscribe to notifications. */
		IRCClient *client = [worldController() findClientById:self.clientID];
		
		[RZNotificationCenter() addObserver:self
								   selector:@selector(underlyingConfigurationChanged:)
									   name:IRCClientConfigurationWasUpdatedNotification
									 object:client];
		
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
		[self.awayNicknameField setTextDidChangeCallback:self];
		
		[self.awayNicknameField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.awayNicknameField setStringValueIsInvalidOnEmpty:NO];
		[self.awayNicknameField setStringValueIsTrimmed:YES];
		[self.awayNicknameField setStringValueUsesOnlyFirstToken:YES];
		
		[self.awayNicknameField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isNickname];
		}];
		
		/* Nickname. */
		[self.nicknameField setTextDidChangeCallback:self];
		
		[self.nicknameField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.nicknameField setStringValueIsInvalidOnEmpty:YES];
		[self.nicknameField setStringValueIsTrimmed:YES];
		[self.nicknameField setStringValueUsesOnlyFirstToken:YES];
		
		[self.nicknameField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isNickname];
		}];
		
		/* Username. */
		[self.usernameField setTextDidChangeCallback:self];
		
		[self.usernameField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.usernameField setStringValueIsInvalidOnEmpty:YES];
		[self.usernameField setStringValueIsTrimmed:YES];
		[self.usernameField setStringValueUsesOnlyFirstToken:YES];
		
		[self.usernameField setValidationBlock:^BOOL(NSString *currentValue) {
			return [currentValue isHostmaskUsername];
		}];

		/* Real name. */
		[self.realnameField setTextDidChangeCallback:self];
		
		[self.realnameField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.realnameField setStringValueIsInvalidOnEmpty:YES];
		[self.realnameField setStringValueIsTrimmed:YES];
		[self.realnameField setStringValueUsesOnlyFirstToken:NO];
		
		/* Normal leaving comment. */
		[self.normalLeavingCommentField setTextDidChangeCallback:self];
		
		[self.normalLeavingCommentField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.normalLeavingCommentField setStringValueIsInvalidOnEmpty:YES];
		[self.normalLeavingCommentField setStringValueIsTrimmed:YES];
		[self.normalLeavingCommentField setStringValueUsesOnlyFirstToken:NO];
		
		[self.normalLeavingCommentField setValidationBlock:^BOOL(NSString *currentValue) {
			if ([currentValue contains:NSStringNewlinePlaceholder]) {
				return NO;
			}
			
			return ([currentValue length] < 390);
		}];
		
		/* Sleep mode leaving comment. */
		[self.sleepModeQuitMessageField setTextDidChangeCallback:self];
		
		[self.sleepModeQuitMessageField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.sleepModeQuitMessageField setStringValueIsInvalidOnEmpty:YES];
		[self.sleepModeQuitMessageField setStringValueIsTrimmed:YES];
		[self.sleepModeQuitMessageField setStringValueUsesOnlyFirstToken:NO];
		
		[self.sleepModeQuitMessageField setValidationBlock:^BOOL(NSString *currentValue) {
			if ([currentValue contains:NSStringNewlinePlaceholder]) {
				return NO;
			}
			
			return ([currentValue length] < 390);
		}];
		
		/* Connection name. */
		[self.serverNameField setTextDidChangeCallback:self];
		
		[self.serverNameField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.serverNameField setStringValueIsInvalidOnEmpty:YES];
		[self.serverNameField setStringValueIsTrimmed:YES];
		[self.serverNameField setStringValueUsesOnlyFirstToken:NO];
		
		/* Server address. */
		[self.serverAddressCombo setTextDidChangeCallback:self];
		
		[self.serverAddressCombo setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.serverAddressCombo setStringValueIsInvalidOnEmpty:YES];
		[self.serverAddressCombo setStringValueIsTrimmed:YES];
		[self.serverAddressCombo setStringValueUsesOnlyFirstToken:YES];

		/* Server port. */
		[self.serverPortField setTextDidChangeCallback:self];
		
		[self.serverPortField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.serverPortField setStringValueIsInvalidOnEmpty:NO];
		[self.serverPortField setStringValueIsTrimmed:YES];
		[self.serverPortField setStringValueUsesOnlyFirstToken:NO];
		
		[self.serverPortField setValidationBlock:^BOOL(NSString *currentValue) {
			if ([currentValue isNumericOnly]) {
				return ([currentValue length] < 7 && [currentValue integerValue] > 1);
			} else {
				return NO;
			}
		}];
		
		/* Proxy address. */
		[self.proxyAddressField setTextDidChangeCallback:self];
		
		[self.proxyAddressField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.proxyAddressField setStringValueIsInvalidOnEmpty:NO];
		[self.proxyAddressField setStringValueIsTrimmed:YES];
		[self.proxyAddressField setStringValueUsesOnlyFirstToken:YES];
		
		[self.proxyAddressField setPerformValidationWhenEmpty:YES];
		
		[self.proxyAddressField setValidationBlock:^BOOL(NSString *currentValue) {
			NSInteger proxyType = [self.proxyTypeButton selectedTag];
			
			if (proxyType == IRCConnectionSocketSocks4ProxyType ||
				proxyType == IRCConnectionSocketSocks5ProxyType)
			{
				return ([currentValue length] > 0);
			} else {
				return YES;
			}
		}];
		
		/* Proxy port. */
		[self.proxyPortField setTextDidChangeCallback:self];
		
		[self.proxyPortField setOnlyShowStatusIfErrorOccurs:YES];
		
		[self.proxyPortField setStringValueIsInvalidOnEmpty:NO];
		[self.proxyPortField setStringValueIsTrimmed:YES];
		[self.proxyPortField setStringValueUsesOnlyFirstToken:NO];
		
		[self.proxyPortField setPerformValidationWhenEmpty:YES];
		
		[self.proxyPortField setValidationBlock:^BOOL(NSString *currentValue) {
			NSInteger proxyType = [self.proxyTypeButton selectedTag];
			
			if (proxyType == IRCConnectionSocketSocks4ProxyType ||
				proxyType == IRCConnectionSocketSocks5ProxyType)
			{
				if ([currentValue isNumericOnly]) {
					return ([currentValue length] < 7 && [currentValue integerValue] > 1);
				} else {
					return NO;
				}
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
#define _navigationIndexForFloodControl				12
#define _navigationIndexForGeneral					5
#define _navigationIndexForIdentity					6
	
	NSMutableArray *navigationTreeMatrix = [NSMutableArray array];
	
	[navigationTreeMatrix addObject:@{
		@"blockCollapse" : @(YES),
		@"name" : TXTLS(@"TDCServerSheet[1007][15]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerSheet[1007][07]"),	@"view" : self.addressBookContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][01]"),	@"view" : self.autojoinContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][02]"),	@"view" : self.connectCommandsContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][03]"),	@"view" : self.contentEncodingContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][05]"),	@"view" : self.generalContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][06]"),	@"view" : self.identityContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][12]"),	@"view" : self.highlightsContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][08]"),	@"view" : self.disconnectMessagesContentView},
		]
	}];
	
	[navigationTreeMatrix addObject:@{
		@"name" : TXTLS(@"TDCServerSheet[1007][16]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerSheet[1007][14]"),	@"view" : self.zncBouncerContentView},
		]
	}];
	
	[navigationTreeMatrix addObject:@{
		@"name" : TXTLS(@"TDCServerSheet[1007][17]"),
		@"children" : @[
			@{@"name" : TXTLS(@"TDCServerSheet[1007][04]"),	@"view" : self.floodControlContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][13]"),	@"view" : self.networkSocketContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][10]"),	@"view" : self.proxyServerContentView},
			@{@"name" : TXTLS(@"TDCServerSheet[1007][11]"),	@"view" : self.sslCertificateContentView},
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
	
	BOOL includeAdvancedEncodings = [RZUserDefaults() boolForKey:@"Server Properties Window Sheet —> Include Advanced Encodings"];
	
	if (includeAdvancedEncodings) {
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

- (void)start:(TDCServerSheetNavigationSelection)viewToken withContext:(NSString *)context
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
	
	if (viewToken == TDCServerSheetFloodControlNavigationSelection) {
		[self showWithDefaultView:_navigationIndexForFloodControl];
	} else if (viewToken == TDCServerSheetAddressBookNavigationSelection ||
			   viewToken == TDCServerSheetNewIgnoreEntryNavigationSelection)
	{
		[self showWithDefaultView:_navigationIndexForAddressBook];
		
		if ([context isEqualToString:@"-"] == NO) {
			/* Create ignore sheet. */
			self.ignoreSheet = [TDCAddressBookSheet new];
			
			self.ignoreSheet.delegate = self;
			self.ignoreSheet.window = self.sheet;
			
			self.ignoreSheet.newItem = YES;
			
			/* Create ignore. */
			IRCAddressBookEntry *newIgnore = [IRCAddressBookEntry new];
			
			newIgnore.ignoreCTCP = YES;
			newIgnore.ignoreJPQE = YES;
			newIgnore.ignoreNotices = YES;
			newIgnore.ignorePrivateHighlights = YES;
			newIgnore.ignorePrivateMessages = YES;
			newIgnore.ignorePublicHighlights = YES;
			newIgnore.ignorePublicMessages = YES;
			newIgnore.ignoreFileTransferRequests = YES;
			
			if ([context isEqualToString:@"--"]) {
				//self.ignoreSheet.ignore.hostmask = @"<nickname>";
			} else {
				newIgnore.hostmask = context;
			}
			
			/* Copy over configuration. */
			self.ignoreSheet.ignore = newIgnore;
			
			/* Present dialog. */
			[self.ignoreSheet start];
		}
	} else {
		[self showWithDefaultView:_navigationIndexForGeneral];
	}
}

- (void)showWithDefaultView:(NSInteger)viewIndex
{
	[self startSheet];
	
	[self.navigationOutlineview startAtSelectionIndex:viewIndex];
}

- (void)closeSheets
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
	[self closeSheets];

	[super cancel:nil];
}

- (void)updateUnderlyingConfigurationProfileCallback:(TLOPopupPromptReturnType)returnType withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnType == TLOPopupPromptReturnPrimaryType) {
		IRCClient *client = [worldController() findClientById:self.clientID];
		
		[self close];
		
		self.config = [client copyOfStoredConfig];
		
		[self load];
		[self showWithDefaultView:_navigationIndexForGeneral];
	}
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	TLOPopupPrompts *popup = [TLOPopupPrompts new];
	
	NSWindow *sheetWindow = self.sheet;
	
	if (self.channelSheet) {
		sheetWindow = self.channelSheet.sheet;
	} else if (self.highlightSheet) {
		sheetWindow = self.highlightSheet.sheet;
	} else if (self.ignoreSheet) {
		sheetWindow = self.ignoreSheet.sheet;
	}
	
	[popup sheetWindowWithQuestion:sheetWindow
							target:self
							action:@selector(updateUnderlyingConfigurationProfileCallback:withOriginalAlert:)
							  body:TXTLS(@"BasicLanguage[1240][2]", self.config.clientName)
							 title:TXTLS(@"BasicLanguage[1240][1]")
					 defaultButton:TXTLS(@"BasicLanguage[1240][3]")
				   alternateButton:TXTLS(@"BasicLanguage[1240][4]")
					   otherButton:nil
					suppressionKey:nil
				   suppressionText:nil];
}

- (void)load
{
	/* General */
	/* Define server address. */
	NSString *networkName = [self hostFoundInServerList:self.config.serverAddress];
	
	if (networkName == nil) {
		[self.serverAddressCombo setStringValue:self.config.serverAddress];
	} else {
		[self.serverAddressCombo setStringValue:networkName];
	}

	/* Server Port. */
	NSString *serverPort = [NSString stringWithInteger:self.config.serverPort];
	
	[self.serverPortField setStringValue:serverPort];

	/* Connection name. */
	[self.serverNameField setStringValue:self.config.clientName];
	
	/* Connection uses SSL. */
	[self.connectionUsesSSLCheck setState:self.config.connectionUsesSSL];
	
	/* Server password. */
	[self.serverPasswordField setStringValue:self.config.serverPassword];
	
	/* Other paramaters. */
	/* Auto connect status. */
	[self.autoConnectCheck setState:self.config.autoConnect];
	[self.autoReconnectCheck setState:self.config.autoReconnect];
	[self.autoDisconnectOnSleepCheck setState:self.config.autoSleepModeDisconnect];
	
	/* Excluded from iCloud. */
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[self.excludedFromCloudSyncingCheck setState:self.config.excludedFromCloudSyncing];
#endif
	
	/* ZNC configuration. */
	[self.zncIgnoreConfiguredAutojoinCheck setState:self.config.zncIgnoreConfiguredAutojoin];
	[self.zncIgnorePlaybackNotificationsCheck setState:self.config.zncIgnorePlaybackNotifications];
	
	/* DNS prefers IPv6. */
	[self.prefersIPv6Check setState:self.config.connectionPrefersIPv6];
	
	/* Internal pong timer. */
	[self.pongTimerCheck setState:self.config.performPongTimer];
	[self.pongTimerDisconnectCheck setState:self.config.performDisconnectOnPongTimer];
	
	/* Reachability check. */
	[self.disconnectOnReachabilityChangeCheck setState:self.config.performDisconnectOnReachabilityChange];
	
	/* Validate SSL certificate. */
	[self.validateServerSSLCertificateCheck setState:self.config.validateServerSSLCertificate];
	
	/* Nickname. */
	if (NSObjectIsEmpty(self.config.nickname)) {
		[self.nicknameField setStringValue:[TPCPreferences defaultNickname]];
	} else {
		[self.nicknameField setStringValue:self.config.nickname];
	}
	
	/* Away nickname. */
	[self.awayNicknameField setStringValue:self.config.awayNickname];
	
	/* Username. */
	if (NSObjectIsEmpty(self.config.username)) {
		[self.usernameField setStringValue:[TPCPreferences defaultUsername]];
	} else {
		[self.usernameField setStringValue:self.config.username];
	}
	
	/* Real name. */
	if (NSObjectIsEmpty(self.config.realname)) {
		[self.realnameField setStringValue:[TPCPreferences defaultRealname]];
	} else {
		[self.realnameField setStringValue:self.config.realname];
	}
	
	/* Alternate nicknames. */
	NSString *nicknames = [self.config.alternateNicknames componentsJoinedByString:NSStringWhitespacePlaceholder];
		
	[self.alternateNicknamesField setStringValue:nicknames];
	
	/* NickServ password. */
	[self.nicknamePasswordField setStringValue:self.config.nicknamePassword];
	
	/* Messages */
	[self.sleepModeQuitMessageField setStringValue:self.config.sleepModeLeavingComment];
	[self.normalLeavingCommentField setStringValue:self.config.normalLeavingComment];
	
	/* Encoding */
	NSString *primaryEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.primaryEncoding)];
	NSString *fallbackEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.fallbackEncoding)];
	
	[self.primaryEncodingButton selectItemWithTitle:primaryEncodingTitle];
	[self.fallbackEncodingButton selectItemWithTitle:fallbackEncodingTitle];
	
	/* Proxy Server */
	[self.proxyTypeButton selectItemWithTag:self.config.proxyType];
	
	[self.proxyAddressField setStringValue:self.config.proxyAddress];
	[self.proxyUsernameField setStringValue:self.config.proxyUsername];
	
	[self.proxyPasswordField setStringValue:self.config.proxyPassword];
	
	[self.proxyPortField setStringValue:[NSString stringWithInteger:self.config.proxyPort]];
	
	/* Connect modes. */
	[self.invisibleModeCheck setState:self.config.invisibleMode];
	
	/* Connect commands. */
	NSString *loginCommands = [self.config.loginCommands componentsJoinedByString:NSStringNewlinePlaceholder];
	
	[self.connectCommandsField setString:loginCommands];
	
	/* Flood Control */
	[self.floodControlCheck setState:self.config.outgoingFloodControl];
	
	[self.floodControlDelayTimerSlider setIntegerValue:self.config.floodControlDelayTimerInterval];
	[self.floodControlMessageCountSlider setIntegerValue:self.config.floodControlMaximumMessages];
	
	/* Mutable stors. */
	[self.mutableChannelList setArray:self.config.channelList];
	[self.mutableHighlightList setArray:self.config.highlightList];
	[self.mutableIgnoreList setArray:self.config.ignoreList];
	
	/* Update window based on new configuration. */
	[self updateConnectionPage];
	[self updateHighlightsPage];
	[self updateChannelsPage];
	[self updateIgnoresPage];
	[self updateSSLCertificatePage];

	[self proxyTypeChanged:nil];
	[self floodControlChanged:nil];
	
	[self reloadChannelTable];
	[self reloadIgnoreTable];
	
	/* @end */
}

- (void)save
{
	/* General */
	/* Auto connect status. */
	self.config.autoConnect	= [self.autoConnectCheck state];
	self.config.autoReconnect = [self.autoReconnectCheck state];
	self.config.autoSleepModeDisconnect = [self.autoDisconnectOnSleepCheck state];
	
	/* Connection type. */
	self.config.connectionPrefersIPv6 = [self.prefersIPv6Check state];
	self.config.connectionUsesSSL = [self.connectionUsesSSLCheck state];
	
	/* Server password. */
	self.config.serverPassword = [self.serverPasswordField trimmedStringValue];
	
	/* Exclude from iCloud. */
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	self.config.excludedFromCloudSyncing = [self.excludedFromCloudSyncingCheck state];
#endif
	
	/* ZNC configuration. */
	self.config.zncIgnoreConfiguredAutojoin = [self.zncIgnoreConfiguredAutojoinCheck state];
	self.config.zncIgnorePlaybackNotifications = [self.zncIgnorePlaybackNotificationsCheck state];
	
	/* Internal pong timer. */
	self.config.performPongTimer = [self.pongTimerCheck state];
	self.config.performDisconnectOnPongTimer = [self.pongTimerDisconnectCheck state];
	
	/* SSL certificate validation. */
	self.config.validateServerSSLCertificate = [self.validateServerSSLCertificateCheck state];
	
	/* Reachability changes. */
	self.config.performDisconnectOnReachabilityChange = [self.disconnectOnReachabilityChangeCheck state];
	
	/* Server address. */
	/* Get server address value. */
	NSString *hostname = [self.serverAddressCombo lowercaseValue];
	
			  hostname = [hostname cleanedServerHostmask];
	
	/* Try to match it against internal server list. */
	NSString *realhost = [self nameMatchesServerInList:hostname];
	
	if (realhost == nil) {
		self.config.serverAddress = hostname;
	} else {
		self.config.serverAddress = self.serverList[realhost];
	}
	
	/* Connection name. */
	self.config.clientName = [self.serverNameField value];
	
	/* Server port. */
	self.config.serverPort = [self.serverPortField integerValue];
	
	/* Identity */
	self.config.nickname = [self.nicknameField value];
	self.config.username = [self.usernameField value];
	self.config.realname = [self.realnameField value];
	
	self.config.awayNickname = [self.awayNicknameField value];
	
	self.config.nicknamePassword = [self.nicknamePasswordField trimmedStringValue];
	
	/* Alternate nicknames. */
	NSString *alternateNicknames = [self.alternateNicknamesField stringValue];
	
	NSArray *nicks = [alternateNicknames split:NSStringWhitespacePlaceholder];
	
	NSMutableArray *newAlternateNicknameList = [NSMutableArray array];
	
	for (NSString *s in nicks) {
		if ([s length] > 0) {
			[newAlternateNicknameList addObject:s];
		}
	}
	
	self.config.alternateNicknames = newAlternateNicknameList;
	
	/* Messages */
	self.config.sleepModeLeavingComment	= [self.sleepModeQuitMessageField value];
	self.config.normalLeavingComment = [self.normalLeavingCommentField value];
	
	/* Encoding */
	NSInteger primaryEncoding = [self.encodingList integerForKey:[self.primaryEncodingButton title]];
	NSInteger fallbackEncoding = [self.encodingList integerForKey:[self.fallbackEncodingButton title]];
	
	self.config.primaryEncoding	= primaryEncoding;
	self.config.fallbackEncoding = fallbackEncoding;
	
	/* Proxy server. */
	self.config.proxyType = [self.proxyTypeButton selectedTag];
	
	self.config.proxyAddress = [self.proxyAddressField lowercaseValue];
	self.config.proxyPort = [self.proxyPortField integerValue];
	
	self.config.proxyUsername = [self.proxyUsernameField firstTokenStringValue];
	self.config.proxyPassword = [self.proxyPasswordField trimmedStringValue];

	/* Connect Commands */
	NSString *connectCommands = [self.connectCommandsField string];
	
	NSArray *commands = [connectCommands split:NSStringNewlinePlaceholder];
	
	NSMutableArray *newConnectCommandsList = [NSMutableArray array];
	
	for (NSString *s in commands) {
		NSString *ts = [s trim];
		
		if ([ts length] > 0) {
			[newConnectCommandsList addObject:ts];
		}
	}
	
	self.config.loginCommands = newConnectCommandsList;
	
	/* Connect modes. */
	self.config.invisibleMode = [self.invisibleModeCheck state];
	
	/* Flood Control */
	self.config.outgoingFloodControl = [self.floodControlCheck state];
	
	self.config.floodControlMaximumMessages = [self.floodControlMessageCountSlider integerValue];
	self.config.floodControlDelayTimerInterval = [self.floodControlDelayTimerSlider integerValue];
	
	/* Mutable stores. */
	self.config.channelList = self.mutableChannelList;
	self.config.highlightList = self.mutableHighlightList;
	self.config.ignoreList = self.mutableIgnoreList;
	
	/* @end */
}

- (id)userDefaultsValues
{
	return RZUserDefaultsValueProxy();
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self updateConnectionPage];
}

- (void)updateConnectionPage
{
	BOOL enabled = ([self.nicknameField valueIsValid]				&&
					[self.awayNicknameField valueIsValid]			&&
					[self.usernameField valueIsValid]				&&
					[self.realnameField valueIsValid]				&&
					[self.serverNameField valueIsValid]				&&
					[self.serverAddressCombo valueIsValid]			&&
					[self.serverPortField valueIsValid]				&&
					[self.proxyAddressField valueIsValid]			&&
					[self.proxyPortField valueIsValid]				&&
					[self.normalLeavingCommentField valueIsValid]	&&
					[self.sleepModeQuitMessageField valueIsValid]);
	
	[self.okButton setEnabled:enabled];
	
	[self.erroneousInputErrorImageView setHidden:enabled];
	[self.erroneousInputErrorTextField setHidden:enabled];
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

- (void)floodControlChanged:(id)sender
{
	BOOL match = ([self.floodControlCheck state] == NSOnState);
	
	[self.floodControlContentViewToolView setHidden:(match == NO)];
}

- (void)useSSLCheckChanged:(id)sender
{
	NSInteger serverPort = [self.serverPortField integerValue];
	
	BOOL useSSL = ([self.connectionUsesSSLCheck state] == NSOnState);
	
	if (useSSL) {
		if (serverPort == 6667) {
			[self.serverPortField setStringValue:@"6697"];
		}
	} else {
		if (serverPort == 6697) {
			[self.serverPortField setStringValue:@"6667"];
		}
	}
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	/* Close anything open just incase. */
	[self closeSheets];
	
	/* Remove observer before calling updateConfig: */
	[RZNotificationCenter() removeObserver:self];
	
	/* Save changes. */
	[self save];
	
	/* Inform delegate. */
	if ([self.delegate respondsToSelector:@selector(serverSheetOnOK:)]) {
		[self.delegate serverSheetOnOK:self];
	}
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (self.requestCloudDeletionOnClose) {
		if ([self.delegate respondsToSelector:@selector(serverSheetRequestedCloudExclusionByDeletion:)]) {
			[self.delegate serverSheetRequestedCloudExclusionByDeletion:self];
		}
	}
#endif
	
	[self.sheet makeFirstResponder:nil];
	
	/* Tell super. */
	[super ok:nil];
}

- (void)cancel:(id)sender
{
	[self closeSheets];

	[RZNotificationCenter() removeObserver:self];
	
	[self.sheet makeFirstResponder:nil];
	
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
	
	BOOL enabled = (tag == IRCConnectionSocketSocks4ProxyType || tag == IRCConnectionSocketSocks5ProxyType);
	
	[self.proxyAddressField	setEnabled:enabled];
	[self.proxyPortField setEnabled:enabled];
	[self.proxyUsernameField setEnabled:enabled];
	[self.proxyPasswordField setEnabled:enabled];
	
	[self updateSSLCertificatePage];
	
	[self.proxyAddressField performValidation];
	[self.proxyPortField performValidation];
	
	[self updateConnectionPage];
}

- (void)toggleAdvancedEncodings:(id)sender
{
	NSString *selectedPrimary = [self.primaryEncodingButton titleOfSelectedItem];
	NSString *selectedFallback = [self.fallbackEncodingButton titleOfSelectedItem];
	
	[self populateEncodings];
	
	NSMenuItem *primaryItem;
	NSMenuItem *fallbackItem;
	
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

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)toggleCloudSyncExclusionRequestDeletionCallback:(TLOPopupPromptReturnType)returnType withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnType == TLOPopupPromptReturnSecondaryType) {
		self.requestCloudDeletionOnClose = YES;
	} else {
		self.requestCloudDeletionOnClose = NO;
	}
}

- (void)toggleCloudSyncExclusion:(id)sender
{
	if ([self.excludedFromCloudSyncingCheck state] == NSOnState) {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];
		
		[popup sheetWindowWithQuestion:self.sheet
								target:self
								action:@selector(toggleCloudSyncExclusionRequestDeletionCallback:withOriginalAlert:)
								  body:TXTLS(@"TDCServerSheet[1002][2]")
								 title:TXTLS(@"TDCServerSheet[1002][1]")
						 defaultButton:TXTLS(@"BasicLanguage[1182]")
					   alternateButton:TXTLS(@"BasicLanguage[1219]")
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
	} else {
		TLOPopupPrompts *popup = [TLOPopupPrompts new];
		
		[popup sheetWindowWithQuestion:self.sheet
								target:[TLOPopupPrompts class]
								action:@selector(popupPromptNilSelector:withOriginalAlert:)
								  body:TXTLS(@"TDCServerSheet[1003][2]")
								 title:TXTLS(@"TDCServerSheet[1003][1]")
						 defaultButton:TXTLS(@"BasicLanguage[1186]")
					   alternateButton:nil
						   otherButton:nil
						suppressionKey:nil
					   suppressionText:nil];
		
		self.requestCloudDeletionOnClose = NO;
	}
}
#endif

#pragma mark -
#pragma mark SSL Certificate

- (IBAction)onSSLCertificateFingerprintSHA1CopyRequested:(id)sender
{
	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", [self.sslCertificateSHA1FingerprintField stringValue]];
	
	[RZPasteboard() setStringContent:command];
}

- (IBAction)onSSLCertificateFingerprintMD5CopyRequested:(id)sender
{
	NSString *command = [NSString stringWithFormat:@"/msg NickServ cert add %@", [self.sslCertificateMD5FingerprintField stringValue]];
	
	[RZPasteboard() setStringContent:command];
}

- (void)updateSSLCertificatePage
{
	NSString *commonName = nil;
	
	NSString *sha1fingerprint = nil;
	NSString *md5fingerprint = nil;
	
	/* Proxies are ran through an older socket engine which means SSL certificate
	 validatin is not available when it is enabled. This is the check for that. */
	NSInteger proxyTag = [self.proxyTypeButton selectedTag];
	
	BOOL proxyEnabled = NSDissimilarObjects(proxyTag, IRCConnectionSocketNoProxyType);
	
	[self.sslCertificateChangeCertButton setEnabled:(proxyEnabled == NO)];
	
	/* Continue normal operations. */
	if (self.config.identitySSLCertificate && proxyEnabled == NO) {
		SecKeychainItemRef cert;
		
		CFDataRef rawCertData = (__bridge CFDataRef)(self.config.identitySSLCertificate);
		
		OSStatus status = SecKeychainItemCopyFromPersistentReference(rawCertData, &cert);
		
		if (status == noErr) {
			/* Get certificate name. */
			CFStringRef commName;
			
			status = SecCertificateCopyCommonName((SecCertificateRef)cert, &commName);
			
			if (status == noErr){
				commonName = (__bridge NSString *)(commName);
				
				CFRelease(commName);
			}
			
			/* Get certificate fingerprint. */
			CFDataRef data = SecCertificateCopyData((SecCertificateRef)cert);
			
			if (data) {
				NSData *certNormData = [NSData dataWithBytes:CFDataGetBytePtr(data) length:CFDataGetLength(data)];
				
				sha1fingerprint = [certNormData sha1];
				md5fingerprint = [certNormData md5];
				
				CFRelease(data);
			}
			
			/* Cleaning. */
			CFRelease(cert);
		}
	}
	
	BOOL hasNoCert = NSObjectIsEmpty(commonName);
	
	if (hasNoCert) {
		[self.sslCertificateCommonNameField setStringValue:TXTLS(@"TDCServerSheet[1008]")];
		
		[self.sslCertificateSHA1FingerprintField setStringValue:TXTLS(@"TDCServerSheet[1008]")];
		[self.sslCertificateMD5FingerprintField setStringValue:TXTLS(@"TDCServerSheet[1008]")];
	} else {
		[self.sslCertificateCommonNameField setStringValue:commonName];
		
		[self.sslCertificateSHA1FingerprintField setStringValue:[sha1fingerprint uppercaseString]];
		[self.sslCertificateMD5FingerprintField setStringValue:[md5fingerprint uppercaseString]];
	}
	
	[self.sslCertificateResetButton setEnabled:(hasNoCert == NO)];
	
	[self.sslCertificateSHA1FingerprintCopyButton setEnabled:(hasNoCert == NO)];
	[self.sslCertificateMD5FingerprintCopyButton setEnabled:(hasNoCert == NO)];
}

- (void)onSSLCertificateResetRequested:(id)sender
{
	self.config.identitySSLCertificate = nil;
	
	[self updateSSLCertificatePage];
}

- (void)onSSLCertificateChangeRequested:(id)sender
{
	/* Before we can present a list of certificates to the end user, we must first
	 query the keychain and build a list of all of them that exist in there first. */
	CFArrayRef identities;
	
	NSDictionary *query = @{
		(id)kSecClass		: (id)kSecClassIdentity,
		(id)kSecMatchLimit	: (id)kSecMatchLimitAll,
		(id)kSecReturnRef	: (id)kCFBooleanTrue
	};
	
	OSStatus querystatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);
	
	/* If we have a good list of identities, we present them. */
	if (querystatus == noErr) {
		SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
		
		[panel setInformativeText:TXTLS(@"TDCServerSheet[1009][2]", [self.serverNameField stringValue])];
		
		[panel setAlternateButtonTitle:BLS(1009)];
		
		NSInteger returnCode = [panel runModalForIdentities:(__bridge NSArray *)(identities)
													message:TXTLS(@"TDCServerSheet[1009][1]")];
		
		/* After the user has chose the identity, we have to update our config value
		 here and not -save since -save has nothing to reference. */
		if (returnCode == NSAlertDefaultReturn) {
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
						self.config.identitySSLCertificate = (__bridge NSData *)(certData);
						
						/* Force enable SSL. */
						if ([self.connectionUsesSSLCheck state] == NSOffState) {
							[self.connectionUsesSSLCheck setState:NSOnState];
							
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
	
	CFSafeRelease(identities);
	
	[self updateSSLCertificatePage];
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
	self.highlightSheet.config = [TDCHighlightEntryMatchCondition new];

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
	TDCHighlightEntryMatchCondition *match = [sender config];
	
	BOOL emptyKeyword = NSObjectIsEmpty([match matchKeyword]);
	
	if ([sender newItem]) {
		if (emptyKeyword == NO) {
			[self.mutableHighlightList addObject:match];
		}
	} else {
		NSArray *ignoreList = [self.mutableHighlightList copy];
		
		for (TDCHighlightEntryMatchCondition *g in ignoreList) {
			if ([[g itemUUID] isEqualToString:[match itemUUID]]) {
				NSInteger index = [ignoreList indexOfObject:g];
				
				if (emptyKeyword) {
					[self.mutableHighlightList removeObjectAtIndex:index];
				} else {
					[self.mutableHighlightList replaceObjectAtIndex:index withObject:match];
				}
				
				break;
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
	NSInteger sel = [self.channelTable selectedRow];
	
	IRCChannelConfig *config;
	
	if (sel < 0) {
		config = [IRCChannelConfig new];
	} else {
		IRCChannelConfig *c = self.mutableChannelList[sel];
		
		config = [c copy];
		
		config.itemUUID			= [NSString stringWithUUID];
		
		config.channelName		= NSStringEmptyPlaceholder;
		config.secretKey		= NSStringEmptyPlaceholder;
		config.encryptionKey	= NSStringEmptyPlaceholder;
	}
	
	self.channelSheet = nil;
	self.channelSheet = [TDChannelSheet new];
	
	self.channelSheet.newItem = YES;
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
	self.channelSheet = [TDChannelSheet new];
	
	self.channelSheet.newItem = NO;
	self.channelSheet.delegate = self;
	self.channelSheet.window = self.sheet;
	self.channelSheet.config = c;
	self.channelSheet.clientID = nil;
	self.channelSheet.channelID = nil;
	
	[self.channelSheet start];
}

- (void)channelSheetOnOK:(TDChannelSheet *)sender
{
	IRCChannelConfig *config = [sender config];
	
	BOOL emptyName = ([config.channelName length] < 2); // For the # in front.
	
	if ([sender newItem]) {
		if (emptyName == NO) {
			[self.mutableChannelList addObject:config];
		}
	} else {
		NSArray *channelList = [self.mutableChannelList copy];
		
		for (IRCChannelConfig *c in channelList) {
			if ([[c itemUUID] isEqualToString:[config itemUUID]]) {
				NSInteger index = [channelList indexOfObject:c];
				
				if (emptyName) {
					[self.mutableChannelList removeObjectAtIndex:index];
				} else {
					[self.mutableChannelList replaceObjectAtIndex:index withObject:config];
				}
				
				break;
			}
		}
	}
	
	[self reloadChannelTable];
}

- (void)channelSheetWillClose:(TDChannelSheet *)sender
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
	
	IRCAddressBookEntry *newIgnore = [IRCAddressBookEntry new];
	
	newIgnore.ignoreCTCP = YES;
	newIgnore.ignoreJPQE = YES;
	newIgnore.ignoreNotices = YES;
	newIgnore.ignorePrivateHighlights = YES;
	newIgnore.ignorePrivateMessages = YES;
	newIgnore.ignorePublicHighlights = YES;
	newIgnore.ignorePublicMessages = YES;
	newIgnore.ignoreFileTransferRequests = YES;
	
	self.ignoreSheet.newItem = YES;
	self.ignoreSheet.delegate = self;
	self.ignoreSheet.window = self.sheet;
	self.ignoreSheet.ignore = newIgnore;
	
	if ([sender tag] == 4) {
		self.ignoreSheet.ignore.entryType = IRCAddressBookUserTrackingEntryType;
	} else {
		self.ignoreSheet.ignore.entryType = IRCAddressBookIgnoreEntryType;
	}
	
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
		NSArray *ignoreList = [self.mutableIgnoreList copy];
		
		for (IRCAddressBookEntry *g in ignoreList) {
			if ([[g itemUUID] isEqualToString:[ignore itemUUID]]) {
				NSInteger index = [ignoreList indexOfObject:g];
				
				if (emptyHost) {
					[self.mutableIgnoreList removeObjectAtIndex:index];
				} else {
					[self.mutableIgnoreList replaceObjectAtIndex:index withObject:ignore];
				}
				
				break;
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
	if (sender == self.channelTable)
	{
		return [self.mutableChannelList count];
	}
	else if (sender == self.highlightsTable)
	{
		return [self.mutableHighlightList count];
	}
	else if (sender == self.ignoreTable)
	{
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
			
			if (secretKeyValue) {
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
		TDCHighlightEntryMatchCondition *c = self.mutableHighlightList[row];

		if ([columnId isEqualToString:@"keyword"]) {
			return [c matchKeyword];
		} else if ([columnId isEqualToString:@"channel"]) {
			if ([c matchChannelID] == nil) {
				return TXTLS(@"TDCServerSheet[1004]");
			} else {
				IRCChannelConfig *channel = nil;
				
				for (IRCChannelConfig *cc in self.mutableChannelList) {
					if ([[cc itemUUID] isEqualToString:[c matchChannelID]]) {
						channel = cc;
					}
				}
				
				if (channel) {
					return [channel channelName];
				} else {
					return TXTLS(@"TDCServerSheet[1004]");
				}
			}
		} else if ([columnId isEqualToString:@"type"]) {
			if ([c matchIsExcluded]) {
				return TXTLS(@"TDCServerSheet[1005]");
			} else {
				return TXTLS(@"TDCServerSheet[1006]");
			}
		}
	}
	else if (sender == self.ignoreTable)
	{
		/* Address Book Table. */
		IRCAddressBookEntry *g = self.mutableIgnoreList[row];
		
		if ([columnId isEqualToString:@"type"]) {
			if ([g entryType] == IRCAddressBookIgnoreEntryType) {
				return TXTLS(@"TDCServerSheet[1000]");
			} else {
				return TXTLS(@"TDCServerSheet[1001]");
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
	if (sender == self.channelTable)
	{
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
	
	if (sender == self.channelTable)
	{
		[self updateChannelsPage];
	}
	else if (sender == self.highlightsTable)
	{
		[self updateHighlightsPage];
	}
	else if (sender == self.ignoreTable)
	{
		[self updateIgnoresPage];
	}
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == self.channelTable)
	{
		[self editChannel:nil];
	}
	else if (sender == self.highlightsTable)
	{
		[self editHighlight:nil];
	}
	else if (sender == self.ignoreTable)
	{
		[self editIgnore:nil];
	}
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (sender == self.channelTable)
	{
		[pboard declareTypes:_tableRowTypes owner:self];
		
		[pboard setPropertyList:@[@([rows firstIndex])] forType:_tableRowType];
	}
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == self.channelTable)
	{
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
	[self.channelTable unregisterDraggedTypes];
	
	if ([self.delegate respondsToSelector:@selector(serverSheetWillClose:)]) {
		[self.delegate serverSheetWillClose:self];
	}
}

@end
