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
@synthesize userInfo;
@synthesize username;
@synthesize useSSL;

- (id)init
{
	if ((self = [super init])) {
		cuid = TXRandomThousandNumber();
		guid = [[NSString stringWithUUID] retain];
		
		ignores = [NSMutableArray new];
		altNicks = [NSMutableArray new];
		channels = [NSMutableArray new];
		loginCommands = [NSMutableArray new];
		
		host = @"";
		port = 6667;
		password = [@"" retain];
		nickPassword = [@"" retain];
		
		proxyHost = @"";
		proxyPort = 1080;
		proxyUser = @"";
		proxyPassword = @"";
		
		encoding = NSUTF8StringEncoding;
		fallbackEncoding = NSISOLatin1StringEncoding;
		
		userInfo = @"";
		
		name = [TXTLS(@"UNTITLED_CONNECTION_NAME") retain];
		nick = [[Preferences defaultNickname] retain];
		username = [[Preferences defaultUsername] retain];
		realName = [[Preferences defaultRealname] retain];
		
		leavingComment = [TXTLS(@"DEFAULT_QPS_MESSAGE") retain];
		sleepQuitMessage = [TXTLS(@"SLEEPING_APPLICATION_QUIT_MESSAGE") retain];
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
		
		if ([Preferences isUpgradedFromVersion100] == YES) {
			if (NSObjectIsEmpty(kcPassword)) { 
				kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual Keychain (NickServ)"
														withItemKind:@"application password" 
														 forUsername:nil 
														 serviceName:[NSString stringWithFormat:@"textual.clients.cuid.%i", cuid]
												   withLegacySupport:YES];
			}
		}
	}
	
	if (kcPassword) {
		if ([Preferences isUpgradedFromVersion100] == YES) {
			[self setNickPassword:kcPassword];
		} else {
			if ([kcPassword isEqualToString:nickPassword] == NO) {
				[nickPassword release];
				nickPassword = nil;
				
				nickPassword = [kcPassword retain];
			}
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
		
		[nickPassword release];
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
		
		if ([Preferences isUpgradedFromVersion100] == YES) {
			if (NSObjectIsEmpty(kcPassword)) { 
				kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual Keychain (Server Password)"
														withItemKind:@"application password" 
														 forUsername:nil
														 serviceName:[NSString stringWithFormat:@"textual.clients.cuid.%i", cuid]
												   withLegacySupport:YES];
			}
		}
	}
	
	if (kcPassword) {
		if ([Preferences isUpgradedFromVersion100] == YES) {
			[self setPassword:kcPassword];
		} else {
			if ([kcPassword isEqualToString:password] == NO) {
				[password release];
				password = nil;
				
				password = [kcPassword retain];
			}
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
		
		[password release];
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
	
	cuid = (([dic intForKey:@"cuid"]) ?: cuid);
	
	if ([dic stringForKey:@"guid"]) {
		[guid release];
		guid = [[dic stringForKey:@"guid"] retain];
	}
	
	if ([dic stringForKey:@"name"]) {
		[name release];
		name = [[dic stringForKey:@"name"] retain];
	}
	
	host = (([[dic stringForKey:@"host"] retain]) ?: @"");
	port = (([dic intForKey:@"port"]) ?: 6667);
	
	if ([dic stringForKey:@"nick"]) {
		[nick release];
		nick = [[dic stringForKey:@"nick"] retain];
	}
	
	useSSL = [dic boolForKey:@"ssl"];
	
	if ([dic stringForKey:@"username"]) {
		[username release];
		username = [[dic stringForKey:@"username"] retain];
	}
	
	if ([dic stringForKey:@"realname"]) {
		[realName release];
		realName = [[dic stringForKey:@"realname"] retain];
	}
	
	[altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];
	
	proxyType = [dic intForKey:@"proxy"];
	proxyHost = (([[dic stringForKey:@"proxy_host"] retain]) ?: @"");
	proxyPort = (([dic intForKey:@"proxy_port"]) ?: 1080);
	proxyUser = (([[dic stringForKey:@"proxy_user"] retain]) ?: @"");
	proxyPassword = (([[dic stringForKey:@"proxy_password"] retain]) ?: @"");
	
	autoConnect = [dic boolForKey:@"auto_connect"];
	autoReconnect = [dic boolForKey:@"auto_reconnect"];
	bouncerMode = [dic boolForKey:@"bouncer_mode"];
	encoding = (([dic intForKey:@"encoding"]) ?: NSUTF8StringEncoding);
	fallbackEncoding = (([dic intForKey:@"fallback_encoding"]) ?: NSISOLatin1StringEncoding);
	
	if ([dic stringForKey:@"leaving_comment"]) {
		[leavingComment release];
		leavingComment = [[dic stringForKey:@"leaving_comment"] retain];
	}
	
	if ([dic stringForKey:@"sleep_quit_message"]) {
		[sleepQuitMessage release];
		sleepQuitMessage = [[dic stringForKey:@"sleep_quit_message"] retain];
	}
	
	userInfo = (([[dic stringForKey:@"userinfo"] retain]) ?: @"");
	invisibleMode = [dic boolForKey:@"invisible"];
	
	isTrustedConnection = [dic boolForKey:@"trustedConnection"];
	
	[loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
	
	for (NSDictionary *e in [dic arrayForKey:@"channels"]) {
		IRCChannelConfig *c = [[[IRCChannelConfig alloc] initWithDictionary:e] autorelease];
		
		[channels addObject:c];
	}
	
	for (NSDictionary *e in [dic arrayForKey:@"ignores"]) {
		AddressBook *ignore = [[[AddressBook alloc] initWithDictionary:e] autorelease];
		
		[ignores addObject:ignore];
	}
	
	return self;
}

- (void)dealloc
{
	[altNicks release];
	[channels release];
	[guid release];
	[host release];
	[ignores release];
	[leavingComment release];
	[loginCommands release];
	[name release];
	[network release];
	[nickPassword release];
	[nick release];
	[password release];
	[proxyHost release];
	[proxyPassword release];
	[proxyUser release];
	[realName release];
	[server release];
	[sleepQuitMessage release];
	[userInfo release];
	[username release];	
	
	[super dealloc];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInt:port forKey:@"port"];
	[dic setInt:proxyType forKey:@"proxy"];
	[dic setInt:proxyPort forKey:@"proxy_port"];
	[dic setInt:encoding forKey:@"encoding"];
	[dic setInt:fallbackEncoding forKey:@"fallback_encoding"];
	
	[dic setBool:useSSL forKey:@"ssl"];
	[dic setBool:autoConnect forKey:@"auto_connect"];
	[dic setBool:autoReconnect forKey:@"auto_reconnect"];
	[dic setBool:bouncerMode forKey:@"bouncer_mode"];
	[dic setBool:invisibleMode forKey:@"invisible"];
	[dic setBool:isTrustedConnection forKey:@"trustedConnection"];
	
	if (cuid) [dic setInt:cuid forKey:@"cuid"];
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
	if (userInfo) [dic setObject:userInfo forKey:@"userinfo"];
	if (altNicks) [dic setObject:loginCommands forKey:@"login_commands"];
	
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in channels) {
		[channelAry addObject:[e dictionaryValue]];
	}
	
	for (AddressBook *e in ignores) {
		[ignoreAry addObject:[e dictionaryValue]];
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