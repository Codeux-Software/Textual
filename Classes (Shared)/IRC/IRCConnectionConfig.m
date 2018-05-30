/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "IRCConnectionConfigInternal.h"

NS_ASSUME_NONNULL_BEGIN

uint16_t const IRCConnectionDefaultServerPort = 6667;
uint16_t const IRCConnectionDefaultProxyPort = 1080;

@implementation IRCConnectionConfig

- (instancetype)init
{
	if ((self = [super init])) {
		[self populateDefaultsPostflight];

		return self;
	}

	return nil;
}

- (void)populateDefaultsPostflight
{
	if (self->_serverAddress == nil) {
		self->_serverAddress = @"";
	}

	if (self->_proxyPort == 0) {
		self->_proxyPort = IRCConnectionDefaultProxyPort;
	}

	if (self->_serverPort == 0) {
		self->_serverPort = IRCConnectionDefaultServerPort;
	}

	if (self->_floodControlDelayInterval == 0) {
		self->_floodControlDelayInterval = IRCConnectionConfigFloodControlDefaultDelayInterval;
	}

	if (self->_floodControlMaximumMessages == 0) {
		self->_floodControlMaximumMessages = IRCConnectionConfigFloodControlDefaultMessageCount;
	}
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	if ((self = [super init])) {
		[self decodeWithCoder:aDecoder];

		[self populateDefaultsPostflight];

		return self;
	}

	return nil;
}

- (void)decodeWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	self->_connectionPrefersIPv4 = [aDecoder decodeBoolForKey:@"connectionPrefersIPv4"];
	self->_connectionPrefersModernCiphersOnly = [aDecoder decodeBoolForKey:@"connectionPrefersModernCiphersOnly"];
	self->_connectionPrefersSecuredConnection = [aDecoder decodeBoolForKey:@"connectionPrefersSecuredConnection"];
	self->_connectionShouldValidateCertificateChain = [aDecoder decodeBoolForKey:@"connectionShouldValidateCertificateChain"];
	self->_floodControlDelayInterval = [aDecoder decodeUnsignedIntegerForKey:@"floodControlDelayInterval"];
	self->_floodControlMaximumMessages = [aDecoder decodeUnsignedIntegerForKey:@"floodControlMaximumMessages"];
	self->_identityClientSideCertificate = [aDecoder decodeDataForKey:@"identityClientSideCertificate"];
	self->_proxyAddress = [aDecoder decodeStringForKey:@"proxyAddress"];
	self->_proxyPassword = [aDecoder decodeStringForKey:@"proxyPassword"];
	self->_proxyPort = [aDecoder decodeUnsignedShortForKey:@"proxyPort"];
	self->_proxyType = [aDecoder decodeUnsignedIntegerForKey:@"proxyType"];
	self->_proxyUsername = [aDecoder decodeStringForKey:@"proxyUsername"];
	self->_serverAddress = [aDecoder decodeStringForKey:@"serverAddress"];
	self->_serverPort = [aDecoder decodeUnsignedShortForKey:@"serverPort"];
	self->_primaryEncoding = [aDecoder decodeUnsignedIntegerForKey:@"primaryEncoding"];
	self->_fallbackEncoding = [aDecoder decodeUnsignedIntegerForKey:@"fallbackEncoding"];
	self->_cipherSuites = [aDecoder decodeUnsignedIntegerForKey:@"cipherSuites"];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	NSParameterAssert(aCoder != nil);

	[aCoder encodeBool:self->_connectionPrefersIPv4 forKey:@"connectionPrefersIPv4"];
	[aCoder encodeBool:self->_connectionPrefersModernCiphersOnly forKey:@"connectionPrefersModernCiphersOnly"];
	[aCoder encodeBool:self->_connectionPrefersSecuredConnection forKey:@"connectionPrefersSecuredConnection"];
	[aCoder encodeBool:self->_connectionShouldValidateCertificateChain forKey:@"connectionShouldValidateCertificateChain"];
	[aCoder encodeUnsignedInteger:self->_floodControlDelayInterval forKey:@"floodControlDelayInterval"];
	[aCoder encodeUnsignedInteger:self->_floodControlMaximumMessages forKey:@"floodControlMaximumMessages"];
	[aCoder maybeEncodeObject:self->_identityClientSideCertificate forKey:@"identityClientSideCertificate"];
	[aCoder maybeEncodeObject:self->_proxyAddress forKey:@"proxyAddress"];
	[aCoder maybeEncodeObject:self->_proxyPassword forKey:@"proxyPassword"];
	[aCoder encodeUnsignedShort:self->_proxyPort forKey:@"proxyPort"];
	[aCoder encodeUnsignedInteger:self->_proxyType forKey:@"proxyType"];
	[aCoder maybeEncodeObject:self->_proxyUsername forKey:@"proxyUsername"];
	[aCoder encodeString:self->_serverAddress forKey:@"serverAddress"];
	[aCoder encodeUnsignedShort:self->_serverPort forKey:@"serverPort"];
	[aCoder encodeUnsignedInteger:self->_primaryEncoding forKey:@"primaryEncoding"];
	[aCoder encodeUnsignedInteger:self->_fallbackEncoding forKey:@"fallbackEncoding"];
	[aCoder encodeUnsignedInteger:self->_cipherSuites forKey:@"cipherSuites"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	IRCConnectionConfig *object = [[IRCConnectionConfig allocWithZone:zone] init];

	object->_connectionPrefersIPv4 = self->_connectionPrefersIPv4;
	object->_connectionPrefersModernCiphersOnly = self->_connectionPrefersModernCiphersOnly;
	object->_connectionPrefersSecuredConnection = self->_connectionPrefersSecuredConnection;
	object->_connectionShouldValidateCertificateChain = self->_connectionShouldValidateCertificateChain;
	object->_floodControlDelayInterval = self->_floodControlDelayInterval;
	object->_floodControlMaximumMessages = self->_floodControlMaximumMessages;
	object->_identityClientSideCertificate = self->_identityClientSideCertificate;
	object->_proxyAddress = self->_proxyAddress;
	object->_proxyPassword = self->_proxyPassword;
	object->_proxyPort = self->_proxyPort;
	object->_proxyType = self->_proxyType;
	object->_proxyUsername = self->_proxyUsername;
	object->_serverAddress = self->_serverAddress;
	object->_serverPort = self->_serverPort;
	object->_primaryEncoding = self->_primaryEncoding;
	object->_fallbackEncoding = self->_fallbackEncoding;
	object->_cipherSuites = self->_cipherSuites;

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	IRCConnectionConfigMutable *object = [[IRCConnectionConfigMutable allocWithZone:zone] init];

	((IRCConnectionConfig *)object)->_connectionPrefersIPv4 = self->_connectionPrefersIPv4;
	((IRCConnectionConfig *)object)->_connectionPrefersModernCiphersOnly = self->_connectionPrefersModernCiphersOnly;
	((IRCConnectionConfig *)object)->_connectionPrefersSecuredConnection = self->_connectionPrefersSecuredConnection;
	((IRCConnectionConfig *)object)->_connectionShouldValidateCertificateChain = self->_connectionShouldValidateCertificateChain;
	((IRCConnectionConfig *)object)->_floodControlDelayInterval = self->_floodControlDelayInterval;
	((IRCConnectionConfig *)object)->_floodControlMaximumMessages = self->_floodControlMaximumMessages;
	((IRCConnectionConfig *)object)->_identityClientSideCertificate = self->_identityClientSideCertificate;
	((IRCConnectionConfig *)object)->_proxyAddress = self->_proxyAddress;
	((IRCConnectionConfig *)object)->_proxyPassword = self->_proxyPassword;
	((IRCConnectionConfig *)object)->_proxyPort = self->_proxyPort;
	((IRCConnectionConfig *)object)->_proxyType = self->_proxyType;
	((IRCConnectionConfig *)object)->_proxyUsername = self->_proxyUsername;
	((IRCConnectionConfig *)object)->_serverAddress = self->_serverAddress;
	((IRCConnectionConfig *)object)->_serverPort = self->_serverPort;
	((IRCConnectionConfig *)object)->_primaryEncoding = self->_primaryEncoding;
	((IRCConnectionConfig *)object)->_fallbackEncoding = self->_fallbackEncoding;
	((IRCConnectionConfig *)object)->_cipherSuites = self->_cipherSuites;

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation IRCConnectionConfigMutable

@dynamic connectionPrefersIPv4;
@dynamic connectionPrefersModernCiphersOnly;
@dynamic connectionPrefersSecuredConnection;
@dynamic connectionShouldValidateCertificateChain;
@dynamic floodControlDelayInterval;
@dynamic floodControlMaximumMessages;
@dynamic identityClientSideCertificate;
@dynamic proxyAddress;
@dynamic proxyPassword;
@dynamic proxyPort;
@dynamic proxyType;
@dynamic proxyUsername;
@dynamic serverAddress;
@dynamic serverPort;
@dynamic primaryEncoding;
@dynamic fallbackEncoding;
@dynamic cipherSuites;

- (BOOL)isMutable
{
	return YES;
}

- (void)setConnectionPrefersIPv4:(BOOL)connectionPrefersIPv4
{
	if (self->_connectionPrefersIPv4 != connectionPrefersIPv4) {
		self->_connectionPrefersIPv4 = connectionPrefersIPv4;
	}
}

- (void)setConnectionPrefersModernCiphersOnly:(BOOL)connectionPrefersModernCiphersOnly
{
	if (self->_connectionPrefersModernCiphersOnly != connectionPrefersModernCiphersOnly) {
		self->_connectionPrefersModernCiphersOnly = connectionPrefersModernCiphersOnly;
	}
}

- (void)setConnectionPrefersSecuredConnection:(BOOL)connectionPrefersSecuredConnection
{
	if (self->_connectionPrefersSecuredConnection != connectionPrefersSecuredConnection) {
		self->_connectionPrefersSecuredConnection = connectionPrefersSecuredConnection;
	}
}

- (void)setConnectionShouldValidateCertificateChain:(BOOL)connectionShouldValidateCertificateChain
{
	if (self->_connectionShouldValidateCertificateChain != connectionShouldValidateCertificateChain) {
		self->_connectionShouldValidateCertificateChain = connectionShouldValidateCertificateChain;
	}
}

- (void)setProxyType:(IRCConnectionSocketProxyType)proxyType
{
	if (self->_proxyType != proxyType) {
		self->_proxyType = proxyType;
	}
}

- (void)setIdentityClientSideCertificate:(nullable NSData *)identityClientSideCertificate
{
	if (self->_identityClientSideCertificate != identityClientSideCertificate) {
		self->_identityClientSideCertificate = identityClientSideCertificate.copy;
	}
}

- (void)setProxyAddress:(nullable NSString *)proxyAddress
{
	if (self->_proxyAddress != proxyAddress) {
		self->_proxyAddress = proxyAddress.copy;
	}
}

- (void)setProxyPassword:(nullable NSString *)proxyPassword
{
	if (self->_proxyPassword != proxyPassword) {
		self->_proxyPassword = proxyPassword.copy;
	}
}

- (void)setProxyUsername:(nullable NSString *)proxyUsername
{
	if (self->_proxyUsername != proxyUsername) {
		self->_proxyUsername = proxyUsername.copy;
	}
}

- (void)setServerAddress:(NSString *)serverAddress
{
	NSParameterAssert(serverAddress != nil);

	if (self->_serverAddress != serverAddress) {
		self->_serverAddress = serverAddress.copy;
	}
}

- (void)setFloodControlDelayInterval:(NSUInteger)floodControlDelayInterval
{
	NSParameterAssert(floodControlDelayInterval >= IRCConnectionConfigFloodControlMinimumDelayInterval &&
					  floodControlDelayInterval <= IRCConnectionConfigFloodControlMaximumDelayInterval);

	if (self->_floodControlDelayInterval != floodControlDelayInterval) {
		self->_floodControlDelayInterval = floodControlDelayInterval;
	}
}

- (void)setFloodControlMaximumMessages:(NSUInteger)floodControlMaximumMessages
{
	NSParameterAssert(floodControlMaximumMessages >= IRCConnectionConfigFloodControlMinimumMessageCount &&
					  floodControlMaximumMessages <= IRCConnectionConfigFloodControlMaximumMessageCount);

	if (self->_floodControlMaximumMessages != floodControlMaximumMessages) {
		self->_floodControlMaximumMessages = floodControlMaximumMessages;
	}
}

- (void)setProxyPort:(uint16_t)proxyPort
{
	if (self->_proxyPort != proxyPort) {
		self->_proxyPort = proxyPort;
	}
}

- (void)setServerPort:(uint16_t)serverPort
{
	if (self->_serverPort != serverPort) {
		self->_serverPort = serverPort;
	}
}

- (void)setPrimaryEncoding:(NSStringEncoding)primaryEncoding
{
	if (self->_primaryEncoding != primaryEncoding) {
		self->_primaryEncoding = primaryEncoding;
	}
}

- (void)setFallbackEncoding:(NSStringEncoding)fallbackEncoding
{
	if (self->_fallbackEncoding != fallbackEncoding) {
		self->_fallbackEncoding = fallbackEncoding;
	}
}

- (void)setCipherSuites:(GCDAsyncSocketCipherSuiteVersion)cipherSuites
{
	if (self->_cipherSuites != cipherSuites) {
		self->_cipherSuites = cipherSuites;
	}
}

@end

NS_ASSUME_NONNULL_END
