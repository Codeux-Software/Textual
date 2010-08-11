// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCChannel.h"
#import "IRCClient.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "MemberListViewCell.h"
#import "NSStringHelper.h"

@interface IRCChannel (Private)
- (void)closeLogFile;
@end

@implementation IRCChannel

@synthesize client;
@synthesize config;
@synthesize mode;
@synthesize members;
@synthesize topic;
@synthesize storedTopic;
@synthesize isActive;
@synthesize isOp;
@synthesize isHalfOp;
@synthesize isModeInit;
@synthesize isNamesInit;
@synthesize isWhoInit;
@synthesize propertyDialog;

- (id)init
{
	if (self = [super init]) {
		mode = [IRCChannelMode new];
		members = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[mode release];
	[members release];
	[topic release];
	[storedTopic release];
	
	[logFile release];
	[logDate release];
	
	[propertyDialog release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (NSMutableDictionary*)dictionaryValue
{
	return [config dictionaryValue];
}

#pragma mark -
#pragma mark Properties

- (NSString*)name
{
	return config.name;
}

- (void)setName:(NSString *)value
{
	config.name = value;
}

- (NSString*)password
{
	return config.password ?: @"";
}

- (BOOL)isChannel
{
	return config.type == CHANNEL_TYPE_CHANNEL;
}

- (BOOL)isTalk
{
	return config.type == CHANNEL_TYPE_TALK;
}

- (NSString*)channelTypeString
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
	[members removeAllObjects];
	[mode clear];
	isOp = NO;
	isHalfOp = NO;
	self.topic = nil;
	isModeInit = NO;
	isNamesInit = NO;
	isWhoInit = NO;
	[self reloadMemberList];
}

- (void)deactivate
{
	isActive = NO;
	[members removeAllObjects];
	isOp = NO;
	isHalfOp = NO;
	[self reloadMemberList];
}

- (BOOL)print:(LogLine*)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(LogLine*)line withHTML:(BOOL)rawHTML
{
	BOOL result = [log print:line withHTML:rawHTML];
	
	if ([Preferences logTranscript]) {
		if (!logFile) {
			logFile = [FileLogger new];
			logFile.client = client;
			logFile.channel = self;
		}
		
		NSString* comp = [NSString stringWithFormat:@"%@", [[NSDate date] dateWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil]];
		if (logDate) {
			if (![logDate isEqualToString:comp]) {
				[logDate release];
				logDate = [comp retain];
				[logFile reopenIfNeeded];
			}
		} else {
			logDate = [comp retain];
		}
		
		NSString* nickStr = @"";
		if (line.nick) {
			nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
		}
		NSString* s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
		[logFile writeLine:s];
	}
	
	return result;
}

#pragma mark -
#pragma mark Member List

- (void)sortedInsert:(IRCUser*)item
{
	const NSInteger LINEAR_SEARCH_THRESHOLD = 5;
	NSInteger left = 0;
	NSInteger right = members.count;
	
	while (right - left > LINEAR_SEARCH_THRESHOLD) {
		NSInteger i = (left + right) / 2;
		IRCUser* t = [members safeObjectAtIndex:i];
		if ([t compare:item] == NSOrderedAscending) {
			left = i + 1;
		} else {
			right = i + 1;
		}
	}
	
	for (NSInteger i=left; i<right; ++i) {
		IRCUser* t = [members safeObjectAtIndex:i];
		if ([t compare:item] == NSOrderedDescending) {
			[members insertObject:item atIndex:i];
			return;
		}
	}
	
	[members addObject:item];
}

- (void)addMember:(IRCUser*)user
{
	[self addMember:user reload:YES];
}

- (void)addMember:(IRCUser*)user reload:(BOOL)reload
{
	NSInteger n = [self indexOfMember:user.nick];
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		[members safeRemoveObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
	
	if (reload) [self reloadMemberList];
}

- (void)removeMember:(NSString*)nick
{
	[self removeMember:nick reload:YES];
}

- (void)removeMember:(NSString*)nick reload:(BOOL)reload
{
	NSInteger n = [self indexOfMember:nick];
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		[members safeRemoveObjectAtIndex:n];
	}

	if (reload) [self reloadMemberList];
}

- (void)renameMember:(NSString*)fromNick to:(NSString*)toNick
{
	NSInteger n = [self indexOfMember:fromNick];
	if (n < 0) return;
	
	IRCUser* m = [members safeObjectAtIndex:n];
	[[m retain] autorelease];
	[self removeMember:toNick reload:NO];
	
	m.nick = toNick;
	
	[[[members safeObjectAtIndex:n] retain] autorelease];
	[members safeRemoveObjectAtIndex:n];
	
	[self sortedInsert:m];
	[self reloadMemberList];
}

- (void)updateOrAddMember:(IRCUser*)user
{
	NSInteger n = [self indexOfMember:user.nick];
	if (n >= 0) {
		[[[members safeObjectAtIndex:n] retain] autorelease];
		[members safeRemoveObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
}

- (void)changeMember:(NSString*)nick mode:(char)modeChar value:(BOOL)value
{
	NSInteger n = [self indexOfMember:nick];
	if (n < 0) return;
	
	IRCUser* m = [members safeObjectAtIndex:n];
	
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

- (void)clearMembers
{
	[members removeAllObjects];
	[self reloadMemberList];
}

- (NSInteger)indexOfMember:(NSString*)nick
{
	NSString* canonicalNick = [nick canonicalName];
	
	NSInteger i = 0;
	for (IRCUser* m in members) {
		if ([m.canonicalNick isEqualToString:canonicalNick]) {
			return i;
		}
		++i;
	}
	
	return -1;
}

- (IRCUser*)memberAtIndex:(NSInteger)index
{
	return [members safeObjectAtIndex:index];
}

- (IRCUser*)findMember:(NSString*)nick
{
	NSInteger n = [self indexOfMember:nick];
	if (n < 0) return nil;
	return [members safeObjectAtIndex:n];
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

- (NSString*)label
{
	return config.name;
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return members.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(MemberListViewCell*)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	cell.member = [members safeObjectAtIndex:row];
}

@synthesize logFile;
@synthesize logDate;
@end