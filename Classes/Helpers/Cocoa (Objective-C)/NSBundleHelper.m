// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation NSBundle (TXBundleHelper)

+ (void)sendUserInputDataToBundles:(IRCWorld *)world
						   message:(NSString *)message
						   command:(NSString *)command
							client:(IRCClient *)client
{
	NSArray *cmdPlugins = [[world bundlesForUserInput] objectForKey:command];
	
	if (NSObjectIsNotEmpty(cmdPlugins)) {
		for (THOTextualPluginItem *plugin in cmdPlugins) {
			THOPluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageSentByUser:client message:message command:command];
		}
	}
}

+ (void)sendServerInputDataToBundles:(IRCWorld *)world
							  client:(IRCClient *)client
							 message:(IRCMessage *)msg
{
	NSArray *cmdPlugins = [[world bundlesForServerInput] objectForKey:[msg command]];
	
	if (NSObjectIsNotEmpty(cmdPlugins)) {
		NSDictionary *senderData = [NSDictionary dictionaryWithObjectsAndKeys:
									msg.sender.raw, @"senderHostmask",
									msg.sender.nick, @"senderNickname",
									msg.sender.user, @"senderUsername",
									msg.sender.address, @"senderDNSMask", 
									NSNumberWithBOOL(msg.sender.isServer), @"senderIsServer", nil];
		
		NSDictionary *messageData = [NSDictionary dictionaryWithObjectsAndKeys:
									 msg.command, @"messageCommand",
									 msg.sequence, @"messageSequence",
									 msg.params, @"messageParamaters",
									 client.config.server, @"messageServer",
									 client.config.network, @"messageNetwork",
									 NSNumberWithInteger(msg.numericReply), @"messageNumericReply", nil];
		
		for (THOTextualPluginItem *plugin in cmdPlugins) {
			THOPluginProtocol *bundle = [plugin pluginPrimaryClass];
			
			[bundle messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
}

+ (void)reloadBundles:(IRCWorld *)world
{
	[self deallocBundlesFromMemory:world];
	[self loadBundlesIntoMemory:world];
}

+ (void)deallocBundlesFromMemory:(IRCWorld *)world
{		
	TDCPreferencesController *prefController = world.menuController.preferencesController;
	
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
}

+ (void)loadBundlesIntoMemory:(IRCWorld *)world
{
    NSString *path_1 = [TPCPreferences wherePluginsPath];
    NSString *path_2 = [TPCPreferences wherePluginsLocalPath];
    
    if (NSObjectIsNotEmpty(world.allLoadedBundles)) {
        [self deallocBundlesFromMemory:world];
    }
    
    NSMutableArray *completeBundleIndex		= [NSMutableArray new];
    NSMutableArray *preferencesBundlesIndex = [NSMutableArray new];
    NSMutableArray *resourceBundles         = [NSMutableArray array];
    
    NSMutableDictionary *userInputBundles	= [NSMutableDictionary new];
    NSMutableDictionary *serverInputBundles = [NSMutableDictionary new];
    NSMutableDictionary *outputRulesDict	= [NSMutableDictionary new];
    
    NSArray *resourceFiles_1 = [_NSFileManager() contentsOfDirectoryAtPath:path_1 error:NULL];
    NSArray *resourceFiles_2 = [_NSFileManager() contentsOfDirectoryAtPath:path_2 error:NULL];
    
    NSArray *resourceFiles = [resourceFiles_1 arrayByAddingObjectsFromArray:resourceFiles_2];
    
    for (NSString *file in resourceFiles) {
        if ([resourceBundles containsObject:file] == NO) {
            [resourceBundles addObject:file];
        }
    }
    
    for (NSString *file in resourceBundles) {
        if ([file hasSuffix:@".bundle"]) {
            NSString *fullPath = [path_1 stringByAppendingPathComponent:file];
            
            if ([_NSFileManager() fileExistsAtPath:fullPath] == NO) {
                fullPath = [path_2 stringByAppendingPathComponent:file];
            }
            
			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath]; 
			
			THOTextualPluginItem *plugin = [THOTextualPluginItem new];
			
			[plugin initWithPluginClass:[currBundle principalClass] 
							  andBundle:currBundle 
							andIRCWorld:world
					  withUserInputDict:&userInputBundles 
					withServerInputDict:&serverInputBundles
					 withOuputRulesDict:&outputRulesDict];
			
			if ([plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesMenuItemName)] && 
				[plugin.pluginPrimaryClass respondsToSelector:@selector(preferencesView)]) {
				
				NSView   *itemView	= [plugin.pluginPrimaryClass preferencesView];
				NSString *itemName  = [plugin.pluginPrimaryClass preferencesMenuItemName];
				
				if (NSObjectIsNotEmpty(itemName) && itemView) {
					[preferencesBundlesIndex safeAddObject:plugin];
				}
			}
			
			[completeBundleIndex safeAddObject:currBundle];
		}
	}
	
	[world setAllLoadedBundles:completeBundleIndex];
	[world setBundlesForUserInput:userInputBundles];
	[world setBundlesWithOutputRules:outputRulesDict];
	[world setBundlesForServerInput:serverInputBundles];
	[world setBundlesWithPreferences:preferencesBundlesIndex];
}

@end