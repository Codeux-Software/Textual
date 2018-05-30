/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
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

#import "TLOLanguagePreferences.h"

NS_ASSUME_NONNULL_BEGIN

NSString *TXTLS(NSString *key, ...)
{
	NSCParameterAssert(key != nil);

	va_list arguments;
	va_start(arguments, key);

	NSString *result = TXLocalizedString(RZMainBundle(), key, arguments);

	va_end(arguments);

	return result;
}

NSString *TXLocalizedString(NSBundle *bundle, NSString *key, va_list args)
{
	NSCParameterAssert(bundle != nil);
	NSCParameterAssert(key != nil);
	NSCParameterAssert(args != NULL);

	NSInteger openBracketPosition = [key stringPosition:@"["];

	if (openBracketPosition > 0) {
		NSString *table = [key substringToIndex:openBracketPosition];

		return [TLOLanguagePreferences localizedStringWithKey:key from:bundle table:table arguments:args];
	} else {
		return [TLOLanguagePreferences localizedStringWithKey:key from:bundle arguments:args];
	}
}

NSString *TXLocalizedStringAlternative(NSBundle *bundle, NSString *key, ...)
{
	NSCParameterAssert(bundle != nil);
	NSCParameterAssert(key != nil);

	va_list arguments;
	va_start(arguments, key);

	NSString *result = TXLocalizedString(bundle, key, arguments);

	va_end(arguments);

	return result;
}

@implementation TLOLanguagePreferences

+ (NSString *)localizedStringWithKey:(NSString *)key
{
	return [self localizedStringWithKey:key from:RZMainBundle() table:@"BasicLanguage" arguments:NULL];
}

+ (NSString *)localizedStringWithKey:(NSString *)key table:(NSString *)table
{
	return [self localizedStringWithKey:key from:RZMainBundle() table:table arguments:NULL];
}

+ (NSString *)localizedStringWithKey:(NSString *)key from:(NSBundle *)bundle
{
	return [self localizedStringWithKey:key from:bundle table:@"BasicLanguage" arguments:NULL];
}

+ (NSString *)localizedStringWithKey:(NSString *)key from:(NSBundle *)bundle arguments:(va_list)arguments
{
	return [self localizedStringWithKey:key from:bundle table:@"BasicLanguage" arguments:arguments];
}

+ (NSString *)localizedStringWithKey:(NSString *)key from:(NSBundle *)bundle table:(NSString *)table
{
	return [self localizedStringWithKey:key from:bundle table:table arguments:NULL];
}

+ (NSString *)localizedStringWithKey:(NSString *)key from:(NSBundle *)bundle table:(NSString *)table arguments:(va_list)arguments
{
	NSParameterAssert(key != nil);
	NSParameterAssert(bundle != nil);
	NSParameterAssert(table != nil);

	NSString *localValue = [bundle localizedStringForKey:key value:@"" table:table];

	if (arguments == NULL) {
		return localValue;
	}

	return [[NSString alloc] initWithFormat:localValue arguments:arguments];
}

@end

NS_ASSUME_NONNULL_END
