/* *********************************************************************
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

/* Please DO NOT use any code declared within this header inside of a plugin.
 The code contained by this header file was designed to be used internally for
 Textual and may be dangerous to use otherwise. */

@interface THOPluginManager : NSObject
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

/* Manage loaded plugins. */
- (void)loadPlugins;
- (void)unloadPlugins;

/* Information about loaded plugins. */
@property (readonly, copy) NSArray *supportedUserInputCommands;
@property (readonly, copy) NSArray *supportedServerInputCommands;

@property (readonly, copy) id supportedAppleScriptCommands;
- (id)supportedAppleScriptCommands:(BOOL)returnPathInfo;

@property (readonly, copy) NSArray *pluginsWithPreferencePanes;

@property (readonly, copy) NSArray *pluginOutputSuppressionRules;

/* Returns YES if at least one loaded plugin supports the feature. */
- (BOOL)supportsFeature:(THOPluginItemSupportedFeatures)feature;

- (void)findHandlerForOutgoingCommand:(NSString *)command
						   scriptPath:(NSString **)scriptPath
						   isReserved:(BOOL *)isReserved
							 isScript:(BOOL *)isScript
						  isExtension:(BOOL *)isExtension;

/* Installer */
- (void)extrasInstallerAskUserIfTheyWantToInstallCommand:(NSString *)command;
- (void)extrasInstallerLaunchInstaller;

/* Talk to plugins. */
/* Unless you are Textual, do not call these. We mean it. */
- (NSString *)processInlineMediaContentURL:(NSString *)resource;

- (id)processInterceptedUserInput:(id)input command:(NSString *)command;

- (IRCMessage *)processInterceptedServerInput:(IRCMessage *)input for:(IRCClient *)client;

- (void)sendServerInputDataToBundles:(IRCClient *)client message:(IRCMessage *)message;
- (void)sendUserInputDataToBundles:(IRCClient *)client message:(NSString *)message command:(NSString *)command;

- (void)postNewMessageEventForViewController:(TVCLogController *)viewController withObject:(THOPluginDidPostNewMessageConcreteObject *)messageObject;

- (NSString *)postWillRenderMessageEvent:(NSString *)newMessage
					   forViewController:(TVCLogController *)viewController
								lineType:(TVCLogLineType)lineType
							  memberType:(TVCLogLineMemberType)memberType;

- (BOOL)postReceivedPlainTextMessageEvent:(NSString *)text
							   authoredBy:(IRCPrefix *)textAuthor
							  destinedFor:(IRCChannel *)textDestination
							   asLineType:(TVCLogLineType)lineType
								 onClient:(IRCClient *)client
							   receivedAt:(NSDate *)receivedAt
							 wasEncrypted:(BOOL)wasEncrypted;

- (BOOL)postReceivedCommand:(NSString *)command
				   withText:(NSString *)text
				 authoredBy:(IRCPrefix *)textAuthor
				destinedFor:(IRCChannel *)textDestination
				   onClient:(IRCClient *)client
				 receivedAt:(NSDate *)receivedAt;
@end
