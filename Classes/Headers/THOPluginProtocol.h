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

/* TPILS and TPIFLS allow a plugin to use localized text within the plugin itself using
 Textual's own API. TPILS takes a single paramater and that is the key to look inside 
 the .strings file for. TPIFLS takes a key then as many paramaters as needed after. 
 TPIFLS takes the key given, finds the localized string, then formats it similar to 
 NSString stringWithFormat:… 
 
 These calls expect the localized strings to be inside the filename "BasicLanguage.strings"
 Any other name will not work unless the actual cocoa APIs for accessing localized strings
 is used in place of these. */
#define TPILS(k)			 TSBLS(k, [NSBundle bundleForClass:[self class]])
#define TPIFLS(k, ...)		TSBFLS(k, [NSBundle bundleForClass:[self class]], ##__VA_ARGS__)

@protocol THOPluginProtocol <NSObject>

@optional

- (NSArray *)pluginSupportsUserInputCommands;
- (NSArray *)pluginSupportsServerInputCommands;

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString;

- (void)messageReceivedByServer:(IRCClient *)client 
						 sender:(NSDictionary *)senderDict 
						message:(NSDictionary *)messageDict;

- (NSDictionary *)pluginOutputDisplayRules;

- (void)pluginLoadedIntoMemory:(IRCWorld *)world;
- (void)pluginUnloadedFromMemory;

- (NSView *)preferencesView;
- (NSString *)preferencesMenuItemName;

/* Process inline media to add custom support for various URLs. */
/* Given a URL, the plugin is expected to return an NSString which represents
 an image to be shown inline. Nothing complex. */
/* Unlike other methods defined below, this one does not hand the URL to every
 plugin. Once one plugin has a returned URL, then it stops and continues to the 
 next URL in the message being parsed. The return value is not checked if it is a
 valid URL. Only whether its length is greater or equal to at least 15 characters
 to allow a scheme, domain, and small filename to be defined. */
- (NSString *)processInlineMediaContentURL:(NSString *)resource;

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
@end
