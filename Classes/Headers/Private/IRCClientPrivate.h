/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

enum {
	ClientIRCv3SupportedCapacitySASLGeneric			= 1 << 9,
	ClientIRCv3SupportedCapacitySASLPlainText		= 1 << 10, // YES if SASL=plain CAP is supported
	ClientIRCv3SupportedCapacitySASLExternal		= 1 << 11, // YES if SASL=external CAP is supported
	ClientIRCv3SupportedCapacityZNCServerTime		= 1 << 12, // YES if the ZNC vendor specific CAP supported
	ClientIRCv3SupportedCapacityZNCServerTimeISO	= 1 << 13, // YES if the ZNC vendor specific CAP supported
};

@interface IRCClient ()
@property (nonatomic, copy, nullable) TXEmtpyBlockDataType disconnectCallback;
@property (nonatomic, assign, readwrite) IRCClientConnectMode connectType;
@property (nonatomic, assign, readwrite) IRCClientDisconnectMode disconnectType;
@property (nonatomic, assign) BOOL inUserInvokedJoinRequest;
@property (nonatomic, assign) BOOL sidebarItemIsExpanded;
@property (nonatomic, copy, readwrite) NSArray<IRCChannel *> *channelList;
@property (nonatomic, weak, readwrite, nullable) IRCChannel *lastSelectedChannel;

- (instancetype)initWithConfig:(IRCClientConfig *)config NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic NS_DESIGNATED_INITIALIZER;

- (void)updateConfig:(IRCClientConfig *)seed;
- (void)updateConfig:(IRCClientConfig *)seed updateSelection:(BOOL)updateSelection;

- (void)updateConfigFromTheCloud:(IRCClientConfig *)seed;

- (NSDictionary<NSString *, id> *)configurationDictionary;
- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud;

- (void)addChannel:(IRCChannel *)channel;
- (void)addChannel:(IRCChannel *)channel atPosition:(NSUInteger)position;

- (void)removeChannel:(IRCChannel *)channel; // This only removes the channel from channel array. Use world controller to properly destroy a channel.

- (NSUInteger)indexOfChannel:(IRCChannel *)channel;

- (void)selectFirstChannelInChannelList;

- (void)updateStoredChannelList;

- (void)cacheHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine;

- (void)willDestroyChannel:(IRCChannel *)channel; // Callback for IRCWorld

- (void)inputText:(id)string asCommand:(NSString *)command;

- (void)enableCapacity:(ClientIRCv3SupportedCapacities)capacity;
- (void)disableCapacity:(ClientIRCv3SupportedCapacities)capacity;

- (void)noteReachabilityChanged:(BOOL)reachable;

- (void)autoConnectWithDelay:(NSUInteger)delay afterWakeUp:(BOOL)afterWakeUp;

- (void)postEventToViewController:(NSString *)eventToken;
- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel;

- (void)sendFile:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken;
- (void)sendFileResume:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken;
- (void)sendFileResumeAccept:(NSString *)nickname port:(uint16_t)port filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize token:(nullable NSString *)transferToken;

- (void)notifyFileTransfer:(TXNotificationType)type nickname:(NSString *)nickname filename:(NSString *)filename filesize:(TXUnsignedLongLong)totalFilesize requestIdentifier:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
