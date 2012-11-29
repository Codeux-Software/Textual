/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (nonatomic, weak) TVCServerList *serverList;
@property (nonatomic, weak) TVCMemberList *memberList;
@property (nonatomic, unsafe_unretained) TVCMainWindow *window;
@property (nonatomic, unsafe_unretained) TVCInputTextField *text;
@property (nonatomic, weak) TPCViewTheme *viewTheme;
@property (nonatomic, weak) TLOGrowlController *growl;
@property (nonatomic, weak) TXMasterController *master;
@property (nonatomic, strong) TVCLogController *dummyLog;
@property (nonatomic, weak) TXMenuController *menuController;
@property (nonatomic, weak) NSBox *logBase;
@property (nonatomic, weak) NSMenu *logMenu;
@property (nonatomic, weak) NSMenu *urlMenu;
@property (nonatomic, weak) NSMenu *chanMenu;
@property (nonatomic, weak) NSMenu *treeMenu;
@property (nonatomic, weak) NSMenu *memberMenu;
@property (nonatomic, strong) NSMenu *serverMenu;
@property (nonatomic, strong) NSMenu *channelMenu;
@property (nonatomic, assign) NSInteger messagesSent;
@property (nonatomic, assign) NSInteger messagesReceived;
@property (nonatomic, assign) TXFSLongInt bandwidthIn;
@property (nonatomic, assign) TXFSLongInt bandwidthOut;
@property (nonatomic, strong) IRCWorldConfig *config;
@property (nonatomic, strong) NSMutableArray *clients;
@property (nonatomic, assign) NSInteger itemId;
@property (nonatomic, assign) BOOL soundMuted;
@property (nonatomic, assign) BOOL reloadingTree;
@property (nonatomic, weak) IRCExtras *extrac;
@property (nonatomic, strong) IRCTreeItem *selected;
@property (nonatomic, assign) NSInteger previousSelectedClientId;
@property (nonatomic, assign) NSInteger previousSelectedChannelId;
@property (nonatomic, strong) NSArray *allLoadedBundles;
@property (nonatomic, strong) NSArray *bundlesWithPreferences;
@property (nonatomic, strong) NSDictionary *bundlesForUserInput;
@property (nonatomic, strong) NSDictionary *bundlesForServerInput;
@property (nonatomic, strong) NSDictionary *bundlesWithOutputRules;
@property (nonatomic, strong) NSOperationQueue *messageOperationQueue;

- (void)setup:(IRCWorldConfig *)seed;
- (void)setupTree;
- (void)save;

- (NSMutableDictionary *)dictionaryValue;

- (void)setServerMenuItem:(NSMenuItem *)item;
- (void)setChannelMenuItem:(NSMenuItem *)item;

- (void)resetLoadedBundles;

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp;
- (void)terminate;
- (void)prepareForSleep;

- (IRCClient *)findClient:(NSString *)name;
- (IRCClient *)findClientById:(NSInteger)uid;
- (IRCChannel *)findChannelByClientId:(NSInteger)uid channelId:(NSInteger)cid;

- (void)select:(id)item;
- (void)selectChannelAt:(NSInteger)n;
- (void)selectClientAt:(NSInteger)n;
- (void)selectPreviousItem;

- (IRCClient *)selectedClient;
- (IRCChannel *)selectedChannel;
- (IRCChannel *)selectedChannelOn:(IRCClient *)c;

- (IRCTreeItem *)previouslySelectedItem;

- (void)focusInputText;
- (BOOL)inputText:(id)str command:(NSString *)command;

- (void)markAllAsRead;
- (void)markAllAsRead:(IRCClient *)limitedClient;

- (void)markAllScrollbacks;

- (void)updateIcon;

- (void)reloadTree;
- (void)adjustSelection;
- (void)expandClient:(IRCClient *)client;

- (void)updateTitle;
- (void)updateClientTitle:(IRCClient *)client;
- (void)updateChannelTitle:(IRCChannel *)channel;

- (void)addHighlightInChannel:(IRCChannel *)channel withMessage:(NSString *)message;
- (void)notifyOnGrowl:(TXNotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;

- (void)preferencesChanged;
- (void)reloadTheme;
- (void)changeTextSize:(BOOL)bigger;

- (IRCClient *)createClient:(IRCClientConfig *)seed reload:(BOOL)reload;
- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel *)createTalk:(NSString *)nick client:(IRCClient *)client;

- (void)destroyChannel:(IRCChannel *)c part:(BOOL)forcePart;
- (void)destroyChannel:(IRCChannel *)c;
- (void)destroyClient:(IRCClient *)client;

- (void)logKeyDown:(NSEvent *)e;
- (void)logDoubleClick:(NSString *)s;

- (void)createConnection:(NSString *)str chan:(NSString *)channel;

- (void)clearContentsOfClient:(IRCClient *)u;
- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u;

- (void)destroyAllEvidence;

- (void)updateReadinessState:(TVCLogController *)controller;

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel;
@end

#pragma mark -

@interface TKMessageBlockOperation : NSOperation
@property (nonatomic, weak) TVCLogController *controller;

+ (TKMessageBlockOperation *)operationWithBlock:(void(^)(void))block
								  forController:(TVCLogController *)controller
									withContext:(NSDictionary *)context;

+ (TKMessageBlockOperation *)operationWithBlock:(void(^)(void))block
								  forController:(TVCLogController *)controller;
@end