// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

#import <Growl/Growl.h>

@class IRCWorld;

typedef enum {
	NOTIFICATION_HIGHLIGHT				= 1000,
	NOTIFICATION_NEW_TALK				= 1001,
	NOTIFICATION_CHANNEL_MSG			= 1002,
	NOTIFICATION_CHANNEL_NOTICE			= 1003,
	NOTIFICATION_TALK_MSG				= 1004,
	NOTIFICATION_TALK_NOTICE			= 1005,
	NOTIFICATION_KICKED					= 1006,
	NOTIFICATION_INVITED				= 1007,
	NOTIFICATION_LOGIN					= 1008,
	NOTIFICATION_DISCONNECT				= 1009,
	NOTIFICATION_ADDRESS_BOOK_MATCH		= 1010,
} NotificationType;

#ifdef _USES_NATIVE_NOTIFICATION_CENTER
	#define GrowlControllerDelegate GrowlApplicationBridgeDelegate,NSUserNotificationCenterDelegate
#else
	#define GrowlControllerDelegate GrowlApplicationBridgeDelegate
#endif

@interface GrowlController : NSObject <GrowlControllerDelegate>
@property (nonatomic, weak) IRCWorld *owner;
@property (nonatomic, strong) id lastClickedContext;
@property (nonatomic, assign) CFAbsoluteTime lastClickedTime;

- (void)notify:(NotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;
@end