// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

#define _treeUserlistHeight    16.0

@interface IRCChannel (Private)
- (void)closeLogFile;
@end

@implementation IRCChannel


- (id)init
{
	if ((self = [super init])) {
		self.mode    = [IRCChannelMode new];
		self.members = [NSMutableArray new];
	}
	
	return self;
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig *)seed
{
	self.config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	self.config = [seed mutableCopy];
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self.config dictionaryValue];
}

#pragma mark -
#pragma mark Properties

- (NSString *)name
{
	return self.config.name;
}

- (void)setName:(NSString *)value
{
	self.config.name = value;
}

- (NSString *)password
{
	return ((self.config.password) ?: NSStringEmptyPlaceholder);
}

- (BOOL)isChannel
{
	return (self.config.type == IRCChannelNormalType);
}

- (BOOL)isTalk
{
	return (self.config.type == IRCChannelPrivateMessageType);
}

- (NSString *)channelTypeString
{
	switch (self.config.type) {
		case IRCChannelNormalType:			return @"channel";
		case IRCChannelPrivateMessageType:	return @"talk";
	}
	
	return nil;
}

#pragma mark -
#pragma mark Utilities

- (void)terminate
{
	self.status = IRCChannelTerminated;
	
	[self closeDialogs];
	[self closeLogFile];
}

- (void)closeDialogs
{
	return;
}

- (void)preferencesChanged
{
	self.log.maxLines = [TPCPreferences maxLogLines];
	
	if (self.logFile) {
		if ([TPCPreferences logTranscript]) {
			[self.logFile reopenIfNeeded];
		} else {
			[self closeLogFile];
		}
	}
}

- (void)activate
{
	self.isActive = YES;
	
	[self.mode clear];
	[self.members removeAllObjects];
	
	self.isOp		= NO;
	self.isHalfOp	= NO;
	
	self.topic = nil;
	
	self.isModeInit		= NO;
	self.errLastJoin	= NO;
	
	self.status = IRCChannelJoined;
	
	[self reloadMemberList];
}

- (void)deactivate
{
	[self.members removeAllObjects];
	
	self.isOp			= NO;
	self.isHalfOp		= NO;
	self.isActive		= NO;
	self.errLastJoin	= NO;
	
	self.status = IRCChannelParted;
	
	[self reloadMemberList];
}

- (void)detectOutgoingConversation:(NSString *)text
{
	if (NSObjectIsNotEmpty([TPCPreferences completionSuffix])) {
		NSArray *pieces = [text split:[TPCPreferences completionSuffix]];
		
		if ([pieces count] > 1) {
			IRCUser *talker = [self findMember:[pieces safeObjectAtIndex:0]];
			
			if (talker) {
				[talker incomingConversation];
			}
		}
	}
}

- (BOOL)print:(TVCLogLine *)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)rawHTML
{
	BOOL result = [self.log print:line withHTML:rawHTML];
	
	if ([TPCPreferences logTranscript]) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];
			self.logFile.client = self.client;
			self.logFile.channel = self;
		}
		
		NSString *comp = [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil]];
		
		if (self.logDate) {
			if ([self.logDate isEqualToString:comp] == NO) {
				self.logDate = comp;
				
				[self.logFile reopenIfNeeded];
			}
		} else {
			self.logDate = comp;
		}
		
		NSString *nickStr = NSStringEmptyPlaceholder;
		
		if (line.nick) {
			nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
		}
		
		NSString *s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
		
		[self.logFile writeLine:s];
	}
	
	return result;
}

#pragma mark -
#pragma mark Member List

- (void)sortedInsert:(IRCUser *)item
{
	const NSInteger LINEAR_SEARCH_THRESHOLD = 5;
	
	NSInteger left = 0;
	NSInteger right = self.members.count;
	
	while (right - left > LINEAR_SEARCH_THRESHOLD) {
		NSInteger i = ((left + right) / 2);
		
		IRCUser *t = [self.members safeObjectAtIndex:i];
		
		if ([t compare:item] == NSOrderedAscending) {
			left = (i + 1);
		} else {
			right = (i + 1);
		}
	}
	
	for (NSInteger i = left; i < right; ++i) {
		IRCUser *t = [self.members safeObjectAtIndex:i];
		
		if ([t compare:item] == NSOrderedDescending) {
			[self.members safeInsertObject:item atIndex:i];
			
			return;
		}
	}
	
	[self.members safeAddObject:item];
}

- (void)addMember:(IRCUser *)user
{
	[self addMember:user reload:YES];
}

- (void)addMember:(IRCUser *)user reload:(BOOL)reload
{
	NSInteger n = [self indexOfMember:user.nick];
	
	if (n >= 0) {
		[self.members safeObjectAtIndex:n];
		[self.members safeRemoveObjectAtIndex:n];
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
		[self.members safeObjectAtIndex:n];
		[self.members safeRemoveObjectAtIndex:n];
	}
	
	if (reload) [self reloadMemberList];
}

- (void)renameMember:(NSString *)fromNick to:(NSString *)toNick
{
	NSInteger n = [self indexOfMember:fromNick];
	
	if (n >= 0) {
		IRCUser *m = [self.members safeObjectAtIndex:n];
		
		[self removeMember:toNick reload:NO];
		
		m.nick = toNick;
		
		[self.members safeObjectAtIndex:n];
		[self.members safeRemoveObjectAtIndex:n];
		
		[self sortedInsert:m];
		[self reloadMemberList];
	}
}

- (void)updateOrAddMember:(IRCUser *)user
{
	NSInteger n = [self indexOfMember:user.nick];
	
	if (n >= 0) {
		[self.members safeObjectAtIndex:n];
		[self.members safeRemoveObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
}

- (void)changeMember:(NSString *)nick mode:(char)modeChar value:(BOOL)value
{
	NSInteger n = [self indexOfMember:nick];
	
	if (n >= 0) {
		IRCUser *m = [self.members safeObjectAtIndex:n];
		
		switch (modeChar) {
			case 'q': m.q = value; break;
			case 'a': m.a = value; break;
			case 'o': m.o = value; break;
			case 'h': m.h = value; break;
			case 'v': m.v = value; break;
		}
		
		[self.members safeObjectAtIndex:n];
		[self.members safeRemoveObjectAtIndex:n];
		
		if (m.q && NSObjectIsEmpty(self.client.isupport.userModeQPrefix)) {
			m.q = NO;
		}
		
		if (m.a && NSObjectIsEmpty(self.client.isupport.userModeAPrefix)) {
			m.a = NO;
		}
		
		if (m.o && NSObjectIsEmpty(self.client.isupport.userModeOPrefix)) {
			m.o = NO;
		}
		
		if (m.h && NSObjectIsEmpty(self.client.isupport.userModeHPrefix)) {
			m.h = NO;
		}
		
		if (m.v && NSObjectIsEmpty(self.client.isupport.userModeVPrefix)) {
			m.v = NO;
		}
		
		[self sortedInsert:m];
		[self reloadMemberList];
	}
}

- (void)clearMembers
{
	[self.members removeAllObjects];
	
	[self reloadMemberList];
}

- (NSInteger)indexOfMember:(NSString *)nick
{
	return [self indexOfMember:nick options:0];
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger i = -1;
	
	for (IRCUser *m in self.members) {
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
	return [self.members safeObjectAtIndex:index];
}

- (IRCUser *)findMember:(NSString *)nick
{
	return [self findMember:nick options:0];
}

- (IRCUser *)findMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger n = [self indexOfMember:nick options:mask];
	
	if (n >= 0) {
		return [self.members safeObjectAtIndex:n];
	}
	
	return nil;
}

- (NSInteger)numberOfMembers
{
	return self.members.count;
}

- (void)reloadMemberList
{
	if (self.client.world.selected == self) {
		[self.client.world.memberList reloadData];
	}
}

- (void)closeLogFile
{
	if (self.logFile) {
		[self.logFile close];
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
	return self.config.name;
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return self.members.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return _treeUserlistHeight;
}

- (id)tableView:(NSTableView *)sender
objectValueForTableColumn:(NSTableColumn *)column
			row:(NSInteger)row
{
	IRCUser *user = [self.members safeObjectAtIndex:row];
	
	return TXTFLS(@"AccessibilityMemberListDescription",
				  [user nick], [self.config.name safeSubstringFromIndex:1]);
}

- (void)tableView:(NSTableView *)sender
  willDisplayCell:(TVCMemberListCell *)cell
   forTableColumn:(NSTableColumn *)column
			  row:(NSInteger)row
{
    cell.cellItem   = cell;
    cell.parent     = self.client.world.memberList;
	cell.member     = [self.members safeObjectAtIndex:row];
}

@end