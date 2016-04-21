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

TEXTUAL_EXTERN NSString * const IRCWorldControllerDefaultsStorageKey;
TEXTUAL_EXTERN NSString * const IRCWorldControllerClientListDefaultsStorageKey; // the key within world controller maintaining the client list

TEXTUAL_EXTERN NSString * const IRCWorldDateHasChangedNotification;

TEXTUAL_EXTERN NSString * const IRCWorldClientListWasModifiedNotification;

@interface IRCWorld : NSObject
@property (nonatomic, assign) NSInteger messagesSent;
@property (nonatomic, assign) NSInteger messagesReceived;
@property (nonatomic, assign) TXUnsignedLongLong bandwidthIn;
@property (nonatomic, assign) TXUnsignedLongLong bandwidthOut;
@property (nonatomic, assign) BOOL isPopulatingSeeds;
@property (nonatomic, copy) NSArray *clientList; // clientList as a proxy setter/getter for the internal storage.
@property (nonatomic, assign) double textSizeMultiplier;

- (void)setupConfiguration;
- (void)setupOtherServices;

- (void)save;
- (void)savePeriodically;

- (NSMutableDictionary *)dictionaryValue;

- (void)prepareForApplicationTermination;

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp;
- (void)prepareForSleep;

- (void)prepareForScreenSleep;
- (void)awakeFomScreenSleep;

- (void)preferencesChanged;

- (void)reachabilityChanged:(BOOL)reachable;

- (void)changeTextSize:(BOOL)bigger;

- (void)markAllAsRead;
- (void)markAllAsRead:(IRCClient *)limitedClient;

- (void)reloadTheme;
- (void)reloadTheme:(BOOL)reloadUserInterface;

@property (readonly) NSInteger clientCount;

- (IRCTreeItem *)findItemByTreeId:(NSString *)uid;
- (IRCClient *)findClientById:(NSString *)uid;
- (IRCChannel *)findChannelByClientId:(NSString *)uid channelId:(NSString *)cid;

- (IRCTreeItem *)findItemFromPasteboardString:(NSString *)s;
- (NSString *)pasteboardStringForItem:(IRCTreeItem *)item;

- (IRCClient *)createClient:(id)seed reload:(BOOL)reload;
- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel *)createPrivateMessage:(NSString *)nickname client:(IRCClient *)client;

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel;

- (void)destroyClient:(IRCClient *)u;
- (void)destroyClient:(IRCClient *)u bySkippingCloud:(BOOL)skipCloud;

- (void)destroyChannel:(IRCChannel *)c;
- (void)destroyChannel:(IRCChannel *)c reload:(BOOL)reload;
- (void)destroyChannel:(IRCChannel *)c reload:(BOOL)reload part:(BOOL)forcePart;

- (void)evaluateFunctionOnAllViews:(NSString *)function arguments:(NSArray *)arguments; // Defaults to onQueue YES
- (void)evaluateFunctionOnAllViews:(NSString *)function arguments:(NSArray *)arguments onQueue:(BOOL)onQueue;

- (void)clearContentsOfClient:(IRCClient *)u;
- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u;

- (void)destroyAllEvidence; // Clears all views everywhere.
@end
