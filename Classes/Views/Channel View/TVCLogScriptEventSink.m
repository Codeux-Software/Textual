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

@interface TVCLogScriptEventSink ()
@property (nonatomic, strong) WKUserContentController *userContentController;
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

	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
	NSString *s = NSStringFromSelector(sel);
	
	if ([s hasPrefix:@"styleSettingsSetValue"]) {
		return nil;
	} else if ([s hasPrefix:@"nicknameColorStyleHash"]) {
		return nil;
	}
	
	if ([s hasSuffix:@":"]) {
		return [s substringToIndex:([s length] - 1)];
	}
	
	return nil;
}

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args
{
	if ([name isEqualToString:@"styleSettingsSetValue"]) {
		return @([self styleSettingsSetValue:args]);
	} else if ([name isEqualToString:@"nicknameColorStyleHash"]) {
		return [self nicknameColorStyleHash:args];
	}

	return nil;
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
	;
}

- (TVCLogView *)webView
{
	return [self parentView];
}

- (TVCLogPolicy *)webViewPolicy
{
	return [[self parentView] webViewPolicy];
}

- (TVCLogController *)logController
{
	return [[self parentView] logController];
}

- (IRCClient *)associatedClient
{
	return [[self logController] associatedClient];
}

- (IRCChannel *)associatedChannel
{
	return [[self logController] associatedChannel];
}

- (void)logToConsole:(NSString *)message
{
    LogToConsole(@"JavaScript: %@", message);
}

- (void)logToJavaScriptConsole:(NSString *)message
{
	TVCLogView *webView = [self webView];

	[webView executeCommand:@"console.log" withArguments:@[message]];
}

- (void)throwJavaScriptException:(NSString *)message
{
	TVCLogView *webView = [self webView];

	[webView executeCommand:@"console.error" withArguments:@[message]];
}

- (void)setURLAddress:(NSString *)s
{
    [[self webViewPolicy] setAnchorURL:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNickname:(NSString *)s
{
    [[self webViewPolicy] setNickname:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChannelName:(NSString *)s
{
    [[self webViewPolicy] setChannelName:[s gtm_stringByUnescapingFromHTML]];
}

- (void)channelNameDoubleClicked
{
    [[self webViewPolicy] channelDoubleClicked];
}

- (void)nicknameDoubleClicked
{
    [[self webViewPolicy] nicknameDoubleClicked];
}

- (void)topicBarDoubleClicked
{
	[[self webViewPolicy] topicBarDoubleClicked];
}

- (NSInteger)channelMemberCount
{
    return [[self associatedChannel] numberOfMembers];
}

- (NSInteger)serverChannelCount
{
	return [[self associatedClient] channelCount];
}

- (BOOL)serverIsConnected
{
	return [[self associatedClient] isLoggedIn];
}

- (BOOL)channelIsJoined
{
	return [[self associatedChannel] isActive];
}

- (NSString *)channelName
{
	return [[self associatedChannel] name];
}

- (NSString *)serverAddress
{
	return [[self associatedClient] networkAddress];
}

- (NSString *)networkName
{
	return [[self associatedClient] networkName];
}

- (NSString *)localUserNickname
{
	return [[self associatedClient] localNickname];
}

- (NSString *)localUserHostmask
{
	return [[self associatedClient] localHostmask];
}

- (BOOL)inlineImagesEnabledForView
{
	return [self inlineImagesEnabledForView];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[[self associatedClient] printDebugInformationToConsole:m];
}

- (void)printDebugInformation:(NSString *)m
{
	[[self associatedClient] printDebugInformation:m channel:[self associatedChannel]];
}

- (BOOL)sidebarInversionIsEnabled
{
	return [TPCPreferences invertSidebarColors];
}

- (NSNumber *)nicknameColorStyleHash:(NSArray *)arguments
{
	if ([arguments count] == 2) {
		id inputString = arguments[0];

		id colorStyle = arguments[1];

		if ([inputString isKindOfClass:[NSString class]] &&
			[colorStyle isKindOfClass:[NSString class]])
		{
			TPCThemeSettingsNicknameColorStyle colorStyleEnum = TPCThemeSettingsNicknameColorLegacyStyle;

			if ([colorStyle isEqualToString:@"HSL-dark"]) {
				colorStyleEnum = TPCThemeSettingsNicknameColorHashHueDarkStyle;
			} else if ([colorStyle isEqualToString:@"HSL-light"]) {
				colorStyleEnum = TPCThemeSettingsNicknameColorHashHueLightStyle;
			}

			return [IRCUserNicknameColorStyleGenerator hashForString:inputString colorStyle:colorStyleEnum];
		}
	}

	return 0;
}

- (BOOL)styleSettingsSetValue:(NSArray *)arguments
{
	id objectKey = nil;
	id objectValue = nil;
	
	if (NSNumberInRange([arguments count], 1, 2)) {
		objectKey = arguments[0];
		
		if ([arguments count] == 1) {
			objectValue = [WebUndefined undefined];
		} else {
			objectValue = arguments[1];
		}
		
		NSString *errorValue = nil;
		
		BOOL result = [themeSettings() styleSettingsSetValue:objectValue forKey:objectKey error:&errorValue];
		
		if (errorValue) {
			[self throwJavaScriptException:errorValue];
		}
		
		if (result) {
			[worldController() executeScriptCommandOnAllViews:@"styleSettingDidChange" arguments:@[objectKey]];
		}
		
		return result;
	} else {
		[self throwJavaScriptException:@"Improperly formatted arguments"];
		
		return NO;
	}
}

- (id)styleSettingsRetrieveValue:(NSString *)key
{
	NSString *errorValue = nil;
	
	id result = [themeSettings() styleSettingsRetrieveValueForKey:key error:&errorValue];
	
	if (errorValue) {
		[self throwJavaScriptException:errorValue];
	}
	
	return result;
}

- (id)retrievePreferencesWithMethodName:(id)name
{
	if ([name isKindOfClass:[NSString class]] == NO) {
		[self throwJavaScriptException:@"The value provided to retrievePreferencesWithMethodName must be a string"];
	} else if ([name length] <= 1) {
		[self throwJavaScriptException:@"Length of value supplied to retrievePreferencesWithMethodName is less than or equal to zero (0)"];
	} else {
		SEL realSelector = NSSelectorFromString(name);
		
		NSArray *resultErrors = nil;
		
		id returnValue = [TPCPreferences performSelector:realSelector
										   withArguments:nil
									   returnsPrimitives:YES
										usesTypeChecking:NO
												   error:&resultErrors];
		
		if (resultErrors) {
			for (NSDictionary *error in resultErrors) {
				if ([error boolForKey:@"isWarning"]) {
					[self logToJavaScriptConsole:error[@"errorMessage"]];
				} else {
					[self throwJavaScriptException:error[@"errorMessage"]];
				}
			}
		}
		
		return returnValue;
	}
	
	return nil;
}

- (void)print:(NSString *)s
{
}

@end
