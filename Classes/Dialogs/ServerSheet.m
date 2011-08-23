// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TABLE_ROW_TYPE			@"row"
#define TABLE_ROW_TYPES			[NSArray arrayWithObject:TABLE_ROW_TYPE]

#define TIMEOUT_INT_MIN     0
#define TIMEOUT_INT_MAX     360

@interface ServerSheet (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
- (void)reloadChannelTable;
- (void)updateIgnoresPage;
- (void)reloadIgnoreTable;
- (void)focusView:(NSView *)view atRow:(NSInteger)row;
@end

@implementation ServerSheet

@synthesize generalView;
@synthesize identityView;
@synthesize messagesView;
@synthesize encodingView;
@synthesize autojoinView;
@synthesize ignoresView;
@synthesize socketsView;
@synthesize commandsView;
@synthesize floodControlView;
@synthesize floodControlToolView;
@synthesize proxyServerView;
@synthesize addChannelButton;
@synthesize addIgnoreButton;
@synthesize altNicksText;
@synthesize prefersIPv6Check;
@synthesize autoConnectCheck;
@synthesize autoReconnectCheck;
@synthesize channelSheet;
@synthesize channelTable;
@synthesize client;
@synthesize config;
@synthesize contentView;
@synthesize deleteChannelButton;
@synthesize deleteIgnoreButton;
@synthesize editChannelButton;
@synthesize editIgnoreButton;
@synthesize encodingCombo;
@synthesize fallbackEncodingCombo;
@synthesize hostCombo;
@synthesize ignoreSheet;
@synthesize ignoreTable;
@synthesize invisibleCheck;
@synthesize addIgnoreMenu;
@synthesize leavingCommentText;
@synthesize loginCommandsText;
@synthesize nameText;
@synthesize nickPasswordText;
@synthesize nickText;
@synthesize passwordText;
@synthesize portText;
@synthesize proxyCombo;
@synthesize proxyHostText;
@synthesize proxyPasswordText;
@synthesize proxyPortText;
@synthesize proxyUserText;
@synthesize realNameText;
@synthesize sleepQuitMessageText;
@synthesize sslCheck;
@synthesize saslCheck;
@synthesize tabView;
@synthesize uid;
@synthesize pongInterval;
@synthesize timeoutInterval;
@synthesize usernameText;
@synthesize floodControlDelayTimer;
@synthesize floodControlMessageCount;
@synthesize outgoingFloodControl;
@synthesize incomingFloodControl;

- (id)init
{
	if ((self = [super init])) {
		tabViewList = [NSMutableArray new];
		
		[tabViewList addObject:[NSArray arrayWithObjects:@"GENERAL",				@"1", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"IDENTITY",				@"2", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"MESSAGES",				@"3", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"ENCODING",				@"4", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"AUTOJOIN",				@"5", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"IGNORES",				@"6", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"COMMANDS",				@"7", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:ListSeparatorCellIndex,	@"-", NSNumberWithBOOL(NO), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"PROXY",					@"8", NSNumberWithBOOL(NO), nil]];
        [tabViewList addObject:[NSArray arrayWithObjects:@"SOCKETS",				@"9", NSNumberWithBOOL(YES), nil]];
		[tabViewList addObject:[NSArray arrayWithObjects:@"FLOODC",					@"10", NSNumberWithBOOL(NO), nil]];
		
		[NSBundle loadNibNamed:@"ServerSheet" owner:self];
		
		serverList = [NSDictionary dictionaryWithContentsOfFile:[[Preferences whereResourcePath] stringByAppendingPathComponent:@"IRCNetworks.plist"]];
		[serverList retain];
		
		NSArray *sortedKeys = [[serverList allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		for (NSString *key in sortedKeys) {
			[hostCombo addItemWithObjectValue:key];
		}
		
		[leavingCommentText		setFont:[NSFont systemFontOfSize:13.0]];
		[sleepQuitMessageText	setFont:[NSFont systemFontOfSize:13.0]];
		[loginCommandsText		setFont:[NSFont systemFontOfSize:13.0]];
	}
    
	return self;
}

- (void)dealloc
{
	[config drain];
	[serverList drain];
	[ignoreSheet drain];
	[identityView drain];
	[messagesView drain];
	[encodingView drain];
	[autojoinView drain];
	[ignoresView drain];
	[commandsView drain];
	[proxyServerView drain];
	[ignoresView drain];
	[tabViewList drain];
	[channelSheet drain];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Server List Factory

- (NSString *)nameMatchesServerInList:(NSString *)name
{
	for (NSString *key in serverList) {
		if ([name isEqualNoCase:key]) {
			return key;
		}
	}
	
	return nil;
}

- (NSString *)hostFoundInServerList:(NSString *)hosto
{
	for (NSString *key in serverList) {
		NSString *host = [serverList objectForKey:key];
		
		if ([hosto isEqualNoCase:host]) {
			return key;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Initalization Handler

- (void)startWithIgnoreTab:(NSString *)imask
{
	[channelTable setTarget:self];
	[channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[channelTable registerForDraggedTypes:TABLE_ROW_TYPES];
	
	[ignoreTable setTarget:self];
	[ignoreTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[ignoreTable registerForDraggedTypes:TABLE_ROW_TYPES];
	
	[self load];
	
	[self updateConnectionPage];
	[self updateChannelsPage];
	[self updateIgnoresPage];
	[self encodingChanged:nil];
	[self proxyChanged:nil];
	[self reloadChannelTable];
	[self reloadIgnoreTable];
	
	if (NSObjectIsNotEmpty(imask)) {
		[self showWithDefaultView:ignoresView andSegment:5];
		
		if ([imask isEqualToString:@"-"] == NO) {
			[ignoreSheet drain];
			ignoreSheet = nil;
			
			ignoreSheet = [AddressBookSheet new];
			ignoreSheet.delegate = self;
			ignoreSheet.window = sheet;
			ignoreSheet.newItem = YES;
			
			ignoreSheet.ignore = [AddressBook new];
            
            if ([imask isEqualToString:@"--"]) {
                ignoreSheet.ignore.hostmask = @"<nickname>";
            } else {
                ignoreSheet.ignore.hostmask = imask;
			}
            
            [ignoreSheet.ignore processHostMaskRegex];
			[ignoreSheet start];
		}
	} else {
		[self show];
	}
}

- (void)show
{
	[self showWithDefaultView:generalView andSegment:0];
}

- (void)showWithDefaultView:(NSView *)view andSegment:(NSInteger)segment
{
	[self startSheet];
	[self focusView:view atRow:segment];
}

- (void)focusView:(NSView *)view atRow:(NSInteger)row
{
	if (NSObjectIsNotEmpty([contentView subviews])) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[contentView addSubview:view];
	[tabView selectItemAtIndex:row];
	
	[self.window recalculateKeyViewLoop];
}

- (void)close
{
	delegate = nil;
	
	[self endSheet];
}

- (void)load
{
	/* General */
	nameText.stringValue		= config.name;
	hostCombo.stringValue		= (([self hostFoundInServerList:config.host]) ?: config.host);
	passwordText.stringValue	= config.password;
	portText.integerValue		= config.port;
	sslCheck.state				= config.useSSL;
    saslCheck.state             = config.useSASL;
	bouncerModeCheck.state		= config.bouncerMode;
	autoConnectCheck.state		= config.autoConnect;
	autoReconnectCheck.state	= config.autoReconnect;
    prefersIPv6Check.state      = config.prefersIPv6;
	
	/* Identity */
	if (NSObjectIsEmpty(config.nick)) {
		nickText.stringValue = [Preferences defaultNickname];
	} else {
		nickText.stringValue = config.nick;
	}
	
	if (NSObjectIsEmpty(config.username)) {
		usernameText.stringValue = [Preferences defaultUsername];
	} else {
		usernameText.stringValue = config.username;
	}
	
	if (NSObjectIsEmpty(config.realName)) {
		realNameText.stringValue = [Preferences defaultRealname];
	} else {
		realNameText.stringValue = config.realName;
	}
	
	if (config.altNicks.count > 0) {
		altNicksText.stringValue = [config.altNicks componentsJoinedByString:NSWhitespaceCharacter];
	} else {
		altNicksText.stringValue = NSNullObject;
	}
	
	nickPasswordText.stringValue = config.nickPassword;
	
	/* Messages */
	sleepQuitMessageText.string = config.sleepQuitMessage;
	leavingCommentText.string	= config.leavingComment;
	
	/* Encoding */
	[encodingCombo			selectItemWithTag:config.encoding];
	[fallbackEncodingCombo	selectItemWithTag:config.fallbackEncoding];
	
	/* Proxy Server */
	[proxyCombo selectItemWithTag:config.proxyType];
	
	proxyHostText.stringValue		= config.proxyHost;
	proxyPortText.integerValue		= config.proxyPort;
	proxyUserText.stringValue		= config.proxyUser;
	proxyPasswordText.stringValue	= config.proxyPassword;
	
	/* Connect Commands */
	invisibleCheck.state		= config.invisibleMode;
	loginCommandsText.string	= [config.loginCommands componentsJoinedByString:NSNewlineCharacter];
    
    /* Sockets */
    pongInterval.integerValue    = config.pongInterval;
    timeoutInterval.integerValue = config.timeoutInterval;
    
    /* Flood Control */
    floodControlDelayTimer.integerValue     = config.floodControlDelayTimerInterval;
    floodControlMessageCount.integerValue   = config.floodControlMaximumMessages;
    outgoingFloodControl.state              = config.outgoingFloodControl;
    incomingFloodControl.state              = config.incomingFloodControl;
    
    [self floodControlChanged:nil];
}

- (void)save
{
	/* General */
	config.autoConnect		= autoConnectCheck.state;
	config.autoReconnect	= autoReconnectCheck.state;
	config.bouncerMode		= bouncerModeCheck.state;
    config.prefersIPv6      = prefersIPv6Check.state;
	
	NSString *realHost		= nil;
	NSString *hostname		= [hostCombo.stringValue cleanedServerHostmask];
	
	if (NSObjectIsEmpty(hostname)) {
		config.host = @"localhost";
	} else {
		realHost = [self nameMatchesServerInList:hostname];
		
		if (NSObjectIsEmpty(realHost)) {
			config.host = hostname;
		} else {
			config.host = [serverList objectForKey:realHost];
		}
	}
	
	if (NSObjectIsEmpty(nameText.stringValue)) {
		if (NSObjectIsEmpty(realHost)) {
			config.name = TXTLS(@"UNTITLED_CONNECTION_NAME");
		} else {
			config.name = realHost;
		}
	} else {
		config.name = nameText.stringValue;
	}
	
	if (portText.integerValue < 1) {
		config.port = 6667;
	} else {
		config.port = portText.integerValue;
	}
	
	config.useSSL = sslCheck.state;
    config.useSASL = saslCheck.state;
	
	/* Identity */
	config.nick				= nickText.stringValue;
	config.password			= passwordText.stringValue;
	config.username			= usernameText.stringValue;
	config.realName			= realNameText.stringValue;
	config.nickPassword		= nickPasswordText.stringValue;
	
	NSArray *nicks = [altNicksText.stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	[config.altNicks removeAllObjects];
	
	for (NSString *s in nicks) {
		if (NSObjectIsNotEmpty(s)) {
			[config.altNicks safeAddObject:s];
		}
	}
	
	/* Messages */
	config.sleepQuitMessage = sleepQuitMessageText.string;
	config.leavingComment = leavingCommentText.string;
	
	/* Encoding */
	config.encoding = encodingCombo.selectedTag;
	config.fallbackEncoding = fallbackEncodingCombo.selectedTag;
	
	/* Proxy Server */
	config.proxyType = proxyCombo.selectedTag;
	config.proxyHost = proxyHostText.stringValue;
	config.proxyPort = proxyPortText.intValue;
	config.proxyUser = proxyUserText.stringValue;
	config.proxyPassword = proxyPasswordText.stringValue;
	
	/* Connect Commands */
    NSArray *commands = [loginCommandsText.string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	[config.loginCommands removeAllObjects];
    
	for (NSString *s in commands) {
		if (NSObjectIsNotEmpty(s)) {
			[config.loginCommands safeAddObject:s];
		}
	}
	
	config.invisibleMode = invisibleCheck.state;
    
    /* Sockets */
    
    config.pongInterval = pongInterval.integerValue;
    config.timeoutInterval = timeoutInterval.integerValue;
    
    [client pongTimerIntervalChanged];
    
    /* Flood Control */
    config.floodControlMaximumMessages      = floodControlMessageCount.integerValue;
    config.floodControlDelayTimerInterval   = floodControlDelayTimer.integerValue;
    config.outgoingFloodControl             = outgoingFloodControl.state;
    config.incomingFloodControl             = incomingFloodControl.state;
}

- (void)updateConnectionPage
{
	NSString *name = [nameText stringValue];
	NSString *host = [hostCombo stringValue];
	NSString *nick = [nickText stringValue];
	
	NSInteger port = [portText integerValue];
	
	BOOL enabled = (NSObjectIsNotEmpty(name) && NSObjectIsNotEmpty(host) && [host isEqualToString:@"-"] == NO && port > 0 && NSObjectIsNotEmpty(nick));
	
	[okButton setEnabled:enabled];
}

- (void)updateChannelsPage
{
	NSInteger i = [channelTable selectedRow];
	
	BOOL count   = (i >= 0);
	BOOL bouncer = BOOLReverseValue([bouncerModeCheck state]);
	BOOL enabled = (count && bouncer);
	
	[addChannelButton		setEnabled:bouncer];
	[editChannelButton		setEnabled:enabled];
	[deleteChannelButton	setEnabled:enabled];
}

- (void)reloadChannelTable
{
	[channelTable reloadData];
	[channelTable setEnabled:BOOLReverseValue([bouncerModeCheck state])];
}

- (void)updateIgnoresPage
{
	NSInteger i = [ignoreTable selectedRow];
	
	BOOL enabled = (i >= 0);
	
	[editIgnoreButton	setEnabled:enabled];
	[deleteIgnoreButton setEnabled:enabled];
}

- (void)reloadIgnoreTable
{
	[ignoreTable reloadData];
}

- (void)floodControlChanged:(id)sender
{
    BOOL match = (incomingFloodControl.state == NSOnState || outgoingFloodControl.state == NSOnState);
        
    [floodControlToolView setHidden:BOOLReverseValue(match)];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	NSMutableArray *ignores = config.ignores;
	
	for (NSInteger i = (ignores.count - 1); i >= 0; --i) {
		AddressBook *g = [ignores safeObjectAtIndex:i];
		
		if (NSObjectIsEmpty(g.hostmask)) {
			[ignores safeRemoveObjectAtIndex:i];
		}
	}
	
	if ([delegate respondsToSelector:@selector(ServerSheetOnOK:)]) {
		[delegate ServerSheetOnOK:self];
	}
	
	[self endSheet];
}

- (void)cancel:(id)sender
{
	[self endSheet];
}

- (void)hostComboChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)encodingChanged:(id)sender
{
	[fallbackEncodingCombo setEnabled:([encodingCombo selectedTag] == NSUTF8StringEncoding)];
}

- (void)proxyChanged:(id)sender
{
	NSInteger tag = [proxyCombo selectedTag];
	
	BOOL enabled = (tag == PROXY_SOCKS4 || tag == PROXY_SOCKS5);
	
	[proxyHostText		setEnabled:enabled];
	[proxyPortText		setEnabled:enabled];
	[proxyUserText		setEnabled:enabled];
	[proxyPasswordText	setEnabled:enabled];
}

- (void)bouncerModeChanged:(id)sender
{
	[channelTable setEnabled:BOOLReverseValue([bouncerModeCheck state])];
}

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	
	IRCChannelConfig *conf;
	
	if (sel < 0) {
		conf = [IRCChannelConfig newad];
	} else {
		IRCChannelConfig *c = [config.channels safeObjectAtIndex:sel];
		
		conf = [[c mutableCopy] autodrain];
		conf.name = NSNullObject;
	}
	
	[channelSheet drain];
	channelSheet = nil;
	
	channelSheet = [ChannelSheet new];
	channelSheet.delegate = self;
	channelSheet.window = sheet;
	channelSheet.config = conf;
	channelSheet.uid = 1;
	channelSheet.cid = -1;
	[channelSheet show];
}

- (void)editChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	if (sel < 0) return;
	
	IRCChannelConfig *c = [[[config.channels safeObjectAtIndex:sel] mutableCopy] autodrain];
	
	[channelSheet drain];
	channelSheet = nil;
	
	channelSheet = [ChannelSheet new];
	channelSheet.delegate = self;
	channelSheet.window = sheet;
	channelSheet.config = c;
	channelSheet.uid = 1;
	channelSheet.cid = 1;
	[channelSheet show];
}

- (void)ChannelSheetOnOK:(ChannelSheet *)sender
{
	IRCChannelConfig *conf = sender.config;
	
	NSString *name = conf.name;
	
	NSInteger i = 0;
	NSInteger n = -1;
	
	for (IRCChannelConfig *c in config.channels) {
		if ([c.name isEqualToString:name]) {
			n = i;
			
			break;
		}
		
		++i;
	}
	
	if (n < 0) {
		[config.channels safeAddObject:conf];
	} else {
		[config.channels replaceObjectAtIndex:n withObject:conf];
	}
	
	[self reloadChannelTable];
}

- (void)ChannelSheetWillClose:(ChannelSheet *)sender
{
	[channelSheet drain];
	channelSheet = nil;
}

- (void)deleteChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	if (sel < 0) return;
	
	[config.channels safeRemoveObjectAtIndex:sel];
	
	NSInteger count = config.channels.count;
	
	if (count) {
		if (count <= sel) {
			[channelTable selectItemAtIndex:(count - 1)];
		} else {
			[channelTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadChannelTable];
}

#pragma mark -
#pragma mark Ignore Actions

- (void)showAddIgnoreMenu:(id)sender
{
	NSRect tableRect = [ignoreTable frame];
	
	tableRect.origin.y += (tableRect.size.height);
	tableRect.origin.y += 34;
    
	[addIgnoreMenu popUpMenuPositioningItem:nil atLocation:tableRect.origin
                                     inView:ignoreTable];
}
- (void)addIgnore:(id)sender
{
	[ignoreSheet drain];
	ignoreSheet = nil;
	
	ignoreSheet = [AddressBookSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = sheet;
	ignoreSheet.ignore = [AddressBook new];
	ignoreSheet.newItem = YES;
	
	if ([sender tag] == 4) {
		ignoreSheet.ignore.entryType = ADDRESS_BOOK_TRACKING_ENTRY;
	} else {
		ignoreSheet.ignore.entryType = ADDRESS_BOOK_IGNORE_ENTRY;
	}
	
	[ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
	NSInteger sel = [ignoreTable selectedRow];
	if (sel < 0) return;
	
	[ignoreSheet drain];
	ignoreSheet = nil;
	
	ignoreSheet = [AddressBookSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = sheet;
	ignoreSheet.ignore = [config.ignores safeObjectAtIndex:sel];
	[ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
	NSInteger sel = [ignoreTable selectedRow];
	if (sel < 0) return;
	
	[config.ignores safeRemoveObjectAtIndex:sel];
	
	NSInteger count = config.ignores.count;
	
	if (count) {
		if (count <= sel) {
			[ignoreTable selectItemAtIndex:(count - 1)];
		} else {
			[ignoreTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadIgnoreTable];
	
	[client populateISONTrackedUsersList:config.ignores];
}

- (void)ignoreItemSheetOnOK:(AddressBookSheet *)sender
{
	NSString *hostmask = [sender.ignore.hostmask trim];
	
	if (sender.newItem) {
		if (NSObjectIsNotEmpty(hostmask)) {
			[config.ignores safeAddObject:sender.ignore];
		}
	} else {
		if (NSObjectIsEmpty(hostmask)) {
			[config.ignores removeObject:sender.ignore];
		}
	}
	
	[self reloadIgnoreTable];
	
	[client populateISONTrackedUsersList:config.ignores];
}

- (void)ignoreItemSheetWillClose:(AddressBookSheet *)sender
{
	[ignoreSheet drain];
	ignoreSheet = nil;
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == channelTable) {
		return config.channels.count;
	} else if (sender == tabView) {
		return tabViewList.count;
	} else {
		return config.ignores.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSString *columnId = [column identifier];
	
	if (sender == channelTable) {
		IRCChannelConfig *c = [config.channels safeObjectAtIndex:row];
		
		if ([columnId isEqualToString:@"name"]) {
			return c.name;
		} else if ([columnId isEqualToString:@"pass"]) {
			return c.password;
		} else if ([columnId isEqualToString:@"join"]) {
			return NSNumberWithBOOL(c.autoJoin);
		}
	} else if (sender == tabView) {
		NSArray *tabInfo = [tabViewList safeObjectAtIndex:row];
        
        NSString *keyhead = [tabInfo safeObjectAtIndex:0];
        
        if ([keyhead isEqualToString:ListSeparatorCellIndex] == NO) {
            NSString *langkey = [NSString stringWithFormat:@"SERVER_SHEET_NAVIGATION_LIST_%@", keyhead];
            
            return TXTLS(langkey);
        } else {
            return ListSeparatorCellIndex;
        }
	} else {
		AddressBook *g = [config.ignores safeObjectAtIndex:row];
		
		if ([columnId isEqualToString:@"type"]) {
			if (g.entryType == ADDRESS_BOOK_IGNORE_ENTRY) {
				return TXTLS(@"ADDRESS_BOOK_ENTRY_IGNORE_TYPE");
			} else {
				return TXTLS(@"ADDRESS_BOOK_EMTRY_TRACKING_TYPE");
			}
		} else {
			return g.hostmask;
		}
	}
	
	return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if (tableView == tabView) {
		NSArray *tabInfo = [tabViewList safeObjectAtIndex:row];
		
		NSString *keyhead = [tabInfo safeObjectAtIndex:0];
		
		if ([keyhead isEqualToString:ListSeparatorCellIndex]) {
			return NO;
		}
	}
	
	return YES;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == channelTable) {
		IRCChannelConfig *c = [config.channels safeObjectAtIndex:row];
		
		NSString *columnId = [column identifier];
		
		if ([columnId isEqualToString:@"join"]) {
			c.autoJoin = BOOLReverseValue([obj integerValue] == 0);
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	id sender = [note object];
	
	if (sender == channelTable) {
		[self updateChannelsPage];
	} else if (sender == tabView) {
		NSInteger row = [tabView selectedRow];
		
        switch (row) {
            case 0:  [self focusView:generalView		atRow:0]; break;
            case 1:  [self focusView:identityView       atRow:1]; break;
            case 2:  [self focusView:messagesView       atRow:2]; break;
            case 3:  [self focusView:encodingView       atRow:3]; break;
            case 4:  [self focusView:autojoinView       atRow:4]; break;
            case 5:  [self focusView:ignoresView		atRow:5]; break;
            case 6:  [self focusView:commandsView       atRow:6]; break;
            case 8:  [self focusView:proxyServerView    atRow:8]; break;
            case 9:  [self focusView:socketsView        atRow:9]; break;
            case 10: [self focusView:floodControlView   atRow:10]; break;
            default: break;
        }
    } else {
        [self updateIgnoresPage];
    }
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == channelTable) {
		[self editChannel:nil];
	} else if (sender == tabView) {
		// ...
	} else {
		[self editIgnore:nil];
	}
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (sender == channelTable) {
		NSArray *ary = [NSArray arrayWithObject:NSNumberWithInteger([rows firstIndex])];
        
		[pboard declareTypes:TABLE_ROW_TYPES owner:self];
		[pboard setPropertyList:ary forType:TABLE_ROW_TYPE];
	}
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == channelTable) {
		NSPasteboard *pboard = [info draggingPasteboard];
        
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
			return NSDragOperationGeneric;
		} else {
			return NSDragOperationNone;
		}
	} else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	if (sender == channelTable) {
		NSPasteboard *pboard = [info draggingPasteboard];
		
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
			NSMutableArray *ary = config.channels;
			
			NSArray  *selectedRows	= [pboard propertyListForType:TABLE_ROW_TYPE];
			NSInteger sel			= [selectedRows integerAtIndex:0];
			
			IRCChannelConfig *target = [ary safeObjectAtIndex:sel];
			
			[target adrv];
            
			NSMutableArray *low  = [[[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy] autodrain];
			NSMutableArray *high = [[[ary subarrayWithRange:NSMakeRange(row, (ary.count - row))] mutableCopy] autodrain];
			
			[low  removeObjectIdenticalTo:target];
			[high removeObjectIdenticalTo:target];
			
			[ary removeAllObjects];
			
			[ary addObjectsFromArray:low];
			[ary safeAddObject:target];
			[ary addObjectsFromArray:high];
			
			[self reloadChannelTable];
			
			sel = [ary indexOfObjectIdenticalTo:target];
			
			if (0 <= sel) {
				[channelTable selectItemAtIndex:sel];
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
	[channelTable unregisterDraggedTypes];
	
	if ([delegate respondsToSelector:@selector(ServerSheetWillClose:)]) {
		[delegate ServerSheetWillClose:self];
	}
}

@end