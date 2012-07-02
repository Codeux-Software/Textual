// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TVCLogLine


+ (NSString *)lineTypeString:(TVCLogLineType)type
{
	switch (type) {
		case TVCLogLineSystemType:							return @"system";
		case TVCLogLineErrorType:							return @"error";
		case TVCLogLineReplyType:							return @"reply";
		case TVCLogLineCTCPType:							return @"ctcp";
		case TVCLogLineErrorReplyType:						return @"error_reply";
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
		case TVCLogLineDebugType:							return @"debug_send";
	}
	
	return NSStringEmptyPlaceholder;
}

+ (NSString *)memberTypeString:(TVCLogMemberType)type
{
	switch (type) {
		case TVCLogMemberNormalType:		return @"normal";
		case TVCLogMemberLocalUserType:	return @"myself";
	}
	
	return NSStringEmptyPlaceholder;
}

@end