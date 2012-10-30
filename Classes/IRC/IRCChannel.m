/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#define _treeUserlistHeight    16.0

@implementation IRCChannel

@synthesize isActive = _isActive;
@synthesize client = _client;

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
	
	if ([TPCPreferences logTranscript] && rawHTML == NO) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];
			self.logFile.client = self.client;
			self.logFile.channel = self;
			self.logFile.writePlainText = YES;
			self.logFile.flatFileStructure = NO;
		}
		
		NSString *logstr = [self.log renderedBodyForTranscriptLog:line];

		if (NSObjectIsNotEmpty(logstr)) {
			[self.logFile writePlainTextLine:logstr];
		}
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

- (BOOL)isActive
{
	return _isActive;
}

- (IRCClient *)client
{
	return _client;
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