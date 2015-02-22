/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

NSString * const THOPluginProtocolDidPostNewMessageLineNumberAttribute			= @"lineNumber";
NSString * const THOPluginProtocolDidPostNewMessageSenderNicknameAttribute		= @"senderNickname";
NSString * const THOPluginProtocolDidPostNewMessageLineTypeAttribute			= @"lineType";
NSString * const THOPluginProtocolDidPostNewMessageMemberTypeAttribute			= @"memberType";
NSString * const THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute		= @"receivedAtTime";
NSString * const THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute	= @"allHyperlinksInBody";
NSString * const THOPluginProtocolDidPostNewMessageListOfUsersAttribute			= @"mentionedUsers";
NSString * const THOPluginProtocolDidPostNewMessageMessageBodyAttribute			= @"messageBody";
NSString * const THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute	= @"wordMatchFound";

@implementation THOPluginManager

#pragma mark -
#pragma mark Init.

- (instancetype)init
{
	if ((self = [super init])) {
		_dispatchQueue = dispatch_queue_create("PluginManagerDispatchQueue", DISPATCH_QUEUE_SERIAL);

		return self;
	}

	return nil;
}

- (void)dealloc
{
	if (_dispatchQueue) {
		_dispatchQueue = NULL;
	}
}

#pragma mark -
#pragma mark Retain & Release.

- (void)loadPlugins
{
	XRPerformBlockAsynchronouslyOnQueue(_dispatchQueue, ^{
		if (_allLoadedBundles) {
			NSAssert(NO, @"-loadPlugins called more than one time.");
		}

		NSArray *paths = [TPCPathInfo buildPathArray:
						  [TPCPathInfo customExtensionFolderPath],
						  [TPCPathInfo bundledExtensionFolderPath],
						  nil];

		NSMutableArray *loadedBundles = [NSMutableArray array];
		NSMutableArray *loadedPlugins = [NSMutableArray array];

		NSMutableDictionary *bundlesToLoad = [NSMutableDictionary dictionary];

		for (NSString *path in paths) {
			NSArray *resourceFiles = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

			if (resourceFiles) {
				for (NSString *file in resourceFiles) {
					if ([file hasSuffix:TPCResourceManagerBundleDocumentTypeExtension]) {
						if (bundlesToLoad[file] == nil) {
							bundlesToLoad[file] = [path stringByAppendingPathComponent:file];
						}
					}
				}
			}
		}

		for (NSString *bundleName in bundlesToLoad) {
			NSString *bundlePath = bundlesToLoad[bundleName];

			NSBundle *currBundle = [NSBundle bundleWithPath:bundlePath];

			if (currBundle) {
				THOPluginItem *currPlugin = [THOPluginItem new];

				BOOL bundleLoaded = [currPlugin loadBundle:currBundle];

				if (bundleLoaded) {
					[loadedBundles addObject:currBundle];
					[loadedPlugins addObject:currPlugin];
				} else {
					currPlugin = nil;
				}
			}
		}

		[self setAllLoadedBundles:loadedBundles];
		[self setAllLoadedPlugins:loadedPlugins];
	});
}

- (void)unloadPlugins
{
	XRPerformBlockSynchronouslyOnQueue(_dispatchQueue, ^{
		for (THOPluginItem *plugin in _allLoadedPlugins) {
			[plugin sendDealloc];
		}

		[self setAllLoadedPlugins:nil];
		[self setAllLoadedBundles:nil];
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
							[TPCPathInfo bundledScriptFolderPath],
							nil];
	
	/* Begin scanning folders. */
	id returnData = nil;

	if (returnPathInfo) {
		returnData = [NSMutableDictionary dictionary];
	} else {
		returnData = [NSMutableArray array];
	}

	for ( NSString *path in scriptPaths) {
		NSArray *resourceFiles = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

		for (__strong NSString *file in resourceFiles) {
			NSString *fullpath = [path stringByAppendingPathComponent:file];

			NSString *extens = NSStringEmptyPlaceholder;

			if ([file contains:@"."]) {
				NSArray *nameParts = [file componentsSeparatedByString:@"."];

				file = nameParts[0];
				extens = nameParts[1];

				if ([scriptExtensions containsObject:extens] == NO) {
					continue;
				}
			}

			if (returnPathInfo) {
				[returnData setObjectWithoutOverride:fullpath forKey:file];
			} else {
				[returnData addObjectWithoutDuplication:file];
			}
		}
	}

	return returnData;
}

#pragma mark -
#pragma mark Extras Installer

- (NSArray *)reservedCommandNamesForExtrasInstaller
{
	/* List of scripts that are available as downloadable
	 content from the codeux.com website. */

	static NSArray *_reservedNames = nil;

	if (_reservedNames == nil) {
		_reservedNames = @[
		   @"apps",
		   @"banhammer",
		   @"ffuu",
		   @"flip",
		   @"hermes",
		   @"instacast",
		   @"itunes",
		   @"music",
		   @"np",
		   @"o_p",
		   @"page",
		   @"qt",
		   @"radium",
		   @"rdio",
		   @"reverse",
		   @"shell",
		   @"slap",
		   @"spotify",
		   @"uuid",
		   @"vlc",
		];
	}

	return _reservedNames;
}

- (void)findHandlerForOutgoingCommand:(NSString *)command
						   scriptPath:(NSString **)scriptPath
						   isReserved:(BOOL *)isReserved
							 isScript:(BOOL *)isScript
						  isExtension:(BOOL *)isExtension
{
	/* Find any script patching this command. */
	NSDictionary *scriptPaths = [sharedPluginManager() supportedAppleScriptCommands:YES];
	
	NSString *_scriptPath = nil;
	
	for (NSString *scriptCommand in scriptPaths) {
		if ([scriptCommand isEqualToString:command]) {
			_scriptPath = scriptPaths[command];
		}
	}
	
	/* If the script exists, return it, otherwise continue to 
	 the list of reserved script names. */
	if (_scriptPath) {
		*scriptPath = _scriptPath;
		
		*isScript = YES;
		*isReserved = NO;
		*isExtension = NO;
		
		return; // We have something so shutdown…
	} else {
		*isScript = NO;
		
		/* Check if list of extensions. */
		BOOL _pluginFound = [[self supportedUserInputCommands] containsObject:command];

		if (_pluginFound) {
			*isExtension = YES;
			
			return; // We found an extension.
		} else {
			*isExtension = NO;
		}
		
		/* Prompt user if command exists as a reserved command. */
		NSArray *reservedNames = [self reservedCommandNamesForExtrasInstaller];
		
		if ([reservedNames containsObject:command]) {
			*isReserved = YES;
		} else {
			*isReserved = NO;
		}
	}
}

- (void)maybeOpenExtrasInstallerDownloadURLForCommand:(NSString *)command
{
	BOOL download = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1236][2]", command)
													   title:TXTLS(@"BasicLanguage[1236][1]")
											   defaultButton:TXTLS(@"BasicLanguage[1236][3]")
											 alternateButton:BLS(1009)
											  suppressionKey:@"plugin_manager_reserved_command_dialog"
											 suppressionText:nil];

	if (download) {
		[self openExtrasInstallerDownloadURL];
	}
}

- (void)openExtrasInstallerDownloadURL
{
	NSString *currentVersion = [TPCApplicationInfo applicationVersion];

	NSString *urlToOpen = [NSString stringWithFormat:@"http://www.codeux.com/textual/downloads/latestExtrasInstaller.download?version=%@", [currentVersion encodeURIFragment]];

	[RZWorkspace() openURL:[NSURL URLWithString:urlToOpen]];
}

#pragma mark -
#pragma mark Extension Information.

/* Everything else. */
- (NSArray *)outputRulesForCommand:(NSString *)command
{
	NSMutableArray *allRules = [NSMutableArray array];

	for (THOPluginItem *plugin in _allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureOutputSuppressionRulesFlag]) {
			NSArray *srules = [[plugin outputSuppressionRules] arrayForKey:command];

			if (srules) {
				[allRules addObjectsFromArray:srules];
			}
		}
	}

	return allRules;
}

- (NSArray *)supportedUserInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];
	
	for (THOPluginItem *plugin in _allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommandsNewStyleFlag] ||
			[plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommandsOldStyleFlag])
		{
			[allCommands addObjectsFromArray:[plugin supportedUserInputCommands]];
		}
	}

	return allCommands;
}

- (NSArray *)supportedServerInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];
	
	for (THOPluginItem *plugin in _allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommandsNewStyleFlag] ||
			[plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommandsOldStyleFlag])
		{
			[allCommands addObjectsFromArray:[plugin supportedServerInputCommands]];
		}
	}

	return allCommands;
}

- (NSArray *)pluginsWithPreferencePanes
{
	NSMutableArray *allExtensions = [NSMutableArray array];
	
	for (THOPluginItem *plugin in _allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportedFeaturePreferencePaneNewStyleFlag] ||
			[plugin supportsFeature:THOPluginItemSupportedFeaturePreferencePaneOldStyleFlag])
		{
			[allExtensions addObject:plugin];
		}
	}

	return allExtensions;
}

- (NSArray *)allLoadedExtensions
{
	NSMutableArray *allPlugins = [NSMutableArray array];
	
	for (NSBundle *bundle in _allLoadedBundles) {
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
	XRPerformBlockAsynchronouslyOnQueue(_dispatchQueue, ^{
		NSString *cmdUpper = [command uppercaseString];

		NSString *cmdLower = [command lowercaseString];
		
		for (THOPluginItem *plugin in _allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommandsNewStyleFlag] ||
				[plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommandsOldStyleFlag])
			{
				if ([[plugin supportedUserInputCommands] containsObject:cmdLower]) {
					if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommandsNewStyleFlag]) {
						[[plugin primaryClass] userInputCommandInvokedOnClient:client commandString:cmdUpper messageString:message];
					} else {
						[[plugin primaryClass] messageSentByUser:client message:message command:cmdUpper];
					}
				}
			}
		}
	});
}

- (void)sendServerInputDataToBundles:(IRCClient *)client message:(IRCMessage *)message
{
	XRPerformBlockAsynchronouslyOnQueue(_dispatchQueue, ^{
		NSString *cmdLower = [[message command] lowercaseString];

		NSDictionary *senderData = @{
			@"senderIsServer"	: @([[message sender] isServer]),
			@"senderHostmask"	: NSDictionaryNilValue([message senderHostmask]),
			@"senderNickname"	: NSDictionaryNilValue([message senderNickname]),
			@"senderUsername"	: NSDictionaryNilValue([message senderUsername]),
			@"senderDNSMask"	: NSDictionaryNilValue([message senderAddress])
		};

		NSDictionary *messageData = @{
			@"messageReceived"      :   [message receivedAt],
			@"messageParamaters"	:   [message params],
			@"messageNumericReply"	: @([message numericReply]),
			@"messageCommand"		:   [message command],
			@"messageSequence"		: NSDictionaryNilValue([message sequence]),
			@"messageServer"		: NSDictionaryNilValue([client networkAddress]),
			@"messageNetwork"		: NSDictionaryNilValue([client networkName])
		};
		
		for (THOPluginItem *plugin in _allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommandsNewStyleFlag] ||
				[plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommandsOldStyleFlag])
			{
				if ([[plugin supportedServerInputCommands] containsObject:cmdLower]) {
					if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommandsNewStyleFlag]) {
						[[plugin primaryClass] didReceiveServerInputOnClient:client senderInformation:senderData messageInformation:messageData];
					} else {
						[[plugin primaryClass] messageReceivedByServer:client sender:senderData message:messageData];
					}
				}
			}
		}
	});
}

#pragma mark -
#pragma mark Inline Content

- (NSString *)processInlineMediaContentURL:(NSString *)resource
{
	id resourceCopy = resource;

    for (THOPluginItem *plugin in _allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureInlineMediaManipulationFlag]) {
            NSString *input = [[plugin primaryClass] processInlineMediaContentURL:resourceCopy];

			if (input) {
				NSURL *outputURL = [NSURL URLWithString:input];
				
				if (outputURL) { // Valid URL?
					return [input copy];
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
	id inputCopy = input;
	id commandCopy = command;

    for (THOPluginItem *plugin in _allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureUserInputDataInterceptionFlag]) {
			inputCopy = [[plugin primaryClass] interceptUserInput:inputCopy command:commandCopy];

			if (inputCopy == nil) {
				return nil; // Refuse to continue.
			}
		}
    }

    return inputCopy;
}

- (IRCMessage *)processInterceptedServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	IRCMessage *inputCopy = input;

    for (THOPluginItem *plugin in _allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureServerInputDataInterceptionFlag]) {
			inputCopy = [[plugin primaryClass] interceptServerInput:inputCopy for:client];

			if (inputCopy == nil) {
				return nil; // Refuse to continue.
			}
		}
    }

    return inputCopy;
}

- (void)postNewMessageEventForViewController:(TVCLogController *)logController messageInfo:(NSDictionary *)messageInfo isThemeReload:(BOOL)isThemeReload isHistoryReload:(BOOL)isHistoryReload
{
	XRPerformBlockAsynchronouslyOnQueue(_dispatchQueue, ^{
		for (THOPluginItem *plugin in _allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureNewMessagePostedEventFlag]) {
				[[plugin primaryClass] didPostNewMessageForViewController:logController messageInfo:messageInfo isThemeReload:isThemeReload isHistoryReload:isHistoryReload];
			}
		}
	});
}

- (NSString *)postWillRenderMessageEvent:(NSString *)newMessage forViewController:(TVCLogController *)viewController lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	BOOL valueChanged = NO;

	NSString *newMessageCopy = newMessage;
	
	for (THOPluginItem *plugin in _allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureWillRenderMessageEventFlag]) {
			NSString *pluginResult = [[plugin primaryClass] willRenderMessage:newMessageCopy forViewController:viewController lineType:lineType memberType:memberType];

			if (NSObjectIsEmpty(pluginResult)) {
				;
			} else {
				if ([pluginResult isEqualToString:newMessageCopy] == NO) {
					newMessageCopy = pluginResult;
					
					valueChanged = YES;
				}
			}
		}
	}
	
	if (valueChanged) {
		return [newMessageCopy copy];
	} else {
		return  newMessageCopy;
	}
}

@end
