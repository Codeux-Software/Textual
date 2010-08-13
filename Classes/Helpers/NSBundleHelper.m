// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "NSBundleHelper.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "IRCClient.h"
#import "Preferences.h"
#import "PluginProtocol.h"
#import "TextualPluginItem.h"

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
			PluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageSentByUser:client message:message command:command];
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
			PluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
	
	[pool drain];
}

+ (void)reloadAllAvailableBundles:(IRCWorld*)world
{
	[self deallocAllAvailableBundlesFromMemory:world];
	[self loadAllAvailableBundlesIntoMemory:world];
}

+ (void)deallocAllAvailableBundlesFromMemory:(IRCWorld*)world
{		
	NSArray *allBundles = [world.allLoadedBundles copy];
	
	[world resetLoadedBundles];
	
	for (NSBundle *bundle in allBundles) {
		if ([bundle isLoaded]) {
			[bundle unload];
		}
	}
	
	[allBundles release];
}

+ (void)loadAllAvailableBundlesIntoMemory:(IRCWorld*)world
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [Preferences wherePluginsPath];
	
	BOOL mergeItems = NO;
	
	NSMutableArray *completeBundleIndex = [NSMutableArray new];
 	NSMutableDictionary *userInputBundles = [NSMutableDictionary new];
	NSMutableDictionary *serverInputBundles = [NSMutableDictionary new];
	
	NSArray* resourceFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	
	for (NSString* file in resourceFiles) {
		if ([file hasSuffix:@".bundle"]) {
			NSString *fullPath = [path stringByAppendingPathComponent:file];
			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath]; 
			
			if (currBundle) {
				if ([world.allLoadedBundles containsObject:currBundle]) {
					if (mergeItems == NO) {
						userInputBundles = world.bundlesForUserInput;
						completeBundleIndex = world.allLoadedBundles;
						serverInputBundles = world.bundlesForServerInput;
					}
					
					mergeItems = YES;
					
					continue;
				}
				
				TextualPluginItem *plugin = [[TextualPluginItem alloc] init];
				
				[plugin initWithPluginClass:[currBundle principalClass] 
								  andBundle:currBundle 
								andIRCWorld:world
						  withUserInputDict:userInputBundles 
						withServerInputDict:serverInputBundles 
					  withUserInputDictRefs:&userInputBundles 
					withServerInputDictRefs:&serverInputBundles];
				
				[completeBundleIndex addObject:currBundle];
				
				[plugin autorelease];
			}
		}
	}
	
	[world setAllLoadedBundles:completeBundleIndex];
	[world setBundlesForUserInput:userInputBundles];
	[world setBundlesForServerInput:serverInputBundles];
	
	[userInputBundles release];
	[serverInputBundles release];
	[completeBundleIndex release];
	
	[pool release];
}

@end