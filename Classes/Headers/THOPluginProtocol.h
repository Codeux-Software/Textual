/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

/* All THOPluginProtocol messages are called within the primary class of a plugin and
 no where else. The primary class can be defined in the Info.plist of your bundle. The
 primary class acts similiar to an application delegate whereas it is responsible for 
 the lifetime management of your plugin. */
/* Each plugin has access to the global variables [self worldController] and 
 [self masterController] which both have unrestricted access to every single API inside
 itself. There is no need to store pointers in your plugin to these. They are always
 available just by calling the above mentioned method names. */

#pragma mark -
#pragma mark Localization

/* TPILS and TPIFLS allow a plugin to use localized text within the plugin itself using
 Textual's own API. TPILS takes a single paramater and that is the key to look inside 
 the .strings file for. TPIFLS takes a key then as many paramaters as needed after. 
 TPIFLS takes the key given, finds the localized string, then formats it similar to 
 NSString stringWithFormat:… 
 
 These calls expect the localized strings to be inside the filename "BasicLanguage.strings"
 Any other name will not work unless the actual cocoa APIs for accessing localized strings
 is used in place of these. */
#define TPIBundleFromClass()		[NSBundle bundleForClass:[self class]]

#define TPILS(k)			 TSBLS(k, [NSBundle bundleForClass:[self class]])
#define TPIFLS(k, ...)		TSBFLS(k, [NSBundle bundleForClass:[self class]], ##__VA_ARGS__)

@protocol THOPluginProtocol <NSObject>

@optional

#pragma mark -
#pragma mark Subscribed Events 

/* Array of commands for a plugin to subscribe to for notifications. */
- (NSArray *)subscribedUserInputCommands;
- (NSArray *)subscribedServerInputCommand;

/* Method called when a user input command subscribed to was invoked. */
- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString;

/* Method called when a server input command subscribed to was received. */
- (void)didReceiveServerInputOnClient:(IRCClient *)client
					senderInformation:(NSDictionary *)senderDict
				   messageInformation:(NSDictionary *)messageDict;

#pragma mark -
#pragma mark Initialization

/* Method called when the primary class of a plugin is initialized. This
 method is called before any setup has been staged. It is called the second
 -new is called on the primary class. This method is a substitute for 
 subclassing the -init method of your primary class. */
- (void)pluginLoadedIntoMemory;

/* Method called during -dealloc of the overall wrapper for the plugin
 stored internally by Textual so prepare for termination at this point. 
 Save any unsaved data and make sure any open dialogs have been closed. */
- (void)pluginWillBeUnloadedFromMemory;

#pragma mark -
#pragma mark Preferences Pane

- (NSView *)pluginPreferencesPaneView;
- (NSString *)pluginPreferencesPaneMenuItemName;

#pragma mark -
#pragma mark Renderer Events

/* Called the moment a new line has been posted to any view in Textual. 
 
 logController has access to the DOM of that view and all associated data.
 
 lineNumber is the actual line number that was assigned to the message when
 it was inserted into the DOM.

 isThemeReload informs the call whether the insertion occured during a style
 reload. Style reloads occur when a style is changed and the entire view has
 to have each message repopulated.
 
 isHistoryReload informs the call whether the insertion occured when the view
 was first initalized and it was part of the data from previous session being
 reloaded into the view. 
 
 It is NOT recommended to do any heavy work when isThemeReload and isHistoryReload
 is YES as these events have thousands of messages being processed.
 
 These events are posted on the dispatch queue associated with the internal plugin
 manager. They are never received on the main thread. IT IS EXTREMELY IMPORTANT
 TO REMEMBER THIS BECAUSE WEBKIT REQUIRES MODIFICATIONS TO THE DOM TO OCCUR ON THE
 MAIN THREAD. So yeah, if you are are doing anything in inside this method that
 involves accessing this message, then do so on main thread. */
- (void)didPostNewMessageForViewController:(TVCLogController *)logController
								lineNumber:(NSString *)lineNumber
							 isThemeReload:(BOOL)isThemeReload
						   isHistoryReload:(BOOL)isHistoryReload;

/* Process inline media to add custom support for various URLs. */
/* Given a URL, the plugin is expected to return an NSString which represents
 an image to be shown inline. Nothing complex. */
/* If the return result is unable to be created into an NSURL, then the
 result is discareded. */
- (NSString *)processInlineMediaContentURL:(NSString *)resource;

#pragma mark -
#pragma mark Input Manipulation

/* Process server input before Textual does. Return nil to have it ignored. */
/* This method is passed a copy of the IRCMessage class which is an internal
 representation of the parsed input line. This method can be used to have
 certain events ignored completely based on what the plugin functions as. */
/* Expected result is the same IRCMessage item with parameters and information
 manipulated as needed. Or, nil for the item to be ignored. */
/* The input of this call is passed to every plugin that Textual has loaded in 
 sequential order based on when it was loaded. Keep this in mind as another plugin 
 loaded may have altered the input already. This is unlikely unless the user has 
 loaded a lot of custom plugins, but it is a possibility. */
- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client;

/* Process user input before Textual does. Return nil to have it ignored. */
/* This command may be fed an NSAttributedString or NSString. If it is an
 NSAttributedString, it most likely contains user defined text formatting.
 Honor that formatting. Do not turn an NSAttributedString into an NSString.
 Return the type you are given and make sure you check the type you get to
 make sure it is handled appropriately. Do not give us a clean NSString if
 we handed you an NSAttributedString that contains formatting. */
/* The input of this call is passed to every plugin that Textual has loaded in
 sequential order based on when it was loaded. Keep this in mind as another plugin
 loaded may have altered the input already. This is unlikely unless the user has
 loaded a lot of custom plugins, but it is a possibility. */
- (id)interceptUserInput:(id)input command:(NSString *)command;

#pragma mark -
#pragma mark Reserved Calls

/* The behavior of this method call is undefined. It exists for internal
 purposes for the plugins packaged with Textual by default. It is not
 recommended to use it. */
- (NSDictionary *)pluginOutputDisplayRules;

#pragma mark -
#pragma mark Deprecated

/* Even though these methods are deprecated, they will still function 
 as they always have. They will however be removed in a future release. */
- (void)pluginLoadedIntoMemory:(IRCWorld *)world TEXTUAL_DEPRECATED;
- (void)pluginUnloadedFromMemory TEXTUAL_DEPRECATED;

- (NSArray *)pluginSupportsUserInputCommands TEXTUAL_DEPRECATED;
- (NSArray *)pluginSupportsServerInputCommands TEXTUAL_DEPRECATED;

- (NSView *)preferencesView TEXTUAL_DEPRECATED;
- (NSString *)preferencesMenuItemName TEXTUAL_DEPRECATED;

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString TEXTUAL_DEPRECATED;

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict TEXTUAL_DEPRECATED;
@end
