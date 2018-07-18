/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "TLOGrowlController.h"
#import "IRCClient.h"

NS_ASSUME_NONNULL_BEGIN

@class TLOSpokenNotification;
@class IRCAddressBookUserTrackingContainer, IRCTimedCommand, IRCUserMutable;

enum {
	ClientIRCv3SupportedCapabilitySASLGeneric			= 1 << 22,
	ClientIRCv3SupportedCapabilitySASLPlainText			= 1 << 23, // YES if SASL=plain CAP is supported
	ClientIRCv3SupportedCapabilitySASLExternal			= 1 << 24, // YES if SASL=external CAP is supported
	ClientIRCv3SupportedCapabilityZNCServerTime			= 1 << 25, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapabilityZNCServerTimeISO		= 1 << 26, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapabilityZNCPlaybackModule		= 1 << 27, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapabilityPlanioPlayback		= 1 << 28  // YES if the plan.io vendor specific CAP supported.
};

@interface IRCClient ()
@property (nonatomic, copy, nullable) dispatch_block_t disconnectCallback;
@property (nonatomic, assign, readwrite) IRCClientConnectMode connectType;
@property (nonatomic, assign, readwrite) IRCClientDisconnectMode disconnectType;
@property (nonatomic, assign) BOOL sidebarItemIsExpanded;
@property (nonatomic, copy, readwrite) NSArray<IRCChannel *> *channelList;
@property (nonatomic, weak, readwrite) IRCChannel *lastSelectedChannel;

- (instancetype)initWithConfig:(IRCClientConfig *)config NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic NS_DESIGNATED_INITIALIZER;

- (void)updateConfig:(IRCClientConfig *)config;
- (void)updateConfig:(IRCClientConfig *)config updateSelection:(BOOL)updateSelection;

- (void)updateConfigFromTheCloud:(IRCClientConfig *)config;

- (NSDictionary<NSString *, id> *)configurationDictionary;
- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud;

- (void)addChannel:(IRCChannel *)channel;
- (void)addChannel:(IRCChannel *)channel atPosition:(NSUInteger)position;

- (void)removeChannel:(IRCChannel *)channel; // This only removes the channel from channel array. Use world controller to properly destroy a channel.

- (NSUInteger)indexOfChannel:(IRCChannel *)channel;

- (void)selectFirstChannelInChannelList;

- (void)reloadServerListItems;

- (void)updateStoredChannelList;

- (void)cacheHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine;

- (void)inputText:(id)string destination:(IRCTreeItem *)destination;

- (void)inputText:(id)string asCommand:(IRCRemoteCommand)command;
- (void)inputText:(id)string asCommand:(IRCRemoteCommand)command destination:(IRCTreeItem *)destination;

- (void)enableCapability:(ClientIRCv3SupportedCapability)capability;
- (void)disableCapability:(ClientIRCv3SupportedCapability)capability;

- (void)noteReachabilityChanged:(BOOL)reachable;

- (void)autoConnectWithDelay:(NSUInteger)delay afterWakeUp:(BOOL)afterWakeUp;

- (void)postEventToViewController:(NSString *)eventToken;
- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel;

- (void)sendFile:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(uint64_t)totalFilesize token:(nullable NSString *)transferToken;
- (void)sendFileResume:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(uint64_t)totalFilesize token:(nullable NSString *)transferToken;
- (void)sendFileResumeAccept:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(uint64_t)totalFilesize token:(nullable NSString *)transferToken;

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(uint64_t)totalFilesize requestIdentifier:(NSString *)identifier;

- (IRCAddressBookUserTrackingContainer *)trackedUsers;

- (IRCUserMutable *)mutableCopyOfUserWithNickname:(NSString *)nickname;

- (void)modifyUser:(IRCUser *)user withBlock:(void (NS_NOESCAPE ^)(IRCUserMutable *userMutable))block;
- (void)modifyUserUserWithNickname:(NSString *)nickname withBlock:(void (NS_NOESCAPE ^)(IRCUserMutable *userMutable))block;

- (void)reopenLogFileIfNeeded;
- (void)closeLogFile;

- (nullable IRCChannel *)findChannelOrCreate:(NSString *)withName isUtility:(BOOL)isUtility;

- (nullable NSString *)formatNotificationToSpeak:(TLOSpokenNotification *)notification;

- (id)queuedBatchMessageWithToken:(NSString *)batchToken;

- (void)print:(NSString *)messageBody by:(nullable NSString *)nickname inChannel:(nullable IRCChannel *)channel asType:(TVCLogLineType)lineType command:(NSString *)command escapeMessage:(BOOL)escapeMessage;

- (void)onTimedCommand:(IRCTimedCommand *)timedCommand;

- (void)logFileRecordSessionChanged:(BOOL)toNewSession inChannel:(nullable IRCChannel *)channel;
@end

NS_ASSUME_NONNULL_END
