// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSBundle (NSBundleHelper)

+ (void)sendUserInputDataToBundles:(IRCWorld *)world
						   message:(NSString *)message
						   command:(NSString *)command
							client:(IRCClient *)client
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

+ (void)sendServerInputDataToBundles:(IRCWorld *)world
							  client:(IRCClient *)client
							 message:(IRCMessage *)msg
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
									 [msg params], @"messageParameters",
									 [NSNumber numberWithInteger:[msg numericReply]], @"messageNumericReply",
									 [msg command], @"messageCommand", nil];
		
		for (TextualPluginItem *plugin in cmdPlugins) {
			PluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
	
	[pool drain];
}

+ (void)reloadAllAvailableBundles:(IRCWorld *)world
{
	[self deallocAllAvailableBundlesFromMemory:world];
	[self loadAllAvailableBundlesIntoMemory:world];
}

+ (void)deallocAllAvailableBundlesFromMemory:(IRCWorld *)world
{		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *allBundles = [world.allLoadedBundles copy];
	
	[world resetLoadedBundles];
	
	for (NSBundle *bundle in allBundles) {
		if ([bundle isLoaded]) {
			[bundle unload];
		}
	}
	
	[allBundles release];
	
	[pool release];
}

+ (void)loadAllAvailableBundlesIntoMemory:(IRCWorld *)world
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [Preferences wherePluginsPath];
	
	if ([world.allLoadedBundles count] > 0) {
		[self deallocAllAvailableBundlesFromMemory:world];
	}
	
	NSMutableArray *completeBundleIndex = [NSMutableArray new];
	NSMutableArray *preferencesBundlesIndex = [NSMutableArray new];
 	NSMutableDictionary *userInputBundles = [NSMutableDictionary new];
	NSMutableDictionary *serverInputBundles = [NSMutableDictionary new];
	
	NSArray *resourceFiles = [TXNSFileManager() contentsOfDirectoryAtPath:path error:NULL];
	
	for (NSString *file in resourceFiles) {
		if ([file hasSuffix:@".bundle"]) {
			NSString *fullPath = [path stringByAppendingPathComponent:file];
			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath]; 
			
			TextualPluginItem *plugin = [[TextualPluginItem alloc] init];
			
			[plugin initWithPluginClass:[currBundle principalClass] 
							  andBundle:currBundle 
							andIRCWorld:world
					  withUserInputDict:userInputBundles 
					withServerInputDict:serverInputBundles 
				  withUserInputDictRefs:&userInputBundles 
				withServerInputDictRefs:&serverInputBundles];
			
			if ([plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesMenuItemName)] && 
				[plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesView)]) {
				
				NSString *itemName = [plugin.pluginPrimaryClass preferencesMenuItemName];
				
				if ([itemName isEmpty] == NO) {
					[preferencesBundlesIndex addObject:plugin];
				}
			}
			
			[completeBundleIndex addObject:currBundle];
			
			[plugin autorelease];
		}
	}
	
	[world setAllLoadedBundles:completeBundleIndex];
	[world setBundlesForUserInput:userInputBundles];
	[world setBundlesForServerInput:serverInputBundles];
	[world setBundlesWithPreferences:preferencesBundlesIndex];
	
	[userInputBundles release];
	[serverInputBundles release];
	[completeBundleIndex release];
	[preferencesBundlesIndex release];
	
	[pool release];
}

@end