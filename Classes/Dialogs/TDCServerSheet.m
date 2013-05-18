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

#define _tableRowType		@"row"
#define _tableRowTypes		[NSArray arrayWithObject:_tableRowType]

@implementation TDCServerSheet

- (id)init
{
	if ((self = [super init])) {
		/* Populate the navigation tree. */
		[self populateTabViewList];

		/* Load our views. */
		[NSBundle loadNibNamed:@"TDCServerSheet" owner:self];

		/* Load the list of available IRC networks. */
		NSString *slp = [[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"IRCNetworks.plist"];
		
		self.serverList = [NSDictionary dictionaryWithContentsOfFile:slp];

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

		/* Connect commands text box better font. */
		NSFont *goodFont = [NSFont fontWithName:@"Lucida Grande" size:13.0];

		[self.loginCommandsField setTextContainerInset:NSMakeSize(1, 3)];
		[self.loginCommandsField setFont:goodFont];
	}
    
	return self;
}

- (void)populateTabViewList
{
	BOOL includeAdvanced = [RZUserDefaults() boolForKey:@"Server Properties Window Sheet —> Show Advanced Settings"];

	NSMutableArray *tabViewList = [NSMutableArray new];

	[tabViewList addObject:@[@"Ignores",						@"1"]];
	[tabViewList addObject:@[@"Autojoin",						@"2"]];
	[tabViewList addObject:@[@"Commands",						@"3"]];
	[tabViewList addObject:@[@"Encoding",						@"4"]];
	[tabViewList addObject:@[@"General",						@"5"]];
	[tabViewList addObject:@[@"Identity",						@"6"]];
	[tabViewList addObject:@[@"Message",						@"7"]];
	[tabViewList addObject:@[@"Mentions",						@"8"]];

	if (includeAdvanced) {
		[tabViewList addObject:@[TXDefaultListSeperatorCellIndex,	@"-"]];
		[tabViewList addObject:@[@"FloodControl",					@"9"]];
		[tabViewList addObject:@[@"Proxy",							@"10"]];
	}

	self.tabViewList = tabViewList;
}

- (void)populateEncodings
{
	[self.primaryEncodingButton removeAllItems];
	[self.fallbackEncodingButton removeAllItems];
	
	/* Build list of encodings. */
	self.encodingList = [NSString supportedStringEncodingsWithTitle:NO];

	/* What we are basically doing now is sorting all the encodings, then removing
	 UTF-8 from the sorted list and inserting it at the top of the list. */
	NSString *utf8title = [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding];

	NSMutableArray *encodingAdditions = [self.encodingList.sortedDictionaryKeys mutableCopy];

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

		NSString *encodingPrefix = [encodingTitle safeSubstringToIndex:parePos];

		if (favoredIgnored && [favoredEncodings containsObject:encodingPrefix]) {
			continue;
		} else if (favoredIgnored == NO && [favoredEncodings containsObject:encodingPrefix] == NO) {
			continue;
		}

		if ([encodingPrefix isEqualToString:previosEncodingPrefix] == NO) {
			[self.primaryEncodingButton.menu addItem:[NSMenuItem separatorItem]];
			[self.fallbackEncodingButton.menu addItem:[NSMenuItem separatorItem]];

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
		NSString *host = (self.serverList)[key];
		
		if ([hosto isEqualIgnoringCase:host]) {
			return key;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start:(NSString *)viewToken withContext:(NSString *)context
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
	
	[self updateConnectionPage];
	[self updateHighlightsPage];
	[self updateChannelsPage];
	[self updateIgnoresPage];
	[self toggleAdvancedEncodings:nil];

	[self proxyTypeChanged:nil];
    [self floodControlChanged:nil];
	
	[self reloadChannelTable];
	[self reloadIgnoreTable];
	
	if ([viewToken isEqualToString:@"floodControl"]) {
        [self showWithDefaultView:self.floodControlView andSegment:9];
    } else if ([viewToken isEqualToString:@"addressBook"]) {
		[self showWithDefaultView:self.ignoresView andSegment:0];
		
		if ([context isEqualToString:@"-"] == NO) {
			self.ignoreSheet = nil;
			
			self.ignoreSheet = [TDCAddressBookSheet new];
			self.ignoreSheet.delegate = self;
			self.ignoreSheet.window = self.sheet;
			self.ignoreSheet.newItem = YES;
			self.ignoreSheet.ignore = [IRCAddressBook new];
            
            if ([context isEqualToString:@"--"]) {
				self.ignoreSheet.ignore.hostmask = @"<nickname>";
            } else {
				self.ignoreSheet.ignore.hostmask = context;
			}

			[self.ignoreSheet start];
		}
	} else {
		[self showWithDefaultView:self.generalView andSegment:4];
    }
}

- (void)showWithDefaultView:(NSView *)view andSegment:(NSInteger)segment
{
	[self startSheet];
	
	[self focusView:view atRow:segment];
}

- (void)focusView:(NSView *)view atRow:(NSInteger)row
{
	if (NSObjectIsNotEmpty(self.contentView.subviews)) {
		[self.contentView.subviews[0] removeFromSuperview];
	}
	
	[self.contentView addSubview:view];
	
	[self.tabView selectItemAtIndex:row];
	
	[self.window recalculateKeyViewLoop]; // This makes tab work for switching input fields.

	[self makeFirstResponderForRow:row];
}

- (void)makeFirstResponderForRow:(NSInteger)row
{
	switch (row) {
		//case 2: { [self.window makeFirstResponder:self.loginCommandsField];				break; } /* self.commandsView */
		case 4: { [self.window makeFirstResponder:self.serverNameField];				break; } /* self.generalView */
		case 5: { [self.window makeFirstResponder:self.nicknameField];					break; } /* self.identityView */
		case 6: { [self.window makeFirstResponder:self.normalLeavingCommentField];		break; } /* self.messagesView */
		default: { break; }
	}
}

- (void)close
{
	self.delegate = nil;

	[super cancel:nil];
}

- (void)load
{
	/* General */

	/* Define server address. */
	NSString *networkName = [self hostFoundInServerList:self.config.serverAddress];

	if (NSObjectIsEmpty(networkName)) {
		self.serverAddressCombo.stringValue = self.config.serverAddress;
	} else {
		self.serverAddressCombo.stringValue = networkName;
	}

	/* Other paramaters. */
	self.autoConnectCheck.state				= self.config.autoConnect;
	self.autoDisconnectOnSleepCheck.state	= self.config.autoSleepModeDisconnect;
	self.autoReconnectCheck.state			= self.config.autoReconnect;
	self.connectionUsesSSLCheck.state		= self.config.connectionUsesSSL;
	self.serverNameField.stringValue		= self.config.clientName;
	self.serverPasswordField.stringValue	= self.config.serverPassword;
	self.serverPortField.stringValue		= [NSString stringWithInteger:self.config.serverPort];

    self.prefersIPv6Check.state				= self.config.connectionPrefersIPv6;

	self.pongTimerCheck.state				= self.config.performPongTimer;
	
	/* Identity */
	if (NSObjectIsEmpty(self.config.nickname)) {
		self.nicknameField.stringValue = [TPCPreferences defaultNickname];
	} else {
		self.nicknameField.stringValue = self.config.nickname;
	}

	//if (NSObjectIsEmpty(self.config.awayNickname)) {
	//	self.awayNicknameField.stringValue = [TPCPreferences defaultAwayNickname];
	//} else {
		self.awayNicknameField.stringValue = self.config.awayNickname;
	//}
	
	if (NSObjectIsEmpty(self.config.username)) {
		self.usernameField.stringValue = [TPCPreferences defaultUsername];
	} else {
		self.usernameField.stringValue = self.config.username;
	}
	
	if (NSObjectIsEmpty(self.config.realname)) {
		self.realnameField.stringValue = [TPCPreferences defaultRealname];
	} else {
		self.realnameField.stringValue = self.config.realname;
	}
	
	if (self.config.alternateNicknames.count > 0) {
		self.alternateNicknamesField.stringValue = [self.config.alternateNicknames componentsJoinedByString:NSStringWhitespacePlaceholder];
	} else {
		self.alternateNicknamesField.stringValue = NSStringEmptyPlaceholder;
	}
	
	self.nicknamePasswordField.stringValue = self.config.nicknamePassword;
	
	/* Messages */
	self.sleepModeQuitMessageField.stringValue = self.config.sleepModeLeavingComment;
	self.normalLeavingCommentField.stringValue = self.config.normalLeavingComment;

	/* Encoding */
    NSString *primaryEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.primaryEncoding)];
    NSString *fallbackEncodingTitle = [self.encodingList firstKeyForObject:@(self.config.fallbackEncoding)];

    [self.primaryEncodingButton selectItemWithTitle:primaryEncodingTitle];
    [self.fallbackEncodingButton selectItemWithTitle:fallbackEncodingTitle];
	
	/* Proxy Server */
	[self.proxyTypeButton selectItemWithTag:self.config.proxyType];
	
	self.proxyAddressField.stringValue		= self.config.proxyAddress;
	self.proxyUsernameField.stringValue		= self.config.proxyUsername;
	self.proxyPasswordField.stringValue		= self.config.proxyPassword;
	self.proxyPortField.stringValue			= [NSString stringWithInteger:self.config.proxyPort];
	
	/* Connect Commands */
	self.invisibleModeCheck.state = self.config.invisibleMode;
	
	self.loginCommandsField.string = [self.config.loginCommands componentsJoinedByString:NSStringNewlinePlaceholder];
    
    /* Flood Control */
	self.floodControlCheck.state = self.config.outgoingFloodControl;
	
    self.floodControlDelayTimerSlider.integerValue     = self.config.floodControlDelayTimerInterval;
    self.floodControlMessageCountSlider.integerValue   = self.config.floodControlMaximumMessages;

	/* @end */
}

- (void)save
{
	/* General */
	self.config.autoConnect					= self.autoConnectCheck.state;
	self.config.autoReconnect				= self.autoReconnectCheck.state;
	self.config.autoSleepModeDisconnect		= self.autoDisconnectOnSleepCheck.state;
	self.config.connectionPrefersIPv6		= self.prefersIPv6Check.state;
	self.config.connectionUsesSSL			= self.connectionUsesSSLCheck.state;
	self.config.performPongTimer			= self.pongTimerCheck.state;
	self.config.serverPassword				= self.serverPasswordField.trimmedStringValue;
	
	NSString *realhost = nil;
	NSString *hostname = [self.serverAddressCombo.firstTokenStringValue cleanedServerHostmask];
	
	if (NSObjectIsEmpty(hostname)) {
		self.config.serverAddress = @"localhost";
	} else {
		realhost = [self nameMatchesServerInList:hostname];
		
		if (NSObjectIsEmpty(realhost)) {
			self.config.serverAddress = hostname;
		} else {
			self.config.serverAddress = (self.serverList)[realhost];
		}
	}

    self.config.serverAddress = self.config.serverAddress.lowercaseString;
	
	if (NSObjectIsEmpty(self.serverNameField.trimmedStringValue)) {
		if (NSObjectIsEmpty(realhost)) {
			self.config.clientName = TXTLS(@"DefaultNewConnectionName");
		} else {
			self.config.clientName = realhost;
		}
	} else {
		self.config.clientName = self.serverNameField.trimmedStringValue;
	}
	
	if (self.serverPortField.integerValue < 1) {
		self.config.serverPort = 6667;
	} else {
		self.config.serverPort = self.serverPortField.integerValue;
	}
	
	/* Identity */
	self.config.nickname			= self.nicknameField.firstTokenStringValue;
	self.config.awayNickname		= self.awayNicknameField.firstTokenStringValue;
	self.config.username			= self.usernameField.firstTokenStringValue;
	self.config.realname			= self.realnameField.trimmedStringValue;
	self.config.nicknamePassword	= self.nicknamePasswordField.trimmedStringValue;
	
	NSArray *nicks = [self.alternateNicknamesField.trimmedStringValue split:NSStringWhitespacePlaceholder];
	
	[self.config.alternateNicknames removeAllObjects];
	
	for (NSString *s in nicks) {
		NSObjectIsEmptyAssertLoopContinue(s);

		[self.config.alternateNicknames safeAddObject:s];
	}
	
	/* Messages */
	self.config.sleepModeLeavingComment		= self.sleepModeQuitMessageField.trimmedStringValue;
	self.config.normalLeavingComment		= self.normalLeavingCommentField.trimmedStringValue;
	
	/* Encoding */
    NSInteger primaryEncoding = [self.encodingList integerForKey:self.primaryEncodingButton.title];
    NSInteger fallbackEncoding = [self.encodingList integerForKey:self.fallbackEncodingButton.title];

	self.config.primaryEncoding		= primaryEncoding;
	self.config.fallbackEncoding	= fallbackEncoding;
	
	/* Proxy Server */
	self.config.proxyType		= self.proxyTypeButton.selectedTag;
	self.config.proxyAddress	= self.proxyAddressField.firstTokenStringValue;
	self.config.proxyPort		= self.proxyPortField.integerValue;
	self.config.proxyUsername	= self.proxyUsernameField.firstTokenStringValue;
	self.config.proxyPassword	= self.proxyPasswordField.trimmedStringValue;

    self.config.proxyAddress = self.config.proxyAddress.lowercaseString;

	if (NSObjectIsEmpty(self.config.proxyAddress) && NSDissimilarObjects(self.config.proxyType, TXConnectionSystemSocksProxyType)) {
		self.config.proxyType = TXConnectionNoProxyType;
	}
	
	/* Connect Commands */
    NSArray *commands = [self.loginCommandsField.string split:NSStringNewlinePlaceholder];
	
	[self.config.loginCommands removeAllObjects];
    
	for (NSString *s in commands) {
		NSObjectIsEmptyAssertLoopContinue(s);

		[self.config.loginCommands safeAddObject:s];
	}
	
	self.config.invisibleMode = self.invisibleModeCheck.state;
    
    /* Flood Control */
	self.config.outgoingFloodControl = self.floodControlCheck.state;
	
    self.config.floodControlMaximumMessages = self.floodControlMessageCountSlider.integerValue;
    self.config.floodControlDelayTimerInterval = self.floodControlDelayTimerSlider.integerValue;

    /* @end */
}

- (void)updateConnectionPage
{
	NSString *name = self.serverNameField.trimmedStringValue;
	NSString *host = self.serverAddressCombo.trimmedStringValue;
	NSString *nick = self.nicknameField.trimmedStringValue;
	
	NSInteger port = self.serverPortField.integerValue;
	
	BOOL enabled = (NSObjectIsNotEmpty(name) &&
					NSObjectIsNotEmpty(host) && port > 0 &&
					NSObjectIsNotEmpty(nick) &&
					[host isEqualToString:@"-"] == NO);
	
	[self.okButton setEnabled:enabled];
}

- (void)updateChannelsPage
{
	NSInteger i = self.channelTable.selectedRow;
	
	[self.editChannelButton	setEnabled:(i >= 0)];
	[self.deleteChannelButton setEnabled:(i >= 0)];
}

- (void)reloadChannelTable
{
	[self.channelTable reloadData];
}

- (void)updateIgnoresPage
{
	NSInteger i = self.ignoreTable.selectedRow;
	
	[self.editIgnoreButton setEnabled:(i >= 0)];
	[self.deleteIgnoreButton setEnabled:(i >= 0)];
}

- (void)reloadIgnoreTable
{
	[self.ignoreTable reloadData];
}

- (void)updateHighlightsPage
{
	NSInteger i = self.highlightsTable.selectedRow;

	[self.editHighlightButton setEnabled:(i >= 0)];
	[self.deleteHighlightButton setEnabled:(i >= 0)];
}

- (void)reloadHighlightsTable
{
	[self.highlightsTable reloadData];
}

- (void)floodControlChanged:(id)sender
{
    BOOL match = (self.floodControlCheck.state == NSOnState);
	
    [self.floodControlToolView setHidden:BOOLReverseValue(match)];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	/* Save changes. */
	[self save];
	
	/* Inform delegate. */
	if ([self.delegate respondsToSelector:@selector(serverSheetOnOK:)]) {
		[self.delegate serverSheetOnOK:self];
	}

	[self.window makeFirstResponder:nil];

	/* Tell super. */
	[super ok:nil];
}

- (void)cancel:(id)sender
{
	[self.window makeFirstResponder:nil];

	[super cancel:nil]; 
}

- (void)serverAddressChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)proxyTypeChanged:(id)sender
{
	NSInteger tag = self.proxyTypeButton.selectedTag;
	
	BOOL enabled = (tag == TXConnectionSocks4ProxyType || tag == TXConnectionSocks5ProxyType);

	[self.proxyPortField setEnabled:enabled];
	[self.proxyAddressField	setEnabled:enabled];
	[self.proxyUsernameField setEnabled:enabled];
	[self.proxyPasswordField setEnabled:enabled];
}

- (void)toggleAdvancedEncodings:(id)sender
{
	NSString *selectedPrimary = self.primaryEncodingButton.selectedItem.title;
	NSString *selectedFallback = self.fallbackEncodingButton.selectedItem.title;

	[self populateEncodings];

	/* If advanced encodings were toggled off and we had one selected, reset the primary
	 and fallback encoding popups to the default encodings. */
	
	NSMenuItem *primaryItem;
	NSMenuItem *fallbackItem;

	if (NSObjectIsNotEmpty(selectedPrimary)) {
		primaryItem = [self.primaryEncodingButton itemWithTitle:selectedPrimary];
	}

	if (NSObjectIsNotEmpty(selectedFallback)) {
		fallbackItem = [self.fallbackEncodingButton itemWithTitle:selectedFallback];
	}

	if (PointerIsEmpty(primaryItem)) {
		selectedPrimary = [NSString localizedNameOfStringEncoding:TXDefaultPrimaryTextEncoding];
	}

	if (PointerIsEmpty(fallbackItem)) {
		selectedFallback = [NSString localizedNameOfStringEncoding:TXDefaultFallbackTextEncoding];
	}

	/* Select items. */
	[self.primaryEncodingButton selectItemWithTitle:selectedPrimary];
	[self.fallbackEncodingButton selectItemWithTitle:selectedFallback];
}

- (void)toggleAdvancedSettings:(id)sender
{
	[self populateTabViewList];

	[self.tabView reloadData];
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
	self.highlightSheet.clientID = self.clientID;
	self.highlightSheet.config = [TDCHighlightEntryMatchCondition new];

	[self.highlightSheet start];
}

- (void)editHighlight:(id)sender
{
	NSInteger sel = self.highlightsTable.selectedRow;

	NSAssertReturn(sel >= 0);

	TDCHighlightEntryMatchCondition *c = [self.config.highlightList safeObjectAtIndex:sel];

	self.highlightSheet = nil;
	self.highlightSheet = [TDCHighlightEntrySheet new];

	self.highlightSheet.newItem = NO;
	self.highlightSheet.delegate = self;
	self.highlightSheet.window = self.sheet;
	self.highlightSheet.clientID = self.clientID;
	self.highlightSheet.config = c.mutableCopy;

	[self.highlightSheet start];
}

- (void)highlightEntrySheetOnOK:(TDCHighlightEntrySheet *)sender
{
	TDCHighlightEntryMatchCondition *match = sender.config;

	BOOL emptyKeyword = NSObjectIsEmpty(match.matchKeyword);

	if (sender.newItem) {
		if (emptyKeyword == NO) {
			[self.config.highlightList safeAddObject:match];
		}
	} else {
		NSArray *ignoreList = self.config.highlightList.copy;

		for (TDCHighlightEntryMatchCondition *g in ignoreList) {
			NSInteger index = [ignoreList indexOfObject:g];

			if ([g.itemUUID isEqualToString:match.itemUUID]) {
				if (emptyKeyword) {
					/* Remove empty entry. */

					[self.config.highlightList removeObjectAtIndex:index];
				} else {
					/* Replace old entry. */

					[self.config.highlightList replaceObjectAtIndex:index withObject:match];
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
	NSInteger sel = self.highlightsTable.selectedRow;

	NSAssertReturn(sel >= 0);

	[self.config.highlightList safeRemoveObjectAtIndex:sel];

	NSInteger count = self.config.highlightList.count;

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
	NSInteger sel = self.channelTable.selectedRow;
	
	IRCChannelConfig *config;
	
	if (sel < 0) {
		config = [IRCChannelConfig new];
	} else {
		IRCChannelConfig *c = [self.config.channelList safeObjectAtIndex:sel];
		
		config = c.mutableCopy;
		
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
	NSInteger sel = self.channelTable.selectedRow;

	NSAssertReturn(sel >= 0);
	
	IRCChannelConfig *c = [self.config.channelList safeObjectAtIndex:sel];

	self.channelSheet = nil;
	self.channelSheet = [TDChannelSheet new];

	self.channelSheet.newItem = NO;
	self.channelSheet.delegate = self;
	self.channelSheet.window = self.sheet;
	self.channelSheet.config = c.mutableCopy;
	self.channelSheet.clientID = nil;
	self.channelSheet.channelID = nil;
	
	[self.channelSheet start];
}

- (void)channelSheetOnOK:(TDChannelSheet *)sender
{
	IRCChannelConfig *config = sender.config;

	BOOL emptyName = (config.channelName.length < 2); // For the # in front.

	if (sender.newItem) {
		if (emptyName == NO) {
			[self.config.channelList safeAddObject:config];
		}
	} else {
		NSArray *channelList = self.config.channelList.copy;
		
		for (IRCChannelConfig *c in channelList) {
			NSInteger index = [channelList indexOfObject:c];

			if ([c.itemUUID isEqualToString:config.itemUUID]) {
				if (emptyName) {
					/* Remove empty channel names. */

					[self.config.channelList removeObjectAtIndex:index];
				} else {
					/* Update existing. */

					[self.config.channelList replaceObjectAtIndex:index withObject:c];
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
	NSInteger sel = self.channelTable.selectedRow;

	NSAssertReturn(sel >= 0);
	
	[self.config.channelList safeRemoveObjectAtIndex:sel];
	
	NSInteger count = self.config.channelList.count;
	
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
	NSRect tableRect = self.ignoreTable.frame;
	
	tableRect.origin.y += (tableRect.size.height);
	tableRect.origin.y += 34;
    
	[self.addIgnoreMenu popUpMenuPositioningItem:nil atLocation:tableRect.origin inView:self.ignoreTable];
}

- (void)addIgnore:(id)sender
{
	self.ignoreSheet = nil;
	self.ignoreSheet = [TDCAddressBookSheet new];

	self.ignoreSheet.newItem = YES;
	self.ignoreSheet.delegate = self;
	self.ignoreSheet.window = self.sheet;
	self.ignoreSheet.ignore = [IRCAddressBook new];
	
	if ([sender tag] == 4) {
		self.ignoreSheet.ignore.entryType = IRCAddressBookUserTrackingEntryType;
	} else {
		self.ignoreSheet.ignore.entryType = IRCAddressBookIgnoreEntryType;
	}
	
	[self.ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
	NSInteger sel = self.ignoreTable.selectedRow;

	NSAssertReturn(sel >= 0);

	IRCAddressBook *c = [self.config.ignoreList safeObjectAtIndex:sel];
	
	self.ignoreSheet = nil;
	self.ignoreSheet = [TDCAddressBookSheet new];

	self.ignoreSheet.newItem = NO;
	self.ignoreSheet.delegate = self;
	self.ignoreSheet.window = self.sheet;
	self.ignoreSheet.ignore = c.mutableCopy;
	
	[self.ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
	NSInteger sel = self.ignoreTable.selectedRow;

	NSAssertReturn(sel >= 0);
	
	[self.config.ignoreList safeRemoveObjectAtIndex:sel];
	
	NSInteger count = self.config.ignoreList.count;
	
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
	IRCAddressBook *ignore = sender.ignore;
	
	BOOL emptyHost = NSObjectIsEmpty(ignore.hostmask);

	if (sender.newItem) {
		if (emptyHost == NO) {
			[self.config.ignoreList safeAddObject:ignore];
		}
	} else {
		NSArray *ignoreList = self.config.ignoreList.copy;

		for (IRCAddressBook *g in ignoreList) {
			NSInteger index = [ignoreList indexOfObject:g];

			if ([g.itemUUID isEqualToString:ignore.itemUUID]) {
				if (emptyHost) {
					/* Remove empty entry. */

					[self.config.ignoreList removeObjectAtIndex:index];
				} else {
					/* Replace old entry. */

					[self.config.ignoreList replaceObjectAtIndex:index withObject:ignore];
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
	if (sender == self.channelTable) {
		/* Channel Table. */
		
		return self.config.channelList.count;
	} else if (sender == self.tabView) {
		/* Navigation Table. */
		
		return self.tabViewList.count;
	} else if (sender == self.highlightsTable) {
		/* Highlight Table. */
		
		return self.config.highlightList.count;
	} else {
		/* Address Book Table. */
		
		return self.config.ignoreList.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSString *columnId = column.identifier;
	
	if (sender == self.channelTable) {
		/* Channel Table. */

		IRCChannelConfig *c = [self.config.channelList safeObjectAtIndex:row];
		
		if ([columnId isEqualToString:@"name"]) {
			return c.channelName;
		} else if ([columnId isEqualToString:@"pass"]) {
			return c.secretKey;
		} else if ([columnId isEqualToString:@"join"]) {
			return @(c.autoJoin);
		}
	} else if (sender == self.tabView) {
		/* Navigation Table. */

		NSArray *tabInfo = [self.tabViewList safeObjectAtIndex:row];
        
        NSString *keyhead = [tabInfo safeObjectAtIndex:0];
        
        if ([keyhead isEqualToString:TXDefaultListSeperatorCellIndex] == NO) {
            NSString *langkey = [NSString stringWithFormat:@"ServerSheet%@NavigationTreeItem", keyhead];
            
            return TXTLS(langkey);
        } else {
            return TXDefaultListSeperatorCellIndex;
        }
	} else if (sender == self.highlightsTable) {
		/* Highlight Table. */
		TDCHighlightEntryMatchCondition *c = [self.config.highlightList safeObjectAtIndex:row];

		if ([columnId isEqualToString:@"keyword"]) {
			return c.matchKeyword;
		} else if ([columnId isEqualToString:@"channel"]) {
			if (NSObjectIsEmpty(c.matchChannelID)) {
				return TXTLS(@"ServerSheetHighlightListTableAllChannels");
			} else {
				IRCChannel *channel = [self.worldController findChannelByClientId:self.clientID channelId:c.matchChannelID];

				if (channel) {
					return channel.name;
				} else {
					return TXTLS(@"ServerSheetHighlightListTableAllChannels");
				}
			}
		} else if ([columnId isEqualToString:@"type"]) {
			if (c.matchIsExcluded) {
				return TXTLS(@"ServerSheetHighlightListTableExcludeEntry");
			} else {
				return TXTLS(@"ServerSheetHighlightListTableIncludeEntry");
			}
		}
	} else {
		/* Address Book Table. */

		IRCAddressBook *g = [self.config.ignoreList safeObjectAtIndex:row];
		
		if ([columnId isEqualToString:@"type"]) {
			if (g.entryType == IRCAddressBookIgnoreEntryType) {
				return TXTLS(@"AddressBookIgnoreEntryType");
			} else {
				return TXTLS(@"AddressBookUserTrackingEntryType");
			}
		} else {
			return g.hostmask;
		}
	}
	
	return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if (tableView == self.tabView) {
		/* Navigation Table. */

		NSArray *tabInfo = [self.tabViewList safeObjectAtIndex:row];
		
		NSString *keyhead = [tabInfo safeObjectAtIndex:0];
		
		if ([keyhead isEqualToString:TXDefaultListSeperatorCellIndex]) {
			return NO;
		}
	}
	
	return YES;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == self.channelTable) {
		/* Channel Table. */

		IRCChannelConfig *c = [self.config.channelList safeObjectAtIndex:row];
		
		if ([column.identifier isEqualToString:@"join"]) {
			c.autoJoin = BOOLReverseValue([obj integerValue] == 0);
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	id sender = [note object];
	
	if (sender == self.channelTable) {
		/* Channel Table. */

		[self updateChannelsPage];
	} else if (sender == self.tabView) {
		/* Navigation Table. */

		NSInteger row = [self.tabView selectedRow];
		
        switch (row) {
            case 0:  { [self focusView:self.ignoresView			atRow:0]; break; }
            case 1:  { [self focusView:self.autojoinView		atRow:1]; break; }
            case 2:  { [self focusView:self.commandsView		atRow:2]; break; }
            case 3:  { [self focusView:self.encodingView		atRow:3]; break; }
            case 4:  { [self focusView:self.generalView			atRow:4]; break; }
            case 5:  { [self focusView:self.identityView		atRow:5]; break; }
            case 6:  { [self focusView:self.messagesView		atRow:6]; break; }
			case 7:  { [self focusView:self.highlightsView		atRow:7]; break; }
            case 9:  { [self focusView:self.floodControlView	atRow:9]; break; }
            case 10: { [self focusView:self.proxyServerView		atRow:10]; break; }

            default: { break; }
        }
	} else if (sender == self.highlightsTable) {
		/* Highlight Table. */

		[self updateHighlightsPage];
    } else {
		/* Ignore Table. */

        [self updateIgnoresPage];
    }
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == self.channelTable) {
		/* Channel Table. */
		
		[self editChannel:nil];
	} else if (sender == self.tabView) {
		/* Navigation Table. */
		
		// ...
	} else if (sender == self.highlightsTable) {
		/* Highlight Table. */

		[self editHighlight:nil];
	} else {
		/* Ignore Table. */
		
		[self editIgnore:nil];
	}
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (sender == self.channelTable) {
		/* Channel Table. */
		
		[pboard declareTypes:_tableRowTypes owner:self];
		
		[pboard setPropertyList:@[@(rows.firstIndex)] forType:_tableRowType];
	}
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == self.channelTable) {
		/* Channel Table. */

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
	if (sender == self.channelTable) {
		/* Channel Table. */

		NSPasteboard *pboard = [info draggingPasteboard];
		
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:_tableRowTypes]) {
			NSMutableArray *ary = self.config.channelList;
			
			NSArray *selectedRows = [pboard propertyListForType:_tableRowType];
			NSInteger selectedRow = [selectedRows integerAtIndex:0];
			
			IRCChannelConfig *target = [ary safeObjectAtIndex:selectedRow];
			
			NSMutableArray *low  = [[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy];
			NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(row, (ary.count - row))] mutableCopy];
			
			[low removeObjectIdenticalTo:target];
			[high removeObjectIdenticalTo:target];
			
			[ary removeAllObjects];
			
			[ary addObjectsFromArray:low];
			[ary safeAddObject:target];
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
