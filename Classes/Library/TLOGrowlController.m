/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
#import "TLOLicenseManager.h"
#endif

#define _clickInterval			2

NSString * const TXNotificationDialogStandardNicknameFormat		= @"%@ %@";
NSString * const TXNotificationDialogActionNicknameFormat		= @"\u2022 %@: %@";

NSString * const TXNotificationHighlightLogStandardActionFormat			= @"\u2022 %@: %@";
NSString * const TXNotificationHighlightLogStandardMessageFormat		= @"%@ %@";
NSString * const TXNotificationHighlightLogAlternativeActionFormat		= @"\u2022 %@ %@";

@interface TLOGrowlController ()
@property (nonatomic, copy) NSDictionary *lastClickedContext;
@property (nonatomic, assign) NSTimeInterval lastClickedTime;
@end

@implementation TLOGrowlController

- (instancetype)init
{
	if ((self = [super init])) {
		[RZUserNotificationCenter() setDelegate:self];
		
		[GrowlApplicationBridge setGrowlDelegate:self];

		return self;
	}
	
	return self;
}

- (NSString *)titleForEvent:(TXNotificationType)event
{
#define _df(key, num)			case (key): { return TXTLS((num)); }

	switch (event) {
		_df(TXNotificationAddressBookMatchType, @"Notifications[1045]")
		_df(TXNotificationChannelMessageType, @"Notifications[1046]")
		_df(TXNotificationChannelNoticeType, @"Notifications[1047]")
		_df(TXNotificationConnectType, @"Notifications[1048]")
		_df(TXNotificationDisconnectType, @"Notifications[1049]")
		_df(TXNotificationInviteType, @"Notifications[1051]")
		_df(TXNotificationKickType, @"Notifications[1052]")
		_df(TXNotificationNewPrivateMessageType, @"Notifications[1053]")
		_df(TXNotificationPrivateMessageType, @"Notifications[1054]")
		_df(TXNotificationPrivateNoticeType, @"Notifications[1055]")
		_df(TXNotificationHighlightType, @"Notifications[1050]")
		_df(TXNotificationFileTransferSendSuccessfulType, @"Notifications[1056]")
		_df(TXNotificationFileTransferReceiveSuccessfulType, @"Notifications[1057]")
		_df(TXNotificationFileTransferSendFailedType, @"Notifications[1058]")
		_df(TXNotificationFileTransferReceiveFailedType, @"Notifications[1059]")
		_df(TXNotificationFileTransferReceiveRequestedType, @"Notifications[1060]")
	}

#undef _df

	return nil;
}

- (void)notify:(TXNotificationType)eventType title:(NSString *)eventTitle description:(NSString *)eventDescription userInfo:(NSDictionary *)eventContext
{
	if ([TPCPreferences growlEnabledForEvent:eventType] == NO) {
		return; // This event is disabled by the user.
	}

	/* titleForEvent: invokes TXTLS for the event type. */
	NSString *eventKind = [self titleForEvent:eventType];
	
	NSInteger eventPriority = 0;
	
	switch (eventType) {
		case TXNotificationHighlightType:
		{
			eventPriority = 1;
			eventTitle = TXTLS(@"Notifications[1021]", eventTitle);
			
			break;
		}
		case TXNotificationNewPrivateMessageType:
		{
			eventPriority = 1;
			eventTitle = TXTLS(@"Notifications[1024]");
			
			break;
		}
		case TXNotificationChannelMessageType:
		{
			eventTitle = TXTLS(@"Notifications[1017]", eventTitle);
			
			break;
		}
		case TXNotificationChannelNoticeType:
		{
			eventTitle = TXTLS(@"Notifications[1018]", eventTitle);
			
			break;
		}
		case TXNotificationPrivateMessageType:
		{
			eventTitle = TXTLS(@"Notifications[1025]");
			
			break;
		}
		case TXNotificationPrivateNoticeType:
		{
			eventTitle = TXTLS(@"Notifications[1026]");
			
			break;
		}
		case TXNotificationKickType:
		{
			eventTitle = TXTLS(@"Notifications[1023]", eventTitle);
			
			break;
		}
		case TXNotificationInviteType:
		{
			eventTitle = TXTLS(@"Notifications[1022]", eventTitle);
			
			break;
		}
		case TXNotificationConnectType:
		{
			eventTitle = TXTLS(@"Notifications[1019]", eventTitle);
			eventDescription = TXTLS(@"Notifications[1032]");
			
			break;
		}
		case TXNotificationDisconnectType:
		{
			eventTitle = TXTLS(@"Notifications[1020]", eventTitle);
			eventDescription = TXTLS(@"Notifications[1033]");
			
			break;
		}
		case TXNotificationAddressBookMatchType: 
		{
			eventTitle = TXTLS(@"Notifications[1016]");
			
			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		{
			eventTitle = TXTLS(@"Notifications[1027]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			eventTitle = TXTLS(@"Notifications[1027]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			eventTitle = TXTLS(@"Notifications[1029]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			eventTitle = TXTLS(@"Notifications[1030]", eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			eventTitle = TXTLS(@"Notifications[1031]", eventTitle);
			
			break;
		}
	}

	if ([TPCPreferences removeAllFormatting] == NO) {
		eventDescription = [eventDescription stripIRCEffects];
	}

	/* Send to notification center? */
	if ([GrowlApplicationBridge isGrowlRunning] == NO) {
		NSUserNotification *notification = [NSUserNotification new];
		
		[notification setTitle:eventTitle];
		[notification setInformativeText:eventDescription];
		[notification setDeliveryDate:[NSDate date]];
		[notification setUserInfo:eventContext];

		if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
			/* These private APIs are not available on Mountain Lion */
			if (eventType == TXNotificationFileTransferReceiveRequestedType) {
				/* sshhhh... you didn't see nothing. */
				[notification setValue:@(YES) forKey:@"_showsButtons"];

				[notification setActionButtonTitle:TXTLS(@"Prompts[0009]")];
			}

			/* These are the only event types we want to support for now. */
			if (eventType == TXNotificationNewPrivateMessageType ||
				eventType == TXNotificationPrivateMessageType)
			{
				[notification setHasReplyButton:YES];

				[notification setResponsePlaceholder:TXTLS(@"Notifications[1044]")];
			}
		}

		[RZUserNotificationCenter() scheduleNotification:notification];

		return; // Do not continue to Growl...
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

#pragma mark -
#pragma mark Notification Cetner Delegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
	   didActivateNotification:(NSUserNotification *)notification
{
	[RZUserNotificationCenter() removeDeliveredNotification:notification];

	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		if ([notification activationType] == NSUserNotificationActivationTypeReplied) {
			NSString *replyMessage = [[notification response] string]; // It is attributed string, we only want string.

			[self notificationWasClicked:[notification userInfo]
						  activationType:[notification activationType]
						withReplyMessage:replyMessage];

			return; // Do not continue this method.
		}
	}

	[self notificationWasClicked:[notification userInfo]
				  activationType:[notification activationType]
				withReplyMessage:nil];
}

- (void)dismissNotificationsInNotificationCenterForClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	NSArray *notifications = [RZUserNotificationCenter() deliveredNotifications];
	
	for (NSUserNotification *note in notifications) {
		NSDictionary *context = [note userInfo];
		
		NSString *uid = context[@"client"];
		NSString *cid = context[@"channel"];
		
		if (NSObjectsAreEqual(uid, [client uniqueIdentifier]) &&
			NSObjectsAreEqual(cid, [channel uniqueIdentifier]))
		{
			[RZUserNotificationCenter() removeDeliveredNotification:note];
		}
	}
}

#pragma mark -
#pragma mark Growl delegate

- (NSString *)applicationNameForGrowl
{
	return [TPCApplicationInfo applicationName];
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[
		TXTLS(@"Notifications[1045]"),
		TXTLS(@"Notifications[1046]"),
		TXTLS(@"Notifications[1047]"),
		TXTLS(@"Notifications[1048]"),
		TXTLS(@"Notifications[1049]"),
		TXTLS(@"Notifications[1050]"),
		TXTLS(@"Notifications[1051]"),
		TXTLS(@"Notifications[1052]"),
		TXTLS(@"Notifications[1053]"),
		TXTLS(@"Notifications[1054]"),
		TXTLS(@"Notifications[1055]"),
		TXTLS(@"Notifications[1056]"),
		TXTLS(@"Notifications[1057]"),
		TXTLS(@"Notifications[1058]"),
		TXTLS(@"Notifications[1059]"),
		TXTLS(@"Notifications[1060]"),
	];
	
	return @{
		GROWL_NOTIFICATIONS_ALL			: allNotifications,
		GROWL_NOTIFICATIONS_DEFAULT		: allNotifications
	};
}

- (void)growlNotificationWasClicked:(id)context
{
	[self notificationWasClicked:context activationType:0 withReplyMessage:nil];
}

- (BOOL)hasNetworkClientEntitlement 
{
    return YES;
}

#pragma mark -
#pragma mark Notification Callback

- (void)notificationWasClicked:(NSDictionary *)context activationType:(NSUserNotificationActivationType)activationType withReplyMessage:(NSString *)message
{
	NSTimeInterval now = [NSDate timeIntervalSince1970];
	
	if ((now - self.lastClickedTime) < _clickInterval) {
		if (   self.lastClickedContext && [self.lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	self.lastClickedTime = now;
	self.lastClickedContext = context;

	BOOL changeFocus = NO;
	
	if (NSDissimilarObjects(activationType, NSUserNotificationActivationTypeReplied) &&
		NSDissimilarObjects(activationType, NSUserNotificationActivationTypeActionButtonClicked))
	{
		changeFocus = YES;
	}
	
	if (changeFocus) {
		[mainWindow() makeKeyAndOrderFront:nil];
		
		[NSApp activateIgnoringOtherApps:YES];
	}

	if ([context isKindOfClass:[NSDictionary class]]) {

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
		/* Handle a notification that was clicked related to a warnings about
		 the trial of Textual preparing to expire. */
		if ([context boolForKey:@"isLicenseManagerTimeRemainingInTrialNotification"])
		{
			if (activationType == NSUserNotificationActivationTypeActionButtonClicked)
			{
				[menuController() manageLicense:nil];
			}
		}
		else
#endif

		/* Handle file transfer notifications allowing the user to start a 
		 file transfer directly through the notification's action button. */
		if ([context boolForKey:@"isFileTransferNotification"])
		{
			NSInteger alertType = [context integerForKey:@"fileTransferNotificationType"];
			
			if (alertType == TXNotificationFileTransferReceiveRequestedType)
			{
				if (activationType == NSUserNotificationActivationTypeActionButtonClicked)
				{
					NSString *uniqueIdentifier = context[@"fileTransferUniqeIdentifier"];
					
					TDCFileTransferDialogTransferController *transfer = [[menuController() fileTransferController] fileTransferFromUniqueIdentifier:uniqueIdentifier];
					
					if (transfer) {
						TDCFileTransferDialogTransferStatus transferStatus = [transfer transferStatus];
					
						if (transferStatus == TDCFileTransferDialogTransferStoppedStatus) {
							if ([transfer path] == nil) {
								[transfer setPath:[TPCPathInfo userDownloadsFolderPath]];
							}
							
							[transfer open];
						}
					}
				}
			}
			
			[[menuController() fileTransferController] show:YES restorePosition:NO];
		}

		/* Handle all other IRC related notifications. */
		else
		{
			NSString *uid = context[@"client"];
			NSString *cid = context[@"channel"];
			
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
					[mainWindow() select:c];
				} else if (u) {
					[mainWindow() select:u];
				}
			}
			
			NSObjectIsEmptyAssert(message);
			
			if (c) { // We want both a client and channel.
				/* A user may want to do an action... */
				if ([message hasPrefix:@"/"] && [message hasPrefix:@"//"] == NO && [message length] > 1) {
					message = [message substringFromIndex:1];
					
					[[c associatedClient] sendCommand:message completeTarget:YES target:[c name]];
				} else {
					[[c associatedClient] sendPrivmsg:message toChannel:c];
				}
			}
		}
	}
}

@end
