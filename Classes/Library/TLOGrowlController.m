/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define _clickInterval			2

@interface TLOGrowlController ()
@property (nonatomic, strong) NSDictionary *lastClickedContext;
@property (nonatomic, assign) NSTimeInterval lastClickedTime;
@end

@implementation TLOGrowlController

- (id)init
{
	if ((self = [super init])) {
		if ([TPCPreferences featureAvailableToOSXMountainLion]) {
			[RZUserNotificationCenter() setDelegate:self];
		}
		
		[GrowlApplicationBridge setGrowlDelegate:self];

		return self;
	}
	
	return self;
}

- (void)notify:(TXNotificationType)eventType title:(NSString *)eventTitle description:(NSString *)eventDescription userInfo:(NSDictionary *)eventContext
{
	NSAssertReturn([TPCPreferences growlEnabledForEvent:eventType]);

	/* titleForEvent: invokes TXTLS for the event type. */
	NSString *eventKind = [TPCPreferences titleForEvent:eventType];
	
	NSInteger eventPriority = 0;
	
	switch (eventType) {
		case TXNotificationHighlightType:
		{
			eventPriority = 1;
			eventTitle = TXTFLS(@"NotificationHighlightMessageTitle", eventTitle);
			
			break;
		}
		case TXNotificationNewPrivateMessageType:
		{
			eventPriority = 1;
			eventTitle = TXTLS(@"NotificationNewPrivateMessageMessageTitle");
			
			break;
		}
		case TXNotificationChannelMessageType:
		{
			eventTitle = TXTFLS(@"NotificationChannelMessageMessageTitle", eventTitle);
			
			break;
		}
		case TXNotificationChannelNoticeType:
		{
			eventTitle = TXTFLS(@"NotificationChannelNoticeMessageTitle", eventTitle);
			
			break;
		}
		case TXNotificationPrivateMessageType:
		{
			eventTitle = TXTLS(@"NotificationPrivateMessageMessageTitle");
			
			break;
		}
		case TXNotificationPrivateNoticeType:
		{
			eventTitle = TXTLS(@"NotificationPrivateNoticeMessageTitle");
			
			break;
		}
		case TXNotificationKickType:
		{
			eventTitle = TXTFLS(@"NotificationKickedMessageTitle", eventTitle);
			
			break;
		}
		case TXNotificationInviteType:
		{
			eventTitle = TXTFLS(@"NotificationInvitedMessageTitle", eventTitle);
			
			break;
		}
		case TXNotificationConnectType:
		{
			eventTitle = TXTFLS(@"NotificationConnectedMessageTitle", eventTitle);
			eventDescription = TXTLS(@"NotificationConnectedMessageDescription");
			
			break;
		}
		case TXNotificationDisconnectType:
		{
			eventTitle = TXTFLS(@"NotificationDisconnectMessageTitle", eventTitle);
			eventDescription = TXTLS(@"NotificationDisconnectMessageDescription");
			
			break;
		}
		case TXNotificationAddressBookMatchType: 
		{
			eventTitle = TXTLS(@"NotificationAddressBookMatchMessageTitle");
			
			break;
		}
	}

	eventDescription = [eventDescription stripIRCEffects];

	/* Send to notification center? */
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		if ([GrowlApplicationBridge isGrowlRunning] == NO) {
			NSUserNotification *notification = [NSUserNotification new];
			
			notification.title = eventTitle;
			notification.informativeText = eventDescription;
			notification.deliveryDate = [NSDate date];
			notification.userInfo = eventContext;

#ifdef TXSystemIsMacOSMavericksOrNewer
			if ([TPCPreferences featureAvailableToOSXMavericks]) {
				/* These are the only event types we want to support for now. */

				if (eventType == TXNotificationNewPrivateMessageType ||
					eventType == TXNotificationPrivateMessageType)
				{
					notification.hasReplyButton = YES;
					notification.responsePlaceholder = TXTFLS(@"NotificationDialogPrivateMessageReplyPlaceholder");
				}
			}
#endif 

			[RZUserNotificationCenter() scheduleNotification:notification];

			return; // Do not continue to Growl…
		}
	}

	/* Nope, let Growl handle. */
	[GrowlApplicationBridge notifyWithTitle:eventTitle
								description:eventDescription
						   notificationName:eventKind
								   iconData:nil
								   priority:(int)eventPriority
								   isSticky:NO
							   clickContext:eventContext];
}

/* NSUserNotificationCenter */

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
	   didActivateNotification:(NSUserNotification *)notification
{
	[RZUserNotificationCenter() removeDeliveredNotification:notification];

#ifdef TXSystemIsMacOSMavericksOrNewer
	if ([TPCPreferences featureAvailableToOSXMavericks]) {
		if (notification.activationType == NSUserNotificationActivationTypeReplied) {
			NSString *replyMessage = notification.response.string; // It is attributed string, we only want string.

			[self growlNotificationWasClicked:[notification userInfo] withReplyMessage:replyMessage changeFocus:NO];

			return; // Do not continue this method.
		}
	}
#endif

	[self growlNotificationWasClicked:[notification userInfo]];
}

/* Growl delegate */

- (NSString *)applicationNameForGrowl
{
	return [TPCPreferences applicationName];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[
		TXTLS(@"TXNotificationAddressBookMatchType"),
		TXTLS(@"TXNotificationChannelMessageType"),
		TXTLS(@"TXNotificationChannelNoticeType"),
		TXTLS(@"TXNotificationConnectType"),
		TXTLS(@"TXNotificationDisconnectType"),
		TXTLS(@"TXNotificationHighlightType"),
		TXTLS(@"TXNotificationInviteType"),
		TXTLS(@"TXNotificationKickType"),
		TXTLS(@"TXNotificationNewPrivateMessageType"),
		TXTLS(@"TXNotificationPrivateMessageType"),
		TXTLS(@"TXNotificationPrivateNoticeType")
	];
	
	return @{
		GROWL_NOTIFICATIONS_ALL : allNotifications,
		GROWL_NOTIFICATIONS_DEFAULT : allNotifications
	};
}

- (void)growlNotificationWasClicked:(NSDictionary *)context
{
	[self growlNotificationWasClicked:context withReplyMessage:nil changeFocus:YES];
}

- (void)growlNotificationWasClicked:(NSDictionary *)context withReplyMessage:(NSString *)message changeFocus:(BOOL)changeFocus
{
	NSTimeInterval now = [NSDate epochTime];
	
	if ((now - self.lastClickedTime) < _clickInterval) {
		if (self.lastClickedContext && [self.lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	self.lastClickedTime = now;
	self.lastClickedContext = context;

	if (changeFocus) {
		[self.masterController.mainWindow makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}

	if ([context isKindOfClass:[NSDictionary class]]) {
		NSString *uid = [context objectForKey:@"client"];
		NSString *cid = [context objectForKey:@"channel"];
		
		IRCClient *u = nil;
		IRCChannel *c = nil;

		NSObjectIsEmptyAssert(uid);
		
		if (cid) {
			c = [self.worldController findChannelByClientId:uid channelId:cid];
		} else {
			u = [self.worldController findClientById:uid];
		}

		if (changeFocus) {
			if (c) {
				[self.worldController select:c];
			} else if (u) {
				[self.worldController select:u];
			}
		}

		NSObjectIsEmptyAssert(message);

		if (c) { // We want both a client and channel.
			/* A user may want to do an action… #yolo */
			if ([message hasPrefix:@"/"] && [message hasPrefix:@"//"] == NO && message.length > 1) {
				message = [message safeSubstringFromIndex:1];

				[c.client sendCommand:message
					   completeTarget:YES
							   target:c.name];
			} else {
				[c.client sendText:[NSAttributedString emptyStringWithBase:message]
						   command:IRCPrivateCommandIndex("privmsg")
						   channel:c];
			}
		}
	}
}

- (BOOL)hasNetworkClientEntitlement 
{
    return YES;
}

@end
