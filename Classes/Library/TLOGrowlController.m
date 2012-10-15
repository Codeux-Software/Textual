/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#define _clickInterval		2

@implementation TLOGrowlController

- (id)init
{
	if ((self = [super init])) {
#ifdef TXForceNativeNotificationCenterDispatch
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
	
#ifdef TXForceNativeNotificationCenterDispatch
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

#ifdef TXForceNativeNotificationCenterDispatch

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
