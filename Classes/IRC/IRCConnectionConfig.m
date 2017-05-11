/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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
	SetVariableIfNil(self->_serverAddress, NSStringEmptyPlaceholder)

	self->_proxyPort = IRCConnectionDefaultProxyPort;

	self->_serverPort = IRCConnectionDefaultServerPort;

	self->_floodControlDelayInterval = IRCConnectionConfigFloodControlDefaultDelayInterval;

	self->_floodControlMaximumMessages = IRCConnectionConfigFloodControlDefaultMessageCount;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	IRCConnectionConfig *object = [[IRCConnectionConfig allocWithZone:zone] init];

	object->_connectionPrefersIPv4 = self->_connectionPrefersIPv4;
	object->_connectionPrefersModernCiphers = self->_connectionPrefersModernCiphers;
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

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	IRCConnectionConfigMutable *object = [[IRCConnectionConfigMutable allocWithZone:zone] init];

	((IRCConnectionConfig *)object)->_connectionPrefersIPv4 = self->_connectionPrefersIPv4;
	((IRCConnectionConfig *)object)->_connectionPrefersModernCiphers = self->_connectionPrefersModernCiphers;
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
@dynamic connectionPrefersModernCiphers;
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

- (void)setConnectionPrefersModernCiphers:(BOOL)connectionPrefersModernCiphers
{
	if (self->_connectionPrefersModernCiphers != connectionPrefersModernCiphers) {
		self->_connectionPrefersModernCiphers = connectionPrefersModernCiphers;
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

@end

NS_ASSUME_NONNULL_END
