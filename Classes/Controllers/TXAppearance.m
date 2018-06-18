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

const TXAppearanceType TXAppearanceNoChangeType = 1000;

@interface TXAppearancePropertyCollection ()
@property (nonatomic, copy, readwrite) NSString *appearanceName;
@property (nonatomic, assign, readwrite) TXAppearanceType appearanceType;
@property (nonatomic, assign, readwrite) BOOL isDarkAppearance;
@property (nonatomic, assign, readwrite) BOOL isModernAppearance;;
@property (nonatomic, assign, readwrite) BOOL appKitAppearanceInherited;
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
#pragma mark Best Appearance

- (TXAppearanceType)recommendedAppearance
{
	TXAppearanceType recommendedAppearance = [self.class recommendedAppearance];

	if (self.properties.appearanceType == recommendedAppearance) {
		return TXAppearanceNoChangeType;
	}

	return recommendedAppearance;
}

+ (TXAppearanceType)recommendedAppearance
{
	BOOL onYosemite = TEXTUAL_RUNNING_ON_YOSEMITE;
	BOOL onMojave = TEXTUAL_RUNNING_ON_MOJAVE;

	BOOL darkMode = NO;

	switch ([TPCPreferences appearance]) {
		case TXPreferredAppearanceInheritedType:
		{
			if (onMojave)
			{
				/* We only inherit from the system on Mojave.
				 On earlier operating systems, user is expected
				 to set an appearance of their own. */
				darkMode = [TXAppearancePropertyCollection systemWideDarkModeEnabled];
			}

			break;
		}
		case TXPreferredAppearanceDarkType:
		{
			darkMode = YES;

			break;
		}
		default:
		{
			break;
		}
	}

	if (onMojave) {
		if (darkMode) {
			return TXAppearanceMojaveDarkType;
		} else {
			return TXAppearanceMojaveLightType;
		}
	} else if (onYosemite) {
		if (darkMode) {
			return TXAppearanceYosemiteDarkType;
		} else {
			return TXAppearanceYosemiteLightType;
		}
	}

	if ([NSColor currentControlTint] == NSGraphiteControlTint) {
		if (darkMode) {
			return TXAppearanceMavericksGraphiteDarkType;
		} else {
			return TXAppearanceMavericksGraphiteLightType;
		}
	} else {
		if (darkMode) {
			return TXAppearanceMavericksAquaDarkType;
		} else {
			return TXAppearanceMavericksAquaLightType;
		}
	}
}

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
#pragma mark Properties

+ (BOOL)isDarkAppearance:(TXAppearanceType)appearanceType
{
	return (appearanceType == TXAppearanceMavericksAquaDarkType ||
			appearanceType == TXAppearanceMavericksGraphiteDarkType ||
			appearanceType == TXAppearanceYosemiteDarkType ||
			appearanceType == TXAppearanceMojaveDarkType);
}

+ (BOOL)isModernAppearance:(TXAppearanceType)appearanceType
{
	return (appearanceType != TXAppearanceMavericksAquaLightType &&
			appearanceType != TXAppearanceMavericksAquaDarkType &&
			appearanceType != TXAppearanceMavericksGraphiteLightType &&
			appearanceType != TXAppearanceMavericksGraphiteDarkType);
}

+ (BOOL)appKitAppearanceInherited:(TXAppearanceType)appearanceType
{
	/* On Mojave and later, we set the appearance on the main window
	 and allow subviews to inherit from that instead of setting them
	 for each individual subview. */
	return (appearanceType == TXAppearanceMojaveLightType ||
			appearanceType == TXAppearanceMojaveDarkType);
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
	TXAppearanceType recommendedAppearance = [self recommendedAppearance];

	BOOL changeAppearance = (recommendedAppearance != TXAppearanceNoChangeType);

	if (changeAppearance == NO)
	{
		/* Even if the desired appearance hasn't changed, we still
		 signal views to perform selection update so that vibrant
		 views can draw correctly when the system changes. */

		if (systemChanged == NO) {
			return;
		}
	}
	else
	{
		/* If a sytem change triggers an appearance change,
		 then treat it as an appearance change. */
		systemChanged = NO;

		/* Change appearance */
		[self changeAppearanceTo:recommendedAppearance];
	}

	/* Notify observers */
	if (systemChanged == NO) {
		[self notifyTextualAppearanceChanged];
	} else {
		[self notifySystemAppearanceChanged];
	}
}

- (void)changeAppearanceTo:(TXAppearanceType)appearanceType
{
	NSParameterAssert(appearanceType != TXAppearanceNoChangeType);

	Class selfClass = self.class; /* Define as variable. We access multiple times. */

	TXAppearancePropertyCollection *properties = [TXAppearancePropertyCollection new];

	properties.appearanceName = [selfClass appearanceNameForType:appearanceType];

	properties.appearanceType = appearanceType;

	properties.isDarkAppearance = [selfClass isDarkAppearance:appearanceType];
	properties.isModernAppearance = [selfClass isModernAppearance:appearanceType];

	properties.appKitAppearanceInherited = [selfClass appKitAppearanceInherited:appearanceType];

	self.properties = properties;
}

- (void)notifyTextualAppearanceChanged
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

- (NSAppearance *)appKitAppearance
{
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
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
TEXTUAL_IGNORE_AVAILABILITY_BEGIN
		return ([[NSApp effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua]] != nil);
TEXTUAL_IGNORE_AVAILABILITY_END
	}

	NSString *objectValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];

	return [objectValue isEqualToStringIgnoringCase:@"dark"];
}

+ (NSAppearance *)appKitDarkAppearance
{
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
TEXTUAL_IGNORE_AVAILABILITY_BEGIN
		return [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
TEXTUAL_IGNORE_AVAILABILITY_END
	} else {
		return [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	}
}

+ (NSAppearance *)appKitLightAppearance
{
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
		return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
	} else {
		return [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}
}

@end

NS_ASSUME_NONNULL_END
