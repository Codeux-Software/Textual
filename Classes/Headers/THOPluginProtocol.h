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

/* All THOPluginProtocol messages are called within the primary class of a plugin and
 no where else. The primary class can be defined in the Info.plist of your bundle. The
 primary class acts similiar to an application delegate whereas it is responsible for 
 the lifetime management of your plugin. */

/* Each plugin has access to the global variables [self worldController] and 
 [self masterController] which both have unrestricted access to every component of 
 Textual. There is no need to store pointers in your plugin for these. They are always
 available just by calling the above mentioned method names. */

#pragma mark -
#pragma mark Localization

/* TPILocalizedString allows a plugin to use localized text within the plugin itself
 using Textual's own API. TPILocalizedString takes a two paramaters and that is the
 key to look inside the .strings file for and the formatting values.  */
/* This call expects the localized strings to be inside the filename "BasicLanguage.strings"
 Any other name will not work unless the actual Cocoa APIs for accessing localized strings
 is used in place of these. */
#define TPILocalizedString(k, ...)		TXLocalizedStringAlternative(TPIBundleFromClass(), k, ##__VA_ARGS__)

/*!
 * @brief Returns the NSBundle that owns the calling class.
 */
#define TPIBundleFromClass()				[NSBundle bundleForClass:[self class]]

@protocol THOPluginProtocol <NSObject>

@optional

#pragma mark -
#pragma mark Subscribed Events 

/*!
 * @brief Defines a list of commands that the plugin will support as user input 
 *  from the main text field.
 *
 * @return An NSArray containing a lowercase list of commands that the plugin
 *  will support as user input from the main text field.
 *
 * @discussion Considerations:
 * 
 * 1. If a command is a number (0-9), then insert it into the array as
 *  an NSString.
 *
 * 2. If a plugin tries to add a command already built into Textual onto
 *  this list, it will not work.
 *
 * 3. It is possible, but unlikely, that another plugin the end user has
 *  loaded is subscribed to the same command. When that occurs, each plugin
 *  subscribed to the command will be informed of when the command is performed.
 *
 * 4. To avoid conflicts, a plugin cannot subscribe to a command already
 *  defined by a script. If a script and a plugin both share the same command, then
 *  neither will be executed and an error will be printed to the OS X console.
 */
- (NSArray *)subscribedUserInputCommands;

/*!
 * @brief Method invoked when a subscribed user input command requires processing.
 *
 * @param client The client responsible for the event
 * @param commandString The name of the command used by the end user
 * @param messageString Data that follows commandString
 */
- (void)userInputCommandInvokedOnClient:(IRCClient *)client commandString:(NSString *)commandString messageString:(NSString *)messageString;

/*!
 * @brief Defines a list of commands that the plugin will support as server input.
 *
 * @return An NSArray containing a lowercase list of commands that the plugin
 *  will support as server input.
 *
 * @discussion If a raw numeric (a number) is being asked for, then insert it into
 *  the array as an NSString.
 */
- (NSArray *)subscribedServerInputCommands;

/*!
 * @brief Method invoked when a subscribed server input command requires processing.
 *
 * @discussion The dictionaries sent as part of this method are guaranteed to always contain 
 *  the same key pair. When a specific key does not have a value, NSNull is used as its value.
 *
 * @param client The client responsible for the event
 * @param senderDict A dictionary which contains information related to the sender
 * @param messageDict A dictionary which contains information related to the incoming data
 *
 * @see //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderHostmaskAttribute THOPluginProtocolDidReceiveServerInputSenderHostmaskAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderUsernameAttribute THOPluginProtocolDidReceiveServerInputSenderUsernameAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderAddressAttribute THOPluginProtocolDidReceiveServerInputSenderAddressAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageReceivedAtTimeAttribute THOPluginProtocolDidReceiveServerInputMessageReceivedAtTimeAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageNumericReplyAttribute THOPluginProtocolDidReceiveServerInputMessageNumericReplyAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageCommandAttribute THOPluginProtocolDidReceiveServerInputMessageCommandAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageNetworkAddressAttribute THOPluginProtocolDidReceiveServerInputMessageNetworkAddressAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputMessageNetworkNameAttribute THOPluginProtocolDidReceiveServerInputMessageNetworkNameAttribute
 */
- (void)didReceiveServerInputOnClient:(IRCClient *)client senderInformation:(NSDictionary *)senderDict messageInformation:(NSDictionary *)messageDict;

/*!
 * @brief Whether the input was from a regular user or from the server itself.
 *
 * @return NSNumber (BOOL)
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute;

/*!
 * @brief The combined hostmask of the sender.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputSenderHostmaskAttribute;

/*!
 * @brief The nickname portion of the sender's hostmask.
 * 
 * @discussion If THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute is YES, then the
 *  value of this field is the address of the server.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute;

/*!
 * @brief The username (ident) portion of the sender's hostmask.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputSenderUsernameAttribute;

/*!
 * @brief The address portion of the sender's hostmask.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputSenderAddressAttribute;

/*!
 * @brief The date & time during which the input was receieved.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageReceivedAtTimeAttribute;

/*!
 * @brief The input, split into sections using the space character.
 *
 * @return NSArray
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute;

/*!
 * @brief The input's command
 *
 * @return
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageCommandAttribute;

/*!
 * @brief The value of @link //textual_ref/c/data/THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute THOPluginProtocolDidReceiveServerInputSenderIsServerAttribute @/link, as an integer.
 *
 * @return NSNumber (NSInteger)
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageNumericReplyAttribute;

/*!
 * @brief The input itself
 *
 * @return NSString 
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute;

/*!
 * @brief The server address of the IRC network 
 * 
 * @discussion The value of this attribute is the address of the server that Textual is 
 *  currently connected to and does not equal the sender of the input.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageNetworkAddressAttribute;

/*!
 * @brief The name of the IRC network
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidReceiveServerInputMessageNetworkNameAttribute;

#pragma mark -
#pragma mark Initialization

/*!
 * @brief Method invoked during initialization of a plugin.
 *
 * @discussion This method is invoked very early on. It occurs once the principal 
 *  class of the plugin has been allocated and is guaranteed to be the first call
 *  home that a plugin will receive from Textual.
 */
- (void)pluginLoadedIntoMemory;

/*!
 * @brief Method invoked prior to deallocation of a plugin.
 */
- (void)pluginWillBeUnloadedFromMemory;

#pragma mark -
#pragma mark Preferences Pane

/*!
 * @brief Defines an NSView used by the Preferences dialog of Textual to 
 *  allow user-interactive configuration of the plugin.
 *
 * @return An instance of NSView with a width of 567 pixels and a minimum 
 *  height of 406 pixels
 */
- (NSView *)pluginPreferencesPaneView;

/*!
 * @brief Defines an NSString which is used by the Preferences dialog of
 *  Textual to create a new entry in its navigation list.
 */
- (NSString *)pluginPreferencesPaneMenuItemName;

#pragma mark -
#pragma mark Renderer Events

/*!
 * @brief Method invoked when the Document Object Model (DOM) of a view has been modified.
 *
 * @discussion This method is invoked when a message has been added to the Document
 *  Object Model (DOM) of logController
 *
 * Depending on the type of message added, the set of keys available within the messageInfo
 *  dictionary will vary.
 *
 * @warning It is NOT recommended to do any heavy work when isThemeReload or isHistoryReload
 *  is YES as these events have thousands of messages being processed at the same time.
 * 
 * @warning This method is invoked on an asynchronous background dispatch queue. Not the 
 *  main thread. It is extremely important to remember this because WebKit will throw an
 *  exception if it is not interacted with on the main thread.
 *
 * @param logController The view responsible for the event
 * @param messageInfo A dictionary which contains information about the message
 * @param isThemeReload Whether or not the message was posted as part of a theme reload
 * @param isHistoryReload Whether or not the message was posted as part of playback on application start
 *
 * @see //textual_ref/c/data/THOPluginProtocolDidPostNewMessageLineNumberAttribute THOPluginProtocolDidPostNewMessageLineNumberAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageSenderNicknameAttribute THOPluginProtocolDidPostNewMessageSenderNicknameAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageLineTypeAttribute THOPluginProtocolDidPostNewMessageLineTypeAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageMemberTypeAttribute THOPluginProtocolDidPostNewMessageMemberTypeAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageListOfUsersAttribute THOPluginProtocolDidPostNewMessageListOfUsersAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageMessageBodyAttribute THOPluginProtocolDidPostNewMessageMessageBodyAttribute
 *  //textual_ref/c/data/THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute
*/
- (void)didPostNewMessageForViewController:(TVCLogController *)logController messageInfo:(NSDictionary *)messageInfo isThemeReload:(BOOL)isThemeReload isHistoryReload:(BOOL)isHistoryReload;

/*!
 * @brief The unique hash of the message which can be used to access the message.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageLineNumberAttribute;

/*!
 * @brief The nickname of the person and/or server responsible for producing the message.
 * This value may be empty. Not every event on IRC will have a sender value.
 *
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageSenderNicknameAttribute;

/*!
 * @brief Integer representation of TVCLogLineType
 * 
 * @return NSNumber (NSInteger)
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageLineTypeAttribute;

/*!
 * @brief Integer representation of TVCLogLineMemberType
 *
 * @return NSNumber (NSInteger)
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageMemberTypeAttribute;

/*!
 * @brief Date & time shown left of the message in the chat view.
 *
 * @return NSDate
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute;

/*!
 * @brief Array of ranges (NSRange) of text in the message body believed to be a URL.
 * 
 * @discussion Each entry in this array is another array containing two indexes. First 
 * index (0) is the range in @link //textual_ref/c/data/THOPluginProtocolDidPostNewMessageMessageBodyAttribute THOPluginProtocolDidPostNewMessageMessageBodyAttribute @/link that the
 * URL was at. The second index (1) is the URL that was found. The URL may differ from the 
 * value in the range as URL schemes may have been appended. For example, the text at the 
 * given range may be "www.example.com" whereas the entry at index 1 is "http://www.example.com"
 * 
 * @return NSArray
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute;

/*!
 * @brief List of users from the channel that appear in the message;
 * 
 * @return NSSet
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageListOfUsersAttribute;

/*!
 * @brief The contents of the message visible to the end user, minus any formatting.
 * 
 * @return NSString
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageMessageBodyAttribute;

/*!
 * @brief Whether or not a highlight word was matched in the message body.
 *
 * @return NSNumber (BOOL)
 */
TEXTUAL_EXTERN NSString * const THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute;

#pragma mark -

/*!
 * @brief Method invoked prior to a message being converted to its HTML equivalent.
 *
 * @discussion This gives a plugin the chance to modify the text that will be displayed 
 * for a certain message by replacing one or more segments of it.
 * 
 * Considerations:
 *
 * 1. Returning nil or a string with zero length from this method will indicate that there is
 *  no interest in modifying newMessage.
 *
 * 2. There is no way to inform the renderer that you do not want a specific value of newMessage
 *  shown to the end user. Use the intercept* methods for this purpose.
 *
 * @warning This method is invoked on each plugin in the order loaded. This method does not 
 *  stop for the first result returned which means that value being passed may have been
 *  modified by a plugin above the one being talked to.
 *
 * @warning Under no circumstances should you insert HTML at this point. Doing so will result 
 *  in undefined behavior.
 * 
 * @return The original and/or modified copy of newMessage
 *
 * @param newMessage An unedited copy of the message being rendered
 * @param viewController The view responsible for the event
 * @param lineType The line type of the message being rendered
 * @param memberType The member type of the message being rendered
 */
- (NSString *)willRenderMessage:(NSString *)newMessage
			  forViewController:(TVCLogController *)viewController
					   lineType:(TVCLogLineType)lineType
					 memberType:(TVCLogLineMemberType)memberType;

#pragma mark -

/*!
 * @brief Given a URL, returns the same URL or another that can be shown as an 
 *  image inline with chat.
 *
 * @return A URL that can be shown as an inline image in relation to resource or 
 *  nil to ignore.
 *
 * @discussion Considerations:
 *
 * 1. The return value must be a valid URL for an image file if non-nil.
 *  Textual validates the return value by attempting to create an instance of NSURL
 *  with it. If NSURL returns a nil object, then it is certain that a plugin returned
 *  a bad value.
 *
 * 2. Textual uses the first non-nil, valid URL, returned by a plugin. It does not
 *  chain the responses similar to other methods defined by the THOPluginProtocol
 *  protocol.
 *
 * @param resource A URL that was detected in a message being rendered.
 */
- (NSString *)processInlineMediaContentURL:(NSString *)resource;

#pragma mark -
#pragma mark Input Manipulation

/*!
 * @brief Method used to modify and/or completely ignore incoming data from
 *  the server before any action can be taken on it by Textual.
 *
 * @warning This method is invoked on each plugin in the order loaded. This method 
 *  does not stop for the first result returned which means that value being passed may
 *  have been modified by a plugin above the one being talked to.
 *
 * @warning Textual does not perform validation against the instance of IRCMessage that 
 *  is returned which means that if Textual tries to access specific information which has
 *  been improperly modified or removed, the entire application may crash.
 * 
 * @return The original and/or modified copy of IRCMessage or nil to prevent the data from being processed altogether.
 *
 * @param input An instance of IRCMessage which is the container class for parsed incoming data
 * @param client The client responsible for the event
 */
- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client;

/*!
 * @brief Method used to modify and/or completely ignore text entered into the
 *  main text field of Textual by the end user.
 *
 * @discussion This method is invoked once the user has hit return on the text field 
 *  to submit whatever its value may be.
 *
 * @warning This method is invoked on each plugin in the order loaded. This method
 *  does not stop for the first result returned which means that value being passed may
 *  have been modified by a plugin above the one being talked to.
 * 
 * @return The original and/or modified copy of input or nil to prevent the data from 
 *  being processed altogether.
 * 
 * @param input Depending on whether the value of the text field was submitted 
 *  programmatically or by the user directly interacting with it, this value can be an
 *  instance of NSString or NSAttributedString.
 * @param command Textual allows the end user to send text entered into the text field 
 *  without using the "/me" command. When this occurs, Textual informs lower-level APIs
 *  of this intent by changing the value of this parameter from "privmsg" to "action" -
 *  In most cases a plugin should disregard this parameter and pass it untouched.
 */
- (id)interceptUserInput:(id)input command:(NSString *)command;

#pragma mark -
#pragma mark Reserved Calls

/* The behavior of this method call is undefined. It exists for internal
 purposes for the plugins packaged with Textual by default. It is not
 recommended to use it, or try to understand it. */
- (NSDictionary *)pluginOutputDisplayRules;

#pragma mark -
#pragma mark Deprecated

/* Even though these methods are deprecated, they will still function 
 as they always have. They will however be removed in a future release. */
- (void)pluginLoadedIntoMemory:(IRCWorld *)world TEXTUAL_DEPRECATED("Use -pluginLoadedIntoMemory instead");
- (void)pluginUnloadedFromMemory TEXTUAL_DEPRECATED("Use -pluginWillBeUnloadedFromMemory instead");

- (NSArray *)pluginSupportsUserInputCommands TEXTUAL_DEPRECATED("Use -subscribedUserInputCommands instead");
- (NSArray *)pluginSupportsServerInputCommands TEXTUAL_DEPRECATED("Use -subscribedServerInputCommands instead");

- (NSView *)preferencesView TEXTUAL_DEPRECATED("Use -pluginPreferencesPaneView instead");
- (NSString *)preferencesMenuItemName TEXTUAL_DEPRECATED("Use -pluginPreferencesPaneMenuItemName instead");

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString TEXTUAL_DEPRECATED("Use -userInputCommandInvokedOnClient:commandString:messageString: instead");

- (void)messageReceivedByServer:(IRCClient *)client
						 sender:(NSDictionary *)senderDict
						message:(NSDictionary *)messageDict TEXTUAL_DEPRECATED("Use -didReceiveServerInputOnClient:senderInformation:messageInformation: instead");
@end
