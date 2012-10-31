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

@implementation TVCLogLine

+ (NSString *)lineTypeString:(TVCLogLineType)type
{
	switch (type) {
		case TVCLogLineCTCPType:							return @"ctcp";
		case TVCLogLinePrivateMessageType:					return @"privmsg";
		case TVCLogLinePrivateMessageNoHighlightType:		return @"privmsg";
		case TVCLogLineNoticeType:							return @"notice";
		case TVCLogLineActionType:							return @"action";
		case TVCLogLineActionNoHighlightType:				return @"action";
		case TVCLogLineJoinType:							return @"join";
		case TVCLogLinePartType:							return @"part";
		case TVCLogLineKickType:							return @"kick";
		case TVCLogLineQuitType:							return @"quit";
		case TVCLogLineKillType:							return @"kill";
		case TVCLogLineNickType:							return @"nick";
		case TVCLogLineModeType:							return @"mode";
		case TVCLogLineTopicType:							return @"topic";
		case TVCLogLineInviteType:							return @"invite";
		case TVCLogLineWebsiteType:							return @"website";
		case TVCLogLineDebugType:							return @"debug";
		case TVCLogLineRawHTMLType:							return @"rawhtml";
	}
	
	return NSStringEmptyPlaceholder;
}

- (id)initWithLineType:(TVCLogLineType)lineType
			memberType:(TVCLogMemberType)memberType
			receivedAt:(NSDate *)receivedAt
				  body:(NSString *)body
{
	if ((self = [self init])) {
		self.receivedAt = receivedAt;
		
		self.nick = nil;
		self.body = body;
		
		self.lineType	= lineType;
		self.memberType = memberType;
		
		self.nickColorNumber = 0;
		
		self.keywords		= nil;
		self.excludeWords	= nil;

		self.isHistoric = NO;

		return self;
	}

	return nil;
}

+ (NSString *)memberTypeString:(TVCLogMemberType)type
{
	switch (type) {
		case TVCLogMemberNormalType:	return @"normal";
		case TVCLogMemberLocalUserType:	return @"myself";
	}
	
	return NSStringEmptyPlaceholder;
}

- (NSString *)formattedTimestamp
{
	IRCWorld *world = TPCPreferences.masterController.world;
	
	if (NSObjectIsNotEmpty(self.receivedAt)) {
		NSString *time = TXFormattedTimestampWithOverride(self.receivedAt, [TPCPreferences themeTimestampFormat], world.viewTheme.other.timestampFormat);

		if (NSObjectIsNotEmpty(time)) {
			return [time stringByAppendingString:NSStringWhitespacePlaceholder];
		}
	}

	return nil;
}

- (NSString *)formattedNickname:(IRCChannel *)owner
{
	if (NSObjectIsNotEmpty(self.nick)) {
		if (self.lineType == TVCLogLineActionType) {
			return [NSString stringWithFormat:TXLogLineActionNicknameFormat, self.nick];
		} else if (self.lineType == TVCLogLineNoticeType) {
			return [NSString stringWithFormat:TXLogLineNoticeNicknameFormat, self.nick];
		} else {
			return [owner.client formatNick:self.nick channel:owner];
		}
	}

	return nil;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		NSInteger receivedAt = NSDictionaryIntegerKeyValueCompare(dic, @"receivedAt",		[NSDate.date timeIntervalSince1970]);

		self.nick			= NSDictionaryObjectKeyValueCompare(dic, @"nick",			NSStringEmptyPlaceholder);
		self.body			= NSDictionaryObjectKeyValueCompare(dic, @"body",			NSStringEmptyPlaceholder);

		self.keywords		= NSDictionaryObjectKeyValueCompare(dic, @"keywords",		@[]);
		self.excludeWords	= NSDictionaryObjectKeyValueCompare(dic, @"excludeWords",	@[]);

		self.lineType			= NSDictionaryIntegerKeyValueCompare(dic, @"lineType",			TVCLogLineRawHTMLType);
		self.memberType			= NSDictionaryIntegerKeyValueCompare(dic, @"memberType",		TVCLogMemberNormalType);
		self.nickColorNumber	= NSDictionaryIntegerKeyValueCompare(dic, @"nickColorNumber",	0);

		self.isHistoric	= [dic boolForKey:@"isHistoric"];

		self.receivedAt	= [NSDate dateWithTimeIntervalSince1970:receivedAt];

		return self;
	}

	return nil;
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	[dict safeSetObject:@([self.receivedAt timeIntervalSince1970])		forKey:@"receivedAt"];

	[dict safeSetObject:self.nick					forKey:@"nick"];
	[dict safeSetObject:self.body					forKey:@"body"];
	[dict safeSetObject:self.keywords				forKey:@"keywords"];
	[dict safeSetObject:self.excludeWords			forKey:@"excludeWords"];

	[dict safeSetObject:@(self.lineType)			forKey:@"lineType"];
	[dict safeSetObject:@(self.memberType)			forKey:@"memberType"];
	[dict safeSetObject:@(self.nickColorNumber)		forKey:@"nickColorNumber"];

	[dict setBool:self.isHistoric					forKey:@"isHistoric"];

	return dict;
}

@end