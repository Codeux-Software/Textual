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

#define _doubleClickRadius		3

@implementation TVCLogScriptEventSink

- (instancetype)init
{
	if ((self = [super init])) {
		self.x = -10000;
		self.y = -10000;
	}
	
	return self;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
	NSString *s = NSStringFromSelector(sel);
	
	if ([s hasPrefix:@"styleSettingsSetValue"]) {
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

- (BOOL)shouldStopDoubleClick:(id)e
{
	NSInteger dr = _doubleClickRadius;
	
	NSInteger cx = [[e valueForKey:@"clientX"] integerValue];
	NSInteger cy = [[e valueForKey:@"clientY"] integerValue];
	
	BOOL res = NO;
	
	NSTimeInterval now = [NSDate unixTime];
	
	if ((self.x - dr) <= cx && cx <= (self.x + dr) &&
		(self.y - dr) <= cy && cy <= (self.y + dr))
	{
		if (now < (self.lastClickTime + [NSEvent doubleClickInterval])) {
			res = YES;
		}
	}
	
	self.lastClickTime = now;
	
	self.x = cx;
	self.y = cy;
	
	return res;
}

- (void)logToConsole:(NSString *)message
{
    LogToConsole(@"JavaScript: %@", message);
}

- (void)throwJavaScriptException:(NSString *)message
{
	[WebScriptObject throwException:message];
}

- (void)logToJavaScriptConsole:(NSString *)message
{
	TVCLogView *webView = [self.logController webView];
	
	WebScriptObject *console = [webView javaScriptConsoleAPI];
	
	[console callWebScriptMethod:@"log" withArguments:@[message]];
}

- (void)toggleInlineImage:(NSString *)object
{
	/* Do we have a properly formatted ID? */
	if ([object hasPrefix:@"inlineImage-"] == NO) {
		object = [@"inlineImage-" stringByAppendingString:object];
	}

	/* Find the element. */
	DOMElement *imageNode = [[self.logController mainFrameDocument] getElementById:object];

	PointerIsEmptyAssert(imageNode);

	/* Update the display information. */
	NSString *display = [[imageNode style] display];

	if ([display isEqualIgnoringCase:@"none"]) {
		display = NSStringEmptyPlaceholder;
	} else {
		display = @"none";
	}
	
	[[imageNode style] setDisplay:display];
	
	if ([display isEqualToString:@"none"]) {
		[self.logController executeScriptCommand:@"didToggleInlineImageToHidden" withArguments:@[imageNode] onQueue:NO];
	} else {
		[self.logController executeScriptCommand:@"didToggleInlineImageToVisible" withArguments:@[imageNode] onQueue:NO];
	}
}

- (void)setURLAddress:(NSString *)s
{
    [[self.logController webViewPolicy] setAnchorURL:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNickname:(NSString *)s
{
    [[self.logController webViewPolicy] setNickname:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChannelName:(NSString *)s
{
    [[self.logController webViewPolicy] setChannelName:[s gtm_stringByUnescapingFromHTML]];
}

- (void)channelNameDoubleClicked
{
    [[self.logController webViewPolicy] channelDoubleClicked];
}

- (void)nicknameDoubleClicked
{
    [[self.logController webViewPolicy] nicknameDoubleClicked];
}

- (void)topicDoubleClicked
{
    [[self.logController webViewPolicy] topicDoubleClicked];
}

- (NSInteger)channelMemberCount
{
    return [[self.logController associatedChannel] numberOfMembers];
}

- (NSInteger)serverChannelCount
{
	return [[self.logController associatedClient] channelCount];
}

- (BOOL)serverIsConnected
{
	return [[self.logController associatedClient] isLoggedIn];
}

- (BOOL)channelIsJoined
{
	return [[self.logController associatedChannel] isActive];
}

- (NSString *)channelName
{
	return [[self.logController associatedChannel] name];
}

- (NSString *)serverAddress
{
	return [[self.logController associatedClient] networkAddress];
}

- (NSString *)networkName
{
	return [[self.logController associatedClient] networkName];
}

- (NSString *)localUserNickname
{
	return [[self.logController associatedClient] localNickname];
}

- (NSString *)localUserHostmask
{
	return [[self.logController associatedClient] localHostmask];
}

- (BOOL)inlineImagesEnabledForView
{
	return [self.logController inlineImagesEnabledForView];
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[[self.logController associatedClient] printDebugInformationToConsole:m];
}

- (void)printDebugInformation:(NSString *)m
{
	[[self.logController associatedClient] printDebugInformation:m channel:[self.logController associatedChannel]];
}

- (BOOL)sidebarInversionIsEnabled
{
	return [TPCPreferences invertSidebarColors];
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
