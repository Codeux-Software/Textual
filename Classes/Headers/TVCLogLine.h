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

#define TXLogLineUndefinedNicknameFormat	@"<%@%n>"
#define TXLogLineActionNicknameFormat		@"%@ "
#define TXLogLineNoticeNicknameFormat		@"-%@-"
#define TXLogLineCTCPTypeNicknameFormat		@"-%@ CTCP-"

#define TXLogLineSpecialNoticeMessageFormat		@"[%@]: %@"

typedef enum TVCLogLineType : NSInteger {
	TVCLogLineCTCPType,
	TVCLogLinePrivateMessageType,
	TVCLogLinePrivateMessageNoHighlightType,
	TVCLogLineNoticeType,
	TVCLogLineActionType,
	TVCLogLineActionNoHighlightType,
	TVCLogLineJoinType,
	TVCLogLinePartType,
	TVCLogLineKickType,
	TVCLogLineQuitType,
	TVCLogLineKillType,
	TVCLogLineNickType,
	TVCLogLineModeType,
	TVCLogLineTopicType,
	TVCLogLineInviteType,
	TVCLogLineWebsiteType,
	TVCLogLineDebugType,
	TVCLogLineRawHTMLType,
} TVCLogLineType;

typedef enum TVCLogMemberType : NSInteger {
	TVCLogMemberNormalType,
	TVCLogMemberLocalUserType,
} TVCLogMemberType;

#define IRCCommandFromLineType(t)		[TVCLogLine lineTypeString:t]

@interface TVCLogLine : NSObject
@property (nonatomic, strong) NSDate *receivedAt;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, assign) TVCLogLineType lineType;
@property (nonatomic, assign) TVCLogMemberType memberType;
@property (nonatomic, assign) NSInteger nickColorNumber;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSArray *excludeWords;
@property (nonatomic, assign) BOOL isHistoric;

- (NSString *)formattedTimestamp;
- (NSString *)formattedNickname:(IRCChannel *)owner;

+ (NSString *)lineTypeString:(TVCLogLineType)type;
+ (NSString *)memberTypeString:(TVCLogMemberType)type;

- (id)initWithLineType:(TVCLogLineType)lineType
			memberType:(TVCLogMemberType)memberType
			receivedAt:(NSDate *)receivedAt
				  body:(NSString *)body; // For internal use only. A plugin should not call.

- (id)initWithDictionary:(NSDictionary *)dic;	// For internal use only. A plugin should not call.
- (NSDictionary *)dictionaryValue;				// For internal use only. A plugin should not call.
@end