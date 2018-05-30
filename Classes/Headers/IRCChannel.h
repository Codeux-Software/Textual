/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

#import "IRCChannelConfig.h"
#import "IRCTreeItem.h"

NS_ASSUME_NONNULL_BEGIN

@class IRCChannelMode, IRCChannelUser;

typedef NS_ENUM(NSUInteger, IRCChannelStatus) {
	IRCChannelStatusParted = 0,
	IRCChannelStatusJoining,
	IRCChannelStatusJoined,
	IRCChannelStatusTerminated,
};

TEXTUAL_EXTERN NSString * const IRCChannelConfigurationWasUpdatedNotification;

@interface IRCChannel : IRCTreeItem
@property (readonly, copy) IRCChannelConfig *config;
@property (nonatomic, copy) NSString *name; // -setName: will do nothing if type != IRCChannelPrivateMessageType
@property (nonatomic, copy, nullable) NSString *topic;
@property (nonatomic, assign) BOOL autoJoin;
@property (readonly) IRCChannelType type;
@property (getter=isChannel, readonly) BOOL channel;
@property (getter=isPrivateMessage, readonly) BOOL privateMessage;
@property (getter=isPrivateMessageForZNCUser, readonly) BOOL privateMessageForZNCUser; // For example: *status, *nickserv, etc.
@property (getter=isUtility, readonly) BOOL utility; // See IRCChannelUtilityType in IRCChannelConfig.h
@property (readonly) IRCChannelStatus status;
@property (readonly) BOOL errorOnLastJoinAttempt;
@property (readonly) NSTimeInterval channelJoinTime;
@property (readonly, copy) NSString *channelTypeString;
@property (readonly, strong, nullable) IRCChannelMode *modeInfo;
@property (readonly, copy, nullable) NSString *secretKey;
@property (readonly, copy, nullable) NSURL *logFilePath;
@property (readonly) NSUInteger logFileSessionCount; // Number of lines sent to channel log file for session (from connect to disconnect)

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@property (readonly) BOOL encryptionStateIsEncrypted;
#endif

- (void)activate;
- (void)deactivate;

/* Member changes (adding, removing, modifying) are done so asynchronously.
 This means that changes wont be immediately reflected by -memberList. */
/* It is safe to call -memberExists: and -findMember: immediately after 
 changing a member because those methods do not require the member to 
 be present in the member list to produce a result. */
- (void)addMember:(IRCChannelUser *)member;

- (void)removeMember:(IRCChannelUser *)member;
- (void)removeMemberWithNickname:(NSString *)nickname;

- (BOOL)memberExists:(NSString *)nickname;

- (nullable IRCChannelUser *)findMember:(NSString *)nickname;

/* -memberList and -numberOfMembers are KVO complient
 which means you can observe their values to know when modified. */
@property (readonly) NSUInteger numberOfMembers;

@property (readonly, copy) NSArray<IRCChannelUser *> *memberList; // Automatically sorted by channel rank
@end

NS_ASSUME_NONNULL_END
