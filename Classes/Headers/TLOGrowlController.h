// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#import <Growl/Growl.h>

typedef enum TXNotificationType : NSInteger {
	TXNotificationHighlightType				= 1000,
	TXNotificationNewQueryType				= 1001,
	TXNotificationChannelMessageType		= 1002,
	TXNotificationChannelNoticeType			= 1003,
	TXNotificationQueryMessageType			= 1004,
	TXNotificationQueryNoticeType			= 1005,
	TXNotificationKickType					= 1006,
	TXNotificationInviteType				= 1007,
	TXNotificationConnectType				= 1008,
	TXNotificationDisconnectType			= 1009,
	TXNotificationAddressBookMatchType		= 1010,
} TXNotificationType;

#ifdef TXNativeNotificationCenterAvailable
	#define GrowlControllerDelegate GrowlApplicationBridgeDelegate,NSUserNotificationCenterDelegate
#else
	#define GrowlControllerDelegate GrowlApplicationBridgeDelegate
#endif

@interface TLOGrowlController : NSObject <GrowlControllerDelegate>
@property (nonatomic, weak) IRCWorld *owner;
@property (nonatomic, strong) id lastClickedContext;
@property (nonatomic, assign) CFAbsoluteTime lastClickedTime;

- (void)notify:(TXNotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;
@end