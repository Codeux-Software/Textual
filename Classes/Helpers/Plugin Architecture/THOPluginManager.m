/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@interface THOPluginManager ()
@property (nonatomic, copy) NSArray *allLoadedBundles;
@property (nonatomic, copy) NSArray *allLoadedPlugins;
@end

@implementation THOPluginManager

#pragma mark -
#pragma mark Init.

- (id)init
{
	if ((self = [super init])) {
		self.dispatchQueue = dispatch_queue_create("PluginManagerDispatchQueue", DISPATCH_QUEUE_SERIAL);

		return self;
	}

	return nil;
}

- (void)dealloc
{
	if (self.dispatchQueue) {
		dispatch_release(self.dispatchQueue);

		self.dispatchQueue = NULL;
	}
}

#pragma mark -
#pragma mark Retain & Release.

- (void)loadPlugins
{
	TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		NSObjectIsNotEmptyAssert(self.allLoadedBundles);

		// ---- //

		NSString *path_1 = [TPCPathInfo customExtensionFolderPath];
		NSString *path_2 = [TPCPathInfo bundledExtensionFolderPath];

		NSMutableArray *loadedBundles = [NSMutableArray array];
		NSMutableArray *loadedPlugins = [NSMutableArray array];
		
		NSMutableArray *resourceBundles = [NSMutableArray array];

		NSArray *resourceFiles_1 = [RZFileManager() contentsOfDirectoryAtPath:path_1 error:NULL];
		NSArray *resourceFiles_2 = [RZFileManager() contentsOfDirectoryAtPath:path_2 error:NULL];

		NSArray *resourceFiles = [resourceFiles_1 arrayByAddingObjectsFromArray:resourceFiles_2];

		for (NSString *file in resourceFiles) {
			[resourceBundles addObjectWithoutDuplication:file];
		}

		// ---- //
		
		NSArray *bannedBundleNames = [self bannedExtensionBundleNames];

		for (NSString *file in resourceBundles) {
			if ([file hasSuffix:TPCResourceManagerBundleDocumentTypeExtension]) {
				NSString *fullPath = [path_1 stringByAppendingPathComponent:file];

				if ([RZFileManager() fileExistsAtPath:fullPath] == NO) {
					fullPath = [path_2 stringByAppendingPathComponent:file];
				} else {
					if ([bannedBundleNames containsObject:file]) {
						fullPath = [path_2 stringByAppendingPathComponent:file];
						
						if ([RZFileManager() fileExistsAtPath:fullPath] == NO) {
							continue;
						}
					}
				}

				NSBundle *currBundle = [NSBundle bundleWithPath:fullPath];

				if (currBundle) {
					THOPluginItem *currPlugin = [THOPluginItem new];

					[currPlugin loadBundle:currBundle];

					[loadedBundles addObject:currBundle];
					[loadedPlugins addObject:currPlugin];
				}
			}
		}

		// ---- //

		self.allLoadedBundles = loadedBundles;
		self.allLoadedPlugins = loadedPlugins;
	});
}

- (void)unloadPlugins
{
	TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		self.allLoadedPlugins = nil;

		for (NSBundle *bundle in self.allLoadedBundles) {
			if ([bundle isLoaded]) {
				[bundle unload];
			}
		}
		
		self.allLoadedBundles = nil;
	});
}

#pragma mark -
#pragma mark AppleScript Support.

- (id)supportedAppleScriptCommands
{
	return [self supportedAppleScriptCommands:NO];
}

- (id)supportedAppleScriptCommands:(BOOL)returnPathInfo
{
	/* List of accepted extensions. */
	NSArray *scriptExtensions = @[@"scpt", @"py", @"pyc", @"rb", @"pl", @"sh", @"php", @"bash"];

	/* Begin building list. Topmost take priority. */
	NSArray *scriptPaths = [TPCPathInfo buildPathArray:
							[TPCPathInfo systemUnsupervisedScriptFolderPath],
							[TPCPathInfo bundledScriptFolderPath]];
	
	/* Begin scanning folders. */
	id returnData;

	if (returnPathInfo) {
		returnData = [NSMutableDictionary dictionary];
	} else {
		returnData = [NSMutableArray array];
	}

	for (NSString *path in scriptPaths) {
		NSArray *resourceFiles = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

		for (NSString *file in resourceFiles) {
			NSString *fullpa = [path stringByAppendingPathComponent:file];
			NSString *script = file;

			NSString *extens = NSStringEmptyPlaceholder;

			if ([script contains:@"."]) {
				NSArray *nameParts = [script componentsSeparatedByString:@"."];

				script = nameParts[0];
				extens = nameParts[1];

				if ([scriptExtensions containsObject:extens] == NO) {
					continue;
				}
			}

			if (returnPathInfo) {
				if ([returnData containsKey:script] == NO) {
					[returnData setObjectWithoutOverride:fullpa forKey:script];
				}
			} else {
				if ([returnData containsObject:script] == NO) {
					[returnData addObjectWithoutDuplication:script];
				}
			}
		}
	}
	
	return returnData;
}

#pragma mark -
#pragma mark Extension Information.

- (NSArray *)dangerousCommandNames
{
	/* List of commands that may be part of Textual that we hide due to them
	 being known to the general populous may result in unexpected harm such as
	 spamming by not understanding what they do.
	 
	 These commands are only excluded from the list of installed addons. We
	 cannot actually prevent the user from executing them. */
    return @[@"clone", @"cloned", @"unclone", @"hspam", @"spam", @"namel"];
}

- (NSArray *)bannedExtensionBundleNames
{
	/* We do not want to allow bundles with this name to be loaded
	 unless they are inside Textual itself. This allows us to package
	 a bundle which was previously installed from an installer to
	 instead by packaged with Textual by default. */
	return @[@"SmileyConverter.bundle"];
}

/* Everything else. */
- (NSArray *)outputRulesForCommand:(NSString *)command
{
	NSMutableArray *allRules = [NSMutableArray array];

	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		NSArray *srules = [[plugin outputSuppressionRules] arrayForKey:command];

		if (NSObjectIsNotEmpty(srules)) {
			[allRules addObjectsFromArray:srules];
		}
	}

	return allRules;
}

- (NSArray *)supportedUserInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		[allCommands addObjectsFromArray:[plugin supportedUserInputCommands]];
	}

	return allCommands;
}

- (NSArray *)supportedServerInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		[allCommands addObjectsFromArray:[plugin supportedServerInputCommands]];
	}

	return allCommands;
}

- (NSArray *)pluginsWithPreferencePanes
{
	NSMutableArray *allExtensions = [NSMutableArray array];
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin hasPreferencePaneView]) {
			[allExtensions addObject:plugin];
		}
	}

	return allExtensions;
}

- (NSArray *)allLoadedExtensions
{
	NSMutableArray *allPlugins = [NSMutableArray array];
	
	for (NSBundle *bundle in self.allLoadedBundles) {
		NSString *path = [bundle bundlePath];

		NSString *bundleName = [path lastPathComponent];
		
		[allPlugins addObjectWithoutDuplication:[bundleName stringByDeletingPathExtension]];
	}

	return allPlugins;
}

#pragma mark -
#pragma mark Talk.

- (void)sendUserInputDataToBundles:(IRCClient *)client message:(NSString *)message command:(NSString *)command
{
	TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		NSString *cmdu = [command uppercaseString];
		NSString *cmdl = [command lowercaseString];
		
		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ([[plugin supportedUserInputCommands] containsObject:cmdl])
			{
				if ([[plugin primaryClass] respondsToSelector:@selector(userInputCommandInvokedOnClient:commandString:messageString:)])
				{
					[[plugin primaryClass] userInputCommandInvokedOnClient:client commandString:cmdu messageString:message];
				}
				else
				{
					[[plugin primaryClass] messageSentByUser:client message:message command:cmdu];
				}
			}
		}
	});
}

- (void)sendServerInputDataToBundles:(IRCClient *)client message:(IRCMessage *)message
{
	TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		NSString *cmdl = [[message command] lowercaseString];

		NSDictionary *senderData = @{
			@"senderIsServer"	: @([[message sender] isServer]),
			@"senderHostmask"	: NSStringNilValueSubstitute([[message sender] hostmask]),
			@"senderNickname"	: NSStringNilValueSubstitute([[message sender] nickname]),
			@"senderUsername"	: NSStringNilValueSubstitute([[message sender] username]),
			@"senderDNSMask"	: NSStringNilValueSubstitute([[message sender] address])
		};

		NSDictionary *messageData = @{
			@"messageReceived"      : [message receivedAt],
			@"messageParamaters"	: [message params],
			@"messageNumericReply"	: @([message numericReply]),
			@"messageCommand"		: NSStringNilValueSubstitute([message command]),
			@"messageSequence"		: NSStringNilValueSubstitute([message sequence]),
			@"messageServer"		: NSStringNilValueSubstitute([client networkAddress]),
			@"messageNetwork"		: NSStringNilValueSubstitute([client networkName])
		};
		
		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ([[plugin supportedServerInputCommands] containsObject:cmdl])
			{
				if ([[plugin primaryClass] respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)])
				{
					[[plugin primaryClass] didReceiveServerInputOnClient:client senderInformation:senderData messageInformation:messageData];
				}
				else
				{
					[[plugin primaryClass] messageReceivedByServer:client sender:senderData message:messageData];
				}
			}
		}
	});
}

#pragma mark -
#pragma mark Inline Content

- (NSString *)processInlineMediaContentURL:(NSString *)resource
{
    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
        if ([plugin supportsInlineMediaManipulation]) {
            NSString *input = [[plugin primaryClass] processInlineMediaContentURL:resource];

			if (input) {
				NSURL *outputURL = [NSURL URLWithString:input];
				
				if (outputURL) { // Valid URL?
					return input;
				}
			}
        }
    }

	return nil;
}

#pragma mark -
#pragma mark Input Replacement

- (id)processInterceptedUserInput:(id)input command:(NSString *)command
{
    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsUserInputDataInterception]) {
			/* Inform plugin of data. */
			input = [[plugin primaryClass] interceptUserInput:input command:command];

			/* If this plugin returned nil, then stop here. Do not pass it on to others. */
			if (input == nil) {
				return nil; // Refuse to continue.
			}
		}
    }

    return input;
}

- (IRCMessage *)processInterceptedServerInput:(IRCMessage *)input for:(IRCClient *)client
{
    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsServerInputDataInterception]) {
			/* Inform plugin of data. */
			input = [[plugin primaryClass] interceptServerInput:input for:client];

			/* If this plugin returned nil, then stop here. Do not pass it on to others. */
			if (input == nil) {
				return nil; // Refuse to continue.
			}
		}
    }

    return input;
}

- (void)postNewMessageEventForViewController:(TVCLogController *)logController messageInfo:(NSDictionary *)messageInfo isThemeReload:(BOOL)isThemeReload isHistoryReload:(BOOL)isHistoryReload
{
	TXPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ( [plugin supportsNewMessagePostedEventNotifications]) {
				[[plugin primaryClass] didPostNewMessageForViewController:logController messageInfo:messageInfo isThemeReload:isThemeReload isHistoryReload:isHistoryReload];
			}
		}
	});
}

- (NSString *)postWillRenderMessageEvent:(NSString *)newMessage lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsWillRenderMessageEventNotifications]) {
			/* Inform plugin of data. */
			NSString *pluginResult = [[plugin primaryClass] willRenderMessage:newMessage lineType:lineType memberType:memberType];
			
			/* If the plugin returns nil, then we don't care. */
			if (NSObjectIsEmpty(pluginResult)) {
				;
			} else {
				newMessage = pluginResult;
			}
		}
	}
	
	return newMessage;
}

@end
