/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@dynamic excludeKeywords;
@dynamic highlightKeywords;
@dynamic isEncrypted;
@dynamic isHistoric;
@dynamic lineTypeInteger;
@dynamic memberTypeInteger;
@dynamic messageBody;
@dynamic nickname;
@dynamic nicknameColorNumber;
@dynamic rawCommand;
@dynamic receivedAt;

- (id)init
{
	if (self = [super init]) {
		/* Define defaults. */
		self.receivedAt = [NSDate date];

		self.nickname = NSStringEmptyPlaceholder;
		self.nicknameColorNumber = 0;

		self.messageBody = NSStringEmptyPlaceholder;

		self.rawCommand = TXLogLineDefaultRawCommandValue;

		self.highlightKeywords = @[];
		self.excludeKeywords = @[];

		self.lineType = TVCLogLinePrivateMessageType;
		self.memberType = TVCLogLineMemberNormalType;

		self.isHistoric = NO;
		self.isEncrypted = NO;

		/* Return new copy. */
		return self;
	}
	
	return nil;
}

+ (TVCLogLine *)newManagedObjectWithoutContextAssociation
{
	/* Gather the entity structure. */
	NSManagedObjectContext *context = [TVCLogControllerHistoricLogSharedInstance() managedObjectContext];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TVCLogLine" inManagedObjectContext:context];

	/* Create a new instance. */
	TVCLogLine *newEntry = (id)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];

	/* Save the creation time of this log line as that will be
	 used for the actual purposes of sorting results. */
	[newEntry setValue:[NSDate date] forKey:@"creationDate"];

	/* Return our managed object. */
	return newEntry;
}

+ (TVCLogLine *)newManagedObjectForClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	/* A client must always be provided. */
	PointerIsEmptyAssertReturn(client, nil);

	/* Create managed object representing a log line. */
	NSManagedObjectContext *context = [TVCLogControllerHistoricLogSharedInstance() managedObjectContext];

	TVCLogLine *newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"TVCLogLine"
														 inManagedObjectContext:context];

	/* Save the creation time of this log line as that will be 
	 used for the actual purposes of sorting results. */
	[newEntry setValue:[NSDate date] forKey:@"creationDate"];

	/* We now save associated client and channel information 
	 for also reference purposes later on. */
	[newEntry setValue:[client uniqueIdentifier] forKey:@"clientID"];

	if (channel) {
		[newEntry setValue:[channel uniqueIdentifier] forKey:@"channelID"];
	}

	/* Return our managed object. */
	return newEntry;
}

+ (NSString *)lineTypeString:(TVCLogLineType)type
{
	switch (type) {
		case TVCLogLineActionType:							{ return @"action";					}
		case TVCLogLineActionNoHighlightType:				{ return @"action";					}
		case TVCLogLineCTCPType:							{ return @"ctcp";					}
		case TVCLogLineDCCFileTransferType:					{ return @"dccfiletransfer";		}
		case TVCLogLineDebugType:							{ return @"debug";					}
		case TVCLogLineInviteType:							{ return @"invite";					}
		case TVCLogLineJoinType:							{ return @"join";					}
		case TVCLogLineKickType:							{ return @"kick";					}
		case TVCLogLineKillType:							{ return @"kill";					}
		case TVCLogLineModeType:							{ return @"mode";					}
		case TVCLogLineNickType:							{ return @"nick";					}
		case TVCLogLineNoticeType:							{ return @"notice";					}
		case TVCLogLinePartType:							{ return @"part";					}
		case TVCLogLinePrivateMessageType:					{ return @"privmsg";				}
		case TVCLogLinePrivateMessageNoHighlightType:		{ return @"privmsg";				}
		case TVCLogLineQuitType:							{ return @"quit";					}
		case TVCLogLineTopicType:							{ return @"topic";					}
		case TVCLogLineWebsiteType:							{ return @"website";				}
		default:											{ return NSStringEmptyPlaceholder;	}
	}
	
	return NSStringEmptyPlaceholder;
}

+ (NSString *)memberTypeString:(TVCLogLineMemberType)type
{
	if (type == TVCLogLineMemberLocalUserType) {
		return @"myself";
	}

	return @"normal";
}

- (TVCLogLineType)lineType;
{
	return [self.lineTypeInteger integerValue];
}

- (void)setLineType:(TVCLogLineType)lineType
{
	[self setLineTypeInteger:@(lineType)];
}

- (TVCLogLineMemberType)memberType
{
	return [self.memberTypeInteger integerValue];
}

- (void)setMemberType:(TVCLogLineMemberType)memberType
{
	[self setMemberTypeInteger:@(memberType)];
}

- (NSString *)lineTypeString
{
	return [TVCLogLine lineTypeString:[self lineType]];
}

- (NSString *)memberTypeString
{
	return [TVCLogLine memberTypeString:[self memberType]];
}

- (NSString *)formattedTimestamp
{
	TPCThemeSettings *customSettings = [self.themeController customSettings];

	return [self formattedTimestampWithForcedFormat:[customSettings timestampFormat]];
}

- (NSString *)formattedTimestampWithForcedFormat:(NSString *)format;
{
	NSObjectIsEmptyAssertReturn(self.receivedAt, nil);

	NSString *time = TXFormattedTimestampWithOverride(self.receivedAt, [TPCPreferences themeTimestampFormat], format);

	NSObjectIsEmptyAssertReturn(time, nil);

	return [time stringByAppendingString:NSStringWhitespacePlaceholder];
}

- (NSString *)formattedNickname:(IRCChannel *)owner
{
	return [self formattedNickname:owner withForcedFormat:nil];
}

- (NSString *)formattedNickname:(IRCChannel *)owner withForcedFormat:(NSString *)format
{
	NSObjectIsEmptyAssertReturn(self.nickname, nil);

	if (format == nil) {
		if ([self lineType] == TVCLogLineActionType) {
			return [NSString stringWithFormat:TXLogLineActionNicknameFormat, self.nickname];
		} else if ([self lineType] == TVCLogLineNoticeType) {
			return [NSString stringWithFormat:TXLogLineNoticeNicknameFormat, self.nickname];
		}
	}

	PointerIsEmptyAssertReturn(owner, nil);

	return [owner.client formatNick:self.nickname channel:owner formatOverride:format];
}

@end
