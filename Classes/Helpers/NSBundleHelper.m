// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "NSBundleHelper.h"
#import "TextualPluginItem.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "IRCClient.h"
#import "Preferences.h"

@implementation NSBundle (NSBundleHelper)

+ (void)sendUserInputDataToBundles:(IRCWorld*)world
				   message:(NSString*)message
				   command:(NSString*)command
				    client:(IRCClient*)client
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *cmdPlugins = [[world bundlesForUserInput] objectForKey:command];
	
	if ([cmdPlugins count] >= 1) {
		for (TextualPluginItem *plugin in cmdPlugins) {
			[[plugin bundleClass] messageSentByUser:client message:message command:command];
		}
	}
	
	[pool drain];
}

+ (void)sendServerInputDataToBundles:(IRCWorld*)world
					client:(IRCClient*)client
				     message:(IRCMessage*)msg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *cmdPlugins = [[world bundlesForServerInput] objectForKey:[msg command]];
	
	if ([cmdPlugins count] >= 1) {
		NSDictionary *senderData = [NSDictionary dictionaryWithObjectsAndKeys:
								msg.sender.raw, @"senderHostmask",
								msg.sender.nick, @"senderNickname",
								msg.sender.user, @"senderUsername",
								msg.sender.address, @"senderDNSMask", 
								[NSNumber numberWithBool:msg.sender.isServer], @"senderIsServer", nil];
		NSDictionary *messageData = [NSDictionary dictionaryWithObjectsAndKeys:
								[[client config] server], @"messageServer",
								[[client config] network], @"messageNetwork",
								[msg sequence], @"messageSequence",
								[msg params], @"messageParamaters",
								[NSNumber numberWithInteger:[msg numericReply]], @"messageNumericReply",
								[msg command], @"messageCommand", nil];
		
		for (TextualPluginItem *plugin in cmdPlugins) {
			[[plugin bundleClass] messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
	
	[pool drain];
}

+ (void)loadAllAvailableBundlesIntoMemory:(IRCWorld*)world
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [Preferences wherePluginsPath];
	
	NSMutableDictionary *userInputBundles = [[NSMutableDictionary new] autorelease];
	NSMutableDictionary *serverInputBundles = [[NSMutableDictionary new] autorelease];
	
	NSArray* resourceFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	
	for (NSString* file in resourceFiles) {
		if ([file hasSuffix:@".bundle"]) {
			NSString *fullPath = [path stringByAppendingPathComponent:file];
			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath]; 
			
			if (currBundle) {
				Class currPrincipalClass = [currBundle principalClass];       
				
				if (currPrincipalClass) {
					PluginProtocol *currInstance = [[currPrincipalClass alloc] init];  
					
					if (currInstance) {
						TextualPluginItem *plugin = [[TextualPluginItem alloc] init];
						
						[plugin setBundleClass:[currInstance autorelease]];
									
						// User Input
						if ([currInstance respondsToSelector:@selector(messageSentByUser:message:command:)]) {
							if ([currInstance respondsToSelector:@selector(pluginSupportsUserInputCommands)]) {
								NSArray *spdcmds = [currInstance pluginSupportsUserInputCommands];
								
								if ([spdcmds count] >= 1) {
									for (NSString *cmd in spdcmds) {
										cmd = [cmd uppercaseString];
										
										NSArray *cmdDict = [userInputBundles objectForKey:cmd];
										
										if (!cmdDict) {
											[userInputBundles setObject:[[NSMutableArray new] autorelease] forKey:cmd];
										}
										
										if (![cmdDict containsObject:plugin]) {
											[[userInputBundles objectForKey:cmd] addObject:plugin];
										}
									}
								}
							}
						}
						
						// Server Input
						if ([currInstance respondsToSelector:@selector(messageReceivedByServer:sender:message:)]) {
							if ([currInstance respondsToSelector:@selector(pluginSupportsServerInputCommands)]) {
								NSArray *spdcmds = [currInstance pluginSupportsServerInputCommands];
								
								if ([spdcmds count] >= 1) {
									for (NSString *cmd in spdcmds) {
										cmd = [cmd uppercaseString];
										
										NSArray *cmdDict = [serverInputBundles objectForKey:cmd];
										
										if (!cmdDict) {
											[serverInputBundles setObject:[[NSMutableArray new] autorelease] forKey:cmd];
										}
										
										if (![cmdDict containsObject:plugin]) {
											[[serverInputBundles objectForKey:cmd] addObject:plugin];
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	[world setBundlesForUserInput:userInputBundles];
	[world setBundlesForServerInput:serverInputBundles];
	
	[pool drain];
}

@end