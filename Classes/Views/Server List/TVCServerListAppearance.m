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
#import "TVCServerListPrivate.h"
#import "TVCServerListAppearancePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCServerListMavericksBackgroundBox ()
@property (nonatomic, weak) IBOutlet TVCServerList *serverList;
@end

@interface TVCServerListAppearance ()
@property (nonatomic, weak, readwrite) TVCServerList *serverList;

@property (nonatomic, assign, readwrite) CGFloat defaultWidth;
@property (nonatomic, assign, readwrite) CGFloat minimumWidth;
@property (nonatomic, assign, readwrite) CGFloat maximumWidth;

@property (nonatomic, copy, nullable, readwrite) NSColor *backgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *backgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *rowSelectionColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *rowSelectionColorInactiveWindow;

#pragma mark -
#pragma mark Server Cell

@property (nonatomic, assign, readwrite) CGFloat serverRowHeight;
@property (nonatomic, copy, nullable, readwrite) NSImage *serverSelectionImageActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSImage *serverSelectionImageInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverDisabledTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverDisabledTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverDisabledTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverDisabledTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverSelectedTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverSelectedTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverSelectedTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *serverSelectedTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSFont *serverFont;
@property (nonatomic, copy, nullable, readwrite) NSFont *serverFontSelected;
@property (nonatomic, assign, readwrite) CGFloat serverTopOffset;

#pragma mark -
#pragma mark Channel Cell

@property (nonatomic, assign, readwrite) CGFloat channelRowHeight;
@property (nonatomic, copy, nullable, readwrite) NSImage *channelSelectionImageActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSImage *channelSelectionImageInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelDisabledTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelDisabledTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelDisabledTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelDisabledTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelSelectedTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelSelectedTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelSelectedTextShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelSelectedTextShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelErroneousTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelErroneousTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelHighlightTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *channelHighlightTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSFont *channelFont;
@property (nonatomic, copy, nullable, readwrite) NSFont *channelFontSelected;
@property (nonatomic, assign, readwrite) CGFloat channelTopOffset;

#pragma mark -
#pragma mark Message Count Badge

@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeBackgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeBackgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeSelectedBackgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeSelectedBackgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeHighlightBackgroundColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeHighlightBackgroundColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeSelectedTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeSelectedTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeHighlightTextColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeHighlightTextColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeShadowColorActiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSColor *unreadBadgeShadowColorInactiveWindow;
@property (nonatomic, copy, nullable, readwrite) NSFont *unreadBadgeFont;
@property (nonatomic, copy, nullable, readwrite) NSFont *unreadBadgeFontSelected;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgeMinimumWidth;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgeHeight;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgePadding;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgeTextCenterYOffset;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgeTopOffset;
@property (nonatomic, assign, readwrite) CGFloat unreadBadgeRightMargin;

@property (nonatomic, weak, readwrite) TVCMainWindowAppearance *parentAppearance;
@end

@implementation TVCServerListAppearance

#pragma mark -
#pragma mark Initialization

- (nullable instancetype)initWithServerList:(TVCServerList *)serverList parentAppearance:(TVCMainWindowAppearance *)appearance
{
	NSParameterAssert(serverList != nil);
	NSParameterAssert(appearance != nil);

	NSString *appearanceName = appearance.appearanceName;

	NSURL *appearanceLocation = [self.class appearanceLocation];

	BOOL forRetinaDisplay = appearance.isHighResolutionAppearance;

	if ((self = [super initWithAppearanceNamed:appearanceName atURL:appearanceLocation forRetinaDisplay:forRetinaDisplay])) {
		self.serverList = serverList;

		self.parentAppearance = appearance;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

+ (NSURL *)appearanceLocation
{
	return [RZMainBundle() URLForResource:@"TVCServerListAppearance" withExtension:@"plist"];
}

- (void)prepareInitialState
{
	NSDictionary *properties = self.appearanceProperties;

	self.defaultWidth = [self measurementForKey:@"defaultWidth"];
	self.minimumWidth = [self measurementForKey:@"minimumWidth"];
	self.maximumWidth = [self measurementForKey:@"maximumWidth"];

	self.rowSelectionColorActiveWindow = [self colorForKey:@"selectionColor" forActiveWindow:YES];
	self.rowSelectionColorInactiveWindow = [self colorForKey:@"selectionColor" forActiveWindow:NO];
	self.backgroundColorActiveWindow = [self colorForKey:@"backgroundColor" forActiveWindow:YES];
	self.backgroundColorInactiveWindow = [self colorForKey:@"backgroundColor" forActiveWindow:NO];

	NSDictionary *serverCell = properties[@"Server Cell"];

	self.serverRowHeight = [self measurementInGroup:serverCell withKey:@"rowHeight"];
	self.serverSelectionImageActiveWindow = [self imageInGroup:serverCell withKey:@"selectionImage" forActiveWindow:YES];
	self.serverSelectionImageInactiveWindow = [self imageInGroup:serverCell withKey:@"selectionImage" forActiveWindow:NO];
	self.serverTextColorActiveWindow = [self colorInGroup:serverCell withKey:@"normalTextColor" forActiveWindow:YES];
	self.serverTextColorInactiveWindow = [self colorInGroup:serverCell withKey:@"normalTextColor" forActiveWindow:NO];
	self.serverTextShadowColorActiveWindow = [self colorInGroup:serverCell withKey:@"normalTextShadowColor" forActiveWindow:YES];
	self.serverTextShadowColorInactiveWindow = [self colorInGroup:serverCell withKey:@"normalTextShadowColor" forActiveWindow:NO];
	self.serverDisabledTextColorActiveWindow = [self colorInGroup:serverCell withKey:@"disabledTextColor" forActiveWindow:YES];
	self.serverDisabledTextColorInactiveWindow = [self colorInGroup:serverCell withKey:@"disabledTextColor" forActiveWindow:NO];
	self.serverDisabledTextShadowColorActiveWindow = [self colorInGroup:serverCell withKey:@"disabledTextShadowColor" forActiveWindow:YES];
	self.serverDisabledTextShadowColorInactiveWindow = [self colorInGroup:serverCell withKey:@"disabledTextShadowColor" forActiveWindow:NO];
	self.serverSelectedTextColorActiveWindow = [self colorInGroup:serverCell withKey:@"selectedTextColor" forActiveWindow:YES];
	self.serverSelectedTextColorInactiveWindow = [self colorInGroup:serverCell withKey:@"selectedTextColor" forActiveWindow:NO];
	self.serverSelectedTextShadowColorActiveWindow = [self colorInGroup:serverCell withKey:@"selectedTextShadowColor" forActiveWindow:YES];
	self.serverSelectedTextShadowColorInactiveWindow = [self colorInGroup:serverCell withKey:@"selectedTextShadowColor" forActiveWindow:NO];
	self.serverFont = [self fontInGroup:serverCell withKey:@"font"];
	self.serverFontSelected = [self fontInGroup:serverCell withKey:@"fontSelected"];
	self.serverTopOffset = [self measurementInGroup:serverCell withKey:@"topOffset"];

	NSDictionary *channelCell = properties[@"Channel Cell"];

	self.channelRowHeight = [self measurementInGroup:channelCell withKey:@"rowHeight"];
	self.channelSelectionImageActiveWindow = [self imageInGroup:channelCell withKey:@"selectionImage" forActiveWindow:YES];
	self.channelSelectionImageInactiveWindow = [self imageInGroup:channelCell withKey:@"selectionImage" forActiveWindow:NO];
	self.channelTextColorActiveWindow = [self colorInGroup:channelCell withKey:@"normalTextColor" forActiveWindow:YES];
	self.channelTextColorInactiveWindow = [self colorInGroup:channelCell withKey:@"normalTextColor" forActiveWindow:NO];
	self.channelTextShadowColorActiveWindow = [self colorInGroup:channelCell withKey:@"normalTextShadowColor" forActiveWindow:YES];
	self.channelTextShadowColorInactiveWindow = [self colorInGroup:channelCell withKey:@"normalTextShadowColor" forActiveWindow:NO];
	self.channelDisabledTextColorActiveWindow = [self colorInGroup:channelCell withKey:@"disabledTextColor" forActiveWindow:YES];
	self.channelDisabledTextColorInactiveWindow = [self colorInGroup:channelCell withKey:@"disabledTextColor" forActiveWindow:NO];
	self.channelDisabledTextShadowColorActiveWindow = [self colorInGroup:channelCell withKey:@"disabledTextShadowColor" forActiveWindow:YES];
	self.channelDisabledTextShadowColorInactiveWindow = [self colorInGroup:channelCell withKey:@"disabledTextShadowColor" forActiveWindow:NO];
	self.channelSelectedTextColorActiveWindow = [self colorInGroup:channelCell withKey:@"selectedTextColor" forActiveWindow:YES];
	self.channelSelectedTextColorInactiveWindow = [self colorInGroup:channelCell withKey:@"selectedTextColor" forActiveWindow:NO];
	self.channelSelectedTextShadowColorActiveWindow = [self colorInGroup:channelCell withKey:@"selectedTextShadowColor" forActiveWindow:YES];
	self.channelSelectedTextShadowColorInactiveWindow = [self colorInGroup:channelCell withKey:@"selectedTextShadowColor" forActiveWindow:NO];
	self.channelErroneousTextColorActiveWindow = [self colorInGroup:channelCell withKey:@"erroneousTextColor" forActiveWindow:YES];
	self.channelErroneousTextColorInactiveWindow = [self colorInGroup:channelCell withKey:@"erroneousTextColor" forActiveWindow:NO];
	self.channelHighlightTextColorActiveWindow = [self colorInGroup:channelCell withKey:@"highlightTextColor" forActiveWindow:YES];
	self.channelHighlightTextColorInactiveWindow = [self colorInGroup:channelCell withKey:@"highlightTextColor" forActiveWindow:NO];
	self.channelFont = [self fontInGroup:channelCell withKey:@"font"];
	self.channelFontSelected = [self fontInGroup:channelCell withKey:@"fontSelected"];
	self.channelTopOffset = [self measurementInGroup:channelCell withKey:@"topOffset"];

	NSDictionary *unreadBadge = properties[@"Unread Badge"];

	self.unreadBadgeBackgroundColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"normalBackgroundColor" forActiveWindow:YES];
	self.unreadBadgeBackgroundColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"normalBackgroundColor" forActiveWindow:NO];
	self.unreadBadgeSelectedBackgroundColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"selectedBackgroundColor" forActiveWindow:YES];
	self.unreadBadgeSelectedBackgroundColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"selectedBackgroundColor" forActiveWindow:NO];
	self.unreadBadgeHighlightBackgroundColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"highlightBackgroundColor" forActiveWindow:YES];
	self.unreadBadgeHighlightBackgroundColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"highlightBackgroundColor" forActiveWindow:NO];
	self.unreadBadgeTextColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"normalTextColor" forActiveWindow:YES];
	self.unreadBadgeTextColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"normalTextColor" forActiveWindow:NO];
	self.unreadBadgeSelectedTextColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"selectedTextColor" forActiveWindow:YES];
	self.unreadBadgeSelectedTextColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"selectedTextColor" forActiveWindow:NO];
	self.unreadBadgeHighlightTextColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"highlightTextColor" forActiveWindow:YES];
	self.unreadBadgeHighlightTextColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"highlightTextColor" forActiveWindow:NO];
	self.unreadBadgeShadowColorActiveWindow = [self colorInGroup:unreadBadge withKey:@"shadowColor" forActiveWindow:YES];
	self.unreadBadgeShadowColorInactiveWindow = [self colorInGroup:unreadBadge withKey:@"shadowColor" forActiveWindow:NO];
	self.unreadBadgeFont = [self fontInGroup:unreadBadge withKey:@"font"];
	self.unreadBadgeFontSelected = [self fontInGroup:unreadBadge withKey:@"fontSelected"];
	self.unreadBadgeMinimumWidth = [self measurementInGroup:unreadBadge withKey:@"minimumWidth"];
	self.unreadBadgeHeight = [self measurementInGroup:unreadBadge withKey:@"height"];
	self.unreadBadgePadding = [self measurementInGroup:unreadBadge withKey:@"padding"];
	self.unreadBadgeTextCenterYOffset = [self measurementInGroup:unreadBadge withKey:@"textCenterYOffset"];
	self.unreadBadgeTopOffset = [self measurementInGroup:unreadBadge withKey:@"topOffset"];
	self.unreadBadgeRightMargin = [self measurementInGroup:unreadBadge withKey:@"rightMargin"];

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

- (void)setOutlineViewDefaultDisclosureTriangle:(NSImage *)image
{
	if (self.serverList.outlineViewDefaultDisclosureTriangle == nil) {
		self.serverList.outlineViewDefaultDisclosureTriangle = image;
	}
}

- (void)setOutlineViewAlternateDisclosureTriangle:(NSImage *)image
{
	if (self.serverList.outlineViewAlternateDisclosureTriangle == nil) {
		self.serverList.outlineViewAlternateDisclosureTriangle = image;
	}
}

- (nullable NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	TVCMainWindowAppearanceType appearanceType = self.appearanceType;

	switch (appearanceType) {
		case TVCMainWindowAppearanceMavericksAquaDarkType:
		case TVCMainWindowAppearanceMavericksGraphiteDarkType:
		{
			if (up) {
				if (selected) {
					return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureUpSelected"];
				} else {
					return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureUp"];
				}
			} else {
				if (selected) {
					return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureDownSelected"];
				} else {
					return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureDown"];
				}
			}
		} // Mavericks
		case TVCMainWindowAppearanceYosemiteDarkType:
		case TVCMainWindowAppearanceMojaveDarkType:
		{
			if (up) {
				return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureUp"];
			} else {
				return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureDown"];
			}
		} // Yosemite, Mojave
		default:
		{
			break;
		}
	} // switch()

	if (up) {
		return self.serverList.outlineViewDefaultDisclosureTriangle;
	} else {
		return self.serverList.outlineViewAlternateDisclosureTriangle;
	}
}

- (nullable NSString *)statusIconForActiveChannel:(BOOL)isActive selected:(BOOL)isSelected activeWindow:(BOOL)isActiveWindow treatAsTemplate:(BOOL *)treatAsTemplate
{
	NSParameterAssert(treatAsTemplate != NULL);

	TVCMainWindowAppearanceType appearanceType = self.appearanceType;

	switch (appearanceType) {
		case TVCMainWindowAppearanceMavericksAquaLightType:
		case TVCMainWindowAppearanceMavericksGraphiteLightType:
		{
			if (isActive) {
				return @"channelRoomStatusIconMavericksLightActive";
			} else {
				return @"channelRoomStatusIconMavericksLightInactive";
			}
		}
		case TVCMainWindowAppearanceMavericksAquaDarkType:
		case TVCMainWindowAppearanceMavericksGraphiteDarkType:
		{
			if (isActive) {
				return @"channelRoomStatusIconMavericksDarkActive";
			} else {
				return @"channelRoomStatusIconMavericksDarkInactive";
			}
		} // Mavericks
		case TVCMainWindowAppearanceYosemiteLightType:
		case TVCMainWindowAppearanceMojaveLightType:
		{
			/* When the window is not in focus, when this item is selected, and when we are not
			 using vibrant dark mode; the outline view does not turn our icon to a light variant
			 like it would do if the window was in focus and used as a template. To workaround
			 this oddity that Apple does, we fudge the icon by using another variant of it. */
			if (isActiveWindow == NO && isSelected) {
				*treatAsTemplate = NO;

				if (isActive) {
					return @"channelRoomStatusIconYosemiteDarkActive";
				} else {
					return @"channelRoomStatusIconYosemiteDarkInactive";
				}
			} // quirk fix

			*treatAsTemplate = YES;

			if (isActive) {
				return @"channelRoomStatusIconYosemiteLightActive";
			} else {
				return @"channelRoomStatusIconYosemiteLightInactive";
			}
		} // Yosemite, Mojave
		case TVCMainWindowAppearanceYosemiteDarkType:
		case TVCMainWindowAppearanceMojaveDarkType:
		{
			*treatAsTemplate = NO;

			if (isActive) {
				return @"channelRoomStatusIconYosemiteDarkActive";
			} else {
				return @"channelRoomStatusIconYosemiteDarkInactive";
			}
		} // Yosemite, Mojave
	} // switch()
}

- (nullable NSString *)statusIconForActiveQuery:(BOOL)isActive selected:(BOOL)isSelected activeWindow:(BOOL)isActiveWindow treatAsTemplate:(BOOL *)treatAsTemplate
{
	NSParameterAssert(treatAsTemplate != NULL);

	TVCMainWindowAppearanceType appearanceType = self.appearanceType;

	switch (appearanceType) {
		case TVCMainWindowAppearanceMavericksAquaLightType:
		case TVCMainWindowAppearanceMavericksAquaDarkType:
		case TVCMainWindowAppearanceMavericksGraphiteLightType:
		case TVCMainWindowAppearanceMavericksGraphiteDarkType:
		{
			if (isSelected) {
				return @"NSUser";
			}

			if (isActive) {
				return @"MavericksDarkServerListViewSelectedPrivateMessageUserActive";
			} else {
				return @"MavericksDarkServerListViewSelectedPrivateMessageUserInactive";
			}
		} // Mavericks
		case TVCMainWindowAppearanceYosemiteLightType:
		case TVCMainWindowAppearanceMojaveLightType:
		{
			*treatAsTemplate = YES;

			if (isActive) {
				return @"VibrantLightServerListViewPrivateMessageUserIconActive";
			} else {
				return @"VibrantLightServerListViewPrivateMessageUserIconInactive";
			}
		} // Yosemite, Mojave
		case TVCMainWindowAppearanceYosemiteDarkType:
		case TVCMainWindowAppearanceMojaveDarkType:
		{
			*treatAsTemplate = NO;

			if (isActive) {
				return @"VibrantDarkServerListViewPrivateMessageUserIconActive";
			} else {
				return @"VibrantDarkServerListViewPrivateMessageUserIconInactive";
			}
		} // Yosemite, Mojave
	} // switch()
}

- (nullable NSColor *)unreadBadgeHighlightBackgroundColorByUser
{
	return [RZUserDefaults() colorForKey:@"Server List Unread Message Count Badge Colors -> Highlight"];
}

@end

#pragma mark -

@implementation TVCServerListMavericksBackgroundBox

- (void)drawRect:(NSRect)dirtyRect
{
	/* The following is specialized drawing for the normal source list
	 background when inside a backed layer view. */
	TVCServerListAppearance *appearance = self.serverList.userInterfaceObjects;

	if (appearance == nil) {
		return;
	}

	NSColor *backgroundColor = nil;

	if (self.mainWindow.isActiveForDrawing) {
		backgroundColor = appearance.backgroundColorActiveWindow;
	} else {
		backgroundColor = appearance.backgroundColorInactiveWindow;
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
