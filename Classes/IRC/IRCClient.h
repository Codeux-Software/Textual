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
	
	BOOL hasIRCopAccess;

	AddressDetectionType addressDetectionMethod;
	HostResolver* nameResolver;
	NSString* joinMyAddress;
	NSString* myAddress;

	Timer* pongTimer;
	Timer* quitTimer;
	Timer* reconnectTimer;
	Timer* retryTimer;
	Timer* autoJoinTimer;
	Timer* commandQueueTimer;
	NSMutableArray* commandQueue;

	IRCChannel* lastSelectedChannel;

	ChanBanSheet* chanBanListSheet;
	ListDialog* channelListDialog;
	ServerSheet* propertyDialog;

	FileLogger* logFile;
	NSString* logDate;

	IRCChannel* whoisChannel;
	
	NSMutableArray* trackedUsers;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) IRCISupportInfo* isupport;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, retain) NSMutableArray* trackedUsers;
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
@property (nonatomic) BOOL reconnectEnabled;
@property (nonatomic) BOOL retryEnabled;
@property (nonatomic) BOOL rawModeEnabled;
@property (nonatomic) BOOL isQuitting;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, retain) NSString* inputNick;
@property (nonatomic, retain) NSString* sentNick;
@property (nonatomic) NSInteger tryingNickNumber;
@property (nonatomic, retain) NSString* serverHostname;
@property (nonatomic) BOOL inList;
@property (nonatomic) BOOL inChanBanList;
@property (nonatomic) BOOL identifyMsg;
@property (nonatomic) BOOL identifyCTCP;
@property (nonatomic) BOOL hasIRCopAccess;
@property (nonatomic, retain) HostResolver* nameResolver;
@property (nonatomic, retain) NSString* joinMyAddress;
@property (nonatomic, retain) Timer* pongTimer;
@property (nonatomic, retain) Timer* quitTimer;
@property (nonatomic, retain) Timer* reconnectTimer;
@property (nonatomic, retain) Timer* retryTimer;
@property (nonatomic, retain) Timer* autoJoinTimer;
@property (nonatomic, retain) Timer* commandQueueTimer;
@property (nonatomic, retain) NSMutableArray* commandQueue;
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

- (void)connect;
- (void)connect:(ConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString*)comment;
- (void)cancelReconnect;

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

- (BOOL)inputText:(NSString*)s command:(NSString*)command;
- (void)sendText:(NSString*)s command:(NSString*)command channel:(IRCChannel*)channel;
- (BOOL)sendCommand:(NSString*)s;
- (BOOL)sendCommand:(NSString*)s completeTarget:(BOOL)completeTarget target:(NSString*)target;

- (void)sendLine:(NSString*)str;
- (void)send:(NSString*)str, ...;

- (IRCChannel*)findChannel:(NSString*)name;
- (NSInteger)indexOfTalkChannel;

- (void)createChannelListDialog;

- (void)sendPrivmsgToSelectedChannel:(NSString*)message;

- (BOOL)printRawHTMLToCurrentChannel:(NSString*)text;
- (BOOL)printRawHTMLToCurrentChannelWithoutTime:(NSString*)text ;
- (BOOL)printRawHTMLToCurrentChannel:(NSString*)text withTimestamp:(BOOL)showTime;

- (void)unloadUserCreatedBundles;
- (void)loadUserCreatedBundles;
@end