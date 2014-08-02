/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

@implementation TVCServerListSharedUserInterface

+ (BOOL)yosemiteIsUsingVibrantDarkMode
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite] == NO) {
		return NO;
	} else {
		NSVisualEffectView *visualEffectView = [mainWindowServerList() visualEffectView];
		
		NSAppearance *currentDesign = [visualEffectView appearance];
		
		NSString *name = [currentDesign name];
		
		if ([name hasPrefix:NSAppearanceNameVibrantDark]) {
			return YES;
		} else {
			return NO;
		}
	}
}

- (void)setOutlineViewDefaultDisclosureTriangle:(NSImage *)image
{
	id cachedObject = [mainWindowServerList() outlineViewDefaultDisclosureTriangle];
	
	if (cachedObject == nil) {
		[mainWindowServerList() setOutlineViewDefaultDisclosureTriangle:image];
	}
}

- (void)setOutlineViewAlternateDisclosureTriangle:(NSImage *)image
{
	id cachedObject = [mainWindowServerList() outlineViewAlternateDisclosureTriangle];
					   
	if (cachedObject == nil) {
		[mainWindowServerList() setOutlineViewAlternateDisclosureTriangle:image];
	}
}

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	if (up) {
		return [mainWindowServerList() outlineViewDefaultDisclosureTriangle];
	} else {
		return [mainWindowServerList() outlineViewAlternateDisclosureTriangle];
	}
}

@end

@implementation TVCServerListMavericksUserInterfaceBackground

- (void)drawRect:(NSRect)dirtyRect
{
	/* The following is specialized drawing for the normal source list
	 background when inside a backed layer view. */
	
	NSColor *backgroundColor = nil;
	
	if ([mainWindow() isActiveForDrawing]) {
		backgroundColor = [[mainWindowServerList() userInterfaceObjects] serverListBackgroundColorForActiveWindow];
	} else {
		backgroundColor = [[mainWindowServerList() userInterfaceObjects] serverListBackgroundColorForInactiveWindow];
	}
	
	if (backgroundColor) {
		[backgroundColor set];
		
		NSRectFill([self bounds]);
	} else {
		NSGradient *backgroundGradient = [NSGradient sourceListBackgroundGradientColor];
		
		[backgroundGradient drawInRect:[self bounds] angle:270.0];
	}
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TVCServerListMavericksUserInterface
@end

@implementation TVCServerListYosemiteUserInterface
@end
#pragma clang diagnostic pop
