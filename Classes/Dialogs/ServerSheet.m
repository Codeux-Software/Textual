// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define IGNORE_TAB_INDEX		3
#define WINDOW_TOOLBAR_HEIGHT	30

#define TABLE_ROW_TYPE			@"row"
#define TABLE_ROW_TYPES			[NSArray arrayWithObject:TABLE_ROW_TYPE]

@interface ServerSheet (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
- (void)reloadChannelTable;
- (void)updateIgnoresPage;
- (void)reloadIgnoreTable;
- (void)firstPane:(NSView *)view;
@end

@implementation ServerSheet

@synthesize addChannelButton;
@synthesize addIgnoreButton;
@synthesize altNicksText;
@synthesize autoConnectCheck;
@synthesize autoReconnectCheck;
@synthesize channelSheet;
@synthesize channelTable;
@synthesize client;
@synthesize config;
@synthesize contentView;
@synthesize deleteChannelButton;
@synthesize deleteIgnoreButton;
@synthesize detailsView;
@synthesize editChannelButton;
@synthesize editIgnoreButton;
@synthesize encodingCombo;
@synthesize fallbackEncodingCombo;
@synthesize generalView;
@synthesize hostCombo;
@synthesize ignoreSheet;
@synthesize ignoresView;
@synthesize ignoreTable;
@synthesize invisibleCheck;
@synthesize leavingCommentText;
@synthesize loginCommandsText;
@synthesize nameText;
@synthesize nickPasswordText;
@synthesize nickText;
@synthesize onloginView;
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
@synthesize tabView;
@synthesize uid;
@synthesize userInfoText;
@synthesize usernameText;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"ServerSheet" owner:self];
		
		serverList = [NSDictionary dictionaryWithContentsOfFile:[[Preferences whereResourcePath] stringByAppendingPathComponent:@"IRCNetworks.plist"]];
		[serverList retain];
		
		NSArray *sortedKeys = [[serverList allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		for (NSString *key in sortedKeys) {
			[hostCombo addItemWithObjectValue:key];
		}
	}

	return self;
}

- (void)dealloc
{
	[config drain];
	[serverList drain];
	[ignoreSheet drain];
	[generalView drain];
	[detailsView drain];
	[onloginView drain];
	[ignoresView drain];
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
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender 
{
	switch ([sender indexOfSelectedItem]) {
		case 0:
			[self firstPane:generalView];
			break;
		case 1:
			[self firstPane:detailsView];
			break;
		case 2:
			[self firstPane:onloginView];
			break;
		case 3:
			[self firstPane:ignoresView];
			break;
		default:
			[self firstPane:generalView];
			break;
	}
} 

- (void)firstPane:(NSView *)view 
{
	NSRect windowFrame = [sheet frame];
	
	windowFrame.size.width = [view frame].size.width;
	windowFrame.size.height = ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	windowFrame.origin.y = (NSMaxY([sheet frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT));
	
	if (NSObjectIsNotEmpty([contentView subviews])) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[sheet setFrame:windowFrame display:YES animate:YES];
	
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
	
	[sheet recalculateKeyViewLoop];
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
		[self showWithDefaultView:ignoresView andSegment:3];
		
		if ([imask isEqualToString:@"-"] == NO) {
			[ignoreSheet drain];
			ignoreSheet = nil;
			
			ignoreSheet = [AddressBookSheet new];
			ignoreSheet.delegate = self;
			ignoreSheet.window = sheet;
			ignoreSheet.newItem = YES;
			
			ignoreSheet.ignore = [AddressBook new];
			ignoreSheet.ignore.hostmask = imask;
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
	[self firstPane:view];
	
	[tabView setSelectedSegment:segment];
}

- (void)close
{
	delegate = nil;
	
	[self endSheet];
}

- (void)load
{
	nameText.stringValue = config.name;
	bouncerModeCheck.state = config.bouncerMode;
	autoConnectCheck.state = config.autoConnect;
	autoReconnectCheck.state = config.autoReconnect;
	
	hostCombo.stringValue = (([self hostFoundInServerList:config.host]) ?: config.host);
	
	sslCheck.state = config.useSSL;
	portText.integerValue = config.port;

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
	
	passwordText.stringValue = config.password;
	nickPasswordText.stringValue = config.nickPassword;

	sleepQuitMessageText.stringValue = config.sleepQuitMessage;
	leavingCommentText.stringValue = config.leavingComment;
	userInfoText.stringValue = config.userInfo;

	[encodingCombo selectItemWithTag:config.encoding];
	[fallbackEncodingCombo selectItemWithTag:config.fallbackEncoding];
	
	[proxyCombo selectItemWithTag:config.proxyType];
	proxyHostText.stringValue = config.proxyHost;
	proxyPortText.integerValue = config.proxyPort;
	proxyUserText.stringValue = config.proxyUser;
	proxyPasswordText.stringValue = config.proxyPassword;

	invisibleCheck.state = config.invisibleMode;
	loginCommandsText.string = [config.loginCommands componentsJoinedByString:NSNewlineCharacter];
}

- (void)save
{
	config.autoConnect = autoConnectCheck.state;
	config.autoReconnect = autoReconnectCheck.state;
	config.bouncerMode = bouncerModeCheck.state;
	
	NSString *realHost = nil;
	NSString *hostname = [hostCombo.stringValue cleanedServerHostmask];
	
	if (NSObjectIsEmpty(hostname)) {
		config.host = @"unknown.host.com";
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
	
	config.nick = nickText.stringValue;
	config.password = passwordText.stringValue;
	config.username = usernameText.stringValue;
	config.realName = realNameText.stringValue;
	config.nickPassword = nickPasswordText.stringValue;
	
	NSArray *nicks = [altNicksText.stringValue componentsSeparatedByString:NSWhitespaceCharacter];
	
	[config.altNicks removeAllObjects];
	
	for (NSString *s in nicks) {
		if (NSObjectIsNotEmpty(s)) {
			[config.altNicks safeAddObject:s];
		}
	}
	
	config.sleepQuitMessage = sleepQuitMessageText.stringValue;
	config.leavingComment = leavingCommentText.stringValue;
	config.userInfo = userInfoText.stringValue;
	
	config.encoding = encodingCombo.selectedTag;
	config.fallbackEncoding = fallbackEncodingCombo.selectedTag;
	
	config.proxyType = proxyCombo.selectedTag;
	config.proxyHost = proxyHostText.stringValue;
	config.proxyPort = proxyPortText.intValue;
	config.proxyUser = proxyUserText.stringValue;
	config.proxyPassword = proxyPasswordText.stringValue;
	
	NSArray *commands = [loginCommandsText.string componentsSeparatedByString:NSNewlineCharacter];
	
	[config.loginCommands removeAllObjects];
	
	for (NSString *s in commands) {
		if (NSObjectIsNotEmpty(s)) {
			[config.loginCommands safeAddObject:s];
		}
	}
	
	config.invisibleMode = invisibleCheck.state;
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
	
	BOOL count = (i >= 0);
	BOOL bouncer = BOOLReverseValue([bouncerModeCheck state]);
	
	BOOL enabled = (count && bouncer);
	
	[addChannelButton setEnabled:bouncer];
	[editChannelButton setEnabled:enabled];
	[deleteChannelButton setEnabled:enabled];
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
	
	[editIgnoreButton setEnabled:enabled];
	[deleteIgnoreButton setEnabled:enabled];
}

- (void)reloadIgnoreTable
{
	[ignoreTable reloadData];
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

- (void)controlTextDidChange:(NSNotification *)note
{
	[self updateConnectionPage];
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
	
	[proxyHostText setEnabled:enabled];
	[proxyPortText setEnabled:enabled];
	[proxyUserText setEnabled:enabled];
	[proxyPasswordText setEnabled:enabled];
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

- (void)addIgnore:(id)sender
{
	[ignoreSheet drain];
	ignoreSheet = nil;
	
	ignoreSheet = [AddressBookSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = sheet;
	ignoreSheet.ignore = [AddressBook new];
	ignoreSheet.newItem = YES;
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
	} else {
		return config.ignores.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == channelTable) {
		IRCChannelConfig *c = [config.channels safeObjectAtIndex:row];
		
		NSString *columnId = [column identifier];
		
		if ([columnId isEqualToString:@"name"]) {
			return c.name;
		} else if ([columnId isEqualToString:@"pass"]) {
			return c.password;
		} else if ([columnId isEqualToString:@"join"]) {
			return NSNumberWithBOOL(c.autoJoin);
		}
	} else {
		AddressBook *g = [config.ignores safeObjectAtIndex:row];
		
		return g.hostmask;
	}
	
	return nil;
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
	} else {
		[self updateIgnoresPage];
	}
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == channelTable) {
		[self editChannel:nil];
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
			
			NSArray *selectedRows = [pboard propertyListForType:TABLE_ROW_TYPE];
			NSInteger sel = [selectedRows integerAtIndex:0];
			
			IRCChannelConfig *target = [ary safeObjectAtIndex:sel];
			
			[target adrv];

			NSMutableArray *low = [[[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy] autodrain];
			NSMutableArray *high = [[[ary subarrayWithRange:NSMakeRange(row, (ary.count - row))] mutableCopy] autodrain];
			
			[low removeObjectIdenticalTo:target];
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