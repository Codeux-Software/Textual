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

#import "THOPluginProtocolPrivate.h"

@interface THOPluginManager ()
@property (nonatomic, copy) NSArray *allLoadedBundles;
@property (nonatomic, copy) NSArray *allLoadedPlugins;
@end

NSString * const THOPluginProtocolCompatibilityMinimumVersion = @"5.0.0";

NSString * const THOPluginProtocolDidPostNewMessageLineNumberAttribute = @"lineNumber";
NSString * const THOPluginProtocolDidPostNewMessageSenderNicknameAttribute = @"senderNickname";
NSString * const THOPluginProtocolDidPostNewMessageLineTypeAttribute = @"lineType";
NSString * const THOPluginProtocolDidPostNewMessageMemberTypeAttribute = @"memberType";
NSString * const THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute = @"receivedAtTime";
NSString * const THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute = @"allHyperlinksInBody";
NSString * const THOPluginProtocolDidPostNewMessageListOfUsersAttribute	= @"mentionedUsers";
NSString * const THOPluginProtocolDidPostNewMessageMessageBodyAttribute	= @"messageBody";
NSString * const THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute = @"wordMatchFound";

NSString * const THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute = @"senderIsServer";
NSString * const THOPluginProtocolDidReceiveServerInputSenderHostmaskAttribute = @"senderHostmask";
NSString * const THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute = @"senderNickname";
NSString * const THOPluginProtocolDidReceiveServerInputSenderUsernameAttribute = @"senderUsername";
NSString * const THOPluginProtocolDidReceiveServerInputSenderAddressAttribute = @"senderDNSMask";

NSString * const THOPluginProtocolDidReceiveServerInputMessageReceivedAtTimeAttribute = @"messageReceived";
NSString * const THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute = @"messageParamaters";
NSString * const THOPluginProtocolDidReceiveServerInputMessageNumericReplyAttribute = @"messageNumericReply";
NSString * const THOPluginProtocolDidReceiveServerInputMessageCommandAttribute = @"messageCommand";
NSString * const THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute = @"messageSequence";
NSString * const THOPluginProtocolDidReceiveServerInputMessageNetworkAddressAttribute = @"messageServer";
NSString * const THOPluginProtocolDidReceiveServerInputMessageNetworkNameAttribute = @"messageNetwork";

@implementation THOPluginManager

#pragma mark -
#pragma mark Init.

- (instancetype)init
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
		self.dispatchQueue = NULL;
	}
}

#pragma mark -
#pragma mark Retain & Release.

- (void)loadPlugins
{
	XRPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		if (self.allLoadedBundles != nil) {
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
					if ([currPlugin supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
						_atleastOnePluginWantsPostNewMessageEvent = YES;
					}

					[loadedBundles addObject:currBundle];

					[loadedPlugins addObject:currPlugin];
				} else {
					currPlugin = nil;
				}
			}
		}

		self.allLoadedBundles = loadedBundles;

		self.allLoadedPlugins = loadedPlugins;
	});
}

- (void)unloadPlugins
{
	XRPerformBlockSynchronouslyOnQueue(self.dispatchQueue, ^{
		for (THOPluginItem *plugin in self.allLoadedPlugins) {
			[plugin sendDealloc];
		}

		self.allLoadedBundles = nil;

		self.allLoadedPlugins = nil;
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

		for (NSString *file in resourceFiles) {
			NSString *fullpath = [path stringByAppendingPathComponent:file];

			NSString *nameWoExtension = [file stringByDeletingPathExtension];

			NSString *fileExtension = [file pathExtension];

			if ([scriptExtensions containsObject:fileExtension] == NO) {
				LogToConsole(@"WARNING: File “%@“ found in unsupervised script folder but it does not have a file extension recognized by Textual. It will be ignored.", file);

				continue;
			}

			if ([[self listOfForbiddenCommandNames] containsObject:[nameWoExtension lowercaseString]]) {
				LogToConsole(@"WARNING: The command “%@“ exists as a script file, but it is being ignored because the command name is forbidden.", nameWoExtension);

				continue;
			}

			if (returnPathInfo) {
				[returnData setObjectWithoutOverride:fullpath forKey:nameWoExtension];
			} else {
				[returnData addObjectWithoutDuplication:nameWoExtension];
			}
		}
	}

	return returnData;
}

- (NSArray *)listOfForbiddenCommandNames
{
	/* List of commands that cannot be used as the name of a script 
	 because they would conflict with the commands defined by one or
	 more standard (RFC) */

	NSArray *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
							 @"THOPluginManager -> THOPluginManager List of Forbidden Commands"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResourcesFolderNamed:@"StaticStore"];

		NSArray *_blockedNames = [staticValues arrayForKey:@"THOPluginManager List of Forbidden Commands"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"THOPluginManager -> THOPluginManager List of Forbidden Commands"];

		cachedValues = _blockedNames;
	}

	return cachedValues;
}

#pragma mark -
#pragma mark Extras Installer

- (NSArray *)reservedCommandNamesForExtrasInstaller
{
	/* List of scripts that are available as downloadable
	 content from the codeux.com website. */

	NSArray *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
							 @"THOPluginManager -> THOPluginManager List of Reserved Commands"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResourcesFolderNamed:@"StaticStore"];

		NSArray *_blockedNames = [staticValues arrayForKey:@"THOPluginManager List of Reserved Commands"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"THOPluginManager -> THOPluginManager List of Reserved Commands"];

		cachedValues = _blockedNames;
	}

	return cachedValues;
}

- (void)findHandlerForOutgoingCommand:(NSString *)command
						   scriptPath:(NSString *__autoreleasing *)scriptPath
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
		
		return; // We have something so shutdown...
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
	BOOL download = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1236][2]")
													   title:TXTLS(@"BasicLanguage[1236][1]", command)
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
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
	NSString *installerURL = [RZMainBundle() pathForResource:@"Textual-Extras-MAS" ofType:@"pkg"];
#else
	NSString *installerURL = [RZMainBundle() pathForResource:@"Textual-Extras" ofType:@"pkg"];
#endif

	if (installerURL) {
		[RZWorkspace() openFile:installerURL withApplication:@"Installer"];
	}
}

#pragma mark -
#pragma mark Extension Information.

- (NSArray *)pluginOutputSuppressionRules
{
	NSMutableArray *allRules = [NSMutableArray array];

	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportsOutputSuppressionRules]) {
			NSArray *srules = [plugin outputSuppressionRules];

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
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportsSubscribedUserInputCommands]) {
			NSArray *commands = [plugin supportedUserInputCommands];

			if (commands) {
				[allCommands addObjectsFromArray:commands];
			}
		}
	}

	return allCommands;
}

- (NSArray *)supportedServerInputCommands
{
	NSMutableArray *allCommands = [NSMutableArray array];
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportsSubscribedServerInputCommands]) {
			NSArray *commands = [plugin supportedServerInputCommands];

			if (commands) {
				[allCommands addObjectsFromArray:commands];
			}
		}
	}

	return allCommands;
}

- (NSArray *)pluginsWithPreferencePanes
{
	NSMutableArray *allExtensions = [NSMutableArray array];
	
	for (THOPluginItem *plugin in self.allLoadedPlugins) {
		if ([plugin supportsFeature:THOPluginItemSupportsPreferencePane]) {
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

		NSString *bundleNameWithoutExtension = [bundleName stringByDeletingPathExtension];
		
		[allPlugins addObjectWithoutDuplication:bundleNameWithoutExtension];
	}

	return allPlugins;
}

#pragma mark -
#pragma mark Talk.

- (void)sendUserInputDataToBundles:(IRCClient *)client message:(NSString *)message command:(NSString *)command
{
	if (client == nil || message == nil || command == nil) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		NSString *uppercaseCommand = [command uppercaseString];

		NSString *lowercaseCommand = [command lowercaseString];
		
		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportsSubscribedUserInputCommands]) {
				if ([[plugin supportedUserInputCommands] containsObject:lowercaseCommand]) {
					[[plugin primaryClass] userInputCommandInvokedOnClient:client commandString:uppercaseCommand messageString:message];
				}
			}
		}
	});
}

- (void)sendServerInputDataToBundles:(IRCClient *)client message:(IRCMessage *)message
{
	if (client == nil || message == nil) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		NSString *lowercaseCommand = [[message command] lowercaseString];

		NSDictionary *senderData = nil;
		NSDictionary *messageData = nil;

		THOPluginDidReceiveServerInputConcreteObject *messageObject = [THOPluginDidReceiveServerInputConcreteObject new];

		[messageObject setSenderIsServer:[message senderIsServer]];

		[messageObject setSenderNickname:[message senderNickname]];
		[messageObject setSenderUsername:[message senderUsername]];
		[messageObject setSenderAddress:[message senderAddress]];
		[messageObject setSenderHostmask:[message senderHostmask]];

		[messageObject setReceivedAt:[message receivedAt]];

		[messageObject setMessageSequence:[message sequence]];
		[messageObject setMessageParamaters:[message params]];

		[messageObject setMessageCommand:[message command]];
		[messageObject setMessageCommandNumeric:[message commandNumeric]];

		[messageObject setNetworkAddress:[client networkAddress]];
		[messageObject setNetworkName:[client networkName]];

		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportsSubscribedServerInputCommands]) {
				if ([[plugin supportedServerInputCommands] containsObject:lowercaseCommand] == NO) {
					continue;
				}

				if ([[plugin primaryClass] respondsToSelector:@selector(didReceiveServerInput:onClient:)]) {
					[[plugin primaryClass] didReceiveServerInput:messageObject onClient:client];
				} else if ([[plugin primaryClass] respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)]) {

TEXTUAL_IGNORE_DEPRECATION_BEGIN
					if (senderData == nil) {
						senderData = @{
						   THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute	: @([messageObject senderIsServer]),
						   THOPluginProtocolDidReceiveServerInputSenderHostmaskAttribute	: NSDictionaryNilValue([messageObject senderHostmask]),
						   THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute	: NSDictionaryNilValue([messageObject senderNickname]),
						   THOPluginProtocolDidReceiveServerInputSenderUsernameAttribute	: NSDictionaryNilValue([messageObject senderUsername]),
						   THOPluginProtocolDidReceiveServerInputSenderAddressAttribute		: NSDictionaryNilValue([messageObject senderAddress])
						};
					}

					if (messageData == nil) {
						messageData = @{
							 THOPluginProtocolDidReceiveServerInputMessageReceivedAtTimeAttribute   : NSDictionaryNilValue([messageObject receivedAt]),
							 THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute		: NSDictionaryNilValue([messageObject messageParamaters]),
							 THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute			: NSDictionaryNilValue([messageObject messageSequence]),
							 THOPluginProtocolDidReceiveServerInputMessageNumericReplyAttribute		: @([messageObject messageCommandNumeric]),
							 THOPluginProtocolDidReceiveServerInputMessageCommandAttribute			:   [messageObject messageCommand],
							 THOPluginProtocolDidReceiveServerInputMessageNetworkAddressAttribute	: NSDictionaryNilValue([client networkAddress]),
							 THOPluginProtocolDidReceiveServerInputMessageNetworkNameAttribute		: NSDictionaryNilValue([client networkName])
						 };
					}

					[[plugin primaryClass] didReceiveServerInputOnClient:client senderInformation:senderData messageInformation:messageData];
TEXTUAL_IGNORE_DEPRECATION_END

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

    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportsInlineMediaManipulation]) {
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
	if (input == nil || command == nil) {
		return nil;
	}

	id inputCopy = input;
	id commandCopy = command;

    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportsUserInputDataInterception]) {
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
	if (input == nil || client == nil) {
		return nil;
	}

	IRCMessage *inputCopy = input;

    for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportsServerInputDataInterception]) {
			inputCopy = [[plugin primaryClass] interceptServerInput:inputCopy for:client];

			if (inputCopy == nil) {
				return nil; // Refuse to continue.
			}
		}
    }

    return inputCopy;
}

- (void)postNewMessageEventForViewController:(TVCLogController *)viewController withObject:(THOPluginDidPostNewMessageConcreteObject *)messageObject
{
	if (viewController == nil || messageObject == nil) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.dispatchQueue, ^{
		for (THOPluginItem *plugin in self.allLoadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
				if ([[plugin primaryClass] respondsToSelector:@selector(didPostNewMessage:forViewController:)]) {
					[[plugin primaryClass] didPostNewMessage:messageObject forViewController:viewController];
				} else if ([[plugin primaryClass] respondsToSelector:@selector(didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:)]) {
					NSMutableDictionary *pluginDictionary  = [[NSMutableDictionary alloc] initWithCapacity:9];

TEXTUAL_IGNORE_DEPRECATION_BEGIN
					[pluginDictionary setBool:[messageObject keywordMatchFound] forKey:THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute];

					[pluginDictionary setInteger:[messageObject lineType] forKey:THOPluginProtocolDidPostNewMessageLineTypeAttribute];
					[pluginDictionary setInteger:[messageObject memberType] forKey:THOPluginProtocolDidPostNewMessageMemberTypeAttribute];

					[pluginDictionary maybeSetObject:[messageObject senderNickname] forKey:THOPluginProtocolDidPostNewMessageSenderNicknameAttribute];

					[pluginDictionary maybeSetObject:[messageObject receivedAt] forKey:THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute];

					[pluginDictionary maybeSetObject:[messageObject lineNumber] forKey:THOPluginProtocolDidPostNewMessageLineNumberAttribute];

					[pluginDictionary maybeSetObject:[messageObject listOfHyperlinks] forKey:THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute];
					[pluginDictionary maybeSetObject:[messageObject listOfUsers] forKey:THOPluginProtocolDidPostNewMessageListOfUsersAttribute];

					[pluginDictionary maybeSetObject:[messageObject messageContents] forKey:THOPluginProtocolDidPostNewMessageMessageBodyAttribute];

					[[plugin primaryClass] didPostNewMessageForViewController:viewController
																  messageInfo:[pluginDictionary copy]
																isThemeReload:[messageObject isProcessedInBulk]
															  isHistoryReload:[messageObject isProcessedInBulk]];
TEXTUAL_IGNORE_DEPRECATION_END

				}
			}
		}
	});
}

- (NSString *)postWillRenderMessageEvent:(NSString *)newMessage forViewController:(TVCLogController *)viewController lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	if (newMessage == nil || viewController == nil) {
		return nil;
	}

	BOOL valueChanged = NO;

	NSString *newMessageCopy = newMessage;
	
	for (THOPluginItem *plugin in self.allLoadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportsWillRenderMessageEvent]) {
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

@implementation THOPluginDidPostNewMessageConcreteObject
@end

@implementation THOPluginDidReceiveServerInputConcreteObject
@end

@implementation THOPluginOutputSuppressionRule
@end
