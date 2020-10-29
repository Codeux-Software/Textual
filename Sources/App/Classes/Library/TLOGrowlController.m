/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2020 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSStringHelper.h"
#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TVCMainWindow.h"
#import "TPCApplicationInfo.h"
#import "TPCPathInfo.h"
#import "TPCPreferencesLocal.h"
#import "TLOLocalization.h"
#import "TDCFileTransferDialogPrivate.h"
#import "TDCFileTransferDialogTransferControllerPrivate.h"
#import "IRCClientPrivate.h"
#import "IRCChannel.h"
#import "IRCWorld.h"
#import "TLOGrowlControllerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _clickInterval			2

NSString * const TXNotificationDialogStandardNicknameFormat		= @"%@ %@";
NSString * const TXNotificationDialogActionNicknameFormat		= @"\u2022 %@: %@";

NSString * const TXNotificationHighlightLogStandardActionFormat			= @"\u2022 %@: %@";
NSString * const TXNotificationHighlightLogStandardMessageFormat		= @"%@ %@";

@interface TLOGrowlController ()
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *lastClickedContext;
@property (nonatomic, assign) NSTimeInterval lastClickedTime;
@end

@implementation TLOGrowlController

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return self;
}

- (void)prepareInitialState
{
	RZUserNotificationCenter().delegate = (id)self;

#if TEXTUAL_BUILT_WITH_GROWL_SDK_ENABLED == 1
	[GrowlApplicationBridge setGrowlDelegate:(id)self];
#endif

	[RZNotificationCenter() addObserver:self selector:@selector(mainWindowSelectionChanged:) name:TVCMainWindowSelectionChangedNotification object:nil];
}

- (void)mainWindowSelectionChanged:(NSNotification *)notification
{
	TVCMainWindow *mainWindow = mainWindow();

	[self dismissNotificationCenterNotificationsForChannel:mainWindow.selectedChannel onClient:mainWindow.selectedClient];
}

- (NSString *)titleForEvent:(TXNotificationType)event
{
#define _df(key, num)			case (key): { return TXTLS((num)); }

	switch (event) {
			_df(TXNotificationTypeAddressBookMatch, @"Notifications[kx3-xk]")
			_df(TXNotificationTypeChannelMessage, @"Notifications[qnz-k4]")
			_df(TXNotificationTypeChannelNotice, @"Notifications[vuq-jp]")
			_df(TXNotificationTypeConnect, @"Notifications[4lr-ej]")
			_df(TXNotificationTypeDisconnect, @"Notifications[wjv-yb]")
			_df(TXNotificationTypeInvite, @"Notifications[eiu-8q]")
			_df(TXNotificationTypeKick, @"Notifications[2nk-lg]")
			_df(TXNotificationTypeNewPrivateMessage, @"Notifications[5yi-gu]")
			_df(TXNotificationTypePrivateMessage, @"Notifications[00b-nx]")
			_df(TXNotificationTypePrivateNotice, @"Notifications[nhz-io]")
			_df(TXNotificationTypeHighlight, @"Notifications[cs4-x9]")
			_df(TXNotificationTypeFileTransferSendSuccessful, @"Notifications[0x2-3h]")
			_df(TXNotificationTypeFileTransferReceiveSuccessful, @"Notifications[qle-7v]")
			_df(TXNotificationTypeFileTransferSendFailed, @"Notifications[sc0-1n]")
			_df(TXNotificationTypeFileTransferReceiveFailed, @"Notifications[we9-1b]")
			_df(TXNotificationTypeFileTransferReceiveRequested, @"Notifications[st5-0n]")
			_df(TXNotificationTypeUserJoined, @"Notifications[25q-af]")
			_df(TXNotificationTypeUserParted, @"Notifications[k3s-by]")
			_df(TXNotificationTypeUserDisconnected, @"Notifications[0fo-bt]")
	}

#undef _df

	return nil;
}

- (void)notify:(TXNotificationType)eventType title:(nullable NSString *)eventTitle description:(nullable NSString *)eventDescription userInfo:(nullable NSDictionary<NSString *,id> *)eventContext
{
	switch (eventType) {
		case TXNotificationTypeHighlight:
		{
			eventTitle = TXTLS(@"Notifications[qka-f3]", eventTitle);

			break;
		}
		case TXNotificationTypeNewPrivateMessage:
		{
			eventTitle = TXTLS(@"Notifications[ltn-hf]");

			break;
		}
		case TXNotificationTypeChannelMessage:
		{
			eventTitle = TXTLS(@"Notifications[ep5-de]", eventTitle);

			break;
		}
		case TXNotificationTypeChannelNotice:
		{
			eventTitle = TXTLS(@"Notifications[chi-km]", eventTitle);

			break;
		}
		case TXNotificationTypePrivateMessage:
		{
			eventTitle = TXTLS(@"Notifications[69i-dy]");

			break;
		}
		case TXNotificationTypePrivateNotice:
		{
			eventTitle = TXTLS(@"Notifications[7hn-dg]");

			break;
		}
		case TXNotificationTypeKick:
		{
			eventTitle = TXTLS(@"Notifications[u30-ia]", eventTitle);

			break;
		}
		case TXNotificationTypeInvite:
		{
			eventTitle = TXTLS(@"Notifications[g4s-cq]", eventTitle);

			break;
		}
		case TXNotificationTypeConnect:
		{
			eventTitle = TXTLS(@"Notifications[mo1-vn]", eventTitle);

			eventDescription = TXTLS(@"Notifications[88k-kl]");

			break;
		}
		case TXNotificationTypeDisconnect:
		{
			eventTitle = TXTLS(@"Notifications[7xe-ig]", eventTitle);

			eventDescription = TXTLS(@"Notifications[bif-2c]");

			break;
		}
		case TXNotificationTypeAddressBookMatch:
		{
			eventTitle = TXTLS(@"Notifications[niq-32]");

			break;
		}
		case TXNotificationTypeFileTransferSendSuccessful:
		{
			eventTitle = TXTLS(@"Notifications[l5y-sx]", eventTitle);

			break;
		}
		case TXNotificationTypeFileTransferReceiveSuccessful:
		{
			eventTitle = TXTLS(@"Notifications[hc9-7n]", eventTitle);

			break;
		}
		case TXNotificationTypeFileTransferSendFailed:
		{
			eventTitle = TXTLS(@"Notifications[het-vh]", eventTitle);

			break;
		}
		case TXNotificationTypeFileTransferReceiveFailed:
		{
			eventTitle = TXTLS(@"Notifications[hm4-ze]", eventTitle);

			break;
		}
		case TXNotificationTypeFileTransferReceiveRequested:
		{
			eventTitle = TXTLS(@"Notifications[nqz-7v]", eventTitle);

			break;
		}
		case TXNotificationTypeUserJoined:
		{
			eventTitle = TXTLS(@"Notifications[keq-ts]", eventTitle);

			break;
		}
		case TXNotificationTypeUserParted:
		{
			eventTitle = TXTLS(@"Notifications[im4-p0]", eventTitle);

			break;
		}
		case TXNotificationTypeUserDisconnected:
		{
			eventTitle = TXTLS(@"Notifications[20x-32]", eventTitle);

			break;
		}
	}

	if ([TPCPreferences removeAllFormatting] == NO) {
		eventDescription = eventDescription.stripIRCEffects;
	}

#if TEXTUAL_BUILT_WITH_GROWL_SDK_ENABLED == 1
	if ([GrowlApplicationBridge isGrowlRunning] == NO) {
#endif

		NSUserNotification *notification = [NSUserNotification new];

		notification.deliveryDate = [NSDate date];
		notification.informativeText = eventDescription;
		notification.title = eventTitle;
		notification.userInfo = eventContext;

		if (eventType == TXNotificationTypeFileTransferReceiveRequested) {
			/* sshhhh... you didn't see nothing. */
			[notification setValue:@(YES) forKey:@"_showsButtons"];

			notification.actionButtonTitle = TXTLS(@"Prompts[qpv-go]");
		}

		/* These are the only event types we want to support for now */
		if (eventType == TXNotificationTypeNewPrivateMessage ||
			eventType == TXNotificationTypePrivateMessage)
		{
			notification.hasReplyButton = YES;

			notification.responsePlaceholder = TXTLS(@"Notifications[do4-2e]");
		}

		[RZUserNotificationCenter() scheduleNotification:notification];

#if TEXTUAL_BUILT_WITH_GROWL_SDK_ENABLED == 1
		return; // Do not continue to Growl...
	}

	NSString *eventKind = [self titleForEvent:eventType];

	[GrowlApplicationBridge notifyWithTitle:eventTitle
								description:eventDescription
						   notificationName:eventKind
								   iconData:nil
								   priority:(signed int)eventPriority
								   isSticky:NO
							   clickContext:eventContext];
#endif
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

	if (notification.activationType == NSUserNotificationActivationTypeReplied) {
		NSString *replyMessage = notification.response.string; // It is attributed string, we only want string.

		[self notificationWasClicked:notification.userInfo
					  activationType:notification.activationType
					withReplyMessage:replyMessage];

		return; // Do not continue this method.
	}

	[self notificationWasClicked:notification.userInfo
				  activationType:notification.activationType
				withReplyMessage:nil];
}

- (void)dismissNotificationCenterNotificationsForChannel:(IRCChannel *)channel onClient:(IRCClient *)client
{
	NSArray *notifications = RZUserNotificationCenter().deliveredNotifications;

	for (NSUserNotification *note in notifications) {
		NSDictionary *context = note.userInfo;

		NSString *clientId = context[@"clientId"];
		NSString *channelId = context[@"channelId"];

		if ([clientId isEqualToString:client.uniqueIdentifier] &&
			[channelId isEqualToString:channel.uniqueIdentifier])
		{
			[RZUserNotificationCenter() removeDeliveredNotification:note];
		}
	}
}

#pragma mark -
#pragma mark Growl delegate

#if TEXTUAL_BUILT_WITH_GROWL_SDK_ENABLED == 1
- (NSString *)applicationNameForGrowl
{
	return [TPCApplicationInfo applicationNameWithoutVersion];
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)registrationDictionaryForGrowl
{
	NSArray *allNotifications = @[
	  TXTLS(@"Notifications[kx3-xk]"),
	  TXTLS(@"Notifications[qnz-k4]"),
	  TXTLS(@"Notifications[vuq-jp]"),
	  TXTLS(@"Notifications[4lr-ej]"),
	  TXTLS(@"Notifications[wjv-yb]"),
	  TXTLS(@"Notifications[cs4-x9]"),
	  TXTLS(@"Notifications[eiu-8q]"),
	  TXTLS(@"Notifications[2nk-lg]"),
	  TXTLS(@"Notifications[5yi-gu]"),
	  TXTLS(@"Notifications[00b-nx]"),
	  TXTLS(@"Notifications[nhz-io]"),
	  TXTLS(@"Notifications[0x2-3h]"),
	  TXTLS(@"Notifications[qle-7v]"),
	  TXTLS(@"Notifications[sc0-1n]"),
	  TXTLS(@"Notifications[we9-1b]"),
	  TXTLS(@"Notifications[st5-0n]"),
	  TXTLS(@"Notifications[25q-af]"),
	  TXTLS(@"Notifications[k3s-by]"),
	  TXTLS(@"Notifications[0fo-bt]"),
	];

	return @{
		GROWL_NOTIFICATIONS_ALL	: allNotifications,
		GROWL_NOTIFICATIONS_DEFAULT	: allNotifications
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
#endif

#pragma mark -
#pragma mark Notification Callback

- (void)notificationWasClicked:(NSDictionary<NSString *, id> *)context activationType:(NSUserNotificationActivationType)activationType withReplyMessage:(nullable NSString *)message
{
	NSParameterAssert(context != nil);

	NSTimeInterval now = [NSDate timeIntervalSince1970];

	if ((now - self.lastClickedTime) < _clickInterval) {
		if (self.lastClickedContext && [self.lastClickedContext isEqualToDictionary:context]) {
			return;
		}
	}

	self.lastClickedContext = context;

	self.lastClickedTime = now;

	BOOL changeFocus =
		(activationType != NSUserNotificationActivationTypeReplied &&
		 activationType != NSUserNotificationActivationTypeActionButtonClicked);

	if (changeFocus) {
		[mainWindow() makeKeyAndOrderFront:nil];

		[NSApp activateIgnoringOtherApps:YES];
	}

	if ([context isKindOfClass:[NSDictionary class]] == NO) {
		return;
	}

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	/* Handle a notification that was clicked related to a warnings about
	 the trial of Textual preparing to expire. */
	if ([context boolForKey:@"isLicenseManagerTimeRemainingInTrialNotification"])
	{
		[menuController() manageLicense:nil];
	}
	else
#endif

	/* Handle file transfer notifications allowing the user to start a
	 file transfer directly through the notification's action button. */
	if ([context boolForKey:@"isFileTransferNotification"])
	{
		NSInteger alertType = [context integerForKey:@"fileTransferNotificationType"];

		if (activationType != NSUserNotificationActivationTypeActionButtonClicked) {
			return;
		}

		if (alertType != TXNotificationTypeFileTransferReceiveRequested) {
			return;
		}

		NSString *uniqueIdentifier = context[@"fileTransferUniqeIdentifier"];

		TDCFileTransferDialogTransferController *fileTransfer = [[TXSharedApplication sharedFileTransferDialog] fileTransferWithUniqueIdentifier:uniqueIdentifier];

		if (fileTransfer == nil) {
			return;
		}

		TDCFileTransferDialogTransferStatus transferStatus = fileTransfer.transferStatus;

		if (transferStatus != TDCFileTransferDialogTransferStatusStopped) {
			return;
		}

		NSString *savePath = fileTransfer.path;

		if (savePath == nil) {
			savePath = [TPCPathInfo userDownloads];
		}

		[fileTransfer openWithPath:savePath];

		[[TXSharedApplication sharedFileTransferDialog] show:YES restorePosition:NO];
	}

	/* Handle all other IRC related notifications. */
	else
	{
		NSString *clientId = context[@"clientId"];
		NSString *channelId = context[@"channelId"];

		if (clientId == nil) {
			return;
		}

		IRCClient *client = nil;
		IRCChannel *channel = nil;

		if (channelId) {
			channel = [worldController() findChannelWithId:channelId onClientWithId:clientId];
		} else {
			client = [worldController() findClientWithId:clientId];
		}

		if (changeFocus) {
			if (channel) {
				[mainWindow() select:channel];
			} else if (client) {
				[mainWindow() select:client];
			}
		}

		if (channel == nil) {
			return;
		}

		if (message.length == 0) {
			return;
		}

		[channel.associatedClient inputText:message destination:channel];
	}
}

@end

#pragma mark -

@implementation TLOGrowlController (Preferences)

- (nullable NSString *)soundForEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSString *channelValue = [channel.config soundForEvent:event];

		if (channelValue != nil) {
			return channelValue;
		}
	}

	return [TPCPreferences soundForEvent:event];
}

- (BOOL)speakEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSUInteger channelValue = [channel.config speakEvent:event];

		if (channelValue != NSMixedState) {
			return (channelValue == NSOnState);
		}
	}

	return [TPCPreferences speakEvent:event];
}

- (BOOL)growlEnabledForEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSUInteger channelValue = [channel.config growlEnabledForEvent:event];

		if (channelValue != NSMixedState) {
			return (channelValue == NSOnState);
		}
	}

	return [TPCPreferences growlEnabledForEvent:event];
}

- (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSUInteger channelValue = [channel.config disabledWhileAwayForEvent:event];

		if (channelValue != NSMixedState) {
			return (channelValue == NSOnState);
		}
	}

	return [TPCPreferences disabledWhileAwayForEvent:event];
}

- (BOOL)bounceDockIconForEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSUInteger channelValue = [channel.config bounceDockIconForEvent:event];

		if (channelValue != NSMixedState) {
			return (channelValue == NSOnState);
		}
	}

	return [TPCPreferences bounceDockIconForEvent:event];
}

- (BOOL)bounceDockIconRepeatedlyForEvent:(TXNotificationType)event inChannel:(nullable IRCChannel *)channel
{
	if (channel) {
		NSUInteger channelValue = [channel.config bounceDockIconRepeatedlyForEvent:event];

		if (channelValue != NSMixedState) {
			return (channelValue == NSOnState);
		}
	}

	return [TPCPreferences bounceDockIconRepeatedlyForEvent:event];
}

@end

NS_ASSUME_NONNULL_END
