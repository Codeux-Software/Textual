// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCClientConfig.h"
#import "IRCChannel.h"
#import "IRCConnection.h"
#import "IRCISupportInfo.h"
#import "Preferences.h"
#import "LogController.h"
#import "ServerSheet.h"
#import "ListDialog.h"
#import "Timer.h"
#import "HostResolver.h"
#import "FileLogger.h"
#import "ChanBanSheet.h"
#import "ChanBanExceptionSheet.h"
#import "IRCMessage.h"
#import "LogLine.h"

@class IRCWorld;

typedef enum {
	CONNECT_NORMAL,
	CONNECT_RECONNECT,
	CONNECT_RETRY,
} ConnectMode;

@interface IRCClient : IRCTreeItem
{
	IRCWorld* world;
	IRCClientConfig* config;

	NSMutableArray* channels;
	IRCISupportInfo* isupport;

	IRCConnection* conn;
	NSInteger connectDelay;
	BOOL reconnectEnabled;
	BOOL retryEnabled;

	BOOL rawModeEnabled;

	BOOL isConnecting;
	BOOL isConnected;
	BOOL isLoggedIn;
	BOOL isQuitting;
	NSStringEncoding encoding;

	NSString* inputNick;
	NSString* sentNick;
	NSString* myNick;
	NSInteger tryingNickNumber;

	NSString* serverHostname;
	BOOL inList;
	BOOL identifyMsg;
	BOOL identifyCTCP;
	BOOL inChanBanList;
	BOOL inWhoWasRequest;
	BOOL hasIRCopAccess;
	BOOL inFirstISONRun;
	
	AddressDetectionType addressDetectionMethod;
	NSString* myAddress;

	Timer* pongTimer;
	Timer* reconnectTimer;
	Timer* retryTimer;
	Timer* isonTimer;
	Timer* autoJoinTimer;
	Timer* commandQueueTimer;
	NSMutableArray* commandQueue;

	IRCChannel* lastSelectedChannel;

	ChanBanExceptionSheet* banExceptionSheet;
	ChanBanSheet* chanBanListSheet;
	ListDialog* channelListDialog;
	ServerSheet* propertyDialog;

	FileLogger* logFile;
	NSString* logDate;

	IRCChannel* whoisChannel;
	
	NSMutableDictionary* trackedUsers;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) IRCISupportInfo* isupport;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, retain) NSMutableDictionary *trackedUsers;
@property (nonatomic, readonly) BOOL isConnecting;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isReconnecting;
@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic, readonly) NSString* myNick;
@property (nonatomic, readonly) NSString* myAddress;
@property (nonatomic, retain) IRCChannel* lastSelectedChannel;
@property (nonatomic, retain) ServerSheet* propertyDialog;
@property (nonatomic, retain) IRCConnection* conn;
@property (nonatomic, setter=autoConnect:, getter=connectDelay) NSInteger connectDelay;
@property (nonatomic, assign) BOOL reconnectEnabled;
@property (nonatomic, assign) BOOL retryEnabled;
@property (nonatomic, assign) BOOL rawModeEnabled;
@property (nonatomic, assign) BOOL isQuitting;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, retain) NSString* inputNick;
@property (nonatomic, retain) NSString* sentNick;
@property (nonatomic) NSInteger tryingNickNumber;
@property (nonatomic, retain) NSString* serverHostname;
@property (nonatomic, assign) BOOL inList;
@property (nonatomic, assign) BOOL inChanBanList;
@property (nonatomic, assign) BOOL identifyMsg;
@property (nonatomic, assign) BOOL identifyCTCP;
@property (nonatomic, assign) BOOL hasIRCopAccess;
@property (nonatomic, assign) BOOL inFirstISONRun;
@property (nonatomic, assign) BOOL inWhoWasRequest;
@property (nonatomic, retain) Timer* pongTimer;
@property (nonatomic, retain) Timer* reconnectTimer;
@property (nonatomic, retain) Timer* retryTimer;
@property (nonatomic, retain) Timer* isonTimer;
@property (nonatomic, retain) Timer* autoJoinTimer;
@property (nonatomic, retain) Timer* commandQueueTimer;
@property (nonatomic, retain) NSMutableArray* commandQueue;
@property (nonatomic, retain) ChanBanExceptionSheet* banExceptionSheet;
@property (nonatomic, retain) ChanBanSheet* chanBanListSheet;
@property (nonatomic, retain) ListDialog* channelListDialog;
@property (nonatomic, retain) FileLogger* logFile;
@property (nonatomic, retain) NSString* logDate;
@property (nonatomic, retain) IRCChannel *whoisChannel;

- (void)setup:(IRCClientConfig*)seed;
- (void)updateConfig:(IRCClientConfig*)seed;
- (IRCClientConfig*)storedConfig;
- (NSMutableDictionary*)dictionaryValue;

- (void)autoConnect:(NSInteger)delay;
- (void)onTimer;
- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (AddressBook*)checkIgnore:(NSString *)hostmask 
					  uname:(NSString *)username 
					   name:(NSString *)nickname
			   matchAgainst:(NSArray *)matches;

- (AddressBook*)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches;

- (void)connect;
- (void)connect:(ConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString*)comment;
- (void)cancelReconnect;

- (BOOL)IRCopStatus;

- (void)changeNick:(NSString*)newNick;
- (void)joinChannel:(IRCChannel*)channel;
- (void)joinChannel:(IRCChannel*)channel password:(NSString*)password;
- (void)partChannel:(IRCChannel*)channel;
- (void)sendWhois:(NSString*)nick;
- (void)changeOp:(IRCChannel*)channel users:(NSArray*)users mode:(char)mode value:(BOOL)value;
- (void)kick:(IRCChannel*)channel target:(NSString*)nick;
- (void)sendFile:(NSString*)nick port:(NSInteger)port fileName:(NSString*)fileName size:(long long)size;
- (void)sendCTCPQuery:(NSString*)target command:(NSString*)command text:(NSString*)text;
- (void)sendCTCPReply:(NSString*)target command:(NSString*)command text:(NSString*)text;
- (void)sendCTCPPing:(NSString*)target;

- (void)createChanBanListDialog;
- (void)createChanBanExceptionListDialog;

- (BOOL)inputText:(NSString*)s command:(NSString*)command;
- (void)sendText:(NSString*)s command:(NSString*)command channel:(IRCChannel*)channel;
- (BOOL)sendCommand:(NSString*)s;
- (BOOL)sendCommand:(NSString*)s completeTarget:(BOOL)completeTarget target:(NSString*)target;

- (void)sendLine:(NSString*)str;
- (void)send:(NSString*)str, ...;

- (NSInteger)indexOfTalkChannel;

- (IRCChannel*)findChannel:(NSString*)name;
- (IRCChannel*)findChannelOrCreate:(NSString*)name;
- (IRCChannel*)findChannelOrCreate:(NSString*)name useTalk:(BOOL)doTalk;

- (void)createChannelListDialog;

- (void)sendPrivmsgToSelectedChannel:(NSString*)message;

- (BOOL)printRawHTMLToCurrentChannel:(NSString*)text;
- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString*)text ;
- (BOOL)printRawHTMLToCurrentChannel:(NSString*)text withTimestamp:(BOOL)showTime;

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type text:(NSString*)text;
- (BOOL)printAndLog:(LogLine*)line withHTML:(BOOL)rawHTML;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (void)printSystem:(id)channel text:(NSString*)text;
- (void)printSystemBoth:(id)channel text:(NSString*)text;
- (void)printReply:(IRCMessage*)m;
- (void)printUnknownReply:(IRCMessage*)m;
- (void)printErrorReply:(IRCMessage*)m;
- (void)printErrorReply:(IRCMessage*)m channel:(IRCChannel*)channel;
- (void)printError:(NSString*)error;

- (void)notifyText:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text;
- (void)notifyEvent:(GrowlNotificationType)type;
- (void)notifyEvent:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text;

- (void)joinChannels:(NSArray*)chans;

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores;
@end