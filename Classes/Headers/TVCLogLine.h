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

#define TXLogLineUndefinedNicknameFormat	@"<%@%n>"
#define TXLogLineActionNicknameFormat		@"%@ "
#define TXLogLineNoticeNicknameFormat		@"-%@-"
#define TXLogLineCTCPTypeNicknameFormat		@"-%@ CTCP-"

#define TXLogLineSpecialNoticeMessageFormat		@"[%@]: %@"

#define TXLogLineDefaultRawCommandValue			@"-100"

typedef enum TVCLogLineType : NSInteger {
	TVCLogLineUndefinedType					= 0,
	TVCLogLineActionType,
	TVCLogLineActionNoHighlightType,
	TVCLogLineCTCPType,
	TVCLogLineDCCFileTransferType,
	TVCLogLineDebugType,
	TVCLogLineInviteType,
	TVCLogLineJoinType,
	TVCLogLineKickType,
	TVCLogLineKillType,
	TVCLogLineModeType,
	TVCLogLineNickType,
	TVCLogLineNoticeType,
	TVCLogLinePartType,
	TVCLogLinePrivateMessageType,
	TVCLogLinePrivateMessageNoHighlightType,
	TVCLogLineQuitType,
	TVCLogLineTopicType,
	TVCLogLineWebsiteType,
} TVCLogLineType;

typedef enum TVCLogLineMemberType : NSInteger {
	TVCLogLineMemberNormalType,
	TVCLogLineMemberLocalUserType,
} TVCLogLineMemberType;

#define IRCCommandFromLineType(t)		[TVCLogLine lineTypeString:t]

@interface TVCLogLine : NSManagedObject
@property (nonatomic, assign) BOOL isEncrypted;
@property (nonatomic, assign) BOOL isHistoric; /* Identifies a line restored from previous session. */
@property (nonatomic, strong) NSDate *receivedAt;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *messageBody;
@property (nonatomic, strong) NSString *rawCommand; // Can be the actual command (PRIVMSG, NOTICE, etc.) or the raw numeric (001, 002, etc.)
@property (nonatomic, assign) NSNumber *lineTypeInteger;
@property (nonatomic, assign) NSNumber *memberTypeInteger;
@property (nonatomic, assign) NSNumber *nicknameColorNumber;
@property (nonatomic, strong) id highlightKeywords;
@property (nonatomic, strong) id excludeKeywords;

/* These properties are proxies for their NSNumber values. */
@property (nonatomic, uweak) TVCLogLineType lineType;
@property (nonatomic, uweak) TVCLogLineMemberType memberType;

+ (TVCLogLine *)newManagedObjectWithoutContextAssociation;
+ (TVCLogLine *)newManagedObjectForClient:(IRCClient *)client channel:(IRCChannel *)channel;

/* performContextInsertion is automatically called by the TVCLogController 
 print method: the moment before it actaully prints. It is not advised to
 call this as it may create duplicate lines. */
- (void)performContextInsertion;

- (NSString *)formattedTimestamp;
- (NSString *)formattedTimestampWithForcedFormat:(NSString *)format;

- (NSString *)formattedNickname:(IRCChannel *)owner;
- (NSString *)formattedNickname:(IRCChannel *)owner withForcedFormat:(NSString *)format;

- (NSString *)lineTypeString;
- (NSString *)memberTypeString;

- (NSString *)renderedBodyForTranscriptLogInChannel:(IRCChannel *)channel;

+ (NSString *)lineTypeString:(TVCLogLineType)type;
+ (NSString *)memberTypeString:(TVCLogLineMemberType)type;
@end
