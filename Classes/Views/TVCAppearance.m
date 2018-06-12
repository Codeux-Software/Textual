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

#import "NSObjectHelperPrivate.h"
#import "TVCAppearancePrivate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TVCListAppearanceColorType)
{
	TVCListAppearanceColorCalibratedWhiteType = 1, // <white value> [alpha]
	TVCListAppearanceColorRGBType = 2, // <r> <g> <b> [alpha]
	TVCListAppearanceColorSystemType = 3, // selector
};

typedef NS_ENUM(NSUInteger, TVCListAppearanceImageType)
{
	TVCListAppearanceImageAssetType = 1,
};

@interface TVCAppearance ()
@property (nonatomic, assign, readwrite) BOOL isHighResolutionAppearance;
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, id> *appearanceProperties;
@end

@implementation TVCAppearance

ClassWithDesignatedInitializerInitMethod

- (nullable instancetype)initWithAppearanceNamed:(NSString *)appearanceName atURL:(NSURL *)appearanceLocation forRetinaDisplay:(BOOL)forRetinaDisplay
{
	NSParameterAssert(appearanceName != nil);
	NSParameterAssert(appearanceLocation != nil);

	if ((self = [super init])) {
		if ([self _loadAppearanceNamed:appearanceName atURL:appearanceLocation forRetinaDisplay:forRetinaDisplay] == NO) {
			return nil;
		}

		self.isHighResolutionAppearance = forRetinaDisplay;

		return self;
	}

	return nil;
}

- (BOOL)_loadAppearanceNamed:(NSString *)appearanceName atURL:(NSURL *)appearanceLocation forRetinaDisplay:(BOOL)forRetinaDisplay
{
	NSParameterAssert(appearanceName != nil);
	NSParameterAssert(appearanceLocation != nil);

	/* Load file */
	NSDictionary *appearances = [NSDictionary dictionaryWithContentsOfURL:appearanceLocation];

	if (appearances == nil) {
		return NO;
	}

	/* Find the appearance */
	NSDictionary *appearance = [appearances dictionaryForKey:appearanceName];

	if (appearance == nil) {
		return NO;
	}

	/* Combine any appearances it may inherit from */
	appearance = [self.class _combineAppearance:appearance withOhterApperances:appearances];

	if (appearance == nil) {
		return NO;
	}

	/* Save appearance */
	self.appearanceProperties = appearance;

	return YES;
}

- (void)flushAppearanceProperties
{
	self.appearanceProperties = nil;
}

#pragma mark -
#pragma mark Inheritance

/* TVCListAppearance allows for one appearance to inherit properties
 from another group recursively. */
/* For eample: 	AppearanceDarkRetina ->
 				AppearanceDarkBase ->
 				AppearanceBase */
/* -_combineAppearance:withOhterApperances: is the staging ground for
 this logic. The first argument is the properties for the appearance
 that was specified in -init. The second argument is the contents of
 the file that appearance originated from. */
+ (nullable NSDictionary *)_combineAppearance:(NSDictionary<NSString *, id> *)appearanceIn withOhterApperances:(NSDictionary<NSString *, id> *)otherAppearances
 {
	 NSParameterAssert(appearanceIn != nil);
	 NSParameterAssert(otherAppearances != nil);

	 /* The array of references is the dictionaries that will be combined. */
	 NSMutableArray<NSDictionary<NSString *, id> *> *inheritedProperties = nil;

	 NSDictionary *lastInheritance = appearanceIn;

	 NSString *lastInheritanceName = nil;

	 while ((lastInheritanceName = [lastInheritance stringForKey:@"inheritFrom"])) {
		 lastInheritance = [otherAppearances dictionaryForKey:lastInheritanceName];

		 /* A missing inheritance is considered a hard failure */
		 if (lastInheritance == nil) {
			 return nil;
		 }

		 if (inheritedProperties == nil) {
			 inheritedProperties = [NSMutableArray array];
		 }

		 /* Add the properties to the beginning of the array
		  so that we don't need to use a revers enumerator. */
		 [inheritedProperties insertObject:lastInheritance atIndex:0];
	 }

	 /* If nothing was inherited, return original input. */
	 if (inheritedProperties == nil) {
		 return appearanceIn;
	 }

	 /* Blocks used for combining properties */
	 /* I may over engineered this */
	 typedef void (^mergingLogicType)(NSMutableDictionary *, NSDictionary *);
	 __weak __block mergingLogicType mergingLogicWeak = nil;

	 NSDictionary *(^mergeImmutableDictionary)(NSDictionary *, NSDictionary *) =
	 ^NSDictionary *(NSDictionary *firstDictionary, NSDictionary *secondDictionary)
	 {
		 NSMutableDictionary *mutableFirstDictionary = [firstDictionary mutableCopy];

		 mergingLogicWeak(mutableFirstDictionary, secondDictionary);

		 return [mutableFirstDictionary copy];
	 }; // mergeImmutableDictionary

	 mergingLogicType mergingLogic =
	 ^(NSMutableDictionary *localDictionary, NSDictionary *remoteDictionary)
	 {
		 [remoteDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id remoteObject, BOOL *stop) {
			 id localObject = localDictionary[key];

			 if (localObject == nil) {
				 [localDictionary setObject:remoteObject forKey:key];

				 return;
			 }

			 /* I tried to be clever by checking checking if localObject
			  is kind of class NSMutableDictionary so we can call this
			  block recursively on it instead of creating new mutable copy.
			  Yeah, I will never make that mistake. Cluster classes take a
			  crap on -isKindOfClass: */
			 if ([remoteObject isKindOfClass:[NSDictionary class]] &&
				 [localObject isKindOfClass:[NSDictionary class]])
			 {
				 localObject = mergeImmutableDictionary(localObject, remoteObject);
			 } else {
				 localObject = remoteObject;
			 }

			 [localDictionary setObject:localObject forKey:key];
		 }];
	 }; // mergingLogic

	 mergingLogicWeak = mergingLogic;

	 /* Combine properties */
	 NSMutableDictionary *appearanceOut = [NSMutableDictionary dictionary];

	 for (NSDictionary *properties in inheritedProperties) {
		 mergingLogic(appearanceOut, properties);
	 }

	 /* Add top most appearance as final combination. */
	 mergingLogic(appearanceOut, appearanceIn);

	 [appearanceOut removeObjectForKey:@"inheritFrom"];

	 return [appearanceOut copy];
 }

#pragma mark -
#pragma mark Utilities

- (nullable id)_valueForKey:(NSString *)key expectedType:(Class)expectedType
{
	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self _valueInGroup:group withKey:key expectedType:expectedType];
}

- (nullable id)_valueInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key expectedType:(Class)expectedType
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	id referenceObject = nil;

	if (self.isHighResolutionAppearance == NO) {
		referenceObject = group[key];
	} else {
		NSString *retinaKey = [key stringByAppendingString:@"@2x"];

		referenceObject = ((group[retinaKey]) ?: group[key]);
	}

	if (referenceObject == nil || [referenceObject isKindOfClass:expectedType] == NO) {
		return nil;
	}

	return referenceObject;
}

#pragma mark -
#pragma mark Color

- (nullable NSColor *)colorForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self colorInGroup:group withKey:key];
}

- (nullable NSColor *)colorInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *colorProperties = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (colorProperties == nil) {
		return nil;
	}

	return [self _colorWithProperties:colorProperties];
}

- (nullable NSColor *)colorForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self colorInGroup:group withKey:key forActiveWindow:forActiveWindow];
}

- (nullable NSColor *)colorInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (referenceObject == nil) {
		return nil;
	}

	NSString *colorKey = ((forActiveWindow) ? @"activeWindow" : @"inactiveWindow");

	NSDictionary *colorProperties = [referenceObject dictionaryForKey:colorKey];

	if (colorProperties == nil) {
		return nil;
	}

	return [self _colorWithProperties:colorProperties];
}

- (nullable NSColor *)_colorWithProperties:(NSDictionary<NSString *, id> *)colorProperties
{
	NSParameterAssert(colorProperties != nil);

	NSString *colorValue = [colorProperties stringForKey:@"value"];

	if (colorValue == nil) {
		return nil;
	}

	TVCListAppearanceColorType colorType = [colorProperties unsignedIntegerForKey:@"type"];

	switch (colorType) {
		case TVCListAppearanceColorCalibratedWhiteType:
		{
			NSArray *components = [colorValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if (components.count == 0) {
				return nil;
			}

			CGFloat white = [components doubleAtIndex:0];

			CGFloat alpha = 1.0;

			if (components.count == 2) {
				alpha = [components doubleAtIndex:1];
			}

			return [NSColor colorWithCalibratedWhite:white alpha:alpha];
		}
		case TVCListAppearanceColorRGBType:
		{
			NSArray *components = [colorValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			if (components.count < 3) {
				return nil;
			}

			CGFloat red = [components doubleAtIndex:0];
			CGFloat green = [components doubleAtIndex:1];
			CGFloat blue = [components doubleAtIndex:2];

			CGFloat alpha = 1.0;

			if (components.count == 4) {
				alpha = [components doubleAtIndex:3];
			}

			return [NSColor calibratedColorWithRed:red green:green blue:blue alpha:alpha];
		}
		case TVCListAppearanceColorSystemType:
		{
			SEL selector = NSSelectorFromString(colorValue);

			if ([NSColor respondsToSelector:selector] == NO) {
				LogToConsoleError("Missing color: %@", colorValue);

				return nil;
			}

			return [NSColor performSelector:selector];
		}
	} // switch()

	return nil;
}

#pragma mark -
#pragma mark Gradient

- (nullable NSGradient *)gradientForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self gradientInGroup:group withKey:key];
}

- (nullable NSGradient *)gradientInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSArray *gradientColors = [self _valueInGroup:group withKey:key expectedType:[NSArray class]];

	if (gradientColors == nil) {
		return nil;
	}

	return [self _gradientWithColors:gradientColors];
}

- (nullable NSGradient *)gradientForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self gradientInGroup:group withKey:key forActiveWindow:forActiveWindow];
}

- (nullable NSGradient *)gradientInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (referenceObject == nil) {
		return nil;
	}

	NSString *gradientKey = ((forActiveWindow) ? @"activeWindow" : @"inactiveWindow");

	NSArray *gradientColors = [referenceObject arrayForKey:gradientKey];

	if (gradientColors == nil) {
		return nil;
	}

	return [self _gradientWithColors:gradientColors];
}

- (nullable NSGradient *)_gradientWithColors:(NSArray<NSDictionary<NSString *, id> *> *)gradientColorsIn
{
	NSParameterAssert(gradientColorsIn != nil);

	NSMutableArray<NSColor *> *gradientColorsOut = nil;

	for (NSDictionary<NSString *, id> *color in gradientColorsIn) {
		NSColor *colorObject = [self _colorWithProperties:color];

		if (colorObject == nil) {
			continue;
		}

		if (gradientColorsOut == nil) {
			gradientColorsOut = [NSMutableArray array];
		}

		[gradientColorsOut addObject:colorObject];
	}

	if (gradientColorsOut == nil || gradientColorsOut.count < 2) {
		return nil;
	}

	return [[NSGradient alloc] initWithColors:gradientColorsOut];
}

#pragma mark -
#pragma mark Font

- (nullable NSFont *)fontForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self fontInGroup:group withKey:key];
}

- (nullable NSFont *)fontInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *fontProperties = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (fontProperties == nil) {
		return nil;
	}

	return [self _fontWithProperties:fontProperties];
}

- (nullable NSFont *)fontForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self fontInGroup:group withKey:key forActiveWindow:forActiveWindow];
}

- (nullable NSFont *)fontInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (referenceObject == nil) {
		return nil;
	}

	NSString *fontKey = ((forActiveWindow) ? @"activeWindow" : @"inactiveWindow");

	NSDictionary *fontProperties = [referenceObject dictionaryForKey:fontKey];

	if (fontProperties == nil) {
		return nil;
	}

	return [self _fontWithProperties:fontProperties];
}

- (nullable NSFont *)_fontWithProperties:(NSDictionary<NSString *, id> *)fontProperties
{
	NSParameterAssert(fontProperties != nil);

	NSString *name = [fontProperties stringForKey:@"name"];

	CGFloat size = [fontProperties doubleForKey:@"size"];

	/* Minimum font size is 5 points */
	if (name == nil || size < 5.0) {
		return nil;
	}

	BOOL onElCapitan = TEXTUAL_RUNNING_ON_ELCAPITAN;

	CGFloat weight = [fontProperties doubleForKey:@"weight"];

	if ([name isEqualToString:@"System"])
	{
		CGFloat systemWeight = ((onElCapitan) ? weight : NSFontWeightRegular);

		if (weight == NSFontWeightRegular) {
			return [NSFont systemFontOfSize:size];
		} else {
			return [NSFont systemFontOfSize:size weight:systemWeight];
		}
	}
	else if ([name isEqualToString:@"SystemBold"])
	{
		return [NSFont boldSystemFontOfSize:size];
	}
	else if ([name isEqualToString:@"SystemMonospace"])
	{
		CGFloat systemWeight = ((onElCapitan) ? weight : NSFontWeightRegular);

		if (onElCapitan) {
			return [NSFont monospacedDigitSystemFontOfSize:size weight:systemWeight];
		} else {
			return [NSFont systemFontOfSize:size];
		}
	}
	else if ([name isEqualToString:@"SystemMonospaceBold"])
	{
		if (onElCapitan) {
			return [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightBold];
		} else {
			return [NSFont boldSystemFontOfSize:size];
		}
	}

	if (weight > 0) {
		return [[NSFontManager sharedFontManager] fontWithFamily:name traits:0 weight:weight size:size];
	} else {
		return [NSFont fontWithName:name size:size];
	}
}

#pragma mark -
#pragma mark Image

- (nullable NSImage *)imageForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self imageInGroup:group withKey:key];
}

- (nullable NSImage *)imageInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *imageProperties = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (imageProperties == nil) {
		return nil;
	}

	return [self _imageWithProperties:imageProperties];
}

- (nullable NSImage *)imageForKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return nil;
	}

	return [self imageInGroup:group withKey:key forActiveWindow:forActiveWindow];
}

- (nullable NSImage *)imageInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key forActiveWindow:(BOOL)forActiveWindow
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSDictionary *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (referenceObject == nil) {
		return nil;
	}

	NSString *imageKey = ((forActiveWindow) ? @"activeWindow" : @"inactiveWindow");

	NSDictionary *imageProperties = [referenceObject dictionaryForKey:imageKey];

	if (imageProperties == nil) {
		return nil;
	}

	return [self _imageWithProperties:imageProperties];
}

- (nullable NSImage *)_imageWithProperties:(NSDictionary<NSString *, id> *)imageProperties
{
	NSParameterAssert(imageProperties != nil);

	id imageValue = [imageProperties stringForKey:@"value"];

	if (imageValue == nil) {
		return nil;
	}

	TVCListAppearanceImageType imageType = [imageProperties unsignedIntegerForKey:@"type"];

	switch (imageType) {
		case TVCListAppearanceImageAssetType:
		{
			return [NSImage imageNamed:imageValue];
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Size

- (NSSize)sizeForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return NSZeroSize;
	}

	return [self sizeInGroup:group withKey:key];
}

- (NSSize)sizeInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSDictionary *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSDictionary class]];

	if (referenceObject == nil) {
		return NSZeroSize;
	}

	CGFloat width = [referenceObject doubleForKey:@"width"];
	CGFloat height = [referenceObject doubleForKey:@"height"];

	return NSMakeSize(width, height);
}

#pragma mark -
#pragma mark Measurement

- (CGFloat)measurementForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSDictionary *group = self.appearanceProperties;

	if (group == nil) {
		return 0;
	}

	return [self measurementInGroup:group withKey:key];
}

- (CGFloat)measurementInGroup:(NSDictionary<NSString *, id> *)group withKey:(NSString *)key
{
	NSParameterAssert(group != nil);
	NSParameterAssert(key != nil);

	NSNumber *referenceObject = [self _valueInGroup:group withKey:key expectedType:[NSNumber class]];

	if (referenceObject == nil) {
		return 0;
	}

	return referenceObject.doubleValue;
}

@end

NS_ASSUME_NONNULL_END
