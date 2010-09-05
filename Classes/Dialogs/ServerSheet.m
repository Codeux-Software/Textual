// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ServerSheet.h"
#import "NSWindowHelper.h"
#import "IRCChannelConfig.h"
#import "AddressBook.h"
#import "Preferences.h"
#import "IRC.h"
#import "IRCClient.h"

#define IGNORE_TAB_INDEX	3
#define WINDOW_TOOLBAR_HEIGHT 30

#define TABLE_ROW_TYPE		@"row"
#define TABLE_ROW_TYPES		[NSArray arrayWithObject:TABLE_ROW_TYPE]

@interface ServerSheet (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
- (void)reloadChannelTable;
- (void)updateIgnoresPage;
- (void)reloadIgnoreTable;
@end

@implementation ServerSheet

@synthesize uid;
@synthesize config;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ServerSheet" owner:self];
		
		NSString *serverListPath = [[Preferences whereResourcePath] stringByAppendingPathComponent:@"Documents/IRCNetworks.plist"];
		serverList = [[NSDictionary alloc] initWithContentsOfFile:serverListPath];
	
		for (NSString* key in serverList) {
			[hostCombo addItemWithObjectValue:key];
		}
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[channelSheet release];
	[ignoreSheet release];
	[generalView release];
	[detailsView release];
	[onloginView release];
	[ignoresView release];
	[serverList release];
	[super dealloc];
}

#pragma mark -
#pragma mark Server List Factory

- (NSString *)nameMatchesServerInList:(NSString *)name
{
	for (NSString *key in serverList) {
		if ([[name lowercaseString] isEqualToString:[key lowercaseString]]) {
			return key;
		}
	}
	
	return nil;
}

- (NSString *)hostFoundInServerList:(NSString *)hosto
{
	for (NSString *key in serverList) {
		NSString *host = [serverList objectForKey:key];
		
		if ([[hosto lowercaseString] isEqualToString:[host lowercaseString]]) {
			return key;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender {
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

- (void)firstPane:(NSView *)view {
	NSRect windowFrame = [sheet frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([sheet frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[sheet setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}

#pragma mark -
#pragma mark Initalization Handler

- (void)startWithIgnoreTab:(BOOL)ignoreTab
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
	
	if (ignoreTab) {
		initialTabTag = 3;
		initalView = ignoresView;
	} else {
		initialTabTag = 0;
		initalView = generalView;
	}
	
	[self show];
}

- (void)show
{
	[self startSheet];
	[self firstPane:initalView];
	[sheet recalculateKeyViewLoop];
	[tabView setSelectedSegment:initialTabTag];
}

- (void)close
{
	delegate = nil;
	[self endSheet];
}

- (void)load
{
	nameText.stringValue = config.name;
	autoConnectCheck.state = config.autoConnect;
	autoReconnectCheck.state = config.autoReconnect;
	
	NSString *realHost = [self hostFoundInServerList:config.host];
	hostCombo.stringValue = ((realHost == nil) ? config.host : realHost);
	
	sslCheck.state = config.useSSL;
	portText.intValue = config.port;

	if ([config.nick length] < 1) {
		nickText.stringValue = [Preferences defaultNickname];
	} else {
		nickText.stringValue = config.nick;
	}
	
	passwordText.stringValue = config.password;
	
	if ([config.username length] < 1) {
		usernameText.stringValue = [Preferences defaultUsername];
	} else {
		usernameText.stringValue = config.username;
	}
	
	if ([config.realName length] < 1) {
		realNameText.stringValue = [Preferences defaultRealname];
	} else {
		realNameText.stringValue = config.realName;
	}
	
	nickPasswordText.stringValue = config.nickPassword;
	
	if (config.altNicks.count) {
		altNicksText.stringValue = [config.altNicks componentsJoinedByString:@" "];
	} else {
		altNicksText.stringValue = @"";
	}

	sleepQuitMessageText.stringValue = config.sleepQuitMessage;
	leavingCommentText.stringValue = config.leavingComment;
	userInfoText.stringValue = config.userInfo;

	[encodingCombo selectItemWithTag:config.encoding];
	[fallbackEncodingCombo selectItemWithTag:config.fallbackEncoding];
	
	[proxyCombo selectItemWithTag:config.proxyType];
	proxyHostText.stringValue = config.proxyHost;
	proxyPortText.intValue = config.proxyPort;
	proxyUserText.stringValue = config.proxyUser;
	proxyPasswordText.stringValue = config.proxyPassword;

	loginCommandsText.string = [config.loginCommands componentsJoinedByString:@"\n"];
	invisibleCheck.state = config.invisibleMode;
}

- (void)save
{
	config.autoConnect = autoConnectCheck.state;
	config.autoReconnect = autoReconnectCheck.state;
	
	NSString *realHost = nil;
	
	if (hostCombo.stringValue.length < 1) {
		config.host = @"unknown.host.com";
	} else {
		realHost = [self nameMatchesServerInList:hostCombo.stringValue];
		config.host = ((realHost == nil) ? hostCombo.stringValue : [serverList objectForKey:realHost]);
	}
	
	if ([nameText.stringValue length] < 1) {
		if (realHost == nil) {
			config.name = TXTLS(@"UNTITLED_CONNECTION_NAME");
		} else {
			config.name = realHost;
		}
	} else {
		config.name = nameText.stringValue;
	}
	
	config.useSSL = sslCheck.state;
	
	if (portText.intValue < 1) {
		config.port = 6667;
	} else {
		config.port = portText.intValue;
	}
	
	config.nick = nickText.stringValue;
	config.password = passwordText.stringValue;
	config.username = usernameText.stringValue;
	config.realName = realNameText.stringValue;
	config.nickPassword = nickPasswordText.stringValue;
	
	NSArray* nicks = [altNicksText.stringValue componentsSeparatedByString:@" "];
	[config.altNicks removeAllObjects];
	for (NSString* s in nicks) {
		if (s.length) {
			[config.altNicks addObject:s];
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
	
	NSArray* commands = [loginCommandsText.string componentsSeparatedByString:@"\n"];
	[config.loginCommands removeAllObjects];
	for (NSString* s in commands) {
		if (s.length) {
			[config.loginCommands addObject:s];
		}
	}
	
	config.invisibleMode = invisibleCheck.state;
}

- (void)updateConnectionPage
{
	NSString* name = [nameText stringValue];
	NSString* host = [hostCombo stringValue];
	NSInteger port = [portText integerValue];
	NSString* nick = [nickText stringValue];
	
	BOOL enabled = name.length > 0 && host.length > 0 && ![host isEqualToString:@"-"] && port > 0 && nick.length > 0;
	[okButton setEnabled:enabled];
}

- (void)updateChannelsPage
{
	NSInteger i = [channelTable selectedRow];
	BOOL enabled = (i >= 0);
	[editChannelButton setEnabled:enabled];
	[deleteChannelButton setEnabled:enabled];
}

- (void)reloadChannelTable
{
	[channelTable reloadData];
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
	
	NSMutableArray* ignores = config.ignores;
	for (NSInteger i=ignores.count-1; i>=0; --i) {
		AddressBook* g = [ignores safeObjectAtIndex:i];
		if ([g.hostmask length] < 1) {
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

- (void)controlTextDidChange:(NSNotification*)note
{
	[self updateConnectionPage];
}

- (void)hostComboChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)encodingChanged:(id)sender
{
	NSInteger tag = [encodingCombo selectedTag];
	[fallbackEncodingCombo setEnabled:(tag == NSUTF8StringEncoding)];
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

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	IRCChannelConfig* conf;
	if (sel < 0) {
		conf = [[IRCChannelConfig new] autorelease];
	} else {
		IRCChannelConfig* c = [config.channels safeObjectAtIndex:sel];
		conf = [[c mutableCopy] autorelease];
		conf.name = @"";
	}
	
	[channelSheet release];
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
	IRCChannelConfig* c = [[[config.channels safeObjectAtIndex:sel] mutableCopy] autorelease];
	
	[channelSheet release];
	channelSheet = [ChannelSheet new];
	channelSheet.delegate = self;
	channelSheet.window = sheet;
	channelSheet.config = c;
	channelSheet.uid = 1;
	channelSheet.cid = 1;
	[channelSheet show];
}

- (void)ChannelSheetOnOK:(ChannelSheet*)sender
{
	IRCChannelConfig* conf = sender.config;
	NSString* name = conf.name;
	
	NSInteger n = -1;
	NSInteger i = 0;
	for (IRCChannelConfig* c in config.channels) {
		if ([c.name isEqualToString:name]) {
			n = i;
			break;
		}
		++i;
	}
	
	if (n < 0) {
		[config.channels addObject:conf];
	} else {
		[config.channels replaceObjectAtIndex:n withObject:conf];
	}
	
	[self reloadChannelTable];
}

- (void)ChannelSheetWillClose:(ChannelSheet*)sender
{
	[channelSheet autorelease];
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
			[channelTable selectItemAtIndex:count - 1];
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
	[ignoreSheet release];
	ignoreSheet = [AddressBookSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = sheet;
	ignoreSheet.ignore = [[AddressBook new] autorelease];
	ignoreSheet.newItem = YES;
	[ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
	NSInteger sel = [ignoreTable selectedRow];
	if (sel < 0) return;
	
	[ignoreSheet release];
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
			[ignoreTable selectItemAtIndex:count - 1];
		} else {
			[ignoreTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadIgnoreTable];
	[client populateISONTrackedUsersList:config.ignores];
}

- (void)ignoreItemSheetOnOK:(AddressBookSheet*)sender
{
	NSString *hostmask = [sender.ignore.hostmask trim];
	
	if (sender.newItem) {
		if ([hostmask length]  > 1) {
			[config.ignores addObject:sender.ignore];
		}
	}
	
	[self reloadIgnoreTable];
	[client populateISONTrackedUsersList:config.ignores];
}

- (void)ignoreItemSheetWillClose:(AddressBookSheet*)sender
{
	[ignoreSheet autorelease];
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
		IRCChannelConfig* c = [config.channels safeObjectAtIndex:row];
		NSString* columnId = [column identifier];
		
		if ([columnId isEqualToString:@"name"]) {
			return c.name;
		} else if ([columnId isEqualToString:@"pass"]) {
			return c.password;
		} else if ([columnId isEqualToString:@"join"]) {
			return [NSNumber numberWithBool:c.autoJoin];
		}
	} else {
		AddressBook* g = [config.ignores safeObjectAtIndex:row];
		return g.hostmask;
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == channelTable) {
		IRCChannelConfig* c = [config.channels safeObjectAtIndex:row];
		NSString* columnId = [column identifier];
		
		if ([columnId isEqualToString:@"join"]) {
			c.autoJoin = [obj integerValue] != 0;
		}
	} else {
		;
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
		NSArray* ary = [NSArray arrayWithObject:[NSNumber numberWithInteger:[rows firstIndex]]];
		[pboard declareTypes:TABLE_ROW_TYPES owner:self];
		[pboard setPropertyList:ary forType:TABLE_ROW_TYPE];
	} else {
		;
	}
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == channelTable) {
		NSPasteboard* pboard = [info draggingPasteboard];
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
		NSPasteboard* pboard = [info draggingPasteboard];
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
			NSArray* selectedRows = [pboard propertyListForType:TABLE_ROW_TYPE];
			NSInteger sel = [[selectedRows safeObjectAtIndex:0] integerValue];
			
			NSMutableArray* ary = config.channels;
			IRCChannelConfig* target = [ary safeObjectAtIndex:sel];
			[[target retain] autorelease];

			NSMutableArray* low = [[[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy] autorelease];
			NSMutableArray* high = [[[ary subarrayWithRange:NSMakeRange(row, ary.count - row)] mutableCopy] autorelease];
			
			[low removeObjectIdenticalTo:target];
			[high removeObjectIdenticalTo:target];
			
			[ary removeAllObjects];
			
			[ary addObjectsFromArray:low];
			[ary addObject:target];
			[ary addObjectsFromArray:high];
			
			[self reloadChannelTable];
			
			sel = [ary indexOfObjectIdenticalTo:target];
			if (0 <= sel) {
				[channelTable selectItemAtIndex:sel];
			}
			
			return YES;
		}
	} else {
		;
	}
	return NO;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	[channelTable unregisterDraggedTypes];
	
	if ([delegate respondsToSelector:@selector(ServerSheetWillClose:)]) {
		[delegate ServerSheetWillClose:self];
	}
}

@synthesize initialTabTag;
@synthesize initalView;
@synthesize contentView;
@synthesize generalView;
@synthesize detailsView;
@synthesize onloginView;
@synthesize ignoresView;
@synthesize tabView;
@synthesize nameText;
@synthesize autoReconnectCheck;
@synthesize autoConnectCheck;
@synthesize hostCombo;
@synthesize sslCheck;
@synthesize portText;
@synthesize nickText;
@synthesize passwordText;
@synthesize usernameText;
@synthesize realNameText;
@synthesize nickPasswordText;
@synthesize altNicksText;
@synthesize sleepQuitMessageText;
@synthesize leavingCommentText;
@synthesize userInfoText;
@synthesize encodingCombo;
@synthesize fallbackEncodingCombo;
@synthesize proxyCombo;
@synthesize proxyHostText;
@synthesize proxyPortText;
@synthesize proxyUserText;
@synthesize proxyPasswordText;
@synthesize channelTable;
@synthesize addChannelButton;
@synthesize editChannelButton;
@synthesize deleteChannelButton;
@synthesize loginCommandsText;
@synthesize invisibleCheck;
@synthesize ignoreTable;
@synthesize addIgnoreButton;
@synthesize editIgnoreButton;
@synthesize deleteIgnoreButton;
@synthesize channelSheet;
@synthesize ignoreSheet;
@synthesize client;
@end