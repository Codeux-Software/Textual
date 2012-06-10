// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [s1.name.lowercaseString compare:s2.name.lowercaseString];
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
@synthesize outgoingFloodControl;
@synthesize floodControlMaximumMessages;
@synthesize floodControlDelayTimerInterval;

- (id)init
{
	if ((self = [super init])) {
		self.cuid = TXRandomNumber(9999);
		self.guid = [NSString stringWithUUID];
		
		self.ignores         = [NSMutableArray new];
		self.altNicks        = [NSMutableArray new];
		self.channels        = [NSMutableArray new];
		self.loginCommands   = [NSMutableArray new];
		
		self.host         = NSNullObject;
		self.port         = 6667;
		self.password     = NSNullObject;
		self.nickPassword = NSNullObject;
		
		self.proxyHost       = NSNullObject;
		self.proxyPort       = 1080;
		self.proxyUser       = NSNullObject;
		self.proxyPassword   = NSNullObject;
        
        self.prefersIPv6 = NO;
		
		self.encoding         = NSUTF8StringEncoding;
		self.fallbackEncoding = NSISOLatin1StringEncoding;
        
        self.outgoingFloodControl            = NO;
        self.floodControlMaximumMessages     = FLOOD_CONTROL_DEFAULT_MESSAGE_COUNT;
		self. floodControlDelayTimerInterval  = FLOOD_CONTROL_DEFAULT_DELAY_TIMER;
		
		self.name        = TXTLS(@"UNTITLED_CONNECTION_NAME");
		self.nick        = [Preferences defaultNickname];
		self.username    = [Preferences defaultUsername];
		self.realName    = [Preferences defaultRealname];
		
		self.leavingComment      = TXTLS(@"DEFAULT_QPS_MESSAGE");
		self.sleepQuitMessage    = TXTLS(@"SLEEPING_APPLICATION_QUIT_MESSAGE");
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
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]
										   withLegacySupport:NO];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:nickPassword] == NO) {
			nickPassword = nil;
			nickPassword = kcPassword;
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
							   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
			
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:self.host
									serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
		}
		
		nickPassword = nil;
		nickPassword = pass;
	}
}

- (NSString *)password
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(password)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
												withItemKind:@"application password" 
												 forUsername:nil 
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]
										   withLegacySupport:NO];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:password] == NO) {
			password = nil;
			password = kcPassword;
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
							   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];		
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:self.host
									serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];			
		}
		
		password = nil;
		password = pass;
	}
}

- (void)destroyKeychains
{	
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
	
	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		self.cuid = (([dic integerForKey:@"cuid"]) ?: self.cuid);
		
		if ([dic stringForKey:@"guid"]) {
			self.guid = [dic stringForKey:@"guid"];
		}
		
		if ([dic stringForKey:@"name"]) {
			self.name = [dic stringForKey:@"name"];
		}
		
		self.host = (([dic stringForKey:@"host"]) ?: NSNullObject);
		self.port = (([dic integerForKey:@"port"]) ?: 6667);
		
		if ([dic stringForKey:@"nick"]) {
			self.nick = [dic stringForKey:@"nick"];
		}
		
		self.useSSL = [dic boolForKey:@"ssl"];
		
		if ([dic stringForKey:@"username"]) {
			self.username = [dic stringForKey:@"username"];
		}
		
		if ([dic stringForKey:@"realname"]) {
			self.realName = [dic stringForKey:@"realname"];
		}
		
		[self.altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];
		
		self.proxyType       = (ProxyType)[dic integerForKey:@"proxy"];
		self.proxyPort       = (([dic integerForKey:@"proxy_port"]) ?: 1080);
		self.proxyHost       = (([dic stringForKey:@"proxy_host"]) ?: NSNullObject);
		self.proxyUser       = (([dic stringForKey:@"proxy_user"]) ?: NSNullObject);
		self.proxyPassword   = (([dic stringForKey:@"proxy_password"]) ?: NSNullObject);
		
		self.autoConnect         = [dic boolForKey:@"auto_connect"];
		self.autoReconnect       = [dic boolForKey:@"auto_reconnect"];
		self.bouncerMode         = [dic boolForKey:@"bouncer_mode"];
		self.encoding            = (([dic integerForKey:@"encoding"]) ?: NSUTF8StringEncoding);
		self.fallbackEncoding    = (([dic integerForKey:@"fallback_encoding"]) ?: NSISOLatin1StringEncoding);
		
		if ([dic stringForKey:@"leaving_comment"]) {
			self.leavingComment = [dic stringForKey:@"leaving_comment"];
		}
		
		if ([dic stringForKey:@"sleep_quit_message"]) {
			self.sleepQuitMessage = [dic stringForKey:@"sleep_quit_message"];
		}
		
		self.prefersIPv6         = [dic boolForKey:@"prefersIPv6"];
		self.invisibleMode       = [dic boolForKey:@"invisible"];
		self.isTrustedConnection = [dic boolForKey:@"trustedConnection"];
		
		[self.loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
		
		for (NSDictionary *e in [dic arrayForKey:@"channels"]) {
			IRCChannelConfig *c;
			
			c = [IRCChannelConfig alloc];
			c = [c initWithDictionary:e];
			c = c;
			
			[self.channels safeAddObject:c];
		}
		
		for (NSDictionary *e in [dic arrayForKey:@"ignores"]) {
			AddressBook *ignore;
			
			ignore = [AddressBook alloc];
			ignore = [ignore initWithDictionary:e];
			ignore = ignore;
			
			[self.ignores safeAddObject:ignore];
		}
		
		if ([dic containsKey:@"flood_control"]) {
			NSDictionary *e = [dic dictionaryForKey:@"flood_control"];
			
			if (NSObjectIsNotEmpty(e)) {
				self.outgoingFloodControl           = [e boolForKey:@"outgoing"];
				
				self.floodControlMaximumMessages    = (([e integerForKey:@"message_count"]) ?: FLOOD_CONTROL_DEFAULT_MESSAGE_COUNT);
				self.floodControlDelayTimerInterval = (([e integerForKey:@"delay_timer"]) ?: FLOOD_CONTROL_DEFAULT_DELAY_TIMER);
			}
		} else {
			if ([self.host hasSuffix:@"freenode.net"]) {
				self.outgoingFloodControl = YES;
			}
		}
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.port				forKey:@"port"];
	[dic setInteger:self.proxyType			forKey:@"proxy"];
	[dic setInteger:self.proxyPort			forKey:@"proxy_port"];
	[dic setInteger:self.encoding			forKey:@"encoding"];
	[dic setInteger:self.fallbackEncoding	forKey:@"fallback_encoding"];
	
	[dic setBool:self.useSSL				forKey:@"ssl"];
    [dic setBool:self.prefersIPv6			forKey:@"prefersIPv6"];
	[dic setBool:self.autoConnect			forKey:@"auto_connect"];
	[dic setBool:self.autoReconnect			forKey:@"auto_reconnect"];
	[dic setBool:self.bouncerMode			forKey:@"bouncer_mode"];
	[dic setBool:self.invisibleMode			forKey:@"invisible"];
	[dic setBool:self.isTrustedConnection	forKey:@"trustedConnection"];
	
	if (self.cuid)				[dic setInteger:self.cuid				forKey:@"cuid"];
	
	if (self.guid)				[dic setObject:self.guid				forKey:@"guid"];
	if (self.name)				[dic setObject:self.name				forKey:@"name"];
	if (self.host)				[dic setObject:self.host				forKey:@"host"];
	if (self.nick)				[dic setObject:self.nick				forKey:@"nick"];
	if (self.username)			[dic setObject:self.username			forKey:@"username"];
	if (self.realName)			[dic setObject:self.realName			forKey:@"realname"];
	if (self.altNicks)			[dic setObject:self.altNicks			forKey:@"alt_nicks"];
	if (self.proxyHost)			[dic setObject:self.proxyHost			forKey:@"proxy_host"];
	if (self.proxyUser)			[dic setObject:self.proxyUser			forKey:@"proxy_user"];
	if (self.proxyPassword)		[dic setObject:self.proxyPassword		forKey:@"proxy_password"];
	if (self.leavingComment)	[dic setObject:self.leavingComment		forKey:@"leaving_comment"];
	if (self.sleepQuitMessage)	[dic setObject:self.sleepQuitMessage	forKey:@"sleep_quit_message"];
	if (self.loginCommands)		[dic setObject:self.loginCommands		forKey:@"login_commands"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:self.floodControlDelayTimerInterval	forKey:@"delay_timer"];
    [floodControl setInteger:self.floodControlMaximumMessages		forKey:@"message_count"];
	
    [floodControl setBool:self.outgoingFloodControl forKey:@"outgoing"];
    
    [dic setObject:floodControl forKey:@"flood_control"];
	
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channels) {
		[channelAry safeAddObject:[e dictionaryValue]];
	}
	
	for (AddressBook *e in self.ignores) {
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