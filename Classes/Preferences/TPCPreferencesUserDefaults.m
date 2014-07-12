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

#import "BuildConfig.h"

#define _userDefaults			[NSUserDefaults standardUserDefaults]

#define _groupDefaults			[TPCPreferencesUserDefaults sharedGroupContainerUserDefaults]

#pragma mark -
#pragma mark Reading & Writing

@implementation TPCPreferencesUserDefaults

+ (TPCPreferencesUserDefaults *)sharedUserDefaults
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [TPCPreferencesUserDefaults new];
	});
	
	return sharedSelf;
}

+ (NSUserDefaults *)sharedGroupContainerUserDefaults
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [[NSUserDefaults alloc] initWithSuiteName:TXBundleGroupIdentifier];
	});
	
	return sharedSelf;
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
	[RZUserDefaultsValueProxy() setValue:value forKey:defaultName];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setURL:(NSURL *)url forKey:(NSString *)defaultName
{
	[self setObject:url forKey:defaultName];
}

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName
{
	[self setObject:[NSArchiver archivedDataWithRootObject:color] forKey:defaultName];
}

- (id)objectForKey:(NSString *)defaultName
{
	/* Group container will take priority. */
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		 id objectValue = [_groupDefaults objectForKey:defaultName];
		
		if (objectValue) {
			return objectValue;
		}
	}
	
	/* Default back to self. */
	return [super objectForKey:defaultName];
}

- (NSString *)stringForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSArray *)arrayForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSData *)dataForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSColor *)colorForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return [NSUnarchiver unarchiveObjectWithData:objectValue];
}

- (NSInteger)integerForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0;
	}
	
	return [objectValue integerValue];
}

- (float)floatForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0.0f;
	}
	
	return [objectValue floatValue];
}

- (double)doubleForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0.0;
	}
	
	return [objectValue doubleValue];
}

- (BOOL)boolForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return NO;
	}
	
	return [objectValue boolValue];
}

- (NSURL *)URLForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (void)removeObjectForKey:(NSString *)defaultName
{
	[RZUserDefaultsValueProxy() willChangeValueForKey:defaultName];
	
	[super removeObjectForKey:defaultName];
	
	[RZUserDefaultsValueProxy() didChangeValueForKey:defaultName];
}

@end

#pragma mark -
#pragma mark Object KVO Proxying

@implementation TPCPreferencesUserDefaultsObjectProxy

+ (id)values
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [TPCPreferencesUserDefaultsObjectProxy new];
	});
	
	return sharedSelf;
}

- (instancetype)init
{
	if ((self = [super init])) {
		[RZNotificationCenter() addObserver:self
								   selector:@selector(userDefaultsDidChange:)
									   name:NSUserDefaultsDidChangeNotification
									 object:nil];
		
		return self;
	}
	
	return nil;
}

- (void)dealloc
{
	[RZNotificationCenter() removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)userDefaultsDidChange:(NSNotification *)aNotification
{
	/* We do nothing for now. */
}

- (id)valueForKey:(NSString *)key
{
	return [RZUserDefaults() objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		[_groupDefaults setObject:value forKey:key];
	} else {
		[_userDefaults setObject:value forKey:key];
	}
	
	[self didChangeValueForKey:key];
}

@end
