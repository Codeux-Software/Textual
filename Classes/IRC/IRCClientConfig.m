// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "IRCChannel.h"
#import "AddressBook.h"
#import "NSDictionaryHelper.h"
#import "Preferences.h"
#import "AGKeychain.h"
#import "IRCWorld.h"

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [[s1.name lowercaseString] compare:[s2.name lowercaseString]];
}

@implementation IRCClientConfig

@synthesize name;
@synthesize host;
@synthesize port;
@synthesize useSSL;
@synthesize nick;
@synthesize password;
@synthesize username;
@synthesize realName;
@synthesize nickPassword;
@synthesize altNicks;
@synthesize proxyType;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;
@synthesize autoConnect;
@synthesize autoReconnect;
@synthesize encoding;
@synthesize fallbackEncoding;
@synthesize leavingComment;
@synthesize userInfo;
@synthesize invisibleMode;
@synthesize loginCommands;
@synthesize channels;
@synthesize ignores;
@synthesize cuid;

- (id)init
{
	if (self = [super init]) {
		cuid = TXRandomThousandNumber();
		altNicks = [NSMutableArray new];
		loginCommands = [NSMutableArray new];
		channels = [NSMutableArray new];
		ignores = [NSMutableArray new];
		
		host = @"";
		port = 6667;
		password = @"";
		nickPassword = @"";
		
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
	}
	
	return self;
}

- (NSString*)keychainServiceID
{
	return [NSString stringWithFormat:@"textual.clients.cuid.%i", cuid];
}

- (NSString*)keychainServiceName:(NSInteger)type
{
	if (type == 1) {
		return @"Textual Keychain (Server Password)";
	} else {
		return @"Textual Keychain (NickServ)";
	}
}

- (void)destroyKeychains
{
	[AGKeychain deleteKeychainItem:[self keychainServiceName:1]
					  withItemKind:@"application password"
						forUsername:nil
					   serviceName:[self keychainServiceID]];
	
	[AGKeychain deleteKeychainItem:[self keychainServiceName:2]
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[self keychainServiceID]];
}

- (void)verifyKeychainsExistsOrAdd
{
	if ([AGKeychain checkForExistanceOfKeychainItem:[self keychainServiceName:1]
									   withItemKind:@"application password" 
										forUsername:nil
										serviceName:[self keychainServiceID]] == NO) {
		[AGKeychain addKeychainItem:[self keychainServiceName:1]
					   withItemKind:@"application password"
						forUsername:nil
					   withPassword:@""
						serviceName:[self keychainServiceID]];
	} 
	
	if ([AGKeychain checkForExistanceOfKeychainItem:[self keychainServiceName:2]
									   withItemKind:@"application password" 
										forUsername:nil
										serviceName:[self keychainServiceID]] == NO) {
		[AGKeychain addKeychainItem:[self keychainServiceName:2]
					   withItemKind:@"application password"
						forUsername:nil
					   withPassword:@""
						serviceName:[self keychainServiceID]];
	}
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	[self init];	
	
	cuid = [dic intForKey:@"cuid"] ?: cuid;
	
	if ([dic stringForKey:@"name"]) {
		[name release];
		name = [[dic stringForKey:@"name"] retain];
	}
	
	host = [[dic stringForKey:@"host"] retain] ?: @"";
	port = [dic intForKey:@"port"] ?: 6667;
	
	if ([dic stringForKey:@"nick"]) {
		[nick release];
		nick = [[dic stringForKey:@"nick"] retain];
	}
	
	// * =================================== * //
	
	[self verifyKeychainsExistsOrAdd];
	
	password = [[AGKeychain getPasswordFromKeychainItem:[self keychainServiceName:1]
										   withItemKind:@"application password" 
											forUsername:nil
											serviceName:[self keychainServiceID]] retain];
	
	nickPassword = [[AGKeychain getPasswordFromKeychainItem:[self keychainServiceName:2]
											   withItemKind:@"application password" 
												forUsername:nil 
												serviceName:[self keychainServiceID]] retain];
	
	// * =================================== * //
	
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
	proxyHost = [[dic stringForKey:@"proxy_host"] retain] ?: @"";
	proxyPort = [dic intForKey:@"proxy_port"] ?: 1080;
	proxyUser = [[dic stringForKey:@"proxy_user"] retain] ?: @"";
	proxyPassword = [[dic stringForKey:@"proxy_password"] retain] ?: @"";
	
	autoConnect = [dic boolForKey:@"auto_connect"];
	autoReconnect = [dic boolForKey:@"auto_reconnect"];
	encoding = [dic intForKey:@"encoding"] ?: NSUTF8StringEncoding;
	fallbackEncoding = [dic intForKey:@"fallback_encoding"] ?: NSISOLatin1StringEncoding;
	
	if ([dic stringForKey:@"leaving_comment"]) {
		[leavingComment release];
		leavingComment = [[dic stringForKey:@"leaving_comment"] retain];
	}
	
	userInfo = [[dic stringForKey:@"userinfo"] retain] ?: @"";
	invisibleMode = [dic boolForKey:@"invisible"];
	
	[loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
	
	for (NSDictionary* e in [dic arrayForKey:@"channels"]) {
		IRCChannelConfig* c = [[[IRCChannelConfig alloc] initWithDictionary:e] autorelease];
		[channels addObject:c];
	}
	
	for (NSDictionary* e in [dic arrayForKey:@"ignores"]) {
		AddressBook* ignore = [[[AddressBook alloc] initWithDictionary:e] autorelease];
		[ignores addObject:ignore];
	}
	
	return self;
}

- (void)dealloc
{
	[name release];
	
	[host release];
	
	[nick release];
	[password release];
	[username release];
	[realName release];
	[nickPassword release];
	[altNicks release];
	
	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[leavingComment release];
	[userInfo release];
	[loginCommands release];
	[channels release];
	[ignores release];
	
	[super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	// * =================================== * //
	
	[self verifyKeychainsExistsOrAdd];
	
	[AGKeychain modifyKeychainItem:[self keychainServiceName:1]
				withItemKind:@"application password"
				 forUsername:nil
			   withNewPassword:password
				 serviceName:[self keychainServiceID]];
	
	[AGKeychain modifyKeychainItem:[self keychainServiceName:2]
				withItemKind:@"application password"
				 forUsername:nil
			   withNewPassword:nickPassword
				 serviceName:[self keychainServiceID]];
	
	// * =================================== * //
	
	[dic setInt:cuid forKey:@"cuid"];
	if (name) [dic setObject:name forKey:@"name"];
	
	if (host) [dic setObject:host forKey:@"host"];
	[dic setInt:port forKey:@"port"];
	[dic setBool:useSSL forKey:@"ssl"];
	
	if (nick) [dic setObject:nick forKey:@"nick"];
	if (username) [dic setObject:username forKey:@"username"];
	if (realName) [dic setObject:realName forKey:@"realname"];
	if (altNicks) [dic setObject:altNicks forKey:@"alt_nicks"];
	
	[dic setInt:proxyType forKey:@"proxy"];
	if (proxyHost) [dic setObject:proxyHost forKey:@"proxy_host"];
	[dic setInt:proxyPort forKey:@"proxy_port"];
	if (proxyUser) [dic setObject:proxyUser forKey:@"proxy_user"];
	if (proxyPassword) [dic setObject:proxyPassword forKey:@"proxy_password"];
	
	[dic setBool:autoConnect forKey:@"auto_connect"];
	[dic setBool:autoReconnect forKey:@"auto_reconnect"];
	[dic setInt:encoding forKey:@"encoding"];
	[dic setInt:fallbackEncoding forKey:@"fallback_encoding"];
	if (leavingComment) [dic setObject:leavingComment forKey:@"leaving_comment"];
	if (userInfo) [dic setObject:userInfo forKey:@"userinfo"];
	[dic setBool:invisibleMode forKey:@"invisible"];
	
	if (altNicks) [dic setObject:loginCommands forKey:@"login_commands"];
	
	NSMutableArray* channelAry = [NSMutableArray array];
	for (IRCChannelConfig* e in channels) {
		[channelAry addObject:[e dictionaryValue]];
	}
	[dic setObject:channelAry forKey:@"channels"];
	
	NSMutableArray* ignoreAry = [NSMutableArray array];
	for (AddressBook* e in ignores) {
		if ([e.hostmask length] >= 1) {
			[ignoreAry addObject:[e dictionaryValue]];
		}
	}
	[dic setObject:ignoreAry forKey:@"ignores"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@synthesize server;
@synthesize network;
@end