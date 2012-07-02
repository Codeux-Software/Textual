// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXLogLineUndefinedNicknameFormat	@"<%@%n>"
#define TXLogLineActionNicknameFormat		@"%@ "
#define TXLogLineNoticeNicknameFormat		@"-%@-"
#define TXLogLineCTCPTypeNicknameFormat		@"-%@ CTCP-"

typedef enum TVCLogLineType : NSInteger {
	TVCLogLineSystemType,
	TVCLogLineErrorType,
	TVCLogLineErrorReplyType,
	TVCLogLineCTCPType,
	TVCLogLineReplyType,
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
} TVCLogLineType;

typedef enum TVCLogMemberType : NSInteger {
	TVCLogMemberNormalType,
	TVCLogMemberLocalUserType,
} TVCLogMemberType;

#define IRCCommandFromLineType(t)		[TVCLogLine lineTypeString:t]

@interface TVCLogLine : NSObject
@property (nonatomic, strong) NSDate *receivedAt;
@property (nonatomic, strong) NSString *time;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, assign) TVCLogLineType lineType;
@property (nonatomic, assign) TVCLogMemberType memberType;
@property (nonatomic, strong) NSString *nickInfo;
@property (nonatomic, assign) BOOL identified;
@property (nonatomic, assign) NSInteger nickColorNumber;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSArray *excludeWords;

+ (NSString *)lineTypeString:(TVCLogLineType)type;
+ (NSString *)memberTypeString:(TVCLogMemberType)type;
@end