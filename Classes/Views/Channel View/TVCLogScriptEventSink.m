/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#define _doubleClickRadius		3

@implementation TVCLogScriptEventSink

- (id)init
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
	
	if ([s hasSuffix:@":"]) {
		return [s safeSubstringToIndex:(s.length - 1)];
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
	
	NSTimeInterval now = [NSDate epochTime];
	
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

- (NSString *)toggleInlineImage:(NSString *)object
{
	return [self toggleInlineImage:object withKeyCheck:YES orientation:(-1)];
}

- (NSString *)toggleInlineImage:(NSString *)object withKeyCheck:(BOOL)checkShiftKey orientation:(NSInteger)orientationIndex
{
	/* Possible values for orientation index:
	
	 -1 Do nothing
	  1 Top, left
	  2 Top, right
	  3 Bottom, right
	  4 Bottom, left
	  5 Left, top
	  6 Right, top
	  7 Right, bottom
	  8 Left, bottom
	 */

	/* What type of request is this? */
	if (([NSEvent modifierFlags] & NSShiftKeyMask) == NO && checkShiftKey) {
		return @"true";
	}

	NSObjectIsEmptyAssertReturn(object, @"true");

	/* Do we have a properly formatted ID? */
	if ([object hasPrefix:@"inlineImage-"] == NO) {
		object = [@"inlineImage-" stringByAppendingString:object];
	}

	/* Find the element. */
	DOMElement *imageNode = [self.owner.mainFrameDocument getElementById:object];

	PointerIsEmptyAssertReturn(imageNode, @"true");

	/* Update the display information. */
	NSString *display = imageNode.style.display;

	if ([display isEqualIgnoringCase:@"none"]) {
		display = NSStringEmptyPlaceholder;
	} else {
		display = @"none";
	}

	imageNode.style.display = display;

	/* Update upstream. */
	return @"false";
}

- (void)setURLAddress:(NSString *)s
{
	[self.owner.policy setAnchorURL:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNickname:(NSString *)s
{
	[self.owner.policy setNickname:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChannelName:(NSString *)s
{
	[self.owner.policy setChannelName:[s gtm_stringByUnescapingFromHTML]];
}

- (void)channelNameDoubleClicked
{
	[self.owner.policy channelDoubleClicked];
}

- (void)nicknameDoubleClicked
{
	[self.owner.policy nicknameDoubleClicked];
}

- (void)topicDoubleClicked
{
    [self.owner.policy topicDoubleClicked];
}

- (NSInteger)channelMemberCount
{
    return [self.owner.channel numberOfMembers];
}

- (NSInteger)serverChannelCount
{
    return [self.owner.client.channels count];
}

- (BOOL)serverIsConnected
{
    return self.owner.client.isLoggedIn;
}

- (BOOL)channelIsJoined
{
    return self.owner.channel.isActive;
}

- (NSString *)channelName
{
	return self.owner.channel.name;
}

- (NSString *)serverAddress
{
	return self.owner.client.networkAddress;
}

- (NSString *)localUserNickname
{
	return self.owner.client.localNickname;
}

- (NSString *)localUserHostmask
{
	return self.owner.client.localHostmask;
}

- (void)printDebugInformationToConsole:(NSString *)m
{
	[self.owner.client printDebugInformationToConsole:m];
}

- (void)printDebugInformation:(NSString *)m
{
	[self.owner.client printDebugInformation:m channel:self.owner.channel];
}

- (BOOL)sidebarInversionIsEnabled
{
	return [TPCPreferences invertSidebarColors];
}

- (void)print:(NSString *)s
{
}

@end
