// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TPCPreferencesMigrationAssistant

+ (NSDictionary *)convertIRCClientConfiguration:(NSDictionary *)config
{
	/* Has this configuration file already been migrated? */
	NSString *lastUpgrade = [config objectForKey:TPCPreferencesMigrationAssistantVersionKey];
	
	if (NSObjectIsNotEmpty(lastUpgrade)) {
		if ([lastUpgrade isEqualToString:TPCPreferencesMigrationAssistantUpgradePath]) {
			return config;
		}
	}
	
	NSMutableDictionary *nconfig = config.mutableCopy;
	
	/* If not, then migrate. */
	[nconfig removeAllObjects];
	
	[nconfig setInteger:[config integerForKey:@"port"]					forKey:@"serverPort"];
	[nconfig setInteger:[config integerForKey:@"proxy"]					forKey:@"proxyServerType"];
	[nconfig setInteger:[config integerForKey:@"proxy_port"]			forKey:@"proxyServerPort"];
	[nconfig setInteger:[config integerForKey:@"encoding"]				forKey:@"characterEncodingDefault"];
	[nconfig setInteger:[config integerForKey:@"fallback_encoding"]		forKey:@"characterEncodingFallback"];
	
	[nconfig setBool:[config boolForKey:@"ssl"]					forKey:@"connectUsingSSL"];
    [nconfig setBool:[config boolForKey:@"prefersIPv6"]			forKey:@"DNSResolverPrefersIPv6"];
	[nconfig setBool:[config boolForKey:@"auto_connect"]		forKey:@"connectOnLaunch"];
	[nconfig setBool:[config boolForKey:@"auto_reconnect"]		forKey:@"connectOnDisconnect"];
	[nconfig setBool:[config boolForKey:@"bouncer_mode"]		forKey:@"serverIsIRCBouncer"];
	[nconfig setBool:[config boolForKey:@"invisible"]			forKey:@"setInvisibleOnConnect"];
	[nconfig setBool:[config boolForKey:@"trustedConnection"]	forKey:@"trustedSSLConnection"];
	
	[nconfig setInteger:[config integerForKey:@"cuid"]				forKey:@"connectionID"];
	
	[nconfig safeSetObject:[config objectForKey:@"guid"]				forKey:@"uniqueIdentifier"];
	[nconfig safeSetObject:[config objectForKey:@"name"]				forKey:@"connectionName"];
	[nconfig safeSetObject:[config objectForKey:@"host"]				forKey:@"serverAddress"];
	[nconfig safeSetObject:[config objectForKey:@"nick"]				forKey:@"identityNickname"];
	[nconfig safeSetObject:[config objectForKey:@"username"]			forKey:@"identityUsername"];
	[nconfig safeSetObject:[config objectForKey:@"realname"]			forKey:@"identityRealname"];
	[nconfig safeSetObject:[config objectForKey:@"alt_nicks"]			forKey:@"identityAlternateNicknames"];
	[nconfig safeSetObject:[config objectForKey:@"proxy_host"]			forKey:@"proxyServerAddress"];
	[nconfig safeSetObject:[config objectForKey:@"proxy_user"]			forKey:@"proxyServerUsername"];
	[nconfig safeSetObject:[config objectForKey:@"proxy_password"]		forKey:@"proxyServerPassword"];
	[nconfig safeSetObject:[config objectForKey:@"leaving_comment"]		forKey:@"connectionDisconnectDefaultMessage"];
	[nconfig safeSetObject:[config objectForKey:@"sleep_quit_message"]	forKey:@"connectionDisconnectSleepModeMessage"];
	[nconfig safeSetObject:[config objectForKey:@"login_commands"]		forKey:@"onConnectCommands"];
	
	NSMutableDictionary *floodControl = [config dictionaryForKey:@"flood_control"].mutableCopy;
	
    [floodControl setInteger:[floodControl integerForKey:@"delay_timer"]		forKey:@"delayTimerInterval"];
    [floodControl setInteger:[floodControl integerForKey:@"message_count"]		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:[floodControl boolForKey:@"outgoing"] forKey:@"serviceEnabled"];
    
    [nconfig setObject:floodControl forKey:@"floodControl"];
	
	[nconfig setObject:[config objectForKey:@"channels"]	forKey:@"channelList"];
	[nconfig setObject:[config objectForKey:@"ignores"]		forKey:@"ignoreList"];
	
	[nconfig safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
					forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return nconfig;
}

+ (NSDictionary *)convertIRCChannelConfiguration:(NSDictionary *)config
{
	/* Has this configuration file already been migrated? */
	NSString *lastUpgrade = [config objectForKey:TPCPreferencesMigrationAssistantVersionKey];
	
	if (NSObjectIsNotEmpty(lastUpgrade)) {
		if ([lastUpgrade isEqualToString:TPCPreferencesMigrationAssistantUpgradePath]) {
			return config;
		}
	}

	NSMutableDictionary *nconfig = config.mutableCopy;
	
	/* If not, then migrate. */
	[nconfig removeAllObjects];
	
	[nconfig setInteger:[config integerForKey:@"type"]		forKey:@"channelType"];
	
	[nconfig setBool:[config boolForKey:@"growl"]				forKey:@"enableNotifications"];
	[nconfig setBool:[config boolForKey:@"auto_join"]			forKey:@"joinOnConnect"];
    [nconfig setBool:[config boolForKey:@"ignore_highlights"]	forKey:@"ignoreHighlights"];
    [nconfig setBool:[config boolForKey:@"disable_images"]		forKey:@"disableInlineMedia"];
    [nconfig setBool:[config boolForKey:@"ignore_join,leave"]	forKey:@"ignoreJPQActivity"];
	
	[nconfig safeSetObject:[config objectForKey:@"name"]			forKey:@"channelName"];
	[nconfig safeSetObject:[config objectForKey:@"password"]		forKey:@"secretJoinKey"];
	[nconfig safeSetObject:[config objectForKey:@"mode"]			forKey:@"defaultMode"];
	[nconfig safeSetObject:[config objectForKey:@"topic"]			forKey:@"defaultTopic"];
	[nconfig safeSetObject:[config objectForKey:@"password"]		forKey:@"secretKey"];
	[nconfig safeSetObject:[config objectForKey:@"encryptionKey"]	forKey:@"encryptionKey"];
	
	[nconfig safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
					forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return nconfig;
}

+ (void)convertExistingGlobalPreferences
{
	return;
}

@end