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

	IRCChannel *whoisChannel;
	
	NSMutableArray *trackedUsers;
}

@property (assign) IRCWorld* world;
@property (readonly) NSString* name;
@property (readonly) IRCClientConfig* config;
@property (readonly) IRCISupportInfo* isupport;
@property (readonly) NSMutableArray* channels;
@property (readonly) NSMutableArray *trackedUsers;
@property (readonly) BOOL isConnecting;
@property (readonly) BOOL isConnected;
@property (readonly) BOOL isReconnecting;
@property (readonly) BOOL isLoggedIn;
@property (readonly) NSString* myNick;
@property (readonly) NSString* myAddress;
@property (retain) IRCChannel* lastSelectedChannel;
@property (retain) ServerSheet* propertyDialog;
@property (retain) IRCConnection* conn;
@property (setter=autoConnect:, getter=connectDelay) NSInteger connectDelay;
@property BOOL reconnectEnabled;
@property BOOL retryEnabled;
@property BOOL rawModeEnabled;
@property BOOL isQuitting;
@property NSStringEncoding encoding;
@property (retain) NSString* inputNick;
@property (retain) NSString* sentNick;
@property NSInteger tryingNickNumber;
@property (retain) NSString* serverHostname;
@property BOOL inList;
@property BOOL inChanBanList;
@property BOOL identifyMsg;
@property BOOL identifyCTCP;
@property (retain) HostResolver* nameResolver;
@property (retain) NSString* joinMyAddress;
@property (retain) Timer* pongTimer;
@property (retain) Timer* quitTimer;
@property (retain) Timer* reconnectTimer;
@property (retain) Timer* retryTimer;
@property (retain) Timer* autoJoinTimer;
@property (retain) Timer* commandQueueTimer;
@property (retain) NSMutableArray* commandQueue;
@property (retain) ChanBanSheet* chanBanListSheet;
@property (retain) ListDialog* channelListDialog;
@property (retain) FileLogger* logFile;
@property (retain) NSString* logDate;
@property (retain) IRCChannel *whoisChannel;

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
@end