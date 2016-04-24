/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "IRCUserPrivate.h"

NSString * const TVCLogLineUndefinedNicknameFormat			= @"<%@%n>";
NSString * const TVCLogLineActionNicknameFormat				= @"%@ ";
NSString * const TVCLogLineNoticeNicknameFormat				= @"-%@-";

NSString * const TVCLogLineSpecialNoticeMessageFormat		= @"[%@]: %@";

NSString * const TVCLogLineDefaultRawCommandValue			= @"-100";

@interface TVCLogLine ()
@property (readwrite, copy) NSString *nicknameColorStyle;
@property (readwrite, assign) BOOL nicknameColorStyleOverride; // YES if the nicknameColorStyle was set by the user
@end

@implementation TVCLogLine

- (instancetype)init
{
	if ((self = [super init])) {
		/* Define defaults. */
		self.receivedAt = [NSDate date];

		self.rawCommand = TVCLogLineDefaultRawCommandValue;

		self.highlightKeywords = @[];
		self.excludeKeywords = @[];

		self.lineType = TVCLogLineUndefinedType;
		self.memberType = TVCLogLineMemberNormalType;

		self.isHistoric = NO;
		self.isEncrypted = NO;

		/* Return new copy. */
		return self;
	}

	return nil;
}

+ (NSString *)lineTypeString:(TVCLogLineType)type
{
#define _dv(lineType, returnValue)			case (lineType): { return (returnValue); break; }

	switch (type) {
		_dv(TVCLogLineActionNoHighlightType, @"action")
		_dv(TVCLogLineActionType, @"action")
		_dv(TVCLogLineCTCPType, @"ctcp")
		_dv(TVCLogLineCTCPQueryType, @"ctcp")
		_dv(TVCLogLineCTCPReplyType, @"ctcp")
		_dv(TVCLogLineDCCFileTransferType, @"dcc-file-transfer")
		_dv(TVCLogLineDebugType, @"debug")
		_dv(TVCLogLineInviteType, @"invite")
		_dv(TVCLogLineJoinType, @"join")
		_dv(TVCLogLineKickType, @"kick")
		_dv(TVCLogLineKillType, @"kill")
		_dv(TVCLogLineModeType, @"mode")
		_dv(TVCLogLineNickType, @"nick")
		_dv(TVCLogLineNoticeType, @"notice")
		_dv(TVCLogLineOffTheRecordEncryptionStatusType, @"off-the-record-encryption-status")
		_dv(TVCLogLinePartType, @"part")
		_dv(TVCLogLinePrivateMessageNoHighlightType, @"privmsg")
		_dv(TVCLogLinePrivateMessageType, @"privmsg")
		_dv(TVCLogLineQuitType, @"quit")
		_dv(TVCLogLineTopicType, @"topic")
		_dv(TVCLogLineWebsiteType, @"website")

		default:
		{
			return nil;
		}
	}

#undef _dv
}

+ (NSString *)memberTypeString:(TVCLogLineMemberType)type
{
	if (type == TVCLogLineMemberLocalUserType) {
		return @"myself";
	} else {
		return @"normal";
	}
}

- (NSString *)lineTypeString
{
	return [TVCLogLine lineTypeString:self.lineType];
}

- (NSString *)memberTypeString
{
	return [TVCLogLine memberTypeString:self.memberType];
}

- (NSString *)formattedTimestamp
{
	return [self formattedTimestampWithFormat:nil];
}

- (NSString *)formattedTimestampWithFormat:(NSString *)format
{
	PointerIsEmptyAssertReturn(self.receivedAt, nil);

	if (NSObjectIsEmpty(format)) {
		format = [themeSettings() themeTimestampFormat];
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeTimestampFormat];
	}

	if (NSObjectIsEmpty(format)) {
		format = [TPCPreferences themeTimestampFormatDefault];
	}
	
	NSString *time = TXFormattedTimestamp(self.receivedAt, format);

	return [time stringByAppendingString:NSStringWhitespacePlaceholder];
}

- (NSString *)formattedNickname:(IRCChannel *)inChannel
{
	return [self formattedNickname:inChannel withFormat:nil];
}

- (NSString *)formattedNickname:(IRCChannel *)inChannel withFormat:(NSString *)format
{
	PointerIsEmptyAssertReturn(inChannel, nil);

	NSObjectIsEmptyAssertReturn(self.nickname, nil);

	if (format == nil) {
		if (self.lineType == TVCLogLineActionType) {
			return [NSString stringWithFormat:TVCLogLineActionNicknameFormat, self.nickname];
		} else if (self.lineType == TVCLogLineNoticeType) {
			return [NSString stringWithFormat:TVCLogLineNoticeNicknameFormat, self.nickname];
		}
	}

	return [[inChannel associatedClient] formatNickname:self.nickname inChannel:inChannel withFormat:format];
}

- (NSString *)renderedBodyForTranscriptLogInChannel:(IRCChannel *)channel
{
	NSMutableString *s = [NSMutableString string];

	/* Format time into a 24 hour universal time. */
	NSString *time = [self formattedTimestampWithFormat:TLOFileLoggerISOStandardClockFormat];

	if (time) {
		[s appendString:time];
	}

	/* Format nickname into a standard format ignoring user preference. */
	NSString *nickname = nil;

	if (self.lineType == TVCLogLineActionType) {
		nickname = [self formattedNickname:channel withFormat:TLOFileLoggerActionNicknameFormat];
	} else if (self.lineType == TVCLogLineNoticeType) {
		nickname = [self formattedNickname:channel withFormat:TLOFileLoggerNoticeNicknameFormat];
	} else {
		nickname = [self formattedNickname:channel withFormat:TLOFileLoggerUndefinedNicknameFormat];
	}

	if (nickname) {
		[s appendString:nickname];
		[s appendString:NSStringWhitespacePlaceholder];
	}

	/* Append actual body. */
	[s appendString:self.messageBody];

	/* Return result minus any formatting. */
	return [s stripIRCEffects];
}

- (void)setNickname:(NSString *)nickname
{
	if (NSObjectsAreEqual(_nickname, nickname) == NO) {
		_nickname = [nickname copy];

		[self computeNicknameColorStyle];
	}
}

- (void)computeNicknameColorStyle
{
	if (self.lineType == TVCLogLinePrivateMessageType ||
		self.lineType == TVCLogLinePrivateMessageNoHighlightType ||
		self.lineType == TVCLogLineActionType ||
		self.lineType == TVCLogLineActionNoHighlightType)
	{
		BOOL isOverride = NO;

		self.nicknameColorStyle =
		[IRCUserNicknameColorStyleGenerator nicknameColorStyleForString:self.nickname isOverride:&isOverride];

		self.nicknameColorStyleOverride = isOverride;
	} else {
		self.nicknameColorStyle = nil;
	}
}

- (NSData *)jsonDictionaryRepresentation
{
	/* Create dictionary with associated data. */
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	NSTimeInterval receivedAt = [self.receivedAt timeIntervalSince1970];

	[dic setDouble:receivedAt forKey:@"receivedAt"];

	[dic maybeSetObject:self.excludeKeywords forKey:@"excludeKeywords"];
	[dic maybeSetObject:self.highlightKeywords	forKey:@"highlightKeywords"];

	[dic maybeSetObject:self.nickname forKey:@"nickname"];

	[dic maybeSetObject:self.messageBody forKey:@"messageBody"];
	[dic maybeSetObject:self.rawCommand forKey:@"rawCommand"];

	[dic setUnsignedInteger:self.lineType forKey:@"lineType"];
	[dic setUnsignedInteger:self.memberType forKey:@"memberType"];

	[dic setBool:self.isEncrypted forKey:@"isEncrypted"];
	[dic setBool:self.isHistoric forKey:@"isHistoric"];

	/* Convert dictionary to JSON. */
	/* Why JSON? Because a binary property list would have to be loaded into memory
	 each time a new entry wanted to be created. The property list would have to be
	 loaded as a dictionary, mutated, then resaved to disk. Instead, with JSON, we
	 simply append a new line for each entry and truncate it based off that logic
	 to make maximum number of lines apply. */
	/* We used to have Core Data but that had too many instablities and performance
	 overhead to justify keeping it around. */
	NSError *serializeError = nil;

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializeError];

	if (jsonData == nil) {
		LogToConsole(@"JSON Serialization Error: %@", [serializeError localizedDescription]);

		NSAssert(NO, @"JSON serialization error in TVCLogLine. See Console for more information.");
	}

	return jsonData;
}

- (TVCLogLine *)initWithRawJSONData:(NSData *)data
{
	NSError *serializeError = nil;

	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];

	if (jsonDictionary == nil) {
		LogToConsole(@"An error occured converting raw data into an JSON object: %@", [serializeError localizedDescription]);

		return nil; // Failed to init.
	} else {
		return [self initWithJSONRepresentation:jsonDictionary];
	}
}

- (TVCLogLine *)initWithJSONRepresentation:(NSDictionary *)dic
{
	if ((self = [self init])) {
		[self populateDictionaryValues:dic];

		return self;
	}

	return nil;
}

- (void)populateDictionaryValues:(nonnull NSDictionary *)dic
{
	/* If any key does not exist, then its value is inherited from the -init method. */
	double receivedAt = [dic doubleForKey:@"receivedAt" orUseDefault:[NSDate unixTime]];
	
	self.receivedAt	= [NSDate dateWithTimeIntervalSince1970:receivedAt];
	
	[dic assignStringTo:&_nickname forKey:@"nickname"];

	[dic assignStringTo:&_messageBody forKey:@"messageBody"];

	[dic assignStringTo:&_rawCommand forKey:@"rawCommand"];
	
	[dic assignArrayTo:&_highlightKeywords forKey:@"highlightKeywords"];
	[dic assignArrayTo:&_excludeKeywords forKey:@"excludeKeywords"];

	[dic assignUnsignedIntegerTo:&_lineType forKey:@"lineType"];
	[dic assignUnsignedIntegerTo:&_memberType forKey:@"memberType"];
	
	[dic assignBoolTo:&_isHistoric forKey:@"isHistoric"];
	[dic assignBoolTo:&_isEncrypted forKey:@"isEncrypted"];

	[self computeNicknameColorStyle];
}

@end
