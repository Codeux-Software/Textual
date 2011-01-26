// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface IRCChannel (Private)
- (void)closeLogFile;
@end

@implementation IRCChannel

@synthesize client;
@synthesize config;
@synthesize errLastJoin;
@synthesize isActive;
@synthesize isHalfOp;
@synthesize isModeInit;
@synthesize isNamesInit;
@synthesize isOp;
@synthesize isWhoInit;
@synthesize logDate;
@synthesize logFile;
@synthesize members;
@synthesize mode;
@synthesize storedTopic;
@synthesize topic;

- (id)init
{
	if ((self = [super init])) {
		mode = [IRCChannelMode new];
		members = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[mode release];
	[topic release];	
	[config release];
	[logDate release];
	[logFile release];
	[members release];
	[storedTopic release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig *)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (NSMutableDictionary *)dictionaryValue
{
	return [config dictionaryValue];
}

#pragma mark -
#pragma mark Properties

- (NSString *)name
{
	return config.name;
}

- (void)setName:(NSString *)value
{
	config.name = value;
}

- (NSString *)password
{
	return ((config.password) ?: @"");
}

- (BOOL)isChannel
{
	return (config.type == CHANNEL_TYPE_CHANNEL);
}

- (BOOL)isTalk
{
	return (config.type == CHANNEL_TYPE_TALK);
}

- (NSString *)channelTypeString
{
	switch (config.type) {
		case CHANNEL_TYPE_CHANNEL: return @"channel";
		case CHANNEL_TYPE_TALK: return @"talk";
	}
	
	return nil;
}

#pragma mark -
#pragma mark Utilities

- (void)terminate
{
	[self closeDialogs];
	[self closeLogFile];
}

- (void)closeDialogs
{
	// do nothing
}

- (void)preferencesChanged
{
	log.maxLines = [Preferences maxLogLines];
	
	if (logFile) {
		if ([Preferences logTranscript]) {
			[logFile reopenIfNeeded];
		} else {
			[self closeLogFile];
		}
	}
}

- (void)activate
{
	isActive = YES;
	
	[mode clear];
	[members removeAllObjects];
	
	isOp = NO;
	isHalfOp = NO;
	
	self.topic = nil;
	
	isWhoInit = NO;
	isModeInit = NO;
	isNamesInit = NO;
	errLastJoin = NO;
	
	[self reloadMemberList];
}

- (void)deactivate
{
	isActive = NO;
	
	[members removeAllObjects];
	
	isOp = NO;
	isHalfOp = NO;
	errLastJoin = NO;
	
	[self reloadMemberList];
}

- (void)detectOutgoingConversation:(NSString *)text
{
	if (NSObjectIsNotEmpty([Preferences completionSuffix])) {
		NSArray *pieces = [text split:[Preferences completionSuffix]];
		
		if ([pieces count] > 1) {
			IRCUser *talker = [self findMember:[pieces safeObjectAtIndex:0]];
			
			if (talker) {
				[talker incomingConversation];
			}
		}
	}
}

- (BOOL)print:(LogLine *)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(LogLine *)line withHTML:(BOOL)rawHTML
{
	BOOL result = [log print:line withHTML:rawHTML];
	
	if ([Preferences logTranscript]) {
		if (PointerIsEmpty(logFile)) {
			logFile = [FileLogger new];
			logFile.client = client;
			logFile.channel = self;
		}
		
		NSString *comp = [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil]];
		
		if (logDate) {
			if ([logDate isEqualToString:comp] == NO) {
				[logDate release];
				
				logDate = [comp retain];
				[logFile reopenIfNeeded];
			}
		} else {
			logDate = [comp retain];
		}
		
		NSString *nickStr = @"";
		
		if (line.nick) {
			nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
		}
		
		NSString *s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
		
		[logFile writeLine:s];
	}
	
	return result;
}

#pragma mark -
#pragma mark Member List

- (void)sortedInsert:(IRCUser *)item
{
	const NSInteger LINEAR_SEARCH_THRESHOLD = 5;
	
	NSInteger left = 0;
	NSInteger right = members.count;
	
	while (right - left > LINEAR_SEARCH_THRESHOLD) {
		NSInteger i = ((left + right) / 2);
		
		IRCUser *t = [members safeObjectAtIndex:i];
		
		if ([t compare:item] == NSOrderedAscending) {
			left = (i + 1);
		} else {
			right = (i + 1);
		}
	}
	
	for (NSInteger i = left; i < right; ++i) {
		IRCUser *t = [members safeObjectAtIndex:i];
		
		if ([t compare:item] == NSOrderedDescending) {
			[members insertObject:item atIndex:i];
			
			return;
		}
	}
	
	[members addObject:item];
}

- (void)addMember:(IRCUser *)user
{
	[self addMember:user reload:YES];
}

- (void)addMember:(IRCUser *)user reload:(BOOL)reload
{
	NSInteger n = [self indexOfMember:user.nick];
	
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		
		[members safeRemoveObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
	
	if (reload) {
		[self reloadMemberList];
	}
}

- (void)removeMember:(NSString *)nick
{
	[self removeMember:nick reload:YES];
}

- (void)removeMember:(NSString *)nick reload:(BOOL)reload
{
	NSInteger n = [self indexOfMember:nick];
	
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		
		[members safeRemoveObjectAtIndex:n];
	}
	
	if (reload) [self reloadMemberList];
}

- (void)renameMember:(NSString *)fromNick to:(NSString *)toNick
{
	NSInteger n = [self indexOfMember:fromNick];
	
	if (n >= 0) {
		IRCUser *m = [members safeObjectAtIndex:n];
		
		[[m retain] autorelease];
		
		[self removeMember:toNick reload:NO];
		
		m.nick = toNick;
		
		[[[members safeObjectAtIndex:n] retain] autorelease];
		
		[members safeRemoveObjectAtIndex:n];
		
		[self sortedInsert:m];
		[self reloadMemberList];
	}
}

- (void)updateOrAddMember:(IRCUser *)user
{
	NSInteger n = [self indexOfMember:user.nick];
	
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		
		[members safeRemoveObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
}

- (void)changeMember:(NSString *)nick mode:(char)modeChar value:(BOOL)value
{
	NSInteger n = [self indexOfMember:nick];
	
	if (n >= 0) {
		IRCUser *m = [members safeObjectAtIndex:n];
		
		switch (modeChar) {
			case 'q': m.q = value; break;
			case 'a': m.a = value; break;
			case 'o': m.o = value; break;
			case 'h': m.h = value; break;
			case 'v': m.v = value; break;
		}
		
		[[[members safeObjectAtIndex:n] retain] autorelease];
		
		[members safeRemoveObjectAtIndex:n];
		
		[self sortedInsert:m];
		[self reloadMemberList];
	}
}

- (void)clearMembers
{
	[members removeAllObjects];
	
	[self reloadMemberList];
}

- (NSInteger)indexOfMember:(NSString *)nick
{
	return [self indexOfMember:nick options:0];
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger i = -1;
	
	for (IRCUser *m in members) {
		i++;
		
		if (mask & NSCaseInsensitiveSearch) {
			if ([nick isEqualNoCase:m.nick]) {
				return i;
			}
		} else {
			if ([m.nick isEqualToString:nick]) {
				return i;
			}
		}
	}
	
	return -1;
}

- (IRCUser *)memberAtIndex:(NSInteger)index
{
	return [members safeObjectAtIndex:index];
}

- (IRCUser *)findMember:(NSString *)nick
{
	return [self findMember:nick options:0];
}

- (IRCUser *)findMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger n = [self indexOfMember:nick options:mask];
	
	if (n >= 0) {
		return [members safeObjectAtIndex:n];
	}
	
	return nil;
}

- (NSInteger)numberOfMembers
{
	return members.count;
}

- (void)reloadMemberList
{
	if (client.world.selected == self) {
		[client.world.memberList reloadData];
	}
}

- (void)closeLogFile
{
	if (logFile) {
		[logFile close];
	}
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return NO;
}

- (NSInteger)numberOfChildren
{
	return 0;
}

- (id)childAtIndex:(NSInteger)index
{
	return nil;
}

- (NSString *)label
{
	return config.name;
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return members.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return ([client.world.viewTheme.other.memberListFont pointSize] + 3.0); // Long callback
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	IRCUser *user = [members safeObjectAtIndex:row];
	
	NSString *channel = [config.name safeSubstringFromIndex:1];
	
	return [NSString stringWithFormat:TXTLS(@"ACCESSIBILITY_MEMBER_LIST_DESCRIPTION"), [user nick], channel];
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(MemberListViewCell *)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	cell.member = [members safeObjectAtIndex:row];
}

@end