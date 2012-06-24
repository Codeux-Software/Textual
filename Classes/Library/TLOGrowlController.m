// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#define _clickInterval		2

@implementation TLOGrowlController


- (id)init
{
	if ((self = [super init])) {
#ifdef TXNativeNotificationCenterAvailable
		if ([TPCPreferences featureAvailableToOSXMountainLion]) {
			[_NSUserNotificationCenter() setDelegate:self];
			
			return self;
		}
#endif
		
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	
	return self;
}


- (void)notify:(TXNotificationType)type title:(NSString *)title
		  desc:(NSString *)desc userInfo:(NSDictionary *)info
{
	if ([TPCPreferences growlEnabledForEvent:type] == NO) return;
	
	NSString *kind = nil;
	
	NSInteger priority = 0;
	
	BOOL sticky = [TPCPreferences growlStickyForEvent:type];
	
	switch (type) {
		case TXNotificationHighlightType:
		{
			priority = 1;
			kind =  TXTLS(@"NotificationHighlightMessage");
			title = TXTFLS(@"NotificationHighlightMessageTitle", title);
			break;
		}
		case TXNotificationNewQueryType:
		{
			priority = 1;
			kind =  TXTLS(@"NotificationNewPrivateQueryMessage");
			title = TXTLS(@"NotificationNewPrivateQueryMessageTitle");
			break;
		}
		case TXNotificationChannelMessageType:
		{
			kind = TXTLS(@"NotificationChannelTalkMessage");
			break;
		}
		case TXNotificationChannelNoticeType:
		{
			kind =  TXTLS(@"NotificationChannelNoticeMessage");
			title = TXTFLS(@"NotificationChannelNoticeMessageTitle", title);
			break;
		}
		case TXNotificationQueryMessageType:
		{
			kind =  TXTLS(@"NotificationPrivateQueryMessage");
			title = TXTLS(@"NotificationPrivateQueryMessageTitle");
			break;
		}
		case TXNotificationQueryNoticeType:
		{
			kind =  TXTLS(@"NotificationPrivateNoticeMessage");
			title = TXTLS(@"NotificationPrivateNoticeMessageTitle");
			break;
		}
		case TXNotificationKickType:
		{
			kind =  TXTLS(@"NotificationKickedMessage");
			title = TXTFLS(@"NotificationKickedMessageTitle", title);
			break;
		}
		case TXNotificationInviteType:
		{
			kind =  TXTLS(@"NotificationInvitedMessage");
			title = TXTFLS(@"NotificationInvitedMessageTitle", title);
			break;
		}
		case TXNotificationConnectType:
		{
			kind =  TXTLS(@"NotificationConnectedMessage");
			title = TXTFLS(@"NotificationConnectedMessageTitle", title);
			break;
		}
		case TXNotificationDisconnectType:
		{
			kind =  TXTLS(@"NotificationDisconnectMessage");
			title = TXTFLS(@"NotificationDisconnectMessageTitle", title);
			break;
		}
		case TXNotificationAddressBookMatchType: 
		{
			kind = TXTLS(@"TXNotificationAddressBookMatchType");
			title = TXTLS(@"NotificationAddressBookMatchMessageTitle");
			break;
		}
	}
	
#ifdef TXNativeNotificationCenterAvailable
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		NSUserNotification *notification = [NSUserNotification new];
		
		notification.title = title;
		notification.informativeText = desc;
		notification.deliveryDate = [NSDate date];
		notification.userInfo = info;
		
		[_NSUserNotificationCenter() scheduleNotification:notification];
		
		return;
	}
#endif
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:desc
						   notificationName:kind
								   iconData:nil
								   priority:(int)priority
								   isSticky:sticky
							   clickContext:info];
}

/* NSUserNotificationCenter */

#ifdef TXNativeNotificationCenterAvailable

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
	   didActivateNotification:(NSUserNotification *)notification
{
	[_NSUserNotificationCenter() removeDeliveredNotification:notification];
	
	[self growlNotificationWasClicked:[notification userInfo]];
}

#endif

/* Growl delegate */

- (NSString *)applicationNameForGrowl
{
	return [TPCPreferences applicationName];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[TXTLS(@"NotificationHighlightMessage"), TXTLS(@"NotificationNewPrivateQueryMessage"),
									TXTLS(@"NotificationChannelTalkMessage"), TXTLS(@"NotificationChannelNoticeMessage"),
									TXTLS(@"NotificationPrivateQueryMessage"), TXTLS(@"NotificationPrivateNoticeMessage"),
									TXTLS(@"NotificationKickedMessage"), TXTLS(@"NotificationInvitedMessage"),
									TXTLS(@"NotificationConnectedMessage"), TXTLS(@"NotificationDisconnectMessage"),
									TXTLS(@"TXNotificationAddressBookMatchType")];
	
	return @{GROWL_NOTIFICATIONS_ALL: allNotifications, GROWL_NOTIFICATIONS_DEFAULT: allNotifications};
}

- (void)growlNotificationWasClicked:(NSDictionary *)context 
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if ((now - self.lastClickedTime) < _clickInterval) {
		if (self.lastClickedContext && [self.lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	self.lastClickedTime = now;
	self.lastClickedContext = context;

	[self.owner.window makeKeyAndOrderFront:nil];

	[NSApp activateIgnoringOtherApps:YES];

	if ([context isKindOfClass:[NSDictionary class]]) {
		NSNumber *uid = context[@"client"];
		
		IRCClient  *u = [self.owner findClientById:[uid integerValue]];
		IRCChannel *c = nil;
		
		if (context[@"channel"]) {
			NSNumber *cid = context[@"channel"];
			
			c = [self.owner findChannelByClientId:[uid integerValue] channelId:[cid integerValue]];
		}
		
		if (c) {
			[self.owner select:c];
		} else if (u) {
			[self.owner select:u];
		}
	}
}

- (BOOL)hasNetworkClientEntitlement 
{
    return YES;
}

@end
