// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "Growl/Growl.h"

@class IRCWorld;

typedef enum {
	GROWL_HIGHLIGHT				= 1000,
	GROWL_NEW_TALK				= 1001,
	GROWL_CHANNEL_MSG			= 1002,
	GROWL_CHANNEL_NOTICE		= 1003,
	GROWL_TALK_MSG				= 1004,
	GROWL_TALK_NOTICE			= 1005,
	GROWL_KICKED				= 1006,
	GROWL_INVITED				= 1007,
	GROWL_LOGIN					= 1008,
	GROWL_DISCONNECT			= 1009,
	GROWL_ADDRESS_BOOK_MATCH	= 1010,
} GrowlNotificationType;

@interface GrowlController : NSObject <GrowlApplicationBridgeDelegate>
{
	IRCWorld		*owner;
	
	id				lastClickedContext;
	CFAbsoluteTime	lastClickedTime;
}

@property (nonatomic, assign) IRCWorld *owner;
@property (nonatomic, retain) id lastClickedContext;
@property (nonatomic, assign) CFAbsoluteTime lastClickedTime;

- (void)notify:(GrowlNotificationType)type title:(NSString *)title desc:(NSString *)desc context:(id)context;
@end