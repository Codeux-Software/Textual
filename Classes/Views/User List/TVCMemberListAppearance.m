/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 *    Copyright (c) 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSColorHelper.h"
#import "NSObjectHelperPrivate.h"
#import "NSViewHelperPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TVCAppearancePrivate.h"
#import "TVCMainWindow.h"
#import "TVCMemberListPrivate.h"
#import "TVCMemberListAppearancePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCMemberListMavericksBackgroundBox ()
@property (nonatomic, weak) IBOutlet TVCMemberList *memberList;
@end

@interface TVCMemberListAppearance ()
@property (nonatomic, weak, readwrite) TVCMemberList *memberList;

@property (nonatomic, copy, nullable, readwrite) NSColor *backgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *backgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *rowSelectionColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *rowSelectionColorInactiveWindow;

#pragma mark -
#pragma mark Member Cell

@property (nonatomic, assign, readwrite) CGFloat cellRowHeight;
@property (nonatomic, copy, nullable, readwrite) NSImage *cellSelectionImageActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSImage *cellSelectionImageInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellAwayTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellAwayTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellAwayTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellAwayTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellSelectedTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellSelectedTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellSelectedTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *cellSelectedTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSFont *cellFont;
@property (nonatomic, copy, nullable, readwrite) NSFont *cellFontSelected;
@property (nonatomic, assign, readwrite) CGFloat cellTopOffset;

#pragma mark -
#pragma mark Mark Badge

@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeBackgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeBackgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeSelectedBackgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeSelectedBackgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeSelectedTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeSelectedTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *markBadgeShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSFont *markBadgeFont;
@property (nonatomic, copy, nullable, readwrite) NSFont *markBadgeFontSelected;
@property (nonatomic, assign, readwrite) CGFloat markBadgeWidth;
@property (nonatomic, assign, readwrite) CGFloat markBadgeHeight;
@property (nonatomic, assign, readwrite) CGFloat markBadgeTopOffset;

@property (nonatomic, weak, readwrite) TVCMainWindowAppearance *parentAppearance;

@property (nonatomic, strong, nullable) NSCache *cachedUserMarkBadges;
@end

@implementation TVCMemberListAppearance

#pragma mark -
#pragma mark Initialization

- (nullable instancetype)initWithMemberList:(TVCMemberList *)MemberList parentAppearance:(TVCMainWindowAppearance *)appearance
{
	NSParameterAssert(MemberList != nil);
	NSParameterAssert(appearance != nil);

	NSString *appearanceName = appearance.appearanceName;

	NSURL *appearanceLocation = [self.class appearanceLocation];

	BOOL forRetinaDisplay = appearance.isHighResolutionAppearance;

	if ((self = [super initWithAppearanceNamed:appearanceName atURL:appearanceLocation forRetinaDisplay:forRetinaDisplay])) {
		self.memberList = MemberList;

		self.parentAppearance = appearance;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

+ (NSURL *)appearanceLocation
{
	return [RZMainBundle() URLForResource:@"TVCMemberListAppearance" withExtension:@"plist"];
}

- (void)prepareInitialState
{
	NSDictionary *properties = self.appearanceProperties;

	self.rowSelectionColorActiveWindow = [self colorForKey:@"selectionColor" forActiveWindow:YES];
	self.rowSelectionColorInactiveWindow = [self colorForKey:@"selectionColor" forActiveWindow:NO];
	self.backgroundColorActiveWindow = [self colorForKey:@"backgroundColor" forActiveWindow:YES];
	self.backgroundColorInactiveWindow = [self colorForKey:@"backgroundColor" forActiveWindow:NO];

	NSDictionary *memberCell = properties[@"Member Cell"];

	self.cellRowHeight = [self measurementInGroup:memberCell withKey:@"rowHeight"];
	self.cellSelectionImageActiveWindow = [self imageInGroup:memberCell withKey:@"selectionImage" forActiveWindow:YES];
	self.cellSelectionImageInactiveWindow = [self imageInGroup:memberCell withKey:@"selectionImage" forActiveWindow:NO];
	self.cellTextColorActiveWindow = [self colorInGroup:memberCell withKey:@"normalTextColor" forActiveWindow:YES];
	self.cellTextColorInactiveWindow = [self colorInGroup:memberCell withKey:@"normalTextColor" forActiveWindow:NO];
	self.cellTextShadowColorActiveWindow = [self colorInGroup:memberCell withKey:@"normalTextShadowColor" forActiveWindow:YES];
	self.cellTextShadowColorInactiveWindow = [self colorInGroup:memberCell withKey:@"normalTextShadowColor" forActiveWindow:NO];
	self.cellAwayTextColorActiveWindow = [self colorInGroup:memberCell withKey:@"awayTextColor" forActiveWindow:YES];
	self.cellAwayTextColorInactiveWindow = [self colorInGroup:memberCell withKey:@"awayTextColor" forActiveWindow:NO];
	self.cellAwayTextShadowColorActiveWindow = [self colorInGroup:memberCell withKey:@"awayTextShadowColor" forActiveWindow:YES];
	self.cellAwayTextShadowColorInactiveWindow = [self colorInGroup:memberCell withKey:@"awayTextShadowColor" forActiveWindow:NO];
	self.cellSelectedTextColorActiveWindow = [self colorInGroup:memberCell withKey:@"selectedTextColor" forActiveWindow:YES];
	self.cellSelectedTextColorInactiveWindow = [self colorInGroup:memberCell withKey:@"selectedTextColor" forActiveWindow:NO];
	self.cellSelectedTextShadowColorActiveWindow = [self colorInGroup:memberCell withKey:@"selectedTextShadowColor" forActiveWindow:YES];
	self.cellSelectedTextShadowColorInactiveWindow = [self colorInGroup:memberCell withKey:@"selectedTextShadowColor" forActiveWindow:NO];
	self.cellFont = [self fontInGroup:memberCell withKey:@"font"];
	self.cellFontSelected = [self fontInGroup:memberCell withKey:@"fontSelected"];
	self.cellTopOffset = [self measurementInGroup:memberCell withKey:@"topOffset"];

	NSDictionary *markBadge = properties[@"Mark Badge"];

	self.markBadgeBackgroundColorActiveWindow = [self colorInGroup:markBadge withKey:@"normalBackgroundColor" forActiveWindow:YES];
	self.markBadgeBackgroundColorInactiveWindow = [self colorInGroup:markBadge withKey:@"normalBackgroundColor" forActiveWindow:NO];
	self.markBadgeSelectedBackgroundColorActiveWindow = [self colorInGroup:markBadge withKey:@"selectedBackgroundColor" forActiveWindow:YES];
	self.markBadgeSelectedBackgroundColorInactiveWindow = [self colorInGroup:markBadge withKey:@"selectedBackgroundColor" forActiveWindow:NO];
	self.markBadgeTextColorActiveWindow = [self colorInGroup:markBadge withKey:@"normalTextColor" forActiveWindow:YES];
	self.markBadgeTextColorInactiveWindow = [self colorInGroup:markBadge withKey:@"normalTextColor" forActiveWindow:NO];
	self.markBadgeSelectedTextColorActiveWindow = [self colorInGroup:markBadge withKey:@"selectedTextColor" forActiveWindow:YES];
	self.markBadgeSelectedTextColorInactiveWindow = [self colorInGroup:markBadge withKey:@"selectedTextColor" forActiveWindow:NO];
	self.markBadgeShadowColorActiveWindow = [self colorInGroup:markBadge withKey:@"shadowColor" forActiveWindow:YES];
	self.markBadgeShadowColorInactiveWindow = [self colorInGroup:markBadge withKey:@"shadowColor" forActiveWindow:NO];
	self.markBadgeFont = [self fontInGroup:markBadge withKey:@"font"];
	self.markBadgeFontSelected = [self fontInGroup:markBadge withKey:@"fontSelected"];
	self.markBadgeWidth = [self measurementInGroup:markBadge withKey:@"width"];
	self.markBadgeHeight = [self measurementInGroup:markBadge withKey:@"height"];
	self.markBadgeTopOffset = [self measurementInGroup:markBadge withKey:@"topOffset"];

	[self flushAppearanceProperties];
}

#pragma mark -
#pragma mark Properties

- (TVCMainWindowAppearanceType)appearanceType
{
	return self.parentAppearance.appearanceType;
}

- (BOOL)isDarkAppearance
{
	return self.parentAppearance.isDarkAppearance;
}

- (BOOL)isHighResolutionAppearance
{
	return self.parentAppearance.isHighResolutionAppearance;
}

- (BOOL)isModernAppearance
{
	return self.parentAppearance.isModernAppearance;
}

#pragma mark -
#pragma mark Everything Else

- (NSString *)_keyForRetrievingCachedUserMarkBadgeWithSymbol:(NSString *)modeSymbol rank:(IRCUserRank)rank
{
	if (modeSymbol.length == 0) {
		return [NSString stringWithFormat:@"%lu > (No Rank)", rank];
	} else {
		return [NSString stringWithFormat:@"%lu > %@", rank, modeSymbol];
	}
}

- (nullable NSImage *)cachedUserMarkBadgeForSymbol:(NSString *)modeSymbol rank:(IRCUserRank)rank
{
	NSParameterAssert(modeSymbol != nil);

	NSCache *cache = self.cachedUserMarkBadges;

	if (cache == nil) {
		return nil;
	}

	NSString *key = [self _keyForRetrievingCachedUserMarkBadgeWithSymbol:modeSymbol rank:rank];

	return [cache objectForKey:key];
}

- (void)cacheUserMarkBadge:(NSImage *)badgeImage forSymbol:(NSString *)modeSymbol rank:(IRCUserRank)rank
{
	NSParameterAssert(badgeImage != nil);
	NSParameterAssert(modeSymbol != nil);

	NSCache *cache = self.cachedUserMarkBadges;

	if (cache == nil) {
		cache = [NSCache new];

		self.cachedUserMarkBadges = cache;
	}

	NSString *key = [self _keyForRetrievingCachedUserMarkBadgeWithSymbol:modeSymbol rank:rank];

	[cache setObject:badgeImage forKey:key];
}

- (void)invalidateUserMarkBadgeCacheForSymbol:(NSString *)modeSymbol rank:(IRCUserRank)rank
{
	NSParameterAssert(modeSymbol != nil);

	NSCache *cache = self.cachedUserMarkBadges;

	if (cache == nil) {
		return;
	}

	NSString *key = [self _keyForRetrievingCachedUserMarkBadgeWithSymbol:modeSymbol rank:rank];

	return [cache removeObjectForKey:key];
}

- (void)invalidateUserMarkBadgeCaches
{
	NSCache *cache = self.cachedUserMarkBadges;

	if (cache == nil) {
		return;
	}

	[cache removeAllObjects];
}

+ (NSColor *)_userMarkBadgeBackgroundColorWithAlphaCorrect:(NSString *)defaultsKey
{
	NSColor *defaultColor = [RZUserDefaults() colorForKey:defaultsKey];

	if (TEXTUAL_RUNNING_ON_YOSEMITE) {
		return [defaultColor colorWithAlphaComponent:0.7];
	} else {
		return  defaultColor;
	}
}

- (NSColor *)markBadgeBackgroundColor_Y // InspIRCd-2.0
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +y"];
}

- (NSColor *)markBadgeBackgroundColor_Q
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +q"];
}

- (NSColor *)markBadgeBackgroundColor_A
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +a"];
}

- (NSColor *)markBadgeBackgroundColor_O
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +o"];
}

- (NSColor *)markBadgeBackgroundColor_H
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +h"];
}

- (NSColor *)markBadgeBackgroundColor_V
{
	return [self.class _userMarkBadgeBackgroundColorWithAlphaCorrect:@"User List Mode Badge Colors -> +v"];
}

@end

#pragma mark -

@implementation TVCMemberListMavericksBackgroundBox

- (void)drawRect:(NSRect)dirtyRect
{
	/* The following is specialized drawing for the normal source list
	 background when inside a backed layer view. */
	NSColor *backgroundColor = nil;

	if (self.mainWindow.isActiveForDrawing) {
		backgroundColor = self.memberList.userInterfaceObjects.backgroundColorActiveWindow;
	} else {
		backgroundColor = self.memberList.userInterfaceObjects.backgroundColorInactiveWindow;
	}

	if ( backgroundColor) {
		[backgroundColor set];

		NSRectFill(self.bounds);
	} else {
		NSGradient *backgroundGradient = [NSGradient sourceListBackgroundGradientColor];

		[backgroundGradient drawInRect:self.bounds angle:270.0];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

@end

NS_ASSUME_NONNULL_END
