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

	if (args == nil || [args count] == 0) {
		return @(NO);
	}

	if ([args[0] isKindOfClass:[WebScriptObject class]] == NO) {
		return @(NO);
	}

	(void)objc_msgSend(self, handlerSelector, args[0], [self parentView]);

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
		  withValidation:(Class (^)(NSInteger argumentIndex))validateArgumentBlock
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
	if ([inputData isKindOfClass:[NSDictionary class]] ||
		[inputData isKindOfClass:[WebScriptObject class]])
	{
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

	/* Perform validation if needed */
	if (minimumArgumentCount > 0 && [values count] < minimumArgumentCount) {
		[self _throwJavaScriptException:@"Minimum number of arguments condition not met" inWebView:intWebView];

		return;
	}

	if (validateArgumentBlock) {
		__block BOOL validationPassed = YES;

		[values enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
			Class expectedClass = validateArgumentBlock(index);

			if ([object isKindOfClass:expectedClass] == NO) {
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
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
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
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
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
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
			}];
}

- (void)printDebugInformationToConsole:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_printDebugInformationToConsole:)
	  minimumArgumentCount:1
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
			}];
}

- (void)retrievePreferencesWithMethodName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_retrievePreferencesWithMethodName:)
	  minimumArgumentCount:1
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
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
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
			}];
}

- (void)setNickname:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setNickname:)
	  minimumArgumentCount:1
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
			}];
}

- (void)setURLAddress:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_setURLAddress:)
	  minimumArgumentCount:1
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
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
			withValidation:^Class(NSInteger argumentIndex) {
				return [NSString class];
			}];
}

- (void)styleSettingsSetValue:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_styleSettingsSetValue:)
	  minimumArgumentCount:1
			withValidation:nil];
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
	NSString *message = [context arguments][0];

	LogToConsole(@"JavaScript: %@", message);
}

- (id)_networkName:(TVCLogScriptEventSinkContext *)context
{
	return [[context associatedClient] networkName];
}

- (id)_nicknameColorStyleHash:(TVCLogScriptEventSinkContext *)context
{
	NSString *inputString = [context arguments][0];

	NSString *colorStyle = [context arguments][1];

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
	NSString *message = [context arguments][0];

	[[context associatedClient] printDebugInformation:message channel:[context associatedChannel]];
}

- (void)_printDebugInformationToConsole:(TVCLogScriptEventSinkContext *)context
{
	NSString *message = [context arguments][0];

	[[context associatedClient] printDebugInformationToConsole:message];
}

- (id)_retrievePreferencesWithMethodName:(TVCLogScriptEventSinkContext *)context
{
	NSString *methodName = [context arguments][0];

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
	NSString *value = [context arguments][0];

	[[context webViewPolicy] setChannelName:[value gtm_stringByUnescapingFromHTML]];
}

- (void)_setNickname:(TVCLogScriptEventSinkContext *)context
{
	NSString *value = [context arguments][0];

	[[context webViewPolicy] setNickname:[value gtm_stringByUnescapingFromHTML]];
}

- (void)_setURLAddress:(TVCLogScriptEventSinkContext *)context
{
	NSString *value = [context arguments][0];

	[[context webViewPolicy] setAnchorURL:[value gtm_stringByUnescapingFromHTML]];
}

- (id)_sidebarInversionIsEnabled:(TVCLogScriptEventSinkContext *)context
{
	return @([TPCPreferences invertSidebarColors]);
}

- (id)_styleSettingsRetrieveValue:(TVCLogScriptEventSinkContext *)context
{
	NSString *keyName = [context arguments][0];

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

	NSString *keyName = arguments[0];

	id keyValue = nil;

	if ([arguments count] > 1) {
		if ([arguments[1] isKindOfClass:[NSNull class]] == NO &&
			[arguments[1] isKindOfClass:[WebUndefined class]] == NO)
		{
			keyValue = arguments[1];
		}
	}

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
