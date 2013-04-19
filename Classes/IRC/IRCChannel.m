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

#define _treeUserlistHeight			16.0

@implementation IRCChannel

@synthesize client = _client;
@synthesize operationQueue = _operationQueue;

- (id)init
{
	if ((self = [super init])) {
		self.modeInfo = [IRCChannelMode new];
		
		self.memberList = [NSMutableArray new];
	}
	
	return self;
}

#pragma mark -
#pragma mark Configuration

- (void)setup:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssert(seed);

	if (PointerIsEmpty(self.config)) {
		self.config = [seed mutableCopy];
	}
}

- (void)updateConfig:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssert(seed);
	
	self.config = [seed mutableCopy];
}

- (NSMutableDictionary *)dictionaryValue
{
	return [self.config dictionaryValue];
}

#pragma mark -
#pragma mark Property Getter

- (NSString *)name
{
	return self.config.channelName;
}

- (NSString *)secretKey
{
	return self.config.secretKey;
}

- (BOOL)isChannel
{
	return (self.config.type == IRCChannelNormalType);
}

- (BOOL)isPrivateMessage
{
	return (self.config.type == IRCChannelPrivateMessageType);
}

- (NSString *)channelTypeString
{
	if (self.config.type == IRCChannelPrivateMessageType) {
		return @"query";
	}

	return @"channel";
}

#pragma mark -
#pragma mark Property Setter

- (void)setName:(NSString *)value
{
	if ([self.name isEqualToString:value] == NO) {
		self.config.channelName = value;
	}
}

- (void)setTopic:(NSString *)topic
{
	if ([_topic isEqualToString:topic] == NO) {
		_topic = topic;
	}

    [self.viewController setTopic:topic];
}

#pragma mark -
#pragma mark Utilities

- (void)preferencesChanged
{
	[self.viewController preferencesChanged];
	
	[self reopenLogFileIfNeeded];
}

#pragma mark -
#pragma mark Channel Status

- (void)resetStatus:(IRCChannelStatus)newStatus
{
	self.errorOnLastJoinAttempt = NO;
	
	self.status = newStatus;

    _topic = nil;
	
	[self.modeInfo clear];

	[self clearMembers];
}

- (void)activate
{
    [self.client postEventToViewController:@"channelJoined" forChannel:self];
    
	[self resetStatus:IRCChannelJoined];
}

- (void)deactivate
{
    [self.client postEventToViewController:@"channelParted" forChannel:self];

    [self.viewController setTopic:nil];
    
	[self resetStatus:IRCChannelParted];
}

- (void)terminate
{
	[self resetStatus:IRCChannelTerminated];
	
	[self closeLogFile];

	[self.viewController terminate];
}

#pragma mark -
#pragma mark Log File

- (void)reopenLogFileIfNeeded
{
	if ([TPCPreferences logTranscript]) {
		PointerIsEmptyAssert(self.logFile);

		[self.logFile reopenIfNeeded];
	} else {
		[self closeLogFile];
	}
}

- (void)closeLogFile
{
	PointerIsEmptyAssert(self.logFile);

	[self.logFile close];
}

#pragma mark -
#pragma mark Printing

- (void)writeToLogFile:(TVCLogLine *)line
{
	if ([TPCPreferences logTranscript]) {
		if (PointerIsEmpty(self.logFile)) {
			self.logFile = [TLOFileLogger new];

			self.logFile.client = self.client;
			self.logFile.channel = self;
			self.logFile.writePlainText = YES;
			self.logFile.flatFileStructure = NO;
		}

		NSString *logstr = [self.viewController renderedBodyForTranscriptLog:line];

		if (NSObjectIsNotEmpty(logstr)) {
			[self.logFile writePlainTextLine:logstr];
		}
	}
}

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	[self.viewController print:logLine completionBlock:completionBlock];
	
	[self writeToLogFile:logLine];
}

#pragma mark -
#pragma mark Member List

- (void)sortedMemberListReload
{
	/* Do not call this unless needed. */
	self.memberList = [self.memberList sortedArrayUsingComparator:NSDefaultComparator];
	self.memberListLengthSorted = [self.memberList sortedArrayUsingComparator:[IRCUser nicknameLengthComparator]];

	[self reloadMemberList];
}

- (void)sortedInsert:(IRCUser *)item
{
	PointerIsEmptyAssert(item);

	self.memberList = [self.memberList arrayByInsertingSortedObject:item usingComparator:NSDefaultComparator];

	/* Conversation tracking scans based on nickname length. */
	self.memberListLengthSorted = [self.memberList arrayByInsertingSortedObject:item usingComparator:[IRCUser nicknameLengthComparator]];
}

#pragma mark -

- (void)addMember:(IRCUser *)user
{
	[self addMember:user reload:YES];
}

- (void)updateOrAddMember:(IRCUser *)user
{
	[self addMember:user reload:NO];
}

- (void)addMember:(IRCUser *)user reload:(BOOL)reload
{
	PointerIsEmptyAssert(user);
	
	[self removeMember:user.nickname reload:NO];
	[self sortedInsert:user];

    [self.client postEventToViewController:@"channelMemberAdded" forChannel:self];
	
	if (reload) {
		[self reloadMemberList];
	}
}

#pragma mark -

- (void)removeMember:(NSString *)nick
{
	[self removeMember:nick reload:YES];
}

- (void)removeMember:(NSString *)nick reload:(BOOL)reload
{
	NSObjectIsEmptyAssert(nick);
	
	NSInteger n = [self indexOfMember:nick];

	if (NSDissimilarObjects(n, NSNotFound)) {
		IRCUser *user = [self.memberList objectAtIndex:n];

		self.memberList = [self.memberList arrayByRemovingObjectAtIndex:n];

        [self.client postEventToViewController:@"channelMemberRemoved" forChannel:self];

		n = [self.memberListLengthSorted indexOfObject:user];

		self.memberListLengthSorted = [self.memberListLengthSorted arrayByRemovingObjectAtIndex:n];
	}
	
	if (reload) {
		[self reloadMemberList];
	}
}

#pragma mark -

- (void)renameMember:(NSString *)fromNick to:(NSString *)toNick
{
	NSObjectIsEmptyAssert(fromNick);
	NSObjectIsEmptyAssert(toNick);
	
	NSInteger n = [self indexOfMember:fromNick];

	NSAssertReturn(NSDissimilarObjects(n, NSNotFound));
	
	IRCUser *m = [self memberAtIndex:n];
	
	m.nickname = toNick;

	[self removeMember:m.nickname reload:NO];
	
	[self sortedInsert:m];
	[self reloadMemberList];
}

#pragma mark -

- (void)changeMember:(NSString *)nick mode:(NSString *)mode value:(BOOL)value
{
	NSObjectIsEmptyAssert(nick);
	NSObjectIsEmptyAssert(mode);
	
	NSInteger n = [self indexOfMember:nick];

	NSAssertReturn(NSDissimilarObjects(n, NSNotFound));
	
	IRCUser *m = [self memberAtIndex:n];
	
	switch ([mode characterAtIndex:0]) {
		case 'q': { m.q = value; break; }
		case 'a': { m.a = value; break; }
		case 'o': { m.o = value; break; }
		case 'h': { m.h = value; break; }
		case 'v': { m.v = value; break; }
	}
	
	[self removeMember:m.nickname reload:NO];

	IRCISupportInfo *isupport = self.client.isupport;

	m.q = (m.q && [isupport modeIsSupportedUserPrefix:@"q"]);
	m.a = (m.a && [isupport modeIsSupportedUserPrefix:@"a"]);
	m.o = (m.o && [isupport modeIsSupportedUserPrefix:@"o"]);
	m.h = (m.h && [isupport modeIsSupportedUserPrefix:@"h"]);
	m.v = (m.v && [isupport modeIsSupportedUserPrefix:@"v"]);
	
	[self sortedInsert:m];
	[self reloadMemberList];
}

#pragma mark -

- (void)clearMembers
{
	self.memberList = nil;
	self.memberList = @[];
	
	[self reloadMemberList];
}

#pragma mark -

- (NSInteger)indexOfMember:(NSString *)nick
{
	return [self indexOfMember:nick options:0];
}

- (NSInteger)indexOfMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSObjectIsEmptyAssertReturn(nick, -1);

	//[self.memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname"];

	if (mask & NSCaseInsensitiveSearch) {
		return [self.memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualIgnoringCase:)];
	} else {
		return [self.memberList indexOfObjectMatchingValue:nick withKeyPath:@"nickname" usingSelector:@selector(isEqualToString:)];
	}
}

#pragma mark -

- (IRCUser *)memberAtIndex:(NSInteger)index
{
	return [self.memberList safeObjectAtIndex:index];
}

#pragma mark -

- (IRCUser *)findMember:(NSString *)nick
{
	return [self findMember:nick options:0];
}

- (IRCUser *)findMember:(NSString *)nick options:(NSStringCompareOptions)mask
{
	NSInteger n = [self indexOfMember:nick options:mask];

	NSAssertReturnR(NSDissimilarObjects(n, NSNotFound), nil);
	
	return [self memberAtIndex:n];
}

#pragma mark -

- (NSInteger)numberOfMembers
{
	return self.memberList.count;
}

#pragma mark -

- (void)reloadMemberList
{
	if (self.worldController.selectedItem == self) {
		[self.masterController.memberList reloadData];
	}
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isActive
{
	return (self.status == IRCChannelJoined);
}

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
	return self.config.channelName;
}

- (IRCClient *)client
{
	return _client;
}

- (TVCLogControllerOperationQueue *)operationQueue
{
    return [_client operationQueue];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return [self numberOfMembers];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return _treeUserlistHeight;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	IRCUser *user = [self memberAtIndex:row];

	return TXTFLS(@"AccessibilityMemberListDescription", user.nickname, [self.name channelNameToken]);
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(TVCMemberListCell *)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	cell.memberPointer = self.memberList[row];
}

@end
