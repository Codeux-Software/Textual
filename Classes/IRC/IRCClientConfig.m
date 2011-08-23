// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [[s1.name lowercaseString] compare:[s2.name lowercaseString]];
}

@implementation IRCClientConfig

@synthesize altNicks;
@synthesize autoConnect;
@synthesize autoReconnect;
@synthesize bouncerMode;
@synthesize channels;
@synthesize cuid;
@synthesize encoding;
@synthesize fallbackEncoding;
@synthesize guid;
@synthesize host;
@synthesize ignores;
@synthesize prefersIPv6;
@synthesize invisibleMode;
@synthesize isTrustedConnection;
@synthesize leavingComment;
@synthesize loginCommands;
@synthesize name;
@synthesize network;
@synthesize nick;
@synthesize nickPassword;
@synthesize password;
@synthesize port;
@synthesize pongInterval;
@synthesize timeoutInterval;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyType;
@synthesize proxyUser;
@synthesize realName;
@synthesize server;
@synthesize sleepQuitMessage;
@synthesize username;
@synthesize useSSL;
@synthesize useSASL;
@synthesize outgoingFloodControl;
@synthesize incomingFloodControl;
@synthesize floodControlMaximumMessages;
@synthesize floodControlDelayTimerInterval;

- (id)init
{
	if ((self = [super init])) {
		cuid = TXRandomNumber(9999);
		guid = [NSString stringWithUUID].retain;
		
		ignores         = [NSMutableArray new];
		altNicks        = [NSMutableArray new];
		channels        = [NSMutableArray new];
		loginCommands   = [NSMutableArray new];
		
		host         = NSNullObject;
		port         = 6667;
		password     = [NSNullObject retain];
		nickPassword = [NSNullObject retain];
		
		proxyHost       = NSNullObject;
		proxyPort       = 1080;
		proxyUser       = NSNullObject;
		proxyPassword   = NSNullObject;
        
        pongInterval = 0;
        timeoutInterval = 0;
        
        prefersIPv6 = NO;
		
		encoding         = NSUTF8StringEncoding;
		fallbackEncoding = NSISOLatin1StringEncoding;
        
        incomingFloodControl            = NO;
        outgoingFloodControl            = NO;
        floodControlMaximumMessages     = FLOOD_CONTROL_DEFAULT_MESSAGE_COUNT;
        floodControlDelayTimerInterval  = FLOOD_CONTROL_DEFAULT_DELAY_TIMER;
		
		name        = TXTLS(@"UNTITLED_CONNECTION_NAME").retain;
		nick        = [Preferences defaultNickname].retain;
		username    = [Preferences defaultUsername].retain;
		realName    = [Preferences defaultRealname].retain;
		
		leavingComment      = TXTLS(@"DEFAULT_QPS_MESSAGE").retain;
		sleepQuitMessage    = TXTLS(@"SLEEPING_APPLICATION_QUIT_MESSAGE").retain;
	}
	
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)nickPassword
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(nickPassword)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
												withItemKind:@"application password" 
												 forUsername:nil 
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]
										   withLegacySupport:NO];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:nickPassword] == NO) {
			[nickPassword drain];
			nickPassword = nil;
			
			nickPassword = [kcPassword retain];
		}
	}
	
	return nickPassword;
}

- (void)setNickPassword:(NSString *)pass
{
	if ([nickPassword isEqualToString:pass] == NO) {	
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
			
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:host
									serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
		}
		
		[nickPassword drain];
		nickPassword = nil;
		
		nickPassword = [pass retain];
	}
}

- (NSString *)password
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(password)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
												withItemKind:@"application password" 
												 forUsername:nil 
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]
										   withLegacySupport:NO];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:password] == NO) {
			[password drain];
			password = nil;
			
			password = [kcPassword retain];
		}
	}
	
	return password;
}

- (void)setPassword:(NSString *)pass
{
	if ([password isEqualToString:pass] == NO) {
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];		
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:host
									serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];			
		}
		
		[password drain];
		password = nil;
		
		password = [pass retain];
	}
}

- (void)destroyKeychains
{	
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];
	
	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	[self init];	
	
	cuid = (([dic integerForKey:@"cuid"]) ?: cuid);
	
	if ([dic stringForKey:@"guid"]) {
		[guid drain];
		guid = [dic stringForKey:@"guid"].retain;
	}
	
	if ([dic stringForKey:@"name"]) {
		[name drain];
		name = [dic stringForKey:@"name"].retain;
	}
	
	host = (([dic stringForKey:@"host"].retain) ?: NSNullObject);
	port = (([dic integerForKey:@"port"]) ?: 6667);
    
	
	if ([dic stringForKey:@"nick"]) {
		[nick drain];
		nick = [dic stringForKey:@"nick"].retain;
	}
	
	useSSL  = [dic boolForKey:@"ssl"];
    useSASL = [dic boolForKey:@"sasl"];
	
	if ([dic stringForKey:@"username"]) {
		[username drain];
		username = [dic stringForKey:@"username"].retain;
	}
	
	if ([dic stringForKey:@"realname"]) {
		[realName drain];
		realName = [dic stringForKey:@"realname"].retain;
	}
	
	[altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];
	
	proxyType       = [dic integerForKey:@"proxy"];
	proxyPort       = (([dic integerForKey:@"proxy_port"]) ?: 1080);
	proxyHost       = (([dic stringForKey:@"proxy_host"].retain) ?: NSNullObject);
	proxyUser       = (([dic stringForKey:@"proxy_user"].retain) ?: NSNullObject);
	proxyPassword   = (([dic stringForKey:@"proxy_password"].retain) ?: NSNullObject);
	
	autoConnect         = [dic boolForKey:@"auto_connect"];
	autoReconnect       = [dic boolForKey:@"auto_reconnect"];
	bouncerMode         = [dic boolForKey:@"bouncer_mode"];
	encoding            = (([dic integerForKey:@"encoding"]) ?: NSUTF8StringEncoding);
	fallbackEncoding    = (([dic integerForKey:@"fallback_encoding"]) ?: NSISOLatin1StringEncoding);
	
    pongInterval    = [dic integerForKey:@"pong_interval"];
    timeoutInterval = [dic integerForKey:@"timeout_interval"];
    
	if ([dic stringForKey:@"leaving_comment"]) {
		[leavingComment drain];
		leavingComment = [dic stringForKey:@"leaving_comment"].retain;
	}
	
	if ([dic stringForKey:@"sleep_quit_message"]) {
		[sleepQuitMessage drain];
		sleepQuitMessage = [dic stringForKey:@"sleep_quit_message"].retain;
	}
	
    prefersIPv6         = [dic boolForKey:@"prefersIPv6"];
	invisibleMode       = [dic boolForKey:@"invisible"];
	isTrustedConnection = [dic boolForKey:@"trustedConnection"];
	
	[loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
	
	for (NSDictionary *e in [dic arrayForKey:@"channels"]) {
        IRCChannelConfig *c;
        
        c = [IRCChannelConfig alloc];
        c = [c initWithDictionary:e];
        c = [c autodrain];
		
		[channels safeAddObject:c];
	}
	
	for (NSDictionary *e in [dic arrayForKey:@"ignores"]) {
        AddressBook *ignore;
        
        ignore = [AddressBook alloc];
        ignore = [ignore initWithDictionary:e];
        ignore = [ignore autodrain];
		
		[ignores safeAddObject:ignore];
	}
    
    NSDictionary *e = [dic dictionaryForKey:@"flood_control"];
    
    if (NSObjectIsNotEmpty(e)) {
        floodControlMaximumMessages    = (([e integerForKey:@"message_count"]) ?: FLOOD_CONTROL_DEFAULT_MESSAGE_COUNT);
        floodControlDelayTimerInterval = (([e integerForKey:@"delay_timer"]) ?: FLOOD_CONTROL_DEFAULT_DELAY_TIMER);
        outgoingFloodControl           = [e boolForKey:@"outgoing"];
        incomingFloodControl           = [e boolForKey:@"incoming"];
    }
	
	return self;
}

- (void)dealloc
{
	[altNicks drain];
	[channels drain];
	[guid drain];
	[host drain];
	[ignores drain];
	[leavingComment drain];
	[loginCommands drain];
	[name drain];
	[network drain];
	[nickPassword drain];
	[nick drain];
	[password drain];
	[proxyHost drain];
	[proxyPassword drain];
	[proxyUser drain];
	[realName drain];
	[server drain];
	[sleepQuitMessage drain];
	[username drain];	
	
	[super dealloc];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:port forKey:@"port"];
	[dic setInteger:proxyType forKey:@"proxy"];
	[dic setInteger:proxyPort forKey:@"proxy_port"];
	[dic setInteger:encoding forKey:@"encoding"];
    [dic setInteger:pongInterval forKey:@"pong_interval"];
    [dic setInteger:timeoutInterval forKey:@"timeout_interval"];
	[dic setInteger:fallbackEncoding forKey:@"fallback_encoding"];
	
	[dic setBool:useSSL forKey:@"ssl"];
    [dic setBool:useSASL forKey:@"sasl"];
    [dic setBool:prefersIPv6 forKey:@"prefersIPv6"];
	[dic setBool:autoConnect forKey:@"auto_connect"];
	[dic setBool:autoReconnect forKey:@"auto_reconnect"];
	[dic setBool:bouncerMode forKey:@"bouncer_mode"];
	[dic setBool:invisibleMode forKey:@"invisible"];
	[dic setBool:isTrustedConnection forKey:@"trustedConnection"];
	
	if (cuid) [dic setInteger:cuid forKey:@"cuid"];
	if (guid) [dic setObject:guid forKey:@"guid"];
	if (name) [dic setObject:name forKey:@"name"];
	if (host) [dic setObject:host forKey:@"host"];
	if (nick) [dic setObject:nick forKey:@"nick"];
	if (username) [dic setObject:username forKey:@"username"];
	if (realName) [dic setObject:realName forKey:@"realname"];
	if (altNicks) [dic setObject:altNicks forKey:@"alt_nicks"];
	if (proxyHost) [dic setObject:proxyHost forKey:@"proxy_host"];
	if (proxyUser) [dic setObject:proxyUser forKey:@"proxy_user"];
	if (proxyPassword) [dic setObject:proxyPassword forKey:@"proxy_password"];
	if (leavingComment) [dic setObject:leavingComment forKey:@"leaving_comment"];
	if (sleepQuitMessage) [dic setObject:sleepQuitMessage forKey:@"sleep_quit_message"];
	if (altNicks) [dic setObject:loginCommands forKey:@"login_commands"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:floodControlDelayTimerInterval forKey:@"delay_timer"];
    [floodControl setInteger:floodControlMaximumMessages forKey:@"message_count"];
    [floodControl setBool:outgoingFloodControl forKey:@"outgoing"];
    [floodControl setBool:incomingFloodControl forKey:@"incoming"];
    
    [dic setObject:floodControl forKey:@"flood_control"];
	
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in channels) {
		[channelAry safeAddObject:[e dictionaryValue]];
	}
	
	for (AddressBook *e in ignores) {
		[ignoreAry safeAddObject:[e dictionaryValue]];
	}
	
	[dic setObject:channelAry forKey:@"channels"];
	[dic setObject:ignoreAry forKey:@"ignores"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end