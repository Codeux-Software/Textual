/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation NSBundle (TXBundleHelper)

+ (void)sendUserInputDataToBundles:(IRCWorld *)world
						   message:(NSString *)message
						   command:(NSString *)command
							client:(IRCClient *)client
{
	NSArray *cmdPlugins = [world bundlesForUserInput][command];
	
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
	NSArray *cmdPlugins = [world bundlesForServerInput][[msg command]];
	
	if (NSObjectIsNotEmpty(cmdPlugins)) {
		NSDictionary *senderData = @{@"senderHostmask": NSStringNilValueSubstitute(msg.sender.raw),
									@"senderNickname":  NSStringNilValueSubstitute(msg.sender.nick),
									@"senderUsername":  NSStringNilValueSubstitute(msg.sender.user),
									@"senderDNSMask":   NSStringNilValueSubstitute(msg.sender.address),
									@"senderIsServer": @(msg.sender.isServer)};
		
		NSDictionary *messageData = @{@"messageParamaters": msg.params,
									 @"messageCommand":  NSStringNilValueSubstitute(msg.command),
									 @"messageSequence": NSStringNilValueSubstitute(msg.sequence),
									 @"messageServer":   NSStringNilValueSubstitute(client.config.server),
									 @"messageNetwork":  NSStringNilValueSubstitute(client.config.network),
									 @"messageNumericReply": @(msg.numericReply)};
		
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
    NSString *path_1 = [TPCPreferences customExtensionFolderPath];
    NSString *path_2 = [TPCPreferences bundledExtensionFolderPath];;
    
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