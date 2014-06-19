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
		if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
			[RZUserNotificationCenter() setDelegate:self];
		}
		
		[GrowlApplicationBridge setGrowlDelegate:self];

		return self;
	}
	
	return self;
}

- (NSString *)titleForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationAddressBookMatchType:				{ return TXTLS(@"BasicLanguage[1086]");		}
		case TXNotificationChannelMessageType:					{ return TXTLS(@"BasicLanguage[1087]");		}
		case TXNotificationChannelNoticeType:					{ return TXTLS(@"BasicLanguage[1088]");		}
		case TXNotificationConnectType:							{ return TXTLS(@"BasicLanguage[1089]");		}
		case TXNotificationDisconnectType:						{ return TXTLS(@"BasicLanguage[1090]");		}
		case TXNotificationInviteType:							{ return TXTLS(@"BasicLanguage[1092]");		}
		case TXNotificationKickType:							{ return TXTLS(@"BasicLanguage[1093]");		}
		case TXNotificationNewPrivateMessageType:				{ return TXTLS(@"BasicLanguage[1094]");		}
		case TXNotificationPrivateMessageType:					{ return TXTLS(@"BasicLanguage[1095]");		}
		case TXNotificationPrivateNoticeType:					{ return TXTLS(@"BasicLanguage[1096]");		}
		case TXNotificationHighlightType:						{ return TXTLS(@"BasicLanguage[1091]");		}
			
		case TXNotificationFileTransferSendSuccessfulType:		{ return TXTLS(@"BasicLanguage[1097]");		}
		case TXNotificationFileTransferReceiveSuccessfulType:	{ return TXTLS(@"BasicLanguage[1098]");		}
		case TXNotificationFileTransferSendFailedType:			{ return TXTLS(@"BasicLanguage[1099]");		}
		case TXNotificationFileTransferReceiveFailedType:		{ return TXTLS(@"BasicLanguage[1100]");		}
		case TXNotificationFileTransferReceiveRequestedType:	{ return TXTLS(@"BasicLanguage[1101]");		}
			
		default: { return nil; }
	}
	
	return nil;
}

- (void)notify:(TXNotificationType)eventType title:(NSString *)eventTitle description:(NSString *)eventDescription userInfo:(NSDictionary *)eventContext
{
	NSAssertReturn([TPCPreferences growlEnabledForEvent:eventType]);

	/* titleForEvent: invokes TXTLS for the event type. */
	NSString *eventKind = [self titleForEvent:eventType];
	
	NSInteger eventPriority = 0;
	
	switch (eventType) {
		case TXNotificationHighlightType:
		{
			eventPriority = 1;
			eventTitle = TXTLS(@"BasicLanguage[1063]", eventTitle);
			
			break;
		}
		case TXNotificationNewPrivateMessageType:
		{
			eventPriority = 1;
			eventTitle = TXTLS(@"BasicLanguage[1066]");
			
			break;
		}
		case TXNotificationChannelMessageType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1059]", eventTitle);
			
			break;
		}
		case TXNotificationChannelNoticeType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1060]", eventTitle);
			
			break;
		}
		case TXNotificationPrivateMessageType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1067]");
			
			break;
		}
		case TXNotificationPrivateNoticeType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1068]");
			
			break;
		}
		case TXNotificationKickType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1065]", eventTitle);
			
			break;
		}
		case TXNotificationInviteType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1064]", eventTitle);
			
			break;
		}
		case TXNotificationConnectType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1061]", eventTitle);
			eventDescription = TXTLS(@"BasicLanguage[1074]");
			
			break;
		}
		case TXNotificationDisconnectType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1062]", eventTitle);
			eventDescription = TXTLS(@"BasicLanguage[1075]");
			
			break;
		}
		case TXNotificationAddressBookMatchType: 
		{
			eventTitle = TXTLS(@"BasicLanguage[1058]");
			
			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1069]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1070]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1071]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1072]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			eventTitle = TXTLS(@"BasicLanguage[1073]", eventTitle);
			
			break;
		}
	}

	eventDescription = [eventDescription stripIRCEffects];

	/* Send to notification center? */
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		if ([GrowlApplicationBridge isGrowlRunning] == NO) {
			NSUserNotification *notification = [NSUserNotification new];
			
			[notification setTitle:eventTitle];
			[notification setInformativeText:eventDescription];
			[notification setDeliveryDate:[NSDate date]];
			[notification setUserInfo:eventContext];

#ifdef TXSystemIsMacOSMavericksOrNewer
			if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
				/* These are the only event types we want to support for now. */

				if (eventType == TXNotificationNewPrivateMessageType ||
					eventType == TXNotificationPrivateMessageType)
				{
					[notification setHasReplyButton:YES];
					[notification setResponsePlaceholder:TXTLS(@"BasicLanguage[1235]")];
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
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		if ([notification activationType] == NSUserNotificationActivationTypeReplied) {
			NSString *replyMessage = [[notification response] string]; // It is attributed string, we only want string.

			[self growlNotificationWasClicked:[notification userInfo]
							 withReplyMessage:replyMessage
								  changeFocus:NO];

			return; // Do not continue this method.
		}
	}
#endif

	[self growlNotificationWasClicked:[notification userInfo]];
}

/* Growl delegate */

- (NSString *)applicationNameForGrowl
{
	return [TPCApplicationInfo applicationName];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[
		TXTLS(@"BasicLanguage[1086]"),
		TXTLS(@"BasicLanguage[1087]"),
		TXTLS(@"BasicLanguage[1088]"),
		TXTLS(@"BasicLanguage[1089]"),
		TXTLS(@"BasicLanguage[1090]"),
		TXTLS(@"BasicLanguage[1091]"),
		TXTLS(@"BasicLanguage[1092]"),
		TXTLS(@"BasicLanguage[1093]"),
		TXTLS(@"BasicLanguage[1094]"),
		TXTLS(@"BasicLanguage[1095]"),
		TXTLS(@"BasicLanguage[1096]"),
		TXTLS(@"BasicLanguage[1097]"),
		TXTLS(@"BasicLanguage[1098]"),
		TXTLS(@"BasicLanguage[1099]"),
		TXTLS(@"BasicLanguage[1100]"),
		TXTLS(@"BasicLanguage[1101]"),
	];
	
	return @{
		GROWL_NOTIFICATIONS_ALL			: allNotifications,
		GROWL_NOTIFICATIONS_DEFAULT		: allNotifications
	};
}

- (void)growlNotificationWasClicked:(NSDictionary *)context
{
	[self growlNotificationWasClicked:context withReplyMessage:nil changeFocus:YES];
}

- (void)growlNotificationWasClicked:(NSDictionary *)context withReplyMessage:(NSString *)message changeFocus:(BOOL)changeFocus
{
	NSTimeInterval now = [NSDate epochTime];
	
	if ((now - _lastClickedTime) < _clickInterval) {
		if (   _lastClickedContext && [_lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	_lastClickedTime = now;
	_lastClickedContext = context;

	if (changeFocus) {
		[mainWindow() makeKeyAndOrderFront:nil];
		
		[NSApp activateIgnoringOtherApps:YES];
	}

	if ([context isKindOfClass:[NSDictionary class]]) {
		BOOL isFileTransferNotification = [context boolForKey:@"isFileTransferNotification"];
		
		if (isFileTransferNotification) {
			[[menuController() fileTransferController] show:YES restorePosition:NO];
		} else {
			NSString *uid = [context objectForKey:@"client"];
			NSString *cid = [context objectForKey:@"channel"];
			
			IRCClient *u = nil;
			IRCChannel *c = nil;
			
			NSObjectIsEmptyAssert(uid);
			
			if (cid) {
				c = [worldController() findChannelByClientId:uid channelId:cid];
			} else {
				u = [worldController() findClientById:uid];
			}
			
			if (changeFocus) {
				if (c) {
					[worldController() select:c];
				} else if (u) {
					[worldController() select:u];
				}
			}
			
			NSObjectIsEmptyAssert(message);
			
			if (c) { // We want both a client and channel.
				/* A user may want to do an action… #yolo */
				if ([message hasPrefix:@"/"] && [message hasPrefix:@"//"] == NO && [message length] > 1) {
					message = [message substringFromIndex:1];
					
					[c.client sendCommand:message
						   completeTarget:YES
								   target:[c name]];
				} else {
					[c.client sendText:[NSAttributedString emptyStringWithBase:message]
							   command:IRCPrivateCommandIndex("privmsg")
							   channel:c];
				}
			}
		}
	}
}

- (BOOL)hasNetworkClientEntitlement 
{
    return YES;
}

@end
