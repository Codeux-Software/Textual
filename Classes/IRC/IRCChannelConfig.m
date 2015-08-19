/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@implementation IRCChannelConfig

@synthesize secretKey = _secretKey;

- (NSDictionary *)defaults
{
	static id _defaults = nil;

	if (_defaults == nil) {
		NSDictionary *defaults = @{
			 @"channelType"						: @(IRCChannelChannelType),

			 @"joinOnConnect"					:	@(YES),

			 @"ignoreGeneralEventMessages"		: @(NO),
			 @"ignoreHighlights"				: @(NO),
			 @"ignoreInlineMedia"				: @(NO),

			 @"enableNotifications"				: @(YES),
			 @"enableTreeBadgeCountDrawing"		: @(YES)
		 };

		_defaults = [defaults copy];
	}

	return _defaults;
}

- (void)populateDefaults
{
	NSDictionary *defaults = [self defaults];

	self.itemUUID						= [NSString stringWithUUID];

	self.type							= [defaults integerForKey:@"channelType"];

	self.autoJoin						= [defaults boolForKey:@"joinOnConnect"];
	self.pushNotifications				= [defaults boolForKey:@"enableNotifications"];
	self.showTreeBadgeCount				= [defaults boolForKey:@"enableTreeBadgeCountDrawing"];

	self.ignoreGeneralEventMessages		= [defaults boolForKey:@"ignoreGeneralEventMessages"];
	self.ignoreHighlights				= [defaults boolForKey:@"ignoreHighlights"];
	self.ignoreInlineImages				= [defaults boolForKey:@"ignoreInlineMedia"];
}

- (instancetype)init
{
	if ((self = [super init])) {
		[self populateDefaults];
	}
    
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)secretKey
{
	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Channel JOIN Key)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];

	return kcPassword;
}

- (void)setSecretKey:(NSString *)pass
{
	_secretKey = [pass copy];
}

- (NSString *)temporarySecretKey
{
	return self.secretKey;
}

- (NSString *)secretKeyValue
{
	if (self.secretKey) {
		return self.secretKey;
	} else {
		return [self secretKey];
	}
}

- (void)writeKeychainItemsToDisk
{
	[self writeSecretKeyKeychainItemToDisk];
}

- (void)writeSecretKeyKeychainItemToDisk
{
	if (_secretKey) {
		[XRKeychain modifyOrAddKeychainItem:@"Textual (Channel JOIN Key)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_secretKey
								serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
	}
	
	_secretKey = nil;
}

- (void)destroyKeychains
{
	[XRKeychain deleteKeychainItem:@"Textual (Channel JOIN Key)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];

	[self resetKeychainStatus];
}

- (void)resetKeychainStatus
{
	/* Reset temporary store. */
	_secretKey = nil;
}

#pragma mark -
#pragma mark Channel Configuration

+ (IRCChannelConfig *)seedWithName:(NSString *)channelName
{
	IRCChannelConfig *seed = [IRCChannelConfig new];
		
	[seed setChannelName:channelName];
		
	return seed;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		[self populateDictionaryValues:dic];
	}

	return self;
}

- (void)populateDictionaryValues:(NSDictionary *)dic
{
	/* Load legacy keys (if they exist) */
	[dic assignBoolTo:&_ignoreInlineImages			forKey:@"disableInlineMedia"];

	[dic assignBoolTo:&_ignoreGeneralEventMessages	forKey:@"ignoreJPQActivity"];

	/* Load the newest set of keys. */
	[dic assignIntegerTo:&_type			forKey:@"channelType"];

	[dic assignStringTo:&_itemUUID		forKey:@"uniqueIdentifier"];
	[dic assignStringTo:&_channelName	forKey:@"channelName"];

	[dic assignBoolTo:&_autoJoin					forKey:@"joinOnConnect"];
	[dic assignBoolTo:&_pushNotifications			forKey:@"enableNotifications"];
	[dic assignBoolTo:&_showTreeBadgeCount			forKey:@"enableTreeBadgeCountDrawing"];

	[dic assignBoolTo:&_ignoreGeneralEventMessages	forKey:@"ignoreGeneralEventMessages"];
	[dic assignBoolTo:&_ignoreHighlights			forKey:@"ignoreHighlights"];
	[dic assignBoolTo:&_ignoreInlineImages			forKey:@"ignoreInlineMedia"];

	[dic assignStringTo:&_defaultModes	forKey:@"defaultMode"];
	[dic assignStringTo:&_defaultTopic	forKey:@"defaultTopic"];
}

- (BOOL)isEqualToChannelConfiguration:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssertReturn(seed, NO);
	
	NSDictionary *s1 = [seed dictionaryValue];
	
	NSDictionary *s2 = [self dictionaryValue];
	
	/* Only declare ourselves as equal when we do not have any 
	 temporary keychain items stored in memory. */
	return (NSObjectsAreEqual(s1, s2) &&
			NSObjectsAreEqual(_secretKey, [seed temporarySecretKey]));
}

- (NSDictionary *)dictionaryValueByStrippingDefaults:(NSMutableDictionary *)dic
{
	NSMutableDictionary *ndic = [NSMutableDictionary dictionary];

	NSDictionary *defaults = [self defaults];

	[dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if (NSObjectsAreEqual(defaults[key], obj) == NO) {
			ndic[key] = obj;
		}
	}];

	return [ndic copy];
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.type forKey:@"channelType"];

	[dic maybeSetObject:self.itemUUID			forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.channelName		forKey:@"channelName"];

	if (self.type == IRCChannelChannelType) {
		[dic setBool:self.autoJoin							forKey:@"joinOnConnect"];
		[dic setBool:self.pushNotifications					forKey:@"enableNotifications"];
		[dic setBool:self.showTreeBadgeCount				forKey:@"enableTreeBadgeCountDrawing"];

		[dic setBool:self.ignoreHighlights					forKey:@"ignoreHighlights"];
		[dic setBool:self.ignoreInlineImages				forKey:@"ignoreInlineMedia"];
		[dic setBool:self.ignoreGeneralEventMessages		forKey:@"ignoreGeneralEventMessages"];

		[dic maybeSetObject:self.defaultModes				forKey:@"defaultMode"];
		[dic maybeSetObject:self.defaultTopic				forKey:@"defaultTopic"];
	}
	
	return [self dictionaryValueByStrippingDefaults:dic];
}

- (id)copyWithZone:(NSZone *)zone
{
	IRCChannelConfig *mut = [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
	
	[mut setSecretKey:_secretKey];
	
	return mut;
}

@end
