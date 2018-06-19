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
 *	* Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *	* Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual and/or Codeux Software, nor the names of
 *    its contributors may be used to endorse or promote products derived
 * 	  from this software without specific prior written permission.
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

#import "NSObjectHelperPrivate.h"
#import "TPCPreferencesLocal.h"
#import "TXAppearance.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TXApplicationAppearanceChangedNotification = @"TXApplicationAppearanceChangedNotification";
NSString * const TXSystemAppearanceChangedNotification = @"TXSystemAppearanceChangedNotification";

@interface TXAppearancePropertyCollection ()
@property (nonatomic, copy, readwrite) NSString *appearanceName;
@property (nonatomic, assign, readwrite) TXAppearanceType appearanceType;
@property (nonatomic, assign, readwrite) BOOL isDarkAppearance;
@property (nonatomic, assign, readwrite) BOOL isModernAppearance;
@property (nonatomic, assign, readwrite) TXAppKitAppearanceTarget appKitAppearanceTarget;
@end

@interface TXAppearance ()
@property (nonatomic, strong, readwrite) TXAppearancePropertyCollection *properties;
@end

@implementation TXAppearance

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[self updateAppearance];

	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		return;
	}

	[RZWorkspaceNotificationCenter() addObserver:self
										selector:@selector(accessibilityDisplayOptionsDidChange:)
											name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
										  object:nil];

	if (TEXTUAL_RUNNING_ON_MOJAVE == NO) {
		[RZNotificationCenter() addObserver:self
								   selector:@selector(systemColorsDidChange:)
									   name:NSControlTintDidChangeNotification
									 object:nil];
	} else {
		[NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void)prepareForApplicationTermination
{
	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		return;
	}

	[RZNotificationCenter() removeObserver:self];

	if (TEXTUAL_RUNNING_ON_MOJAVE) {
		[NSApp removeObserver:self forKeyPath:@"effectiveAppearance"];
	}
}

#pragma mark -
#pragma mark Properties

+ (nullable NSString *)appearanceNameForType:(TXAppearanceType)type
{
	switch (type) {
		case TXAppearanceMavericksAquaLightType:
		{
			return @"MavericksLightAqua";
		}
		case TXAppearanceMavericksAquaDarkType:
		{
			return @"MavericksDarkAqua";
		}
		case TXAppearanceMavericksGraphiteLightType:
		{
			return @"MavericksLightGraphite";
		}
		case TXAppearanceMavericksGraphiteDarkType:
		{
			return @"MavericksDarkGraphite";
		}
		case TXAppearanceYosemiteLightType:
		{
			return @"YosemiteLight";
		}
		case TXAppearanceYosemiteDarkType:
		{
			return @"YosemiteDark";
		}
		case TXAppearanceMojaveLightType:
		{
			return @"MojaveLight";
		}
		case TXAppearanceMojaveDarkType:
		{
			return @"MojaveDark";
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Notifications

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
{
	if ([keyPath isEqualToString:@"effectiveAppearance"]) {
		[self applicationAppearanceChanged];
	}
}

- (void)applicationAppearanceChanged
{
	/* Wait until next pass of the run loop to perform
	 update because the effective appearance may not
	 be propegated to all subviews when this is called. */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self updateAppearanceBySystemChange];
	});
}

- (void)systemColorsDidChange:(NSNotification *)aNote
{
	[self updateAppearanceBySystemChange];
}

- (void)accessibilityDisplayOptionsDidChange:(NSNotification *)aNote
{
	[self updateAppearanceBySystemChange];
}

- (void)updateAppearance
{
	[self updateAppearanceBySystemChange:NO];
}

- (void)updateAppearanceBySystemChange
{
	[self updateAppearanceBySystemChange:YES];
}

- (void)updateAppearanceBySystemChange:(BOOL)systemChanged
{
	TXAppearanceType appearanceType;

	BOOL onYosemite = TEXTUAL_RUNNING_ON_YOSEMITE;
	BOOL onMojave = TEXTUAL_RUNNING_ON_MOJAVE;

	BOOL isAppearanceDark = NO;
	BOOL isAppearanceModern = YES; // good default

	TXPreferredAppearanceType preferredAppearance = [TPCPreferences appearance];

	/* Determine user's preference */
	switch (preferredAppearance) {
		case TXPreferredAppearanceInheritedType:
		{
			if (onMojave)
			{
				/* We only inherit from the system on Mojave.
				 On earlier operating systems, user is expected
				 to set an appearance of their own. */
				isAppearanceDark = [TXAppearancePropertyCollection systemWideDarkModeEnabled];
			}

			break;
		}
		case TXPreferredAppearanceDarkType:
		{
			isAppearanceDark = YES;

			break;
		}
		default:
		{
			break;
		}
	}

	/* Determine best appearance and define other properties */
	TXAppKitAppearanceTarget appKitAppearanceTarget = TXAppKitAppearanceTargetNone;

	if (onMojave)
	{
		if (isAppearanceDark) {
			appearanceType = TXAppearanceMojaveDarkType;
		} else {
			appearanceType = TXAppearanceMojaveLightType;
		} // isAppearanceDark

		/* On Mojave, if the user doesn't select a specific appearance,
		 then we don't set an NSAppearance object on anything. */
		/* When the user selects a specific appearance, we set the
		 prefer the NSAppearance object be set on the window because
		 visual effect views have correct inheritance as of Mojave
		 which means they don't need to set the object on individual
		 views, unlike earlier versions of macOS. */
		if (preferredAppearance != TXPreferredAppearanceInheritedType) {
			appKitAppearanceTarget = TXAppKitAppearanceTargetWindow;
		}
	}
	else if (onYosemite)
	{
		if (isAppearanceDark) {
			appearanceType = TXAppearanceYosemiteDarkType;
		} else {
			appearanceType = TXAppearanceYosemiteLightType;
		} // isAppearanceDark

		/* On Yosemite through to High Sierra, we set the NSAppearance
		 object on individual views. We do this for dark and light
		 appearance because we want to set vibrant light. Not aqua. */
		appKitAppearanceTarget = TXAppKitAppearanceTargetView;
	}
	else
	{
		isAppearanceModern = NO;

		if ([NSColor currentControlTint] == NSGraphiteControlTint) {
			if (isAppearanceDark) {
				appearanceType = TXAppearanceMavericksGraphiteDarkType;
			} else {
				appearanceType = TXAppearanceMavericksGraphiteLightType;
			} // isAppearanceDark
		} else {
			if (isAppearanceDark) {
				appearanceType = TXAppearanceMavericksAquaDarkType;
			} else {
				appearanceType = TXAppearanceMavericksAquaLightType;
			} // isAppearanceDark
		} // Graphite

		/* Mavericks doesn't have vibrancy or dark which means there
		 is no need to change the AppKit appearance target for it. */
	} // macOS Version

	/* Test for changes */
	TXAppearancePropertyCollection *oldProperties = self.properties;

	BOOL changeAppearance = (oldProperties == nil ||
							 (oldProperties.appearanceType != appearanceType) ||
							 (oldProperties.appKitAppearanceTarget != appKitAppearanceTarget));

	if (changeAppearance == NO)
	{
		/* Even if the desired appearance hasn't changed, we still
		 signal views to perform selection update so that vibrant
		 views can draw correctly when the system changes. */

		if (systemChanged == NO) {
			return;
		}
	}

	/* Assign new properties */
	TXAppearancePropertyCollection *newProperties = [TXAppearancePropertyCollection new];

	newProperties.appearanceName = [self.class appearanceNameForType:appearanceType];

	newProperties.appearanceType = appearanceType;

	newProperties.isDarkAppearance = isAppearanceDark;
	newProperties.isModernAppearance = isAppearanceModern;

	newProperties.appKitAppearanceTarget = appKitAppearanceTarget;

	self.properties = newProperties;

	/* Notify observers */
	if (systemChanged == NO) {
		[self notifyApplicationAppearanceChanged];
	} else {
		[self notifySystemAppearanceChanged];
	}
}

- (void)notifyApplicationAppearanceChanged
{
	[RZNotificationCenter() postNotificationName:TXApplicationAppearanceChangedNotification object:self];
}

- (void)notifySystemAppearanceChanged
{
	[RZNotificationCenter() postNotificationName:TXSystemAppearanceChangedNotification object:self];
}

@end

#pragma mark -
#pragma mark Property Collection

@implementation TXAppearancePropertyCollection

- (nullable NSAppearance *)appKitAppearance
{
	if (self.appKitAppearanceTarget == TXAppKitAppearanceTargetNone) {
		return nil;
	}

	if (self.isDarkAppearance) {
		return [self.class appKitDarkAppearance];
	} else {
		return [self.class appKitLightAppearance];
	}
}

- (NSString *)shortAppearanceDescription
{
	if (self.isDarkAppearance == NO) {
		return @"light";
	} else {
		return @"dark";
	}
}

+ (BOOL)systemWideDarkModeEnabled
{
#ifdef TXSystemIsOSXMojaveOrLater
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
TEXTUAL_IGNORE_AVAILABILITY_BEGIN
		return ([[NSApp effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua]] != nil);
TEXTUAL_IGNORE_AVAILABILITY_END
	}
#endif

	NSString *objectValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];

	return [objectValue isEqualToStringIgnoringCase:@"dark"];
}

+ (nullable NSAppearance *)appKitDarkAppearance
{
#ifdef TXSystemIsOSXMojaveOrLater
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
TEXTUAL_IGNORE_AVAILABILITY_BEGIN
		return [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
TEXTUAL_IGNORE_AVAILABILITY_END
	} else {
#endif

		return [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];

#ifdef TXSystemIsOSXMojaveOrLater
	}
#endif
}

+ (nullable NSAppearance *)appKitLightAppearance
{
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
		return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
	} else {
		return [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}
}

@end

NS_ASSUME_NONNULL_END
