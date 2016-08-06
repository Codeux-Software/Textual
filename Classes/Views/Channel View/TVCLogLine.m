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

#import "TVCLogLineInternal.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TVCLogLineUndefinedNicknameFormat = @"<%@%n>";
NSString * const TVCLogLineActionNicknameFormat	= @"%@ ";
NSString * const TVCLogLineNoticeNicknameFormat	= @"-%@-";

NSString * const TVCLogLineSpecialNoticeMessageFormat = @"[%@]: %@";

NSString * const TVCLogLineDefaultCommandValue = @"-100";

@implementation TVCLogLine

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		if ([self isMutable] == NO) {
			DESIGNATED_INITIALIZER_EXCEPTION
		}

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (nullable TVCLogLine *)initWithJSONData:(NSData *)data
{
	ObjectIsAlreadyInitializedAssert

	NSError *serializeError = nil;

	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];

	if (jsonDictionary == nil) {
		LogToConsoleError("An error occured converting data into a JSON object: %{public}@",
				serializeError.localizedDescription)

		return nil; // Failed to init
	}

	return [self initWithDictionary:jsonDictionary];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (TVCLogLine *)initWithDictionary:(NSDictionary<NSString *, id> *)dic
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self populateDictionaryValues:dic];

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)populateDictionaryValues:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	ObjectIsAlreadyInitializedAssert

	double receivedAt = [dic doubleForKey:@"receivedAt"];

	if (receivedAt > 0) {
		self->_receivedAt = [NSDate dateWithTimeIntervalSince1970:receivedAt];
	}

	[dic assignArrayTo:&self->_excludeKeywords forKey:@"excludeKeywords"];
	[dic assignArrayTo:&self->_highlightKeywords forKey:@"highlightKeywords"];

	[dic assignBoolTo:&self->_isEncrypted forKey:@"isEncrypted"];
	[dic assignBoolTo:&self->_isHistoric forKey:@"isHistoric"];

	[dic assignStringTo:&self->_command forKey:@"command"];
	[dic assignStringTo:&self->_command forKey:@"rawCommand"]; // Legacy key
	[dic assignStringTo:&self->_messageBody forKey:@"messageBody"];
	[dic assignStringTo:&self->_nickname forKey:@"nickname"];

	[dic assignUnsignedIntegerTo:&self->_lineType forKey:@"lineType"];
	[dic assignUnsignedIntegerTo:&self->_memberType forKey:@"memberType"];

	[self computeNicknameColorStyle];
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNilCopy(self->_command, TVCLogLineDefaultCommandValue)
	SetVariableIfNilCopy(self->_messageBody, NSStringEmptyPlaceholder)
	SetVariableIfNilCopy(self->_receivedAt, [NSDate date])
	SetVariableIfNilCopy(self->_uniqueIdentifier, [TVCLogLine newUniqueIdentifier])

	if (self->_lineType == TVCLogLineActionNoHighlightType) {
		self->_lineType = TVCLogLineActionType;

		self->_highlightKeywords = nil;
	} else if (self->_lineType == TVCLogLinePrivateMessageNoHighlightType) {
		self->_lineType = TVCLogLinePrivateMessageType;

		self->_highlightKeywords = nil;
	}
}

- (NSData *)jsonRepresentation
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.command forKey:@"command"];
	[dic maybeSetObject:self.excludeKeywords forKey:@"excludeKeywords"];
	[dic maybeSetObject:self.highlightKeywords	forKey:@"highlightKeywords"];
	[dic maybeSetObject:self.messageBody forKey:@"messageBody"];
	[dic maybeSetObject:self.nickname forKey:@"nickname"];

	[dic setBool:self.isEncrypted forKey:@"isEncrypted"];
	[dic setBool:self.isHistoric forKey:@"isHistoric"];

	[dic setDouble:self.receivedAt.timeIntervalSince1970 forKey:@"receivedAt"];

	[dic setUnsignedInteger:self.lineType forKey:@"lineType"];
	[dic setUnsignedInteger:self.memberType forKey:@"memberType"];

	NSError *serializeError = nil;

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializeError];

	NSAssert((jsonData != nil),
		serializeError.localizedDescription);

	return jsonData;
}

+ (NSString *)newUniqueIdentifier
{
	NSString *printIdentifier = [NSString stringWithUUID]; // Example: 68753A44-4D6F-1226-9C60-0050E4C00067

	return [printIdentifier substringFromIndex:19]; // Example: 9C60-0050E4C00067
}

+ (nullable NSString *)stringForLineType:(TVCLogLineType)type
{
#define _dv(lineType, returnValue)			case (lineType): { return (returnValue); break; }

	switch (type) {
		_dv(TVCLogLineActionType, @"action")
		_dv(TVCLogLineActionNoHighlightType, @"action")
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
		_dv(TVCLogLinePrivateMessageType, @"privmsg")
		_dv(TVCLogLinePrivateMessageNoHighlightType, @"privmsg")
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

+ (NSString *)stringForMemberType:(TVCLogLineMemberType)type
{
	if (type == TVCLogLineMemberLocalUserType) {
		return @"myself";
	} else {
		return @"normal";
	}
}

- (nullable NSString *)lineTypeString
{
	return [TVCLogLine stringForLineType:self.lineType];
}

- (NSString *)memberTypeString
{
	return [TVCLogLine stringForMemberType:self.memberType];
}

- (NSString *)formattedTimestamp
{
	return [self formattedTimestampWithFormat:nil];
}

- (NSString *)formattedTimestampWithFormat:(nullable NSString *)format
{
	if (NSObjectIsEmpty(format)) {
		format = themeSettings().themeTimestampFormat;
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

- (nullable NSString *)formattedNicknameInChannel:(nullable IRCChannel *)channel
{
	return [self formattedNicknameInChannel:channel withFormat:nil];
}

- (nullable NSString *)formattedNicknameInChannel:(nullable IRCChannel *)channel withFormat:(nullable NSString *)format
{
	if (self.nickname == nil) {
		return nil;
	}

	if (format == nil) {
		if (self.lineType == TVCLogLineActionType) {
			return [NSString stringWithFormat:TVCLogLineActionNicknameFormat, self.nickname];
		} else if (self.lineType == TVCLogLineNoticeType) {
			return [NSString stringWithFormat:TVCLogLineNoticeNicknameFormat, self.nickname];
		}
	}

	return [channel.associatedClient formatNickname:self.nickname inChannel:channel withFormat:format];
}

- (NSString *)renderedBodyForTranscriptLog
{
	return [self renderedBodyForTranscriptLogInChannel:nil];
}

- (NSString *)renderedBodyForTranscriptLogInChannel:(nullable IRCChannel *)channel
{
	NSMutableString *s = [NSMutableString string];

	NSString *timeFormatted = [self formattedTimestampWithFormat:TLOFileLoggerISOStandardClockFormat];

	if (timeFormatted) {
		[s appendString:timeFormatted];
	}

	NSString *nicknameFormatted = nil;

	if (self.lineType == TVCLogLineActionType) {
		nicknameFormatted = [self formattedNicknameInChannel:channel withFormat:TLOFileLoggerActionNicknameFormat];
	} else if (self.lineType == TVCLogLineNoticeType) {
		nicknameFormatted = [self formattedNicknameInChannel:channel withFormat:TLOFileLoggerNoticeNicknameFormat];
	} else {
		nicknameFormatted = [self formattedNicknameInChannel:channel withFormat:TLOFileLoggerUndefinedNicknameFormat];
	}

	if (nicknameFormatted) {
		[s appendString:nicknameFormatted];
		[s appendString:NSStringWhitespacePlaceholder];
	}

	[s appendString:self.messageBody];

	return s.stripIRCEffects;
}

- (void)computeNicknameColorStyle
{
	if (self.nickname != nil &&
		(self.lineType == TVCLogLinePrivateMessageType ||
		 self.lineType == TVCLogLinePrivateMessageNoHighlightType ||
		 self.lineType == TVCLogLineActionType ||
		 self.lineType == TVCLogLineActionNoHighlightType))
	{
		BOOL isOverride = NO;

		self->_nicknameColorStyle =
		[IRCUserNicknameColorStyleGenerator nicknameColorStyleForString:self.nickname isOverride:&isOverride];

		self->_nicknameColorStyleOverride = isOverride;
	} else {
		self->_nicknameColorStyle = nil;
	}
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	  TVCLogLine *object =
	[[TVCLogLine alloc] initWithJSONData:self.jsonRepresentation];

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	  TVCLogLineMutable *object =
	[[TVCLogLineMutable alloc] initWithJSONData:self.jsonRepresentation];

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation TVCLogLineMutable

@dynamic command;
@dynamic excludeKeywords;
@dynamic highlightKeywords;
@dynamic isEncrypted;
@dynamic isHistoric;
@dynamic lineType;
@dynamic memberType;
@dynamic messageBody;
@dynamic nickname;
@dynamic receivedAt;

- (BOOL)isMutable
{
	return YES;
}

- (void)setIsEncrypted:(BOOL)isEncrypted
{
	if (self->_isEncrypted != isEncrypted) {
		self->_isEncrypted = isEncrypted;
	}
}

- (void)setIsHistoric:(BOOL)isHistoric
{
	if (self->_isHistoric != isHistoric) {
		self->_isHistoric = isHistoric;
	}
}

- (void)setExcludeKeywords:(nullable NSArray<NSString *> *)excludeKeywords
{
	if (self->_excludeKeywords != excludeKeywords) {
		self->_excludeKeywords = [excludeKeywords copy];
	}
}

- (void)setHighlightKeywords:(nullable NSArray<NSString *> *)highlightKeywords
{
	if (self->_highlightKeywords != highlightKeywords) {
		self->_highlightKeywords = [highlightKeywords copy];
	}
}

- (void)setReceivedAt:(NSDate *)receivedAt
{
	NSParameterAssert(receivedAt != nil);

	if (self->_receivedAt != receivedAt) {
		self->_receivedAt = [receivedAt copy];
	}
}

- (void)setCommand:(NSString *)command
{
	NSParameterAssert(command != nil);

	if (self->_command != command) {
		self->_command = [command copy];
	}
}

- (void)setMessageBody:(NSString *)messageBody
{
	NSParameterAssert(messageBody != nil);

	if (self->_messageBody != messageBody) {
		self->_messageBody = [messageBody copy];
	}
}

- (void)setNickname:(nullable NSString *)nickname
{
	if (self->_nickname != nickname) {
		self->_nickname = [nickname copy];

		[self computeNicknameColorStyle];
	}
}

- (void)setMemberType:(TVCLogLineMemberType)memberType
{
	if (self->_memberType != memberType) {
		self->_memberType = memberType;
	}
}

- (void)setLineType:(TVCLogLineType)lineType
{
	if (self->_lineType != lineType) {
		self->_lineType = lineType;
	}
}

@end

NS_ASSUME_NONNULL_END
