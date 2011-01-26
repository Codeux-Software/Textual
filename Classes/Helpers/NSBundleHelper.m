// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSBundle (NSBundleHelper)

+ (void)sendUserInputDataToBundles:(IRCWorld *)world
						   message:(NSString *)message
						   command:(NSString *)command
							client:(IRCClient *)client
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *cmdPlugins = [[world bundlesForUserInput] objectForKey:command];
	
	if (NSObjectIsNotEmpty(cmdPlugins)) {
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
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *cmdPlugins = [[world bundlesForServerInput] objectForKey:[msg command]];
	
	if (NSObjectIsNotEmpty(cmdPlugins)) {
		NSDictionary *senderData = [NSDictionary dictionaryWithObjectsAndKeys:
									msg.sender.raw, @"senderHostmask",
									msg.sender.nick, @"senderNickname",
									msg.sender.user, @"senderUsername",
									msg.sender.address, @"senderDNSMask", 
									[NSNumber numberWithBool:msg.sender.isServer], @"senderIsServer", nil];
		
		NSDictionary *messageData = [NSDictionary dictionaryWithObjectsAndKeys:
									 msg.command, @"messageCommand",
									 [msg sequence], @"messageSequence",
									 [msg params], @"messageParamaters",
									 client.config.server, @"messageServer",
									 client.config.network, @"messageNetwork",
									 [NSNumber numberWithInteger:[msg numericReply]], @"messageNumericReply", nil];
		
		for (TextualPluginItem *plugin in cmdPlugins) {
			PluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
	
	[pool drain];
}

+ (void)reloadBundles:(IRCWorld *)world
{
	[self deallocBundlesFromMemory:world];
	[self loadBundlesIntoMemory:world];
}

+ (void)deallocBundlesFromMemory:(IRCWorld *)world
{		
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	PreferencesController *prefController = world.menuController.preferencesController;
	
	if (prefController) {
		if (NSObjectIsNotEmpty(world.bundlesWithPreferences)) {
			if ([prefController isWindowLoaded]) {
				[prefController.window close];
			}
		}
	}
	
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

+ (void)loadBundlesIntoMemory:(IRCWorld *)world
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *path = [Preferences wherePluginsPath];
	
	if (NSObjectIsNotEmpty(world.allLoadedBundles)) {
		[self deallocBundlesFromMemory:world];
	}
	
	NSMutableArray *completeBundleIndex = [NSMutableArray new];
	NSMutableArray *preferencesBundlesIndex = [NSMutableArray new];
 	NSMutableDictionary *userInputBundles = [NSMutableDictionary new];
	NSMutableDictionary *serverInputBundles = [NSMutableDictionary new];
	
	NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
	
	for (NSString *file in resourceFiles) {
		if ([file hasSuffix:@".bundle"]) {
			NSString *fullPath = [path stringByAppendingPathComponent:file];
			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath]; 
			
			TextualPluginItem *plugin = [TextualPluginItem new];
			
			[plugin initWithPluginClass:[currBundle principalClass] 
							  andBundle:currBundle 
							andIRCWorld:world
					  withUserInputDict:userInputBundles 
					withServerInputDict:serverInputBundles 
				  withUserInputDictRefs:&userInputBundles 
				withServerInputDictRefs:&serverInputBundles];
			
			if ([plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesMenuItemName)] && 
				[plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesView)]) {
				
				NSView *itemView = [plugin.pluginPrimaryClass preferencesView];
				NSString *itemName = [plugin.pluginPrimaryClass preferencesMenuItemName];
				
				if (NSObjectIsNotEmpty(itemName) && itemView) {
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