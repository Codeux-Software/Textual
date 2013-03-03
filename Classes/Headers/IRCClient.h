/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

#import "IRCTreeItem.h" // superclass

#import "TVCLogLine.h"			// typedef enum
#import "TLOGrowlController.h"	// typedef enum

typedef enum IRCConnectMode : NSInteger {
	IRCConnectNormalMode,
	IRCConnectRetryMode,
	IRCConnectReconnectMode,
	IRCConnectBadSSLCertificateMode,
} IRCConnectMode;

typedef enum IRCDisconnectMode : NSInteger {
	IRCDisconnectNormalMode,
	IRCDisconnectTrialPeriodMode,
	IRCDisconnectComputerSleepMode,
	IRCDisconnectBadSSLCertificateMode,
} IRCDisconnectMode;

@interface IRCClient : IRCTreeItem
/* Public information. They are considered read-only outside of
 IRCClient. Just not enforced. Play nice plugins. */

@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, strong) IRCISupportInfo *isupport;
@property (nonatomic, assign) IRCConnectMode connectType;
@property (nonatomic, assign) IRCDisconnectMode disconnectType;
@property (nonatomic, assign, setter=autoConnect:) NSInteger connectDelay;
@property (nonatomic, assign) BOOL autojoinInProgress;			// YES if autojoin is running, else NO.
@property (nonatomic, assign) BOOL hasIRCopAccess;				// YES if local user is IRCOp, else NO.
@property (nonatomic, assign) BOOL isAutojoined;				// YES if autojoin has been completed, else NO.
@property (nonatomic, assign) BOOL isAway;						// YES if Textual has knowledge of local user being away, else NO.
@property (nonatomic, assign) BOOL isConnected;					// YES if socket is connected, else NO.
@property (nonatomic, assign) BOOL isConnecting;				// YES if socket is connecting, else, NO. Set to NO on raw numeric 001.
@property (nonatomic, assign) BOOL isIdentifiedWithNickServ;	// YES if NickServ identification was successful, else NO.
@property (nonatomic, assign) BOOL isLoggedIn;					// YES if connected to server, else NO. Set to YES on raw numeric 001.
@property (nonatomic, assign) BOOL isQuitting;					// YES if connection to IRC server is being quit, else NO.
@property (nonatomic, assign) BOOL isWaitingForNickServ;		// YES if NickServ identification is pending, else NO.
@property (nonatomic, assign) BOOL rawModeEnabled;				// YES if sent & received data should be logged to console, else NO.
@property (nonatomic, assign) BOOL reconnectEnabled;			// YES if reconnection is allowed, else NO.
@property (nonatomic, assign) BOOL serverHasNickServ;			// YES if NickServ service was found on server, else NO.
@property (nonatomic, assign) BOOL CAPidentifyCTCP;				// YES if identify-ctcp CAP supported.
@property (nonatomic, assign) BOOL CAPidentifyMsg;				// YES if identify-msg CAP supported.
@property (nonatomic, assign) BOOL CAPinSASLRequest;			// YES if in SASL CAP authentication request, else NO.
@property (nonatomic, assign) BOOL CAPisIdentifiedWithSASL;		// YES if SASL authentication was successful, else NO.
@property (nonatomic, assign) BOOL CAPmultiPrefix;				// YES if multi-prefix CAP supported.
@property (nonatomic, assign) BOOL CAPuserhostInNames;			// YES if userhost-in-names CAP supported.
@property (nonatomic, strong) NSMutableArray *CAPacceptedCaps;
@property (nonatomic, strong) NSMutableArray *CAPpendingCaps;
@property (nonatomic, strong) IRCChannel *lastSelectedChannel;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *highlights;

- (void)setup:(id)seed;
- (void)updateConfig:(IRCClientConfig *)seed;
- (IRCClientConfig *)storedConfig;
- (NSMutableDictionary *)dictionaryValue;

- (NSString *)networkName; // Only returns the actual network name.
- (NSString *)altNetworkName; // Will return the configured name if the actual name is not available.
- (NSString *)networkAddress;

- (NSString *)localNickname;
- (NSString *)localHostmask;

- (void)autoConnect:(NSInteger)delay;

- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (BOOL)isReconnecting;

- (void)postEventToViewController:(NSString *)eventToken;
- (void)postEventToViewController:(NSString *)eventToken forChannel:(IRCChannel *)channel;

- (IRCAddressBook *)checkIgnoreAgainstHostmask:(NSString *)host withMatches:(NSArray *)matches;

- (BOOL)encryptOutgoingMessage:(NSString **)message channel:(IRCChannel *)channel;
- (void)decryptIncomingMessage:(NSString **)message channel:(IRCChannel *)channel;

- (BOOL)outputRuleMatchedInMessage:(NSString *)raw inChannel:(IRCChannel *)chan withLineType:(TVCLogLineType)type;

- (void)connect;
- (void)connect:(IRCConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString *)comment;
- (void)cancelReconnect;

- (void)sendNextCap;
- (void)pauseCap;
- (void)resumeCap;
- (BOOL)isCapAvailable:(NSString *)cap;
- (void)cap:(NSString *)cap result:(BOOL)supported;

- (void)joinChannel:(IRCChannel *)channel;
- (void)joinChannel:(IRCChannel *)channel password:(NSString *)password;
- (void)joinUnlistedChannel:(NSString *)channel;
- (void)joinUnlistedChannel:(NSString *)channel password:(NSString *)password;
- (void)forceJoinChannel:(NSString *)channel password:(NSString *)password;
- (void)partChannel:(IRCChannel *)channel;
- (void)partChannel:(IRCChannel *)channel withComment:(NSString *)comment;
- (void)partUnlistedChannel:(NSString *)channel;
- (void)partUnlistedChannel:(NSString *)channel withComment:(NSString *)comment;

- (void)sendWhois:(NSString *)nick;
- (void)changeNick:(NSString *)newNick;
- (void)kick:(IRCChannel *)channel target:(NSString *)nick;
- (void)sendCTCPQuery:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPReply:(NSString *)target command:(NSString *)command text:(NSString *)text;
- (void)sendCTCPPing:(NSString *)target;

- (void)toggleAwayStatus:(BOOL)setAway;

- (void)createChannelListDialog;
- (void)createChanBanListDialog;
- (void)createChanBanExceptionListDialog;
- (void)createChanInviteExceptionListDialog;

- (void)sendCommand:(id)str;
- (void)sendCommand:(id)str completeTarget:(BOOL)completeTarget target:(NSString *)targetChannelName;
- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel;
- (void)sendText:(NSAttributedString *)str command:(NSString *)command channel:(IRCChannel *)channel withEncryption:(BOOL)encryptChat;
- (void)inputText:(id)str command:(NSString *)command;

- (void)sendLine:(NSString *)str;
- (void)send:(NSString *)str, ...;

- (NSInteger)indexOfFirstPrivateMessage;

- (IRCChannel *)findChannel:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name;
- (IRCChannel *)findChannelOrCreate:(NSString *)name isPrivateMessage:(BOOL)isPM;

- (NSData *)convertToCommonEncoding:(NSString *)data;
- (NSString *)convertFromCommonEncoding:(NSData *)data;

- (NSString *)formatNick:(NSString *)nick channel:(IRCChannel *)channel;

- (void)sendPrivmsgToSelectedChannel:(NSString *)message;

- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype;
- (BOOL)notifyEvent:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text;
- (BOOL)notifyText:(TXNotificationType)type lineType:(TVCLogLineType)ltype target:(IRCChannel *)target nick:(NSString *)nick text:(NSString *)text;

- (void)populateISONTrackedUsersList:(NSMutableArray *)ignores;

#pragma mark -

- (BOOL)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text;
- (BOOL)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text receivedAt:(NSDate *)receivedAt;
- (BOOL)print:(id)chan type:(TVCLogLineType)type nick:(NSString *)nick text:(NSString *)text encrypted:(BOOL)isEncrypted receivedAt:(NSDate *)receivedAt;

- (void)printReply:(IRCMessage *)m;
- (void)printUnknownReply:(IRCMessage *)m;

- (void)printDebugInformation:(NSString *)m;
- (void)printDebugInformationToConsole:(NSString *)m;
- (void)printDebugInformation:(NSString *)m channel:(IRCChannel *)channel;

- (void)printError:(NSString *)error;
- (void)printErrorReply:(IRCMessage *)m;
- (void)printErrorReply:(IRCMessage *)m channel:(IRCChannel *)channel;
@end
