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

#import "IRCChannel.h"
#import "TVCLogController.h"

NS_ASSUME_NONNULL_BEGIN

@class TVCLogLine;

@interface IRCChannel ()
@property (nonatomic, assign, readwrite) IRCChannelStatus status;
@property (nonatomic, assign) BOOL sentInitialWhoRequest;
@property (nonatomic, assign) BOOL channelModesReceived;
@property (nonatomic, assign) BOOL channelNamesReceived;
@property (nonatomic, assign, readwrite) BOOL errorOnLastJoinAttempt;

- (instancetype)initWithConfig:(IRCChannelConfig *)config NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConfigDictionary:(NSDictionary<NSString *, id> *)dic NS_DESIGNATED_INITIALIZER;

- (void)updateConfig:(IRCChannelConfig *)config;
- (void)updateConfig:(IRCChannelConfig *)config fireChangedNotification:(BOOL)fireChangedNotification;
- (void)updateConfig:(IRCChannelConfig *)config fireChangedNotification:(BOOL)fireChangedNotification updateStoredChannelList:(BOOL)updateStoredChannelList;

- (NSDictionary<NSString *, id> *)configurationDictionary;
- (NSDictionary<NSString *, id> *)configurationDictionaryForCloud;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)noteEncryptionStateDidChange;
#endif

- (void)addMember:(IRCChannelUser *)member checkForDuplicates:(BOOL)checkForDuplicates;

- (void)changeMember:(NSString *)nickname mode:(NSString *)mode value:(BOOL)value;

- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2;
- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2 resort:(BOOL)resort;
- (void)replaceMember:(IRCChannelUser *)member1 withMember:(IRCChannelUser *)member2 resort:(BOOL)resort replaceInAllChannels:(BOOL)replaceInAllChannels;

- (void)clearMembers; // This will not reload table view

- (void)resortMember:(IRCChannelUser *)member;

- (void)reloadDataForTableView;
- (void)reloadDataForTableViewBySortingMembers;

- (void)writeToLogLineToLogFile:(TVCLogLine *)logLine;
- (void)logFileWriteSessionBegin;
- (void)logFileWriteSessionEnd;

- (void)print:(TVCLogLine *)logLine;
- (void)print:(TVCLogLine *)logLine completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock;

+ (BOOL)readNicknamesFromPasteboardData:(NSData *)pasteboardData withBlock:(void (NS_NOESCAPE ^)(IRCChannel *channel, NSArray<NSString *> *nicknames))callbackBlock;
+ (BOOL)readMembersFromPasteboardData:(NSData *)pasteboardData withBlock:(void (NS_NOESCAPE ^)(IRCChannel *channel, NSArray<IRCChannelUser *> *members))callbackBlock;

+ (void)resumeMemberListSerialQueues;
+ (void)suspendMemberListSerialQueues;

- (void)reopenLogFileIfNeeded;
- (void)closeLogFile;
@end

NS_ASSUME_NONNULL_END
