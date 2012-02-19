// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Growl/Growl.h>

@class IRCWorld;

typedef enum {
	NOTIFICATION_HIGHLIGHT				= 1000,
	NOTIFICATION_NEW_TALK				= 1001,
	NOTIFICATION_CHANNEL_MSG			= 1002,
	NOTIFICATION_CHANNEL_NOTICE		= 1003,
	NOTIFICATION_TALK_MSG				= 1004,
	NOTIFICATION_TALK_NOTICE			= 1005,
	NOTIFICATION_KICKED				= 1006,
	NOTIFICATION_INVITED				= 1007,
	NOTIFICATION_LOGIN					= 1008,
	NOTIFICATION_DISCONNECT			= 1009,
	NOTIFICATION_ADDRESS_BOOK_MATCH	= 1010,
} NotificationType;

@interface GrowlController : NSObject <GrowlApplicationBridgeDelegate,NSUserNotificationCenterDelegate>
{
	IRCWorld		*owner;
	
	id				lastClickedContext;
	CFAbsoluteTime	lastClickedTime;
}

@property (nonatomic, assign) IRCWorld *owner;
@property (nonatomic, retain) id lastClickedContext;
@property (nonatomic, assign) CFAbsoluteTime lastClickedTime;

- (void)notify:(NotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;
@end