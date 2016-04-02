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

#import "TVCLogObjectsPrivate.h"

#import "IRCUserPrivate.h"

#include <objc/message.h>

@interface TVCLogScriptEventSink ()
@property (nonatomic, strong) WKUserContentController *userContentController;
@end

@interface TVCLogScriptEventSinkContext : NSObject
@property (nonatomic, weak) TVCLogView *webView;
@property (readonly) TVCLogPolicy *webViewPolicy;
@property (readonly) TVCLogController *logController;
@property (readonly) IRCClient *associatedClient;
@property (readonly) IRCChannel *associatedChannel;
@property (nonatomic, copy) NSArray *arguments;
@end

@implementation TVCLogScriptEventSink

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if (sel == @selector(init) ||
		sel == @selector(webView) ||
		sel == @selector(webViewPolicy) ||
 		sel == @selector(associatedClient) ||
		sel == @selector(associatedChannel))
	{
		return YES;
	}

	if ([NSStringFromSelector(sel) hasPrefix:@"_"]) {
		return NO;
	}

	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
	return nil;
}

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args
{
	SEL handlerSelector = NSSelectorFromString([name stringByAppendingString:@":inWebView:"]);

	if ([self respondsToSelector:handlerSelector] == NO) {
		return @(NO);
	}

	if (args && [args count] > 0) {
		id argument = args[0];

		if ([argument isKindOfClass:[WebScriptObject class]]) {
			argument = [[self parentView] webScriptObjectToCommon:argument];
		}

		(void)objc_msgSend(self, handlerSelector, argument, [self parentView]);
	} else {
		(void)objc_msgSend(self, handlerSelector, nil, [self parentView]);
	}

	return @(YES);
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
	return YES;
}

+ (NSString *)webScriptNameForKey:(const char *)name
{
	return nil;
}

+ (id)objectValueToCommon:(id)object
{
	if ([object isKindOfClass:[NSNull class]] ||
		[object isKindOfClass:[WebUndefined class]])
	{
		return nil;
	}

	if ([object isKindOfClass:[NSString class]]) {
		return [object gtm_stringByUnescapingFromHTML];
	}

	return object;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
	NSString *handlerName = [message name];

	SEL handlerSelector = NSSelectorFromString([handlerName stringByAppendingString:@":inWebView:"]);

	if ([self respondsToSelector:handlerSelector] == NO) {
		return;
	}

	if ([TVCLogScriptEventSink isSelectorExcludedFromWebScript:handlerSelector]) {
		return;
	}

	(void)objc_msgSend(self, handlerSelector, [message body], [message webView]);
}

- (void)processInputData:(id)inputData inWebView:(id)webView forSelector:(SEL)selector
{
	[self processInputData:inputData inWebView:webView forSelector:selector minimumArgumentCount:0 withValidation:nil];
}

- (void)processInputData:(id)inputData
			   inWebView:(id)webView
			 forSelector:(SEL)selector
   minimumArgumentCount:(NSInteger)minimumArgumentCount
		  withValidation:(BOOL (^)(NSInteger argumentIndex, id argument))validateArgumentBlock
{
	TVCLogView *intWebView = nil;

	if ([webView isKindOfClass:[TVCLogView class]]) {
		intWebView = webView;
	} else if ([webView isKindOfClass:[TVCLogViewInternalWK1 class]] ||
			   [webView isKindOfClass:[TVCLogViewInternalWK2 class]])
	{
		intWebView = [webView t_parentView];
	} else {
		return;
	}

	NSInteger promiseIndex = (-1);

	NSArray *values = nil;

	/* Extract relevant information from inputData */
	if ([inputData isKindOfClass:[NSDictionary class]]) {
		/* Check that the object exists in the dictionary before 
		 setting the value. If the object does not exist and we
		 do not do this, then -integerValue will return 0 which
		 is considered a valid promiseIndex value. */
		id promiseIndexObj = [inputData valueForKey:@"promiseIndex"];

		if (promiseIndexObj) {
			if ([promiseIndexObj isKindOfClass:[NSNumber class]] == NO) {
				[self _throwJavaScriptException:@"'promiseIndex' must be a number" inWebView:intWebView];

				return;
			}

			promiseIndex = [promiseIndexObj integerValue];
		}

		/* Values should always be in an array */
		if (minimumArgumentCount > 0) {
			id valuesObj = [inputData valueForKey:@"values"];

			if (valuesObj == nil || [valuesObj isKindOfClass:[NSArray class]] == NO) {
				[self _throwJavaScriptException:@"'values' must be an array" inWebView:intWebView];

				return;
			} else {
				values = valuesObj;
			}
		}
	}
	else if ([inputData isKindOfClass:[NSString class]] ||
			 [inputData isKindOfClass:[NSNumber class]])
	{
		if (minimumArgumentCount > 0) {
			values = @[inputData];
		}
	}
	else if ([inputData isKindOfClass:[NSArray class]])
	{
		if (minimumArgumentCount > 0) {
			values = inputData;
		}
	}
	else if ([inputData isKindOfClass:[NSNull class]] ||
			 [inputData isKindOfClass:[WebUndefined class]])
	{
		if (minimumArgumentCount > 0) {
			values = @[[NSNull null]];
		}
	}

	/* Perform validation if needed */
	if (minimumArgumentCount > 0 && [values count] < minimumArgumentCount) {
		[self _throwJavaScriptException:@"Minimum number of arguments condition not met" inWebView:intWebView];

		return;
	}

	if (validateArgumentBlock) {
		__block BOOL validationPassed = YES;

		[values enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
			if (validateArgumentBlock(index, object) == NO) {
				validationPassed = NO;

				*stop = YES;
			}
		}];

		if (validationPassed == NO) {
			[self _throwJavaScriptException:@"Invalid argument type(s)" inWebView:intWebView];

			return;
		}
	}

	/* Pass validated data to selector */
	TVCLogScriptEventSinkContext *context = [TVCLogScriptEventSinkContext new];

	[context setWebView:intWebView];

	[context setArguments:values];

	if (promiseIndex == (-1)) {
		(void)objc_msgSend(self, selector, context);
	} else {
		id returnValue = objc_msgSend(self, selector, context);

		if (returnValue == nil) {
			returnValue = [NSNull null];
		}

		[intWebView executeCommand:@"appInternal.promiseKept"
					 withArguments:@[@(promiseIndex), returnValue]];
	}
}

- (void)_logToJavaScriptConsole:(NSString *)message inWebView:(TVCLogView *)webView
{
	[webView executeCommand:@"console.log" withArguments:@[message]];
}

- (void)_throwJavaScriptException:(NSString *)message inWebView:(TVCLogView *)webView
{
	[webView executeCommand:@"console.error" withArguments:@[message]];
}

#pragma mark -
#pragma mark Private Implementation

- (void)channelIsJoined:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_channelIsJoined:)];
}

- (void)channelMemberCount:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_channelMemberCount:)];
}

- (void)channelName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_channelName:)];
}

- (void)channelNameDoubleClicked:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_channelNameDoubleClicked:)];
}

- (void)displayContextMenu:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_displayContextMenu:)];
}

- (void)copySelectionWhenPermitted:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_copySelectionWhenPermitted:)];
}

- (void)inlineImagesEnabledForView:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_inlineImagesEnabledForView:)];
}

- (void)localUserHostmask:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_localUserHostmask:)];
}

- (void)localUserNickname:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_localUserNickname:)];
}

- (void)logToConsole:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_logToConsole:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)logToConsoleFile:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_logToConsoleFile:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)networkName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_networkName:)];
}

- (void)nicknameColorStyleHash:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_nicknameColorStyleHash:)
	  minimumArgumentCount:2
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)nicknameDoubleClicked:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_nicknameDoubleClicked:)];
}

- (void)printDebugInformation:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_printDebugInformation:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)printDebugInformationToConsole:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_printDebugInformationToConsole:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)retrievePreferencesWithMethodName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_retrievePreferencesWithMethodName:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)sendPluginPayload:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_sendPluginPayload:)
	  minimumArgumentCount:2
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				if (argumentIndex == 0) {
					return [argument isKindOfClass:[NSString class]];
				} else {
					return YES;
				}
			}];
}

- (void)serverAddress:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_serverAddress:)];
}

- (void)serverChannelCount:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_serverChannelCount:)];
}

- (void)serverIsConnected:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_serverIsConnected:)];
}

- (void)setChannelName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setChannelName:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return ([argument isKindOfClass:[NSNull class]] ||
						[argument isKindOfClass:[NSString class]]);
			}];
}

- (void)setNickname:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setNickname:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return ([argument isKindOfClass:[NSNull class]] ||
						[argument isKindOfClass:[NSString class]]);
			}];
}

- (void)setSelection:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setSelection:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return ([argument isKindOfClass:[NSNull class]] ||
						[argument isKindOfClass:[NSString class]]);
			}];
}

- (void)setURLAddress:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setURLAddress:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return ([argument isKindOfClass:[NSNull class]] ||
						[argument isKindOfClass:[NSString class]]);
			}];
}

- (void)sidebarInversionIsEnabled:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_sidebarInversionIsEnabled:)];
}

- (void)styleSettingsRetrieveValue:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_styleSettingsRetrieveValue:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)styleSettingsSetValue:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_styleSettingsSetValue:)
	  minimumArgumentCount:2
			withValidation:^BOOL(NSInteger argumentIndex, id argument) {
				if (argumentIndex == 0) {
					return [argument isKindOfClass:[NSString class]];
				} else {
					return ([argument isKindOfClass:[NSArray class]] ||
							[argument isKindOfClass:[NSDictionary class]] ||
							[argument isKindOfClass:[NSNull class]] ||
							[argument isKindOfClass:[NSNumber class]] ||
							[argument isKindOfClass:[NSString class]]);
				}
			}];
}

- (void)topicBarDoubleClicked:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_topicBarDoubleClicked:)];
}

#pragma mark -
#pragma mark Private Implementation

- (id)_channelIsJoined:(TVCLogScriptEventSinkContext *)context
{
	return @([[context associatedChannel] isActive]);
}

- (id)_channelMemberCount:(TVCLogScriptEventSinkContext *)context
{
	return @([[context associatedChannel] numberOfMembers]);
}

- (id)_channelName:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedChannel] name];
}

- (void)_channelNameDoubleClicked:(TVCLogScriptEventSinkContext *)context
{
	[[context webViewPolicy] channelNameDoubleClicked];
}

- (void)_displayContextMenu:(TVCLogScriptEventSinkContext *)context
{
	[[context webViewPolicy] displayContextMenuInWebView:[context webView]];
}

- (id)_copySelectionWhenPermitted:(TVCLogScriptEventSinkContext *)context
{
	if ([TPCPreferences copyOnSelect]) {
		NSString *selection = [[context webView] selection];

		if (selection) {
			[RZPasteboard() setStringContent:selection];

			return @(YES);
		}
	}

	return @(NO);
}

- (id)_inlineImagesEnabledForView:(TVCLogScriptEventSinkContext *)context
{
	return @([[context logController] inlineImagesEnabledForView]);
}

- (id)_localUserHostmask:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedClient] localHostmask];
}

- (id)_localUserNickname:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedClient] localNickname];
}

- (void)_logToConsole:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	LogToConsole(@"JavaScript: %@", message);
}

- (void)_logToConsoleFile:(TVCLogScriptEventSinkContext *)context
{
	/* Define the file path in which the data is written to. */
	IRCClient *u = [context associatedClient];

	IRCChannel *c = [context associatedChannel];

	NSString *basePath = [[TPCPathInfo applicationLogsFolderPath] stringByAppendingPathComponent:@"/JavaScript-Console/"];

	NSString *filename = nil;

	if (c) {
		NSString *subPath = [NSString stringWithFormat:@"/%@/", [u  uniqueIdentifier]];

		basePath = [basePath stringByAppendingPathComponent:subPath];

		filename = [NSString stringWithFormat:@"%@.txt", [[c name] safeFilename]];
	}
	else // c != nil
	{
		filename = [NSString stringWithFormat:@"%@.txt", [u uniqueIdentifier]];
	}

	/* Create folder in which the log files will be kept or throw error. */
	if ([RZFileManager() fileExistsAtPath:basePath] == NO) {
		NSError *createDirectoryError = nil;

		if ([RZFileManager() createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
			NSString *errorMessage = [NSString stringWithFormat:@"Failed to create directory to write files in: %@", [createDirectoryError localizedDescription]];

			[self _throwJavaScriptException:errorMessage inWebView:[context webView]];

			return;
		}
	}

	/* Try to create blank file if it does not exist yet or throw error. */
	NSString *writePath = [basePath stringByAppendingPathComponent:filename];

	if ([RZFileManager() fileExistsAtPath:writePath] == NO) {
		NSError *writeToFileError = nil;

		if ([NSStringEmptyPlaceholder writeToFile:writePath atomically:NO encoding:NSUTF8StringEncoding error:&writeToFileError] == NO) {
			NSString *errorMessage = [NSString stringWithFormat:@"Failed to write blank file: %@", [writeToFileError localizedDescription]];

			[self _throwJavaScriptException:errorMessage inWebView:[context webView]];

			return;
		}
	}

	/* Get file handle for writing or throw error */
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:writePath];

	if (fileHandle == nil) {
		NSString *errorMessage = [NSString stringWithFormat:@"Failed to open file handle for file: %@", writePath];

		[self _throwJavaScriptException:errorMessage inWebView:[context webView]];

		return;
	}

	[fileHandle seekToEndOfFile];

	/* Write to file */
	NSArray *arguments = [context arguments];

	NSString *messageString = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	NSString *message = [NSString stringWithFormat:@"(%f) %@\x0d\x0a",
						 CFAbsoluteTimeGetCurrent(), messageString];

	NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];

	[fileHandle writeData:messageData];

	/* Close access to file */
	[fileHandle closeFile];

	 fileHandle = nil;
}

- (id)_networkName:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedClient] networkName];
}

- (id)_nicknameColorStyleHash:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *inputString = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	NSString *colorStyle = [TVCLogScriptEventSink objectValueToCommon:arguments[1]];

	TPCThemeSettingsNicknameColorStyle colorStyleEnum = TPCThemeSettingsNicknameColorLegacyStyle;

	if ([colorStyle isEqualToString:@"HSL-dark"]) {
		colorStyleEnum = TPCThemeSettingsNicknameColorHashHueDarkStyle;
	} else if ([colorStyle isEqualToString:@"HSL-light"]) {
		colorStyleEnum = TPCThemeSettingsNicknameColorHashHueLightStyle;
	}

	return [IRCUserNicknameColorStyleGenerator hashForString:inputString colorStyle:colorStyleEnum];
}

- (void)_nicknameDoubleClicked:(TVCLogScriptEventSinkContext *)context
{
	[[context webViewPolicy] nicknameDoubleClicked];
}

- (void)_printDebugInformation:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[[context associatedClient] printDebugInformation:message channel:[context associatedChannel]];
}

- (void)_printDebugInformationToConsole:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[[context associatedClient] printDebugInformationToConsole:message];
}

- (id)_retrievePreferencesWithMethodName:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *methodName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	SEL methodSelector = NSSelectorFromString(methodName);

	NSArray *resultErrors = nil;

	id returnValue = [TPCPreferences performSelector:methodSelector
									   withArguments:nil
								   returnsPrimitives:YES
									usesTypeChecking:NO
											   error:&resultErrors];

	if (resultErrors) {
		for (NSDictionary *error in resultErrors) {
			if ([error boolForKey:@"isWarning"]) {
				[self _logToJavaScriptConsole:error[@"errorMessage"] inWebView:[context webView]];
			} else {
				[self _throwJavaScriptException:error[@"errorMessage"] inWebView:[context webView]];
			}
		}
	}

	return returnValue;
}

- (void)_sendPluginPayload:(TVCLogScriptEventSinkContext *)context
{
	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsWebViewJavaScriptPayloads] == NO) {
		[self _throwJavaScriptException:@"There are no plugins loaded that support JavaScritp payloads" inWebView:[context webView]];

		return;
	}

	NSArray *arguments = [context arguments];

	NSString *payloadLabel = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	id payloadContents = [TVCLogScriptEventSink objectValueToCommon:arguments[1]];

	THOPluginWebViewJavaScriptPayloadConcreteObject *payloadObject =
	[THOPluginWebViewJavaScriptPayloadConcreteObject new];

	[payloadObject setPayloadLabel:payloadLabel];
	[payloadObject setPayloadContents:payloadContents];

	[sharedPluginManager() postJavaScriptPayloadForViewController:[context logController] withObject:payloadObject];
}

- (id)_serverAddress:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedClient] networkAddress];
}

- (id)_serverChannelCount:(TVCLogScriptEventSinkContext *)context
{
	return @([[context associatedClient] channelCount]);
}

- (id)_serverIsConnected:(TVCLogScriptEventSinkContext *)context
{
	return @([[context associatedClient] isLoggedIn]);
}

- (void)_setChannelName:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[[context webViewPolicy] setChannelName:value];
}

- (void)_setNickname:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[[context webViewPolicy] setNickname:value];
}

- (void)_setSelection:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *selection = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	if (selection && [selection length] == 0) {
		selection = nil;
	}

	[[context webView] setSelection:selection];
}

- (void)_setURLAddress:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[[context webViewPolicy] setAnchorURL:value];
}

- (id)_sidebarInversionIsEnabled:(TVCLogScriptEventSinkContext *)context
{
	return @([TPCPreferences invertSidebarColors]);
}

- (id)_styleSettingsRetrieveValue:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *keyName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	NSString *errorValue = nil;

	id result = [themeSettings() styleSettingsRetrieveValueForKey:keyName error:&errorValue];

	if (errorValue) {
		[self _throwJavaScriptException:errorValue inWebView:[context webView]];
	}

	return result;
}

- (id)_styleSettingsSetValue:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = [context arguments];

	NSString *keyName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	id keyValue = [TVCLogScriptEventSink objectValueToCommon:arguments[1]];

	NSString *errorValue = nil;

	BOOL result = [themeSettings() styleSettingsSetValue:keyValue forKey:keyName error:&errorValue];

	if (errorValue) {
		[self _throwJavaScriptException:errorValue inWebView:[context webView]];
	}

	if (result) {
		[worldController() executeScriptCommandOnAllViews:@"Textual.styleSettingDidChange" arguments:@[keyName]];
	}

	return @(result);
}

- (void)_topicBarDoubleClicked:(TVCLogScriptEventSinkContext *)context
{
	[[context webViewPolicy] topicBarDoubleClicked];
}

@end

@implementation TVCLogScriptEventSinkContext

- (TVCLogController *)logController
{
	return [[self webView] logController];
}

- (TVCLogPolicy *)webViewPolicy
{
	return [[self webView] webViewPolicy];
}

- (IRCClient *)associatedClient
{
	return [[self logController] associatedClient];
}

- (IRCChannel *)associatedChannel
{
	return [[self logController] associatedChannel];
}

@end
