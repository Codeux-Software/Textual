// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation LogLine

@synthesize time;
@synthesize nick;
@synthesize body;
@synthesize lineType;
@synthesize keywords;
@synthesize nickInfo;
@synthesize identified;
@synthesize memberType;
@synthesize excludeWords;
@synthesize nickColorNumber;

- (void)dealloc
{
	[time drain];
	[nick drain];
	[body drain];
	[keywords drain];
	[nickInfo drain];
	[excludeWords drain];
	
	[super dealloc];
}

+ (NSString *)lineTypeString:(LogLineType)type
{
	switch (type) {
		case LINE_TYPE_SYSTEM: return @"system";
		case LINE_TYPE_ERROR: return @"error";
		case LINE_TYPE_REPLY: return @"reply";
		case LINE_TYPE_CTCP: return @"ctcp";
		case LINE_TYPE_ERROR_REPLY: return @"error_reply";
		case LINE_TYPE_PRIVMSG: return @"privmsg";
		case LINE_TYPE_PRIVMSG_NH: return @"privmsg";
		case LINE_TYPE_NOTICE: return @"notice";
		case LINE_TYPE_ACTION: return @"action";
		case LINE_TYPE_ACTION_NH: return @"action";
		case LINE_TYPE_JOIN: return @"join";
		case LINE_TYPE_PART: return @"part";
		case LINE_TYPE_KICK: return @"kick";
		case LINE_TYPE_QUIT: return @"quit";
		case LINE_TYPE_KILL: return @"kill";
		case LINE_TYPE_NICK: return @"nick";
		case LINE_TYPE_MODE: return @"mode";
		case LINE_TYPE_TOPIC: return @"topic";
		case LINE_TYPE_INVITE: return @"invite";
		case LINE_TYPE_WEBSITE: return @"website";
		case LINE_TYPE_DEBUG: return @"debug_send";
	}
	
	return NSNullObject;
}

+ (NSString *)memberTypeString:(LogMemberType)type
{
	switch (type) {
		case MEMBER_TYPE_NORMAL: return @"normal";
		case MEMBER_TYPE_MYSELF: return @"myself";
	}
	
	return NSNullObject;
}

@end