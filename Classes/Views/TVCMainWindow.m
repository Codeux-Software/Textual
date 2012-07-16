/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation TVCMainWindow

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if ((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])) {
		self.keyHandler = [TLOKeyEventHandler new];
	}
	
	return self;
}

- (void)setKeyHandlerTarget:(id)target
{
	[self.keyHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[self.keyHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[self.keyHandler registerSelector:selector character:c modifiers:mods];
}

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == NSKeyDown) {
		if ([self.keyHandler processKeyEvent:e]) {
			return;
		}
	}
	
	[super sendEvent:e];
}

- (void)endEditingFor:(id)object
{
	/* WebHTMLView results in this method being called.
	 *
	 * The documentation states "The endEditingFor: method should be used only as a
	 * last resort if the field editor refuses to resign first responder status."
	 *
	 * The documentation then goes to say how you should try setting makeFirstResponder first.
	 */

	if ([self makeFirstResponder:self] == NO) {
		[super endEditingFor:object];
	}
}

@end