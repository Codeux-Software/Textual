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

@implementation NSWindow (TXWindowHelper)

- (void)exactlyCenterWindow
{
	NSScreen *screen = [NSScreen mainScreen];
	
	if (screen) {
		NSRect rect = [screen visibleFrame];
		
		NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
								(rect.origin.y + (rect.size.height / 2)));
		
		NSInteger w = self.frame.size.width;
		NSInteger h = self.frame.size.height;
		
		rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
		
		[self setFrame:rect display:YES animate:YES];
	}	
}

- (void)saveWindowStateForClass:(Class)owner
{
	[self saveWindowStateUsingKeyword:NSStringFromClass(owner)];
}

- (void)restoreWindowStateForClass:(Class)owner
{
	[self restoreWindowStateUsingKeyword:NSStringFromClass(owner)];
}

- (void)saveWindowStateUsingKeyword:(NSString *)keyword
{
	NSObjectIsEmptyAssert(keyword);

	keyword = [NSString stringWithFormat:@"Saved Window State —> Internal —> %@", keyword];

	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	NSRect rect = self.frame;

	[dic setInteger:rect.origin.x forKey:@"x"];
	[dic setInteger:rect.origin.y forKey:@"y"];
	[dic setInteger:rect.size.width forKey:@"w"];
	[dic setInteger:rect.size.height forKey:@"h"];

	[TPCPreferences saveWindowState:dic name:keyword];
}

- (void)restoreWindowStateUsingKeyword:(NSString *)keyword
{
	NSObjectIsEmptyAssert(keyword);

	keyword = [NSString stringWithFormat:@"Saved Window State —> Internal —> %@", keyword];

	NSDictionary *dic = [TPCPreferences loadWindowStateWithName:keyword];

	BOOL invalidateSavedState = NSDissimilarObjects(dic.count, 4);

	NSRect visibleRect = [RZMainScreen() frame];

	NSRect currFrame = self.frame;
	
	NSInteger x = [dic integerForKey:@"x"];
	NSInteger y = [dic integerForKey:@"y"];

	NSInteger oldHeight = [dic integerForKey:@"h"];
	NSInteger heightDff = (oldHeight - currFrame.size.height);

	y += heightDff;
	
	if ((x + currFrame.size.width) > visibleRect.size.width) {
		invalidateSavedState = YES;
	}

	if ((y + currFrame.size.height) > visibleRect.size.height) {
		invalidateSavedState = YES;
	}

	if (invalidateSavedState) {
		[self exactlyCenterWindow];

		return;
	}

	currFrame.origin.x = x;
	currFrame.origin.y = y;

	[self setFrame:currFrame display:YES animate:YES];
}

- (BOOL)isInFullscreenMode
{
	return ((self.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}

@end
