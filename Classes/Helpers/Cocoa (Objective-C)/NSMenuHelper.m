/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

#import <objc/runtime.h>

@implementation NSMenu (TXMenuHelper)
@end

@implementation NSMenuItem (TXMenuItemHelper)

static void *_internalUserInfo = nil;

- (NSString *)userInfo
{
	return objc_getAssociatedObject(self, _internalUserInfo);
}

- (void)setUserInfo:(NSString *)userInfo
{
	objc_setAssociatedObject(self, _internalUserInfo, userInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setUserInfo:(NSString *)userInfo recursively:(BOOL)recursively
{
	if (recursively) {
		if ([self hasSubmenu]) {
			NSArray *subItems = [[self submenu] itemArray];

			for (NSMenuItem *subItem in subItems) {
				[subItem setUserInfo:userInfo recursively:YES];
			}
		}
	}

	[self setUserInfo:userInfo];
}

+ (instancetype)menuItemWithTitle:(NSString *)aString target:(id)aTarget action:(SEL)aSelector
{
	return [self menuItemWithTitle:aString target:aTarget action:aSelector keyEquivalent:NSStringEmptyPlaceholder keyEquivalentMask:0];
}

+ (instancetype)menuItemWithTitle:(NSString *)aString target:(id)aTarget action:(SEL)aSelector keyEquivalent:(NSString *)charCode keyEquivalentMask:(NSUInteger)mask
{
	id menuItem = [[self alloc] initWithTitle:aString action:aSelector keyEquivalent:charCode];

	[menuItem setKeyEquivalentModifierMask:mask];
	[menuItem setTarget:aTarget];

	return menuItem;
}

@end
