/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@interface THOPluginManager ()
@property (nonatomic, strong) NSArray *allLoadedBundles;
@property (nonatomic, strong) NSArray *allLoadedPlugins;
@end

@implementation THOPluginManager

#pragma mark -
#pragma mark Easy Pointer.

+ (THOPluginManager *)defaultManager
{
	TXMasterController *master = [THOPluginManager masterController];

	if (master) {
		return master.pluginManager;
	}

	return nil;
}

#pragma mark -
#pragma mark Retain & Release.

- (void)loadPlugins
{
	if (NSObjectIsNotEmpty(self.allLoadedBundles)) {
		return;
	}

	// ---- //

    NSString *path_1 = [TPCPreferences customExtensionFolderPath];
    NSString *path_2 = [TPCPreferences bundledExtensionFolderPath];;

    NSMutableArray *loadedBundles = [NSMutableArray array];
    NSMutableArray *loadedPlugins = [NSMutableArray array];
	
    NSMutableArray *resourceBundles = [NSMutableArray array];

    NSArray *resourceFiles_1 = [RZFileManager() contentsOfDirectoryAtPath:path_1 error:NULL];
    NSArray *resourceFiles_2 = [RZFileManager() contentsOfDirectoryAtPath:path_2 error:NULL];

    NSArray *resourceFiles = [resourceFiles_1 arrayByAddingObjectsFromArray:resourceFiles_2];

    for (NSString *file in resourceFiles) {
        [resourceBundles safeAddObjectWithoutDuplication:file];
    }

	// ---- //

    for (NSString *file in resourceBundles) {
        if ([file hasSuffix:@".bundle"]) {
            NSString *fullPath = [path_1 stringByAppendingPathComponent:file];

            if ([RZFileManager() fileExistsAtPath:fullPath] == NO) {
                fullPath = [path_2 stringByAppendingPathComponent:file];
            }

			NSBundle *currBundle = [NSBundle bundleWithPath:fullPath];

			if (currBundle) {
				THOPluginItem *currPlugin = [THOPluginItem new];

				[currPlugin loadBundle:currBundle];

				[loadedBundles safeAddObject:currBundle];
				[loadedPlugins safeAddObject:currPlugin];
			}
		}
	}

	// ---- //

	self.allLoadedBundles = loadedBundles;
	self.allLoadedPlugins = loadedPlugins;
}

- (void)unloadPlugins
{
	id prefController = [self.masterController.menuController windowFromWindowList:@"TDCPreferencesController"];

	if (prefController) {
		if ([prefController isWindowLoaded]) {
			[[prefController window] close];
		}
	}

	// ---- //

	self.allLoadedPlugins = nil;

	for (NSBundle *bundle in self.allLoadedBundles) {
		if ([bundle isLoaded]) {
			[bundle unload];
		}
	}
	
	self.allLoadedBundles = nil;
}

#pragma mark -
#pragma mark AppleScript Support.

- (id)supportedAppleScriptCommands
{
	return [self supportedAppleScriptCommands:NO];
}

- (id)supportedAppleScriptCommands:(BOOL)returnPathInfo
{
	NSArray *scriptExtensions = @[@"scpt", @"py", @"pyc", @"rb", @"pl", @"sh", @"php", @"bash"];

	NSArray *scriptPaths = @[
        NSStringNilValueSubstitute([TPCPreferences systemUnsupervisedScriptFolderPath]),
		NSStringNilValueSubstitute([TPCPreferences customScriptFolderPath]),
		NSStringNilValueSubstitute([TPCPreferences bundledScriptFolderPath]),
	];

	id returnData;

	if (returnPathInfo) {
		returnData = [NSMutableDictionary dictionary];
	} else {
		returnData = [NSMutableArray array];
	}

	for (NSString *path in scriptPaths) {
		if (NSObjectIsNotEmpty(path)) {
			NSArray *resourceFiles = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

			if (NSObjectIsNotEmpty(resourceFiles)) {
				for (NSString *file in resourceFiles) {
					NSString *fullpa = [path stringByAppendingPathComponent:file];
					NSString *script = [file lowercaseString];

					if ([file hasPrefix:@"."] || [file hasSuffix:@".rtf"]) {
						continue;
					}

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
							[returnData safeSetObjectWithoutOverride:fullpa forKey:script];
						}
					} else {
						if ([returnData containsObject:script] == NO) {
							[returnData safeAddObjectWithoutDuplication:script];
						}
					}
				}
			}
		}
	}
	
	return returnData;
}

#pragma mark -
#pragma mark Extension Information.

/* List of commands that may be part of Textual that we hide due to them
 being known to the general populous may result in unexpected harm such as 
 spamming by not understanding what they do. 
 
 These commands are only excluded from the list of installed addons. We 
 cannot actually prevent the user from executing them. */

- (NSArray *)dangerousCommandNames
{
    return @[@"clone", @"cloned", @"unclone", @"hspam", @"spam"];
}

/* Everything else. */
- (NSArray *)outputRulesForCommand:(NSString *)command
{
	NSMutableArray *allRules = [NSMutableArray array];

	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		NSArray *srules = [plugin.outputSuppressionRules arrayForKey:command];

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
		[allCommands addObjectsFromArray:plugin.supportedUserInputCommands];
	}

	return allCommands;
}

- (NSArray *)supportedServerInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];

	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		[allCommands addObjectsFromArray:plugin.supportedServerInputCommands];
	}

	return allCommands;
}

- (NSArray *)pluginsWithPreferencePanes
{
	NSMutableArray *allExtensions = [NSMutableArray array];

	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if (plugin.hasPreferencePaneView) {
			[allExtensions safeAddObject:plugin];
		}
	}

	return allExtensions;
}

- (NSArray *)allLoadedExtensions
{
	NSMutableArray *allPlugins = [NSMutableArray array];

	for (NSBundle *bundle in self.allLoadedBundles) {
		NSString *path = bundle.bundlePath;

		[allPlugins safeAddObjectWithoutDuplication:path.lastPathComponent.stringByDeletingPathExtension];
	}

	return allPlugins;
}

#pragma mark -
#pragma mark Talk.

- (void)sendUserInputDataToBundles:(IRCClient *)client message:(NSString *)message command:(NSString *)command
{
	NSString *cmdu = command.uppercaseString;
	NSString *cmdl = command.lowercaseString;
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin.supportedUserInputCommands containsObject:cmdl]) {
			[plugin.primaryClass messageSentByUser:client message:message command:cmdu];
		}
	}
}

- (void)sendServerInputDataToBundles:(IRCClient *)client message:(IRCMessage *)message
{
	NSString *cmdl = message.command.lowercaseString;

	NSDictionary *senderData = @{
		@"senderHostmask"	: NSStringNilValueSubstitute(message.sender.hostmask),
		@"senderNickname"	: NSStringNilValueSubstitute(message.sender.nickname),
		@"senderUsername"	: NSStringNilValueSubstitute(message.sender.username),
		@"senderDNSMask"	: NSStringNilValueSubstitute(message.sender.address),
		@"senderIsServer"	: @(message.sender.isServer)
	};

	NSDictionary *messageData = @{
		@"messageReceived"      : message.receivedAt,
		@"messageParamaters"	: message.params,
		@"messageCommand"		: NSStringNilValueSubstitute(message.command),
		@"messageSequence"		: NSStringNilValueSubstitute(message.sequence),
		@"messageServer"		: NSStringNilValueSubstitute([client networkAddress]),
		@"messageNetwork"		: NSStringNilValueSubstitute([client networkName]),
		@"messageNumericReply"	: @(message.numericReply)
	};
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin.supportedServerInputCommands containsObject:cmdl]) {
			[plugin.primaryClass messageReceivedByServer:client sender:senderData message:messageData];
		}
	}
}

#pragma mark -
#pragma mark Inline Content

- (NSString *)processInlineMediaContentURL:(NSString *)resource
{
    for (THOPluginItem *plugin in self.allLoadedPlugins) {
        if ([plugin.primaryClass respondsToSelector:@selector(processInlineMediaContentURL:)]) {
            NSString *input = [plugin.primaryClass processInlineMediaContentURL:resource];

			if (input.length >= 15) {
				return input;
			}
        }
    }

	return nil;
}

#pragma mark -
#pragma mark Input Replacement

- (id)processInterceptedUserInput:(id)input command:(NSString *)command
{
    for (THOPluginItem *plugin in self.allLoadedPlugins) {
        if ([plugin.primaryClass respondsToSelector:@selector(interceptUserInput:command:)]) {
            input = [plugin.primaryClass interceptUserInput:input command:command];
        }
    }

    return input;
}

- (IRCMessage *)processInterceptedServerInput:(IRCMessage *)input for:(IRCClient *)client
{
    for (THOPluginItem *plugin in self.allLoadedPlugins) {
        if ([plugin.primaryClass respondsToSelector:@selector(interceptServerInput:for:)]) {
            input = [plugin.primaryClass interceptServerInput:input for:client];
        }
    }

    return input;
}

@end
