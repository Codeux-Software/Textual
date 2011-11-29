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
        [GrowlApplicationBridge setGrowlDelegate:self];
	}
	
	return self;
}

- (void)dealloc
{
	[lastClickedContext drain];
	
	[super dealloc];
}

- (NSString *) applicationNameForGrowl {
	return @"Textual";
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
										TXTLS(@"GROWL_MSG_NEW_TALK"), TXTLS(@"GROWL_MSG_TALK_MSG"),
										TXTLS(@"GROWL_MSG_HIGHLIGHT"), TXTLS(@"GROWL_MSG_INVITED"),
										TXTLS(@"GROWL_MSG_KICKED"), nil];
	NSArray *allNotifications = [NSArray arrayWithObjects:
									TXTLS(@"GROWL_MSG_HIGHLIGHT"), TXTLS(@"GROWL_MSG_NEW_TALK"),
									TXTLS(@"GROWL_MSG_CHANNEL_MSG"), TXTLS(@"GROWL_MSG_CHANNEL_NOTICE"),
									TXTLS(@"GROWL_MSG_TALK_MSG"), TXTLS(@"GROWL_MSG_TALK_NOTICE"),
									TXTLS(@"GROWL_MSG_KICKED"), TXTLS(@"GROWL_MSG_INVITED"),
									TXTLS(@"GROWL_MSG_LOGIN"), TXTLS(@"GROWL_MSG_DISCONNECT"),
									TXTLS(@"GROWL_ADDRESS_BOOK_MATCH"), nil];
	return [NSDictionary dictionaryWithObjectsAndKeys: allNotifications, GROWL_NOTIFICATIONS_ALL, defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
}

- (void)notify:(GrowlNotificationType)type title:(NSString *)title desc:(NSString *)desc context:(id)context
{
	if ([Preferences growlEnabledForEvent:type] == NO) return;
	
	NSString *kind = nil;
	NSInteger priority = 0;
	
	BOOL sticky = [Preferences growlStickyForEvent:type];
	
	switch (type) {
		case GROWL_HIGHLIGHT:
		{
			priority = 1;
			kind =  TXTLS(@"GROWL_MSG_HIGHLIGHT");
			title = TXTFLS(@"GROWL_MSG_HIGHLIGHT_TITLE", title);
			break;
		}
		case GROWL_NEW_TALK:
		{
			priority = 1;
			kind =  TXTLS(@"GROWL_MSG_NEW_TALK");
			title = TXTLS(@"GROWL_MSG_NEW_TALK_TITLE");
			break;
		}
		case GROWL_CHANNEL_MSG:
		{
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_MSG");
			break;
		}
		case GROWL_CHANNEL_NOTICE:
		{
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_NOTICE");
			title = TXTFLS(@"GROWL_MSG_CHANNEL_NOTICE_TITLE", title);
			break;
		}
		case GROWL_TALK_MSG:
		{
			kind =  TXTLS(@"GROWL_MSG_TALK_MSG");
			title = TXTLS(@"GROWL_MSG_TALK_MSG_TITLE");
			break;
		}
		case GROWL_TALK_NOTICE:
		{
			kind =  TXTLS(@"GROWL_MSG_TALK_NOTICE");
			title = TXTLS(@"GROWL_MSG_TALK_NOTICE_TITLE");
			break;
		}
		case GROWL_KICKED:
		{
			kind =  TXTLS(@"GROWL_MSG_KICKED");
			title = TXTFLS(@"GROWL_MSG_KICKED_TITLE", title);
			break;
		}
		case GROWL_INVITED:
		{
			kind =  TXTLS(@"GROWL_MSG_INVITED");
			title = TXTFLS(@"GROWL_MSG_INVITED_TITLE", title);
			break;
		}
		case GROWL_LOGIN:
		{
			kind =  TXTLS(@"GROWL_MSG_LOGIN");
			title = TXTFLS(@"GROWL_MSG_LOGIN_TITLE", title);
			break;
		}
		case GROWL_DISCONNECT:
		{
			kind =  TXTLS(@"GROWL_MSG_DISCONNECT");
			title = TXTFLS(@"GROWL_MSG_DISCONNECT_TITLE", title);
			break;
		}
		case GROWL_ADDRESS_BOOK_MATCH: 
		{
			kind = TXTLS(@"GROWL_ADDRESS_BOOK_MATCH");
			title = TXTLS(@"GROWL_MSG_ADDRESS_BOOK_MATCH_TITLE");
			break;
		}
	}
	
	[GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:kind iconData:nil priority:priority isSticky:sticky clickContext:context];
}

- (void)growlNotificationWasClicked:(id)context {
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

	if ([context isKindOfClass:[NSString class]]) {
		NSArray *ary = [context componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

		if (ary.count >= 2) {
			NSInteger uid = [ary integerAtIndex:0];
			NSInteger cid = [ary integerAtIndex:1];
			
			IRCClient  *u = [owner findClientById:uid];
			IRCChannel *c = [owner findChannelByClientId:uid channelId:cid];
			
			if (c) {
				[owner select:c];
			} else if (u) {
				[owner select:u];
			}
		} else if (ary.count == 1) {
			NSInteger uid = [ary integerAtIndex:0];
			
			IRCClient *u = [owner findClientById:uid];
			
			if (u) {
				[owner select:u];
			}
		}
	}
}

@end