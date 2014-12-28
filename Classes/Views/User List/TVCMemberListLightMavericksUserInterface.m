/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

@interface TVCMemberListSharedUserInterface ()
@property (nonatomic, strong) NSCache *cachedUserMarkBadges;
@end

@implementation TVCMemberListSharedUserInterface

+ (BOOL)yosemiteIsUsingVibrantDarkMode
{
#ifdef TXSystemIsMacOSYosemiteOrNewer
	if ([CSFWSystemInformation featureAvailableToOSXYosemite] == NO) {
		return NO;
	} else {
		NSVisualEffectView *visualEffectView = [mainWindowMemberList() visualEffectView];
		
		NSAppearance *currentDesign = [visualEffectView appearance];
		
		NSString *name = [currentDesign name];
		
		if ([name hasPrefix:NSAppearanceNameVibrantDark]) {
			return YES;
		} else {
			return NO;
		}
	}
#else
	return NO;
#endif
}

- (NSString *)keyForRetrievingCachedUserMarkBadgeWithSymbol:(NSString *)mark rank:(IRCUserRank)rank
{
	return [NSString stringWithFormat:@"%lu > %@", rank, mark];
}

- (NSImage *)cachedUserMarkBadgeForSymbol:(NSString *)mark rank:(IRCUserRank)rank
{
	if (self.cachedUserMarkBadges == nil) {
		self.cachedUserMarkBadges = [NSCache new];
		
		return nil;
	} else {
		NSString *key = [self keyForRetrievingCachedUserMarkBadgeWithSymbol:mark rank:rank];
		
		return [self.cachedUserMarkBadges objectForKey:key];
	}
}

- (void)cacheUserMarkBadge:(NSImage *)badgeImage forSymbol:(NSString *)mark rank:(IRCUserRank)rank
{
	if (self.cachedUserMarkBadges == nil) {
		self.cachedUserMarkBadges = [NSCache new];
	}
	
	NSString *key = [self keyForRetrievingCachedUserMarkBadgeWithSymbol:mark rank:rank];
	
	[self.cachedUserMarkBadges setObject:[badgeImage copy] forKey:key];
}

- (void)invalidateAllUserMarkBadgeCaches
{
	if ( self.cachedUserMarkBadges) {
		[self.cachedUserMarkBadges removeAllObjects];
	}
}

- (NSColor *)memberListBackgroundColorForActiveWindow
{
	return nil;
}

- (NSColor *)memberListBackgroundColorForInactiveWindow
{
	return nil;
}

- (NSColor *)userMarkBadgeBackgroundColor_YDefault // InspIRCd-2.0
{
	return [NSColor colorWithCalibratedRed:0.632 green:0.335 blue:0.226 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_QDefault
{
	return [NSColor colorWithCalibratedRed:0.726 green:0.0 blue:0.0 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_ADefault
{
	return [NSColor colorWithCalibratedRed:0.613 green:0.0 blue:0.347 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_ODefault
{
	return [NSColor colorWithCalibratedRed:0.351 green:0.199 blue:0.609 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_HDefault
{
	return [NSColor colorWithCalibratedRed:0.066 green:0.488 blue:0.074 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_VDefault
{
	return [NSColor colorWithCalibratedRed:0.199 green:0.480 blue:0.609 alpha:1.0];
}

+ (NSColor *)userMarkBadgeBackgroundColorWithAlphaCorrect:(NSString *)defaultsKey
{
	NSColor *defaultColor = [RZUserDefaults() colorForKey:defaultsKey];
	
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		return [defaultColor colorWithAlphaComponent:0.7];
	} else {
		return  defaultColor;
	}
}

- (NSColor *)userMarkBadgeBackgroundColor_Y // InspIRCd-2.0
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +y"];
}

- (NSColor *)userMarkBadgeBackgroundColor_Q
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +q"];
}

- (NSColor *)userMarkBadgeBackgroundColor_A
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +a"];
}

- (NSColor *)userMarkBadgeBackgroundColor_O
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +o"];
}

- (NSColor *)userMarkBadgeBackgroundColor_H
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +h"];
}

- (NSColor *)userMarkBadgeBackgroundColor_V
{
	return [TVCMemberListSharedUserInterface userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors —> +v"];
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.5];
}

- (NSFont *)userMarkBadgeFontForRetina
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (NSFont *)userMarkBadgeFontSelected
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.5];
}

- (NSFont *)userMarkBadgeFontSelectedForRetina
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (NSInteger)userMarkBadgeWidth
{
	return 20.0;
}

- (NSInteger)userMarkBadgeHeight
{
	return 16.0;
}

@end

@implementation TVCMemberListMavericksUserInterfaceBackground

- (void)drawRect:(NSRect)dirtyRect
{
	/* The following is specialized drawing for the normal source list
	 background when inside a backed layer view. */
	
	NSColor *backgroundColor = nil;
	
	if ([mainWindow() isActiveForDrawing]) {
		backgroundColor = [[mainWindowMemberList() userInterfaceObjects] memberListBackgroundColorForActiveWindow];
	} else {
		backgroundColor = [[mainWindowMemberList() userInterfaceObjects] memberListBackgroundColorForInactiveWindow];
	}
	
	if (backgroundColor) {
		[backgroundColor set];
		
		NSRectFill([self bounds]);
	} else {
		NSGradient *backgroundGradient = [NSGradient sourceListBackgroundGradientColor];
		
		[backgroundGradient drawInRect:[self bounds] angle:270.0];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TVCMemberListMavericksUserInterface
@end

@implementation TVCMemberListYosemiteUserInterface
@end
#pragma clang diagnostic pop
