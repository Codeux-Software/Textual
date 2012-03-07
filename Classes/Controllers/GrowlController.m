// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define CLICK_INTERVAL	2

@implementation GrowlController

@synthesize owner;
@synthesize lastClickedContext;
@synthesize lastClickedTime;

- (id)init
{
	if ((self = [super init])) {
#ifdef _USES_NATIVE_NOTIFICATION_CENTER
		if ([Preferences featureAvailableToOSXMountainLion]) {
			[_NSUserNotificationCenter() setDelegate:self];
			
			return self;
		}
#endif
		
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	
	return self;
}

- (void)dealloc
{
	[lastClickedContext drain];
	
	[super dealloc];
}

- (void)notify:(NotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info
{
	if ([Preferences growlEnabledForEvent:type] == NO) return;
	
	NSString *kind = nil;
	
	NSInteger priority = 0;
	
	BOOL sticky = [Preferences growlStickyForEvent:type];
	
	switch (type) {
		case NOTIFICATION_HIGHLIGHT:
		{
			priority = 1;
			kind =  TXTLS(@"NOTIFICATION_MSG_HIGHLIGHT");
			title = TXTFLS(@"NOTIFICATION_MSG_HIGHLIGHT_TITLE", title);
			break;
		}
		case NOTIFICATION_NEW_TALK:
		{
			priority = 1;
			kind =  TXTLS(@"NOTIFICATION_MSG_NEW_TALK");
			title = TXTLS(@"NOTIFICATION_MSG_NEW_TALK_TITLE");
			break;
		}
		case NOTIFICATION_CHANNEL_MSG:
		{
			kind = TXTLS(@"NOTIFICATION_MSG_CHANNEL_MSG");
			break;
		}
		case NOTIFICATION_CHANNEL_NOTICE:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_CHANNEL_NOTICE");
			title = TXTFLS(@"NOTIFICATION_MSG_CHANNEL_NOTICE_TITLE", title);
			break;
		}
		case NOTIFICATION_TALK_MSG:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_TALK_MSG");
			title = TXTLS(@"NOTIFICATION_MSG_TALK_MSG_TITLE");
			break;
		}
		case NOTIFICATION_TALK_NOTICE:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_TALK_NOTICE");
			title = TXTLS(@"NOTIFICATION_MSG_TALK_NOTICE_TITLE");
			break;
		}
		case NOTIFICATION_KICKED:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_KICKED");
			title = TXTFLS(@"NOTIFICATION_MSG_KICKED_TITLE", title);
			break;
		}
		case NOTIFICATION_INVITED:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_INVITED");
			title = TXTFLS(@"NOTIFICATION_MSG_INVITED_TITLE", title);
			break;
		}
		case NOTIFICATION_LOGIN:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_LOGIN");
			title = TXTFLS(@"NOTIFICATION_MSG_LOGIN_TITLE", title);
			break;
		}
		case NOTIFICATION_DISCONNECT:
		{
			kind =  TXTLS(@"NOTIFICATION_MSG_DISCONNECT");
			title = TXTFLS(@"NOTIFICATION_MSG_DISCONNECT_TITLE", title);
			break;
		}
		case NOTIFICATION_ADDRESS_BOOK_MATCH: 
		{
			kind = TXTLS(@"NOTIFICATION_ADDRESS_BOOK_MATCH");
			title = TXTLS(@"NOTIFICATION_MSG_ADDRESS_BOOK_MATCH_TITLE");
			break;
		}
	}
	
#ifdef _USES_NATIVE_NOTIFICATION_CENTER
	if ([Preferences featureAvailableToOSXMountainLion]) {
		NSUserNotification *notification = [NSUserNotification newad];
		
		notification.title = title;
		notification.informativeText = desc;
		notification.deliveryDate = [NSDate date];
		notification.userInfo = info;
		
		[_NSUserNotificationCenter() scheduleNotification:notification];
		return;
	}
#endif
	
	[GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:kind iconData:nil priority:priority isSticky:sticky clickContext:info];
}

/* NSUserNotificationCenter */

#ifdef _USES_NATIVE_NOTIFICATION_CENTER

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
	[_NSUserNotificationCenter() removeDeliveredNotification:notification];
	
	[self growlNotificationWasClicked:[notification userInfo]];
}

#endif

/* Growl delegate */

- (NSString *)applicationNameForGrowl
{
	return [Preferences applicationName];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = [NSArray arrayWithObjects:
									TXTLS(@"NOTIFICATION_MSG_HIGHLIGHT"), TXTLS(@"NOTIFICATION_MSG_NEW_TALK"),
									TXTLS(@"NOTIFICATION_MSG_CHANNEL_MSG"), TXTLS(@"NOTIFICATION_MSG_CHANNEL_NOTICE"),
									TXTLS(@"NOTIFICATION_MSG_TALK_MSG"), TXTLS(@"NOTIFICATION_MSG_TALK_NOTICE"),
									TXTLS(@"NOTIFICATION_MSG_KICKED"), TXTLS(@"NOTIFICATION_MSG_INVITED"),
									TXTLS(@"NOTIFICATION_MSG_LOGIN"), TXTLS(@"NOTIFICATION_MSG_DISCONNECT"),
									TXTLS(@"NOTIFICATION_ADDRESS_BOOK_MATCH"), nil];
	
	return [NSDictionary dictionaryWithObjectsAndKeys: allNotifications, GROWL_NOTIFICATIONS_ALL, allNotifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
}

- (void)growlNotificationWasClicked:(NSDictionary *)context 
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if ((now - lastClickedTime) < CLICK_INTERVAL) {
		if (lastClickedContext && [lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	lastClickedTime = now;
	
	[lastClickedContext drain];
	lastClickedContext = [context retain];

	[owner.window makeKeyAndOrderFront:nil];

	[NSApp activateIgnoringOtherApps:YES];

	if ([context isKindOfClass:[NSDictionary class]]) {
		NSNumber *uid = [context objectForKey:@"client"];
		
		IRCClient  *u = [owner findClientById:[uid integerValue]];
		IRCChannel *c = nil;
		
		if ([context objectForKey:@"channel"]) {
			NSNumber *cid = [context objectForKey:@"channel"];
			
			c = [owner findChannelByClientId:[uid integerValue] channelId:[cid integerValue]];
		}
		
		if (c) {
			[owner select:c];
		} else if (u) {
			[owner select:u];
		}
	}
}

- (BOOL)hasNetworkClientEntitlement 
{
    return YES;
}

@end
