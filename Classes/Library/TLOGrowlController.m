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
#define _df(key, num)			case (key): { return BLS((num)); }

	switch (event) {
		_df(TXNotificationAddressBookMatchType, 1086)
		_df(TXNotificationChannelMessageType, 1087)
		_df(TXNotificationChannelNoticeType, 1088)
		_df(TXNotificationConnectType, 1089)
		_df(TXNotificationDisconnectType, 1090)
		_df(TXNotificationInviteType, 1092)
		_df(TXNotificationKickType, 1093)
		_df(TXNotificationNewPrivateMessageType, 1094)
		_df(TXNotificationPrivateMessageType, 1095)
		_df(TXNotificationPrivateNoticeType, 1096)
		_df(TXNotificationHighlightType, 1091)
		_df(TXNotificationFileTransferSendSuccessfulType, 1097)
		_df(TXNotificationFileTransferReceiveSuccessfulType, 1098)
		_df(TXNotificationFileTransferSendFailedType, 1099)
		_df(TXNotificationFileTransferReceiveFailedType, 1100)
		_df(TXNotificationFileTransferReceiveRequestedType, 1101)
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
			eventTitle = BLS(1063, eventTitle);
			
			break;
		}
		case TXNotificationNewPrivateMessageType:
		{
			eventPriority = 1;
			eventTitle = BLS(1066);
			
			break;
		}
		case TXNotificationChannelMessageType:
		{
			eventTitle = BLS(1059, eventTitle);
			
			break;
		}
		case TXNotificationChannelNoticeType:
		{
			eventTitle = BLS(1060, eventTitle);
			
			break;
		}
		case TXNotificationPrivateMessageType:
		{
			eventTitle = BLS(1067);
			
			break;
		}
		case TXNotificationPrivateNoticeType:
		{
			eventTitle = BLS(1068);
			
			break;
		}
		case TXNotificationKickType:
		{
			eventTitle = BLS(1065, eventTitle);
			
			break;
		}
		case TXNotificationInviteType:
		{
			eventTitle = BLS(1064, eventTitle);
			
			break;
		}
		case TXNotificationConnectType:
		{
			eventTitle = BLS(1061, eventTitle);
			eventDescription = BLS(1074);
			
			break;
		}
		case TXNotificationDisconnectType:
		{
			eventTitle = BLS(1062, eventTitle);
			eventDescription = BLS(1075);
			
			break;
		}
		case TXNotificationAddressBookMatchType: 
		{
			eventTitle = BLS(1058);
			
			break;
		}
		case TXNotificationFileTransferSendSuccessfulType:
		{
			eventTitle = BLS(1069, eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveSuccessfulType:
		{
			eventTitle = BLS(1070, eventTitle);
			
			break;
		}
		case TXNotificationFileTransferSendFailedType:
		{
			eventTitle = BLS(1071, eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveFailedType:
		{
			eventTitle = BLS(1072, eventTitle);
			
			break;
		}
		case TXNotificationFileTransferReceiveRequestedType:
		{
			eventTitle = BLS(1073, eventTitle);
			
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

				[notification setActionButtonTitle:BLS(1244)];
			}

			/* These are the only event types we want to support for now. */
			if (eventType == TXNotificationNewPrivateMessageType ||
				eventType == TXNotificationPrivateMessageType)
			{
				[notification setHasReplyButton:YES];
				[notification setResponsePlaceholder:BLS(1239)];
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
		
		if (NSObjectsAreEqual(uid, [client treeUUID]) &&
			NSObjectsAreEqual(cid, [channel treeUUID]))
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
		BLS(1086),
		BLS(1087),
		BLS(1088),
		BLS(1089),
		BLS(1090),
		BLS(1091),
		BLS(1092),
		BLS(1093),
		BLS(1094),
		BLS(1095),
		BLS(1096),
		BLS(1097),
		BLS(1098),
		BLS(1099),
		BLS(1100),
		BLS(1101),
	];
	
	return @{
		GROWL_NOTIFICATIONS_ALL			: allNotifications,
		GROWL_NOTIFICATIONS_DEFAULT		: allNotifications
	};
}

- (void)growlNotificationWasClicked:(NSDictionary *)context
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
	NSTimeInterval now = [NSDate unixTime];
	
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
								[transfer setPath:[TPCPathInfo userDownloadFolderPath]];
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
