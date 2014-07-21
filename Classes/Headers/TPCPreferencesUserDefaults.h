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

/* Invoke RZUserDefaults() for writing directly to either the group container or
 the application container. Depending on the OS in use, it will automatically
 handle all the nasty bits of deciding where to write data. */
#define RZUserDefaults()						[TPCPreferencesUserDefaults sharedUserDefaults]

/* See comments below for proxy. */
#define RZUserDefaultsValueProxy()				[TPCPreferencesUserDefaultsObjectProxy values]

/* Write to the standard user defaults to write directly to the application container.
 Certain state information such as saved frames should be saved there. */
#define RZStandardUserDefualts()				[NSUserDefaults standardUserDefaults]

@interface TPCPreferencesUserDefaults : NSUserDefaults
/* Our reading object will read from our own application container
 and the shared group container defined for Textual. */
+ (TPCPreferencesUserDefaults *)sharedUserDefaults;

/* Declares an object for reading the com.apple.universalaccess suite name. Writing to
 this object will do nothing to the accessbility object itself. Any changes written will
 be written to the application continer which means there is no reason to write to this. */
+ (NSUserDefaults *)accessbilityUserDefaults;

/* This class proxies these methods. */
/* Depending on whether we are on Mavericks or later, these methods
 will either write to our group container or application container. */
- (id)objectForKey:(NSString *)defaultName;

- (NSString *)stringForKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSArray *)stringArrayForKey:(NSString *)defaultName;
- (NSColor *)colorForKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (float)floatForKey:(NSString *)defaultName;
- (double)doubleForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
- (NSURL *)URLForKey:(NSString *)defaultName;

- (void)setObject:(id)value forKey:(NSString *)defaultName;
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setDouble:(double)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
- (void)setURL:(NSURL *)url forKey:(NSString *)defaultName;
- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;

- (void)removeObjectForKey:(NSString *)defaultName;

- (NSDictionary *)dictionaryRepresentation;

- (void)registerDefaultsForApplicationContainer:(NSDictionary *)registrationDictionary;
- (void)registerDefaultsForGroupContainer:(NSDictionary *)registrationDictionary;
@end

@interface TPCPreferencesUserDefaultsObjectProxy : NSObject
/* Similiar to NSUserDefaultsController, -values can be bound to in
 Interface Builder for reading and writing defaults. It will handle
 decision between which shared object to call for us. Do not access
 this value for any other reason than to read and write in a bound
 Interface Builder. It is not a shorthand for retreiving all values. */
+ (id)values;
@end
