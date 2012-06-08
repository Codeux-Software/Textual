// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

typedef enum {
	LINE_TYPE_SYSTEM,
	LINE_TYPE_ERROR,
	LINE_TYPE_CTCP,
	LINE_TYPE_REPLY,
	LINE_TYPE_ERROR_REPLY,
	LINE_TYPE_PRIVMSG,
	LINE_TYPE_PRIVMSG_NH,
	LINE_TYPE_NOTICE,
	LINE_TYPE_ACTION,
	LINE_TYPE_ACTION_NH,
	LINE_TYPE_JOIN,
	LINE_TYPE_PART,
	LINE_TYPE_KICK,
	LINE_TYPE_QUIT,
	LINE_TYPE_KILL,
	LINE_TYPE_NICK,
	LINE_TYPE_MODE,
	LINE_TYPE_TOPIC,
	LINE_TYPE_INVITE,
	LINE_TYPE_WEBSITE,
	LINE_TYPE_DEBUG,
} LogLineType;

typedef enum {
	MEMBER_TYPE_NORMAL,
	MEMBER_TYPE_MYSELF,
} LogMemberType;

#define IRCCommandFromLineType(t)	[LogLine lineTypeString:t]

@interface LogLine : NSObject
@property (strong) NSDate *receivedAt;
@property (strong) NSString *time;
@property (strong) NSString *nick;
@property (strong) NSString *body;
@property (assign) LogLineType lineType;
@property (assign) LogMemberType memberType;
@property (strong) NSString *nickInfo;
@property (assign) BOOL identified;
@property (assign) NSInteger nickColorNumber;
@property (strong) NSArray *keywords;
@property (strong) NSArray *excludeWords;

+ (NSString *)lineTypeString:(LogLineType)type;
+ (NSString *)memberTypeString:(LogMemberType)type;
@end