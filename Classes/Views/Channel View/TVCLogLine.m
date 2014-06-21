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

- (id)init
{
	if (self = [super init]) {
		/* Define defaults. */
		_receivedAt = [NSDate date];

		_nickname = NSStringEmptyPlaceholder;
		_nicknameColorNumber = 0;

		_messageBody = NSStringEmptyPlaceholder;

		_rawCommand = TVCLogLineDefaultRawCommandValue;

		_highlightKeywords = @[];
		_excludeKeywords = @[];

		_lineType = TVCLogLineUndefinedType;
		_memberType = TVCLogLineMemberNormalType;

		_isHistoric = NO;
		_isEncrypted = NO;

		/* Return new copy. */
		return self;
	}

	return nil;
}

+ (NSString *)lineTypeString:(TVCLogLineType)type
{
	switch (type) {
		case TVCLogLineActionType:							{ return @"action";						}
		case TVCLogLineActionNoHighlightType:				{ return @"action";						}
		case TVCLogLineCTCPType:							{ return @"ctcp";						}
		case TVCLogLineDCCFileTransferType:					{ return @"dccfiletransfer";			}
		case TVCLogLineDebugType:							{ return @"debug";						}
		case TVCLogLineInviteType:							{ return @"invite";						}
		case TVCLogLineJoinType:							{ return @"join";						}
		case TVCLogLineKickType:							{ return @"kick";						}
		case TVCLogLineKillType:							{ return @"kill";						}
		case TVCLogLineModeType:							{ return @"mode";						}
		case TVCLogLineNickType:							{ return @"nick";						}
		case TVCLogLineNoticeType:							{ return @"notice";						}
		case TVCLogLinePartType:							{ return @"part";						}
		case TVCLogLinePrivateMessageType:					{ return @"privmsg";					}
		case TVCLogLinePrivateMessageNoHighlightType:		{ return @"privmsg";					}
		case TVCLogLineQuitType:							{ return @"quit";						}
		case TVCLogLineTopicType:							{ return @"topic";						}
		case TVCLogLineWebsiteType:							{ return @"website";					}
		default:											{ return NSStringEmptyPlaceholder;		}
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
	return [self formattedTimestampWithForcedFormat:[themeSettings() timestampFormat]];
}

- (NSString *)formattedTimestampWithForcedFormat:(NSString *)format
{
	NSObjectIsEmptyAssertReturn(_receivedAt, nil);

	if (format == nil) {
		format = [TPCPreferences themeTimestampFormat];
	}
	
	NSString *time = TXFormattedTimestamp(_receivedAt, format);

	return [time stringByAppendingString:NSStringWhitespacePlaceholder];
}

- (NSString *)formattedNickname:(IRCChannel *)owner
{
	return [self formattedNickname:owner withForcedFormat:nil];
}

- (NSString *)formattedNickname:(IRCChannel *)owner withForcedFormat:(NSString *)format
{
	NSObjectIsEmptyAssertReturn(_nickname, nil);

	if (format == nil) {
		if ([self lineType] == TVCLogLineActionType) {
			return [NSString stringWithFormat:TVCLogLineActionNicknameFormat, _nickname];
		} else if ([self lineType] == TVCLogLineNoticeType) {
			return [NSString stringWithFormat:TVCLogLineNoticeNicknameFormat, _nickname];
		}
	}

	return [[owner associatedClient] formatNick:_nickname channel:owner formatOverride:format];
}

- (NSString *)renderedBodyForTranscriptLogInChannel:(IRCChannel *)channel
{
	NSObjectIsEmptyAssertReturn(_messageBody, nil);

	NSMutableString *s = [NSMutableString string];

	/* Format time into a 24 hour universal time. */
	NSString *time = [self formattedTimestampWithForcedFormat:TLOFileLoggerISOStandardClockFormat];

	if (time) {
		[s appendString:time];
	}

	/* Format nickname into a standard format ignoring user preference. */
	NSString *nick;

	if ([self lineType] == TVCLogLineActionType) {
		nick = [self formattedNickname:channel withForcedFormat:TLOFileLoggerActionNicknameFormat];
	} else if ([self lineType] == TVCLogLineNoticeType) {
		nick = [self formattedNickname:channel withForcedFormat:TLOFileLoggerNoticeNicknameFormat];
	} else {
		nick = [self formattedNickname:channel withForcedFormat:TLOFileLoggerUndefinedNicknameFormat];
	}

	if (nick) {
		[s appendString:nick];
		[s appendString:NSStringWhitespacePlaceholder];
	}

	/* Append actual body. */
	[s appendString:_messageBody];

	/* Return result minus any formatting. */
	return [s stripIRCEffects];
}

- (NSData *)jsonDictionaryRepresentation
{
	/* Create dictionary with associated data. */
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	NSString *dateValue = [NSString stringWithDouble:[_receivedAt timeIntervalSince1970]];

	[dict maybeSetObject:dateValue					forKey:@"receivedAt"];

	[dict maybeSetObject:_excludeKeywords			forKey:@"excludeKeywords"];
	[dict maybeSetObject:_highlightKeywords			forKey:@"highlightKeywords"];

	[dict maybeSetObject:_nickname					forKey:@"nickname"];

	[dict maybeSetObject:@(_nicknameColorNumber)	forKey:@"nicknameColorNumber"];

	[dict maybeSetObject:_rawCommand				forKey:@"rawCommand"];
	[dict maybeSetObject:_messageBody				forKey:@"messageBody"];

	[dict maybeSetObject:@(_lineType)				forKey:@"lineType"];
	[dict maybeSetObject:@(_memberType)				forKey:@"memberType"];

	[dict setBool:_isEncrypted						forKey:@"isEncrypted"];
	[dict setBool:_isHistoric						forKey:@"isHistoric"];

	/* Convert dictionary to JSON. */
	/* Why JSON? Because a binary property list would have to be loaded into memory
	 each time a new entry wanted to be created. The property list would have to be
	 loaded as a dictionary, mutated, then resaved to disk. Instead, with JSON, we
	 simply append a new line for each entry and truncate it based off that logic
	 to make maximum number of lines apply. */
	/* We used to have Core Data but that had too many instablities and performance
	 overhead to justify keeping it around. */
	NSError *jsonerror;

	NSData *jsondata = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&jsonerror];

	if (jsonerror) {
		LogToConsole(@"JSON Serialization Error: %@", [jsonerror localizedDescription]);

		NSAssert(NO, @"JSON serialization error in TVCLogLine. See Console for more information.");
	}

	return jsondata;
}

- (TVCLogLine *)initWithRawJSONData:(NSData *)input
{
	NSError *jsonconverr;

	NSDictionary *jsondata = [NSJSONSerialization JSONObjectWithData:input options:0 error:&jsonconverr];

	if (jsonconverr) {
		LogToConsole(@"An error occured converting raw data into an JSON object: %@", [jsonconverr localizedDescription]);

		return nil; // Failed to init.
	} else {
		return [self initWithJSONRepresentation:jsondata];
	}
}


- (TVCLogLine *)initWithJSONRepresentation:(NSDictionary *)input
{
	if ((self = [self init])) {;
		double receivedAt = [input doubleForKey:@"receivedAt" orUseDefault:[NSDate epochTime]];

		_nickname				= [input objectForKey:@"nickname" orUseDefault:NSStringEmptyPlaceholder];
		_nicknameColorNumber	= [input integerForKey:@"nicknameColorNumber" orUseDefault:0];

		_messageBody		= [input objectForKey:@"messageBody" orUseDefault:NSStringEmptyPlaceholder];

		_rawCommand			= [input objectForKey:@"rawCommand" orUseDefault:TVCLogLineDefaultRawCommandValue];

		_highlightKeywords	= [input objectForKey:@"highlightKeywords" orUseDefault:@[]];
		_excludeKeywords	= [input objectForKey:@"excludeKeywords" orUseDefault:@[]];

		_lineType			= [input integerForKey:@"lineType" orUseDefault:TVCLogLineUndefinedType];
		_memberType			= [input integerForKey:@"memberType" orUseDefault:TVCLogLineMemberNormalType];

		_isHistoric		= [input integerForKey:@"isHistoric" orUseDefault:NO];
		_isEncrypted	= [input integerForKey:@"isEncrypted" orUseDefault:NO];

		_receivedAt		= [NSDate dateWithTimeIntervalSince1970:receivedAt];

		return self;
	}
		
	return nil;
}

@end
