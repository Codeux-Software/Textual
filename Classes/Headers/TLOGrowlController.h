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

#import <Growl/Growl.h>

typedef NS_ENUM(NSUInteger, TXNotificationType) {
	TXNotificationHighlightType							= 1000,
	TXNotificationNewPrivateMessageType					= 1001,
	TXNotificationChannelMessageType					= 1002,
	TXNotificationChannelNoticeType						= 1003,
	TXNotificationPrivateMessageType					= 1004,
	TXNotificationPrivateNoticeType						= 1005,
	TXNotificationKickType								= 1006,
	TXNotificationInviteType							= 1007,
	TXNotificationConnectType							= 1008,
	TXNotificationDisconnectType						= 1009,
	TXNotificationAddressBookMatchType					= 1010,
	TXNotificationFileTransferSendSuccessfulType		= 1011,
	TXNotificationFileTransferReceiveSuccessfulType		= 1012,
	TXNotificationFileTransferSendFailedType			= 1013,
	TXNotificationFileTransferReceiveFailedType			= 1014,
	TXNotificationFileTransferReceiveRequestedType		= 1015,
};

TEXTUAL_EXTERN NSString * const TXNotificationDialogStandardNicknameFormat;
TEXTUAL_EXTERN NSString * const TXNotificationDialogActionNicknameFormat;

TEXTUAL_EXTERN NSString * const TXNotificationHighlightLogStandardActionFormat;
TEXTUAL_EXTERN NSString * const TXNotificationHighlightLogStandardMessageFormat;
TEXTUAL_EXTERN NSString * const TXNotificationHighlightLogAlternativeActionFormat;

@interface TLOGrowlController : NSObject <GrowlApplicationBridgeDelegate, NSUserNotificationCenterDelegate>
@property (nonatomic, assign) BOOL areNotificationsDisabled;
@property (nonatomic, assign) BOOL areNotificationSoundsDisabled;

- (NSString *)titleForEvent:(TXNotificationType)event;

- (void)notify:(TXNotificationType)eventType
		 title:(NSString *)eventTitle
   description:(NSString *)eventDescription
	  userInfo:(NSDictionary *)eventContext;

- (void)dismissNotificationsInNotificationCenterForClient:(IRCClient *)client channel:(IRCChannel *)channel;
@end
