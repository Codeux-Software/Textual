/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@implementation IRCChannelConfig

@synthesize secretKey = _secretKey;
@synthesize encryptionKey = _encryptionKey;

- (instancetype)init
{
	if ((self = [super init])) {
		self.itemUUID = [NSString stringWithUUID];

		self.type = IRCChannelNormalType;
		
		self.autoJoin			= YES;
        self.ignoreHighlights	= NO;
        self.ignoreInlineImages	= NO;
        self.ignoreJPQActivity	= NO;
		self.pushNotifications	= YES;
		self.showTreeBadgeCount = YES;

		self.defaultModes	= NSStringEmptyPlaceholder;
		self.defaultTopic	= NSStringEmptyPlaceholder;
		self.channelName	= NSStringEmptyPlaceholder;
	}
    
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)encryptionKey
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Blowfish Encryption)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];

	return kcPassword;
}

- (NSString *)secretKey
{
	NSString *kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Channel JOIN Key)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];

	return kcPassword;
}

- (void)setEncryptionKey:(NSString *)pass
{
	_encryptionKey = [pass copy];
}

- (void)setSecretKey:(NSString *)pass
{
	_secretKey = [pass copy];
}

- (NSString *)temporarySecretKey
{
	return _secretKey;
}

- (NSString *)temporaryEncryptionKey
{
	return _encryptionKey;
}

- (NSString *)secretKeyValue
{
	if (_secretKey) {
		return _secretKey;
	} else {
		return [self secretKey];
	}
}

- (NSString *)encryptionKeyValue
{
	if (_encryptionKey) {
		return _encryptionKey;
	} else {
		return [self encryptionKey];
	}
}

- (void)writeKeychainItemsToDisk
{
	[self writeEncryptionKeyKeychainItemToDisk];
	[self writeSecretKeyKeychainItemToDisk];
}

- (void)writeSecretKeyKeychainItemToDisk
{
	if (_secretKey == nil){
		[AGKeychain deleteKeychainItem:@"Textual (Channel JOIN Key)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Channel JOIN Key)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_secretKey
								serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
	}
	
	_secretKey = nil;
}

- (void)writeEncryptionKeyKeychainItemToDisk
{
	if (_encryptionKey == nil) {
		[AGKeychain deleteKeychainItem:@"Textual (Blowfish Encryption)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Blowfish Encryption)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_encryptionKey
								serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	}

	_encryptionKey = nil;
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)migrateKeychainItemsToCloud
{
	[AGKeychain migrateKeychainItemToCloud:@"Textual (Blowfish Encryption)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	
	[AGKeychain migrateKeychainItemToCloud:@"Textual (Channel JOIN Key)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
}

- (void)migrateKeychainItemsFromCloud
{
	[AGKeychain migrateKeychainItemFromCloud:@"Textual (Blowfish Encryption)"
								withItemKind:@"application password"
								 forUsername:nil
								 serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	
	[AGKeychain migrateKeychainItemFromCloud:@"Textual (Channel JOIN Key)"
								withItemKind:@"application password"
								 forUsername:nil
								 serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
}

- (void)destroyKeychainsThatExistOnCloud
{
	[AGKeychain deleteKeychainItem:@"Textual (Blowfish Encryption)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]
						 fromCloud:YES];
	
	[AGKeychain deleteKeychainItem:@"Textual (Channel JOIN Key)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]
						 fromCloud:YES];
}
#endif

- (void)destroyKeychains
{
	[AGKeychain deleteKeychainItem:@"Textual (Blowfish Encryption)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	
	[AGKeychain deleteKeychainItem:@"Textual (Channel JOIN Key)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];

	[self resetKeychainStatus];
}

- (void)resetKeychainStatus
{
	/* Reset temporary store. */
	_secretKey = nil;
	_encryptionKey = nil;
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
		/* If any key does not exist, then its value is inherited from the -init method. */
		
		/* General preferences. */
		[dic assignIntegerTo:&_type forKey:@"channelType"];
		
		[dic assignStringTo:&_itemUUID forKey:@"uniqueIdentifier"];
		[dic assignStringTo:&_channelName forKey:@"channelName"];

		[dic assignBoolTo:&_autoJoin forKey:@"joinOnConnect"];
		[dic assignBoolTo:&_ignoreHighlights forKey:@"ignoreHighlights"];
		[dic assignBoolTo:&_ignoreInlineImages forKey:@"disableInlineMedia"];
		[dic assignBoolTo:&_ignoreJPQActivity forKey:@"ignoreJPQActivity"];
		[dic assignBoolTo:&_pushNotifications forKey:@"enableNotifications"];
		[dic assignBoolTo:&_showTreeBadgeCount forKey:@"enableTreeBadgeCountDrawing"];

		[dic assignStringTo:&_defaultModes forKey:@"defaultMode"];
		[dic assignStringTo:&_defaultTopic forKey:@"defaultTopic"];
		
		[dic assignIntegerTo:&_encryptionAlgorithm forKey:@"encryptionAlgorithm"];
		
		return self;
	}
	
	return nil;
}

- (BOOL)isEqualToChannelConfiguration:(IRCChannelConfig *)seed
{
	PointerIsEmptyAssertReturn(seed, NO);
	
	NSDictionary *s1 = [seed dictionaryValue];
	
	NSDictionary *s2 = [self dictionaryValue];
	
	/* Only declare ourselves as equal when we do not have any 
	 temporary keychain items stored in memory. */
	return (NSObjectsAreEqual(s1, s2) &&
			NSObjectsAreEqual(_secretKey, [seed temporarySecretKey]) &&
			NSObjectsAreEqual(_encryptionKey, [seed temporaryEncryptionKey]));
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.type forKey:@"channelType"];

	if (self.type == IRCChannelNormalType) {
		[dic setBool:self.autoJoin				forKey:@"joinOnConnect"];
		[dic setBool:self.pushNotifications		forKey:@"enableNotifications"];
		[dic setBool:self.ignoreHighlights		forKey:@"ignoreHighlights"];
		[dic setBool:self.ignoreInlineImages	forKey:@"disableInlineMedia"];
		[dic setBool:self.ignoreJPQActivity		forKey:@"ignoreJPQActivity"];
		[dic setBool:self.showTreeBadgeCount	forKey:@"enableTreeBadgeCountDrawing"];
	}

	[dic setInteger:self.encryptionAlgorithm	forKey:@"encryptionAlgorithm"];
	
	[dic maybeSetObject:self.itemUUID			forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.channelName		forKey:@"channelName"];

	if (self.type == IRCChannelNormalType) {
		[dic maybeSetObject:self.defaultModes		forKey:@"defaultMode"];
		[dic maybeSetObject:self.defaultTopic		forKey:@"defaultTopic"];
	}
	
	return dic;
}

- (id)copyWithZone:(NSZone *)zone
{
	IRCChannelConfig *mut = [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
	
	[mut setSecretKey:_secretKey];
	[mut setEncryptionKey:_encryptionKey];
	
	return mut;
}

@end
