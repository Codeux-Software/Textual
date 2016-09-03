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

#include <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@interface TVCLogScriptEventSink ()
@property (nonatomic, weak) TVCLogView *webView;
@end

@interface TVCLogScriptEventSinkContext : NSObject
@property (nonatomic, weak) TVCLogView *webView;
@property (readonly) TVCLogPolicy *webViewPolicy;
@property (readonly) TVCLogController *viewController;
@property (readonly) IRCClient *associatedClient;
@property (readonly, nullable) IRCChannel *associatedChannel;
@property (nonatomic, copy, nullable) NSArray *arguments;
@end

@implementation TVCLogScriptEventSink

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithWebView:(nullable TVCLogView *)webView
{
	if ((self = [super init])) {
		self.webView = webView;

		return self;
	}

	return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
	if (selector == @selector(init) ||
		selector == @selector(initWithWebView:) ||
		selector == @selector(webView) ||
		selector == @selector(webViewPolicy) ||
 		selector == @selector(associatedClient) ||
		selector == @selector(associatedChannel) ||
		selector == @selector(objectValueToCommon:) ||
		selector == @selector(userContentController:didReceiveScriptMessage:) ||
		selector == @selector(processInputData:inWebView:forSelector:) ||
		selector == @selector(processInputData:inWebView:forSelector:minimumArgumentCount:withValidation:))
	{
		return YES;
	}

	if ([NSStringFromSelector(selector) hasPrefix:@"_"]) {
		return NO;
	}

	return NO;
}

+ (nullable NSString *)webScriptNameForSelector:(SEL)sel
{
	return nil;
}

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)arguments
{
	SEL handlerSelector = NSSelectorFromString([name stringByAppendingString:@":inWebView:"]);

	if ([self respondsToSelector:handlerSelector] == NO) {
		return @(NO);
	}

	if (arguments && arguments.count > 0) {
		id argument = arguments[0];

		if ([argument isKindOfClass:[WebScriptObject class]]) {
			argument = [self.webView webScriptObjectToCommon:argument];
		}

		(void)objc_msgSend(self, handlerSelector, argument, self.webView);
	} else {
		(void)objc_msgSend(self, handlerSelector, nil, self.webView);
	}

	return @(YES);
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
	return YES;
}

+ (nullable NSString *)webScriptNameForKey:(const char *)name
{
	return nil;
}

+ (nullable id)objectValueToCommon:(id)object
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
	NSString *handlerName = message.name;

	SEL handlerSelector = NSSelectorFromString([handlerName stringByAppendingString:@":inWebView:"]);

	if ([self respondsToSelector:handlerSelector] == NO) {
		return;
	}

	if ([TVCLogScriptEventSink isSelectorExcludedFromWebScript:handlerSelector]) {
		return;
	}

	(void)objc_msgSend(self, handlerSelector, message.body, message.webView);
}

- (void)processInputData:(id)inputData inWebView:(id)webView forSelector:(SEL)selector
{
	[self processInputData:inputData inWebView:webView forSelector:selector minimumArgumentCount:0 withValidation:nil];
}

- (void)processInputData:(id)inputData
			   inWebView:(id)webView
			 forSelector:(SEL)selector
   minimumArgumentCount:(NSUInteger)minimumArgumentCount
		  withValidation:(BOOL (NS_NOESCAPE ^ _Nullable)(NSUInteger argumentIndex, id argument))validateArgumentBlock
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
	if (minimumArgumentCount > 0 && values.count < minimumArgumentCount) {
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

	context.webView = intWebView;

	context.arguments = values;

	if (promiseIndex <= (-1)) {
		(void)objc_msgSend(self, selector, context);
	} else {
		id returnValue = objc_msgSend(self, selector, context);

		if (returnValue == nil) {
			returnValue = [NSNull null];
		}

		[intWebView evaluateFunction:@"appInternal.promiseKept"
					   withArguments:@[@(promiseIndex), returnValue]];
	}
}

- (void)_logToJavaScriptConsole:(NSString *)message inWebView:(TVCLogView *)webView
{
	[webView evaluateFunction:@"console.log" withArguments:@[message]];
}

- (void)_throwJavaScriptException:(NSString *)message inWebView:(TVCLogView *)webView
{
	[webView evaluateFunction:@"console.error" withArguments:@[message]];
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

- (void)inlineMediaEnabledForView:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_inlineMediaEnabledForView:)];
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)printDebugInformationToConsole:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_printDebugInformationToConsole:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)retrievePreferencesWithMethodName:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_retrievePreferencesWithMethodName:)
	  minimumArgumentCount:1
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)sendPluginPayload:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_sendPluginPayload:)
	  minimumArgumentCount:2
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
				return [argument isKindOfClass:[NSString class]];
			}];
}

- (void)styleSettingsSetValue:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData
				 inWebView:webView
			   forSelector:@selector(_styleSettingsSetValue:)
	  minimumArgumentCount:2
			withValidation:^BOOL(NSUInteger argumentIndex, id argument) {
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

- (void)finishedLayingOutView:(id)inputData inWebView:(id)webView
{
	[self processInputData:inputData inWebView:webView forSelector:@selector(_finishedLayingOutView:)];
}

#pragma mark -
#pragma mark Private Implementation

- (id)_channelIsJoined:(TVCLogScriptEventSinkContext *)context
{
	return @(context.associatedChannel.isActive);
}

- (id)_channelMemberCount:(TVCLogScriptEventSinkContext *)context
{
	return @(context.associatedChannel.numberOfMembers);
}

- (id)_channelName:(TVCLogScriptEventSinkContext *)context
{
	return context.associatedChannel.name;
}

- (void)_channelNameDoubleClicked:(TVCLogScriptEventSinkContext *)context
{
	[context.webViewPolicy channelNameDoubleClicked];
}

- (void)_displayContextMenu:(TVCLogScriptEventSinkContext *)context
{
	[context.webViewPolicy displayContextMenuInWebView:context.webView];
}

- (id)_copySelectionWhenPermitted:(TVCLogScriptEventSinkContext *)context
{
	if ([TPCPreferences copyOnSelect]) {
		NSString *selection = context.webView.selection;

		if (selection) {
			RZPasteboard().stringContent = selection;

			return @(YES);
		}
	}

	return @(NO);
}

- (id)_inlineMediaEnabledForView:(TVCLogScriptEventSinkContext *)context
{
	return @(context.viewController.inlineMediaEnabledForView);
}

- (id)_localUserHostmask:(TVCLogScriptEventSinkContext *)context
{
	return context.associatedClient.userHostmask;
}

- (id)_localUserNickname:(TVCLogScriptEventSinkContext *)context
{
	return context.associatedClient.userNickname;
}

- (void)_logToConsole:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	LogToConsoleInfo("JavaScript: %{public}@", message)
}
- (id)_networkName:(TVCLogScriptEventSinkContext *)context
{
	return context.associatedClient.networkName;
}

- (id)_nicknameColorStyleHash:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

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
	[context.webViewPolicy nicknameDoubleClicked];
}

- (void)_printDebugInformation:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[context.associatedClient printDebugInformation:message inChannel:context.associatedChannel];
}

- (void)_printDebugInformationToConsole:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *message = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	[context.associatedClient printDebugInformationToConsole:message];
}

- (nullable id)_retrievePreferencesWithMethodName:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *methodName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	SEL methodSelector = NSSelectorFromString(methodName);

	NSMethodSignature *methodSignature =
	[TPCPreferences methodSignatureForSelector:methodSelector];

	if (methodSignature == nil) {
		NSString *errorMessage = [NSString stringWithFormat:@"Unknown method named: '%@'", methodName];

		[self _throwJavaScriptException:errorMessage inWebView:context.webView];

		return nil;
	} else if (strcmp(methodSignature.methodReturnType, @encode(void)) == 0) {
		NSString *errorMessage = [NSString stringWithFormat:@"Method named '%@' does not return a value", methodName];

		[self _throwJavaScriptException:errorMessage inWebView:context.webView];

		return nil;
	}

	NSInvocation *invocation =
	[NSInvocation invocationWithMethodSignature:methodSignature];

	invocation.target = [TPCPreferences class];

	invocation.selector = methodSelector;

	[invocation invoke];

	void *returnValue;

	[invocation getReturnValue:&returnValue];

	return [NSValue valueWithPrimitive:returnValue withType:methodSignature.methodReturnType];
}

- (void)_sendPluginPayload:(TVCLogScriptEventSinkContext *)context
{
	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsWebViewJavaScriptPayloads] == NO) {
		[self _throwJavaScriptException:@"There are no plugins loaded that support JavaScritp payloads" inWebView:context.webView];

		return;
	}

	NSArray *arguments = context.arguments;

	NSString *payloadLabel = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	id payloadContents = [TVCLogScriptEventSink objectValueToCommon:arguments[1]];

	THOPluginWebViewJavaScriptPayloadConcreteObject *payloadObject =
	[THOPluginWebViewJavaScriptPayloadConcreteObject new];

	payloadObject.payloadLabel = payloadLabel;
	payloadObject.payloadContents = payloadContents;

	[THOPluginDispatcher didReceiveJavaScriptPayload:payloadObject fromViewController:context.viewController];
}

- (id)_serverAddress:(TVCLogScriptEventSinkContext *)context
{
	return context.associatedClient.serverAddress;
}

- (id)_serverChannelCount:(TVCLogScriptEventSinkContext *)context
{
	return @(context.associatedClient.channelCount);
}

- (id)_serverIsConnected:(TVCLogScriptEventSinkContext *)context
{
	return @(context.associatedClient.isLoggedIn);
}

- (void)_setChannelName:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	context.webViewPolicy.channelName = value;
}

- (void)_setNickname:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	context.webViewPolicy.nickname = value;
}

- (void)_setSelection:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *selection = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	if (selection && selection.length == 0) {
		selection = nil;
	}

	context.webView.selection = selection;
}

- (void)_setURLAddress:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *value = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	context.webViewPolicy.anchorURL = value;
}

- (id)_sidebarInversionIsEnabled:(TVCLogScriptEventSinkContext *)context
{
	return @([TPCPreferences invertSidebarColors]);
}

- (id)_styleSettingsRetrieveValue:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *keyName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	NSString *errorValue = nil;

	id result = [themeSettings() styleSettingsRetrieveValueForKey:keyName error:&errorValue];

	if (errorValue) {
		[self _throwJavaScriptException:errorValue inWebView:context.webView];
	}

	return result;
}

- (id)_styleSettingsSetValue:(TVCLogScriptEventSinkContext *)context
{
	NSArray *arguments = context.arguments;

	NSString *keyName = [TVCLogScriptEventSink objectValueToCommon:arguments[0]];

	id keyValue = [TVCLogScriptEventSink objectValueToCommon:arguments[1]];

	NSString *errorValue = nil;

	BOOL result = [themeSettings() styleSettingsSetValue:keyValue forKey:keyName error:&errorValue];

	if (errorValue) {
		[self _throwJavaScriptException:errorValue inWebView:context.webView];
	}

	if (result) {
		[worldController() evaluateFunctionOnAllViews:@"Textual.styleSettingDidChange" arguments:@[keyName]];
	}

	return @(result);
}

- (void)_topicBarDoubleClicked:(TVCLogScriptEventSinkContext *)context
{
	[context.webViewPolicy topicBarDoubleClicked];
}

- (void)_finishedLayingOutView:(TVCLogScriptEventSinkContext *)context
{
	[context.webView setViewFinishedLayout];
}

@end

#pragma mark -

@implementation TVCLogScriptEventSinkContext

- (TVCLogController *)viewController
{
	return self.webView.viewController;
}

- (TVCLogPolicy *)webViewPolicy
{
	return self.webView.webViewPolicy;
}

- (IRCClient *)associatedClient
{
	return self.viewController.associatedClient;
}

- (nullable IRCChannel *)associatedChannel
{
	return self.viewController.associatedChannel;
}

@end

NS_ASSUME_NONNULL_END
