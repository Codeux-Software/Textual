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

- (id)init
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

- (void)dealloc
{
	if (self.type == IRCChannelPrivateMessageType) {
		[self destroyKeychains];
	}
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
	self.encryptionKeyIsSet = NSObjectIsNotEmpty(pass);

	_encryptionKey = pass;
}

- (void)setSecretKey:(NSString *)pass
{
	self.secretKeyIsSet = NSObjectIsNotEmpty(pass);

	_secretKey = pass;
}

- (NSString *)temporarySecretKey
{
	return _secretKey;
}

- (NSString *)temporaryEncryptionKey
{
	return _encryptionKey;
}

- (void)writeKeychainItemsToDisk
{
	[self writeEncryptionKeyKeychainItemToDisk];
	[self writeSecretKeyKeychainItemToDisk];
}

- (void)writeSecretKeyKeychainItemToDisk
{
	if (self.secretKeyIsSet == NO) {
		[AGKeychain deleteKeychainItem:@"Textual (Channel JOIN Key)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
	} else {
		/* Write secret key. */
		NSObjectIsEmptyAssert(_secretKey);
		
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Channel JOIN Key)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_secretKey
								serviceName:[NSString stringWithFormat:@"textual.cjoinkey.%@", self.itemUUID]];
	
		_secretKey = nil;
	}
}

- (void)writeEncryptionKeyKeychainItemToDisk
{
	if (self.encryptionKeyIsSet == NO) {
		[AGKeychain deleteKeychainItem:@"Textual (Blowfish Encryption)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	} else {
		/* Write encryption key. */
		NSObjectIsEmptyAssert(_encryptionKey);
		
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Blowfish Encryption)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:_encryptionKey
								serviceName:[NSString stringWithFormat:@"textual.cblowfish.%@", self.itemUUID]];
	
		_encryptionKey = nil;
	}
}

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

	self.secretKeyIsSet = NO;
	self.encryptionKeyIsSet = NO;
	
	_secretKey = nil;
	_encryptionKey = nil;
}

#pragma mark -
#pragma mark Channel Configuration

+ (NSDictionary *)seedDictionary:(NSString *)channelName
{
	if ([channelName isChannelName]) {
		return @{
			@"channelName" : channelName,
		};
	}

	return nil;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		/* General preferences. */
		self.type			= (IRCChannelType)NSDictionaryIntegerKeyValueCompare(dic, @"channelType", self.type);

		self.itemUUID			= NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", self.itemUUID);
		self.channelName		= NSDictionaryObjectKeyValueCompare(dic, @"channelName", self.channelName);

		self.autoJoin			= NSDictionaryBOOLKeyValueCompare(dic, @"joinOnConnect", self.autoJoin);
		self.ignoreHighlights	= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreHighlights", self.ignoreHighlights);
		self.ignoreInlineImages	= NSDictionaryBOOLKeyValueCompare(dic, @"disableInlineMedia", self.ignoreInlineImages);
		self.ignoreJPQActivity	= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreJPQActivity", self.ignoreJPQActivity);
		self.pushNotifications	= NSDictionaryBOOLKeyValueCompare(dic, @"enableNotifications", self.pushNotifications);
		self.showTreeBadgeCount = NSDictionaryBOOLKeyValueCompare(dic, @"enableTreeBadgeCountDrawing", self.showTreeBadgeCount);

		self.defaultModes		= NSDictionaryObjectKeyValueCompare(dic, @"defaultMode", self.defaultModes);
		self.defaultTopic		= NSDictionaryObjectKeyValueCompare(dic, @"defaultTopic", self.defaultTopic);

		/* Establish state. */
		self.secretKeyIsSet = NSObjectIsNotEmpty(self.secretKey);
		self.encryptionKeyIsSet = NSObjectIsNotEmpty(self.encryptionKey);

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
			NSObjectsAreEqual(_encryptionKey, [seed temporaryEncryptionKey]) &&
			_encryptionKeyIsSet == [seed encryptionKeyIsSet] &&
			_secretKeyIsSet == [seed secretKeyIsSet]);
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

	[dic safeSetObject:self.itemUUID			forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.channelName			forKey:@"channelName"];

	if (self.type == IRCChannelNormalType) {
		[dic safeSetObject:self.defaultModes		forKey:@"defaultMode"];
		[dic safeSetObject:self.defaultTopic		forKey:@"defaultTopic"];
	}
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	IRCChannelConfig *mut = [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
	
	[mut setSecretKey:_secretKey];
	[mut setEncryptionKey:_encryptionKey];
	
	[mut setSecretKeyIsSet:_secretKeyIsSet];
	[mut setEncryptionKeyIsSet:_encryptionKeyIsSet];
	
	return mut;
}

@end
