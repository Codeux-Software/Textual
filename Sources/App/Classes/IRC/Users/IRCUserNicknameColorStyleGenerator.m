/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

#import <CommonCrypto/CommonDigest.h>

#import "TPCPreferencesUserDefaults.h"
#import "TPCThemeController.h"
#import "TPCThemeSettings.h"
#import "IRCUserNicknameColorStyleGeneratorPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _overridesDefaultsKey		@"Nickname Color Style Overrides"

@implementation IRCUserNicknameColorStyleGenerator

+ (NSString *)nicknameColorStyleForString:(NSString *)inputString
{
	return [self nicknameColorStyleForString:inputString isOverride:NULL];
}

+ (NSString *)nicknameColorStyleForString:(NSString *)inputString isOverride:(BOOL * _Nullable)isOverride
{
	NSParameterAssert(inputString != nil);

	NSString *unshuffledString = inputString.lowercaseString;

	NSColor *styleOverride = [self nicknameColorStyleOverrideForKey:unshuffledString];

	if (styleOverride) {
		if (isOverride) {
			*isOverride = YES;
		}

		return styleOverride.hexadecimalValue;
	} else {
		if (isOverride) {
			*isOverride = NO;
		}
	}

	TPCThemeSettingsNicknameColorStyle colorStyle = themeSettings().nicknameColorStyle;

	NSNumber *stringHash =
	[self hashForString:unshuffledString colorStyle:colorStyle];

	return [self nicknameColorStyleForHash:stringHash colorStyle:colorStyle];
}

+ (NSString *)nicknameColorStyleForHash:(NSNumber *)stringHash colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	NSParameterAssert(stringHash != nil);

	BOOL onLightBackground = (colorStyle == TPCThemeSettingsNicknameColorHashHueLightStyle);

	unsigned int stringHash32 = stringHash.intValue;

	int shash = (stringHash32 >> 1);
	int lhash = (stringHash32 >> 2);

	int h = (stringHash32 % 360);

	int s;
	int l;

	if (onLightBackground)
	{
		s = (shash % 50 + 35);   // 35 - 85
		l = (lhash % 38 + 20);   // 20 - 58

		// Lower lightness for Yello, Green, Cyan
		if (h > 45 && h <= 195) {
			l = (lhash % 21 + 20);   // 20 - 41

			if (l > 31) {
				s = (shash % 40 + 55);   // 55 - 95
			} else {
				s = (shash % 35 + 65);   // 65 - 95
			}
		}

		// Give the reds a bit more saturation
		if (h <= 25 || h >= 335) {
			s = (shash % 33 + 45); // 45 - 78
		}
	}
	else
	{
		s = (shash % 50 + 45);   // 50 - 95
		l = (lhash % 36 + 45);   // 45 - 81

		// give the pinks a wee bit more lightness
		if (h >= 280 && h < 335) {
			l = (lhash % 36 + 50); // 50 - 86
		}

		// Give the blues a smaller (but lighter) range
		if (h >= 210 && h < 240) {
			l = (lhash % 30 + 60); // 60 - 90
		}

		// Tone down very specific range of blue/purple
		if (h >= 240 && h < 280) {
			s = (shash % 55 + 40); // 40 - 95
			l = (lhash % 20 + 65); // 65 - 85
		}

		// Give the reds a bit less saturation
		if (h <= 25 || h >= 335) {
			s = (shash % 33 + 45); // 45 - 78
		}

		// Give the yellows and greens a bit less saturation as well
		if (h >= 50 && h <= 150) {
			s = (shash % 50 + 40); // 40 - 90
		}
	}

	return [NSString stringWithFormat:@"hsl(%i,%i%%,%i%%)", h, s, l];
}

+ (NSString *)preprocessString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	NSParameterAssert(inputString != nil);

	return [NSString stringWithFormat:@"a-%@", inputString];
}

+ (NSNumber *)hashForString:(NSString *)inputString colorStyle:(TPCThemeSettingsNicknameColorStyle)colorStyle
{
	NSParameterAssert(inputString != nil);

	NSString *stringToHash = [self preprocessString:inputString colorStyle:colorStyle];

	NSData *stringToHashData = [stringToHash dataUsingEncoding:NSUTF8StringEncoding];

	NSMutableData *hashedData = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];

	CC_MD5(stringToHashData.bytes, (CC_LONG)stringToHashData.length, hashedData.mutableBytes);

	unsigned int hashedValue;
	[hashedData getBytes:&hashedValue length:sizeof(unsigned int)];

	return @(hashedValue);
}

/*
 *   Color override storage talks in NSColor instead of hexadecimal strings for a few reasons:
 *    1. Easier to work with when modifying. No need to perform messy string conversion.
 *    2. Easier to change output format in another update (if that decision is made)
 */
+ (nullable NSColor *)nicknameColorStyleOverrideForKey:(NSString *)styleKey
{
	NSParameterAssert(styleKey != nil);

	NSDictionary *colorStyleOverrides = [RZUserDefaults() dictionaryForKey:_overridesDefaultsKey];

	if (colorStyleOverrides == nil) {
		return nil;
	}

	id objectValue = colorStyleOverrides[styleKey];

	if (objectValue == nil || [objectValue isKindOfClass:[NSData class]] == NO) {
		return nil;
	}

	id objectValueObj = [NSUnarchiver unarchiveObjectWithData:objectValue];

	if (objectValueObj == nil || [objectValueObj isKindOfClass:[NSColor class]] == NO) {
		return nil;
	}

	return objectValueObj;
}

+ (void)setNicknameColorStyleOverride:(nullable NSColor *)styleValue forKey:(NSString *)styleKey
{
	NSParameterAssert(styleKey != nil);

	NSDictionary *colorStyleOverrides = [RZUserDefaults() dictionaryForKey:_overridesDefaultsKey];

	if (colorStyleOverrides == nil && styleValue == nil) {
		return;
	}

	NSData *styleValueRolled = nil;

	if (styleValue) {
		styleValueRolled = [NSArchiver archivedDataWithRootObject:styleValue];

		if (colorStyleOverrides == nil) {
			colorStyleOverrides = [NSDictionary new];
		}
	}

	NSMutableDictionary *colorStyleOverridesMut = [colorStyleOverrides mutableCopy];

	if (styleValue == nil) {
		[colorStyleOverridesMut removeObjectForKey:styleKey];
	} else {
		colorStyleOverridesMut[styleKey] = styleValueRolled;
	}

	if (colorStyleOverridesMut.count == 0) {
		[RZUserDefaults() removeObjectForKey:_overridesDefaultsKey];
	} else {
		[RZUserDefaults() setObject:[colorStyleOverridesMut copy] forKey:_overridesDefaultsKey];
	}
}

@end

NS_ASSUME_NONNULL_END
