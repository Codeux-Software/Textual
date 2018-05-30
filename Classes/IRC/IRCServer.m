/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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
#import "IRC.h"
#import "IRCConnectionConfig.h"
#import "IRCServerInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation IRCServer

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	return [self initWithDictionary:@{}];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self populateDefaultsPreflight];

		[self populateDictionaryValues:dic];

		[self populateDefaultsPostflight];

		/* Health checks are disabled because Server Properties might
		 write an empty server address to the class then perform a
		 copy on the object which would throw an exception. */
		/* TODO: Modify Server Properties to be more friendly. */
//		[self initializedClassHealthCheck];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)initializedClassHealthCheck
{
	ObjectIsAlreadyInitializedAssert

	if ([self isMutable]) {
		return;
	}

	NSParameterAssert(self->_serverAddress.length > 0);
	NSParameterAssert(self->_serverPort > 0 && self->_serverPort <= TXMaximumTCPPort);
}

- (void)populateDefaultsPreflight
{
	ObjectIsAlreadyInitializedAssert

	self->_defaults = @{
		@"serverPort" : @(IRCConnectionDefaultServerPort)
	};
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNil(self->_serverAddress, @"")

	SetVariableIfNil(self->_uniqueIdentifier, [NSString stringWithUUID])
}

- (void)populateDictionaryValues:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	if ([self isMutable] == NO) {
		ObjectIsAlreadyInitializedAssert
	}

	NSMutableDictionary<NSString *, id> *defaultsMutable = [self->_defaults mutableCopy];

	[defaultsMutable addEntriesFromDictionary:dic];

	[defaultsMutable assignBoolTo:&self->_prefersSecuredConnection forKey:@"prefersSecuredConnection"];

	[defaultsMutable assignStringTo:&self->_serverAddress forKey:@"serverAddress"];
	[defaultsMutable assignStringTo:&self->_uniqueIdentifier forKey:@"uniqueIdentifier"];

	[defaultsMutable assignUnsignedShortTo:&self->_serverPort forKey:@"serverPort"];
}

- (NSDictionary<NSString *, id> *)dictionaryValue
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	[dic setBool:self.prefersSecuredConnection forKey:@"prefersSecuredConnection"];

	[dic maybeSetObject:self.serverAddress forKey:@"serverAddress"];
	[dic maybeSetObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];

	[dic setUnsignedShort:self.serverPort forKey:@"serverPort"];

	return [dic copy];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	  IRCServer *object =
	[[IRCServer allocWithZone:zone] initWithDictionary:self.dictionaryValue];

	object->_serverPassword = self->_serverPassword;

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	  IRCServerMutable *object =
	[[IRCServerMutable allocWithZone:zone] initWithDictionary:self.dictionaryValue];

	((IRCServer *)object)->_serverPassword = self->_serverPassword;

	return object;
}

- (id)uniqueCopy
{
	return [self uniqueCopyAsMutable:NO];
}

- (id)uniqueCopyMutable
{
	return [self uniqueCopyAsMutable:YES];
}

- (id)uniqueCopyAsMutable:(BOOL)asMutable
{
	IRCServer *object = nil;

	if (asMutable == NO) {
		object = [self copy];
	} else {
		object = [self mutableCopy];
	}

	object->_uniqueIdentifier = [NSString stringWithUUID];

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

- (void)dealloc
{
	if (self.destroyKeychainItemsDuringDealloc) {
		[self destroyServerPasswordKeychainItem];
	}
}

#pragma mark -
#pragma mark Keychain Management

- (nullable NSString *)serverPassword
{
	if (self->_serverPassword) {
		return self->_serverPassword;
	}

	return self.serverPasswordFromKeychain;
}

- (nullable NSString *)serverPasswordFromKeychain
{
	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	NSString *kcPassword = [XRKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
													  withItemKind:@"application password"
													   forUsername:nil
													   serviceName:serverPasswordServiceName];

	return kcPassword;
}

- (void)writeItemsToKeychain
{
	TEXTUAL_DEPRECATED_WARNING

	[self writeServerPasswordToKeychain];
}

- (void)writeServerPasswordToKeychain
{
	if (self->_serverPassword == nil) {
		return;
	}

	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	[XRKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
						   withItemKind:@"application password"
							forUsername:nil
						withNewPassword:self->_serverPassword
							serviceName:serverPasswordServiceName];

	self->_serverPassword = nil;
}

- (void)destroyServerPasswordKeychainItem
{
	NSString *serverPasswordServiceName = [NSString stringWithFormat:@"textual.server.%@", self.uniqueIdentifier];

	[XRKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:serverPasswordServiceName];

	self->_serverPassword = nil;
}

- (void)destroyKeychainItems
{
	TEXTUAL_DEPRECATED_WARNING

	[self destroyServerPasswordKeychainItem];
}

@end

#pragma mark -

@implementation IRCServerMutable

@dynamic prefersSecuredConnection;
@dynamic serverAddress;
@dynamic serverPassword;
@dynamic serverPort;

- (BOOL)isMutable
{
	return YES;
}

- (void)setPrefersSecuredConnection:(BOOL)prefersSecuredConnection
{
	if (self->_prefersSecuredConnection != prefersSecuredConnection) {
		self->_prefersSecuredConnection = prefersSecuredConnection;
	}
}

- (void)setServerAddress:(NSString *)serverAddress
{
	NSParameterAssert(serverAddress != nil);

	if (self->_serverAddress != serverAddress) {
		self->_serverAddress = serverAddress;
	}
}

- (void)setServerPassword:(nullable NSString *)serverPassword
{
	if (self->_serverPassword != serverPassword) {
		self->_serverPassword = serverPassword;
	}
}

- (void)setServerPort:(uint16_t)serverPort
{
	if (self->_serverPort != serverPort) {
		self->_serverPort = serverPort;
	}
}

@end

NS_ASSUME_NONNULL_END
