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

#import "IRCHighlightLogEntryInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation IRCHighlightLogEntry

- (NSString *)timeLoggedFormatted
{
	NSTimeInterval timeInterval = self.timeLogged.timeIntervalSinceNow;

	NSString *formattedTimeInterval = TXHumanReadableTimeInterval(timeInterval, YES, 0);

	return TXTLS(@"BasicLanguage[1025]", formattedTimeInterval);
}

- (nullable IRCChannel *)channel
{
	IRCChannel *channel = [worldController() findChannelByClientId:self.clientId channelId:self.channelId];

	return channel;
}

- (NSString *)channelName
{
	IRCChannel *channel = self.channel;

	if (channel) {
		return channel.name;
	}

	return TXTLS(@"BasicLanguage[1002]");
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	IRCHighlightLogEntry *object = [[IRCHighlightLogEntry allocWithZone:zone] init];

	object->_renderedMessage = [self.renderedMessage copyWithZone:zone];
	object->_timeLogged = [self.timeLogged copyWithZone:zone];
	object->_clientId = [self.clientId copyWithZone:zone];
	object->_channelId = [self.channelId copyWithZone:zone];
	object->_lineNumber = [self.lineNumber copyWithZone:zone];

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	IRCHighlightLogEntryMutable *object = [[IRCHighlightLogEntryMutable allocWithZone:zone] init];

	object.renderedMessage = self.renderedMessage;
	object.timeLogged = self.timeLogged;
	object.clientId = self.clientId;
	object.channelId = self.channelId;
	object.lineNumber = self.lineNumber;

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation IRCHighlightLogEntryMutable

@dynamic renderedMessage;
@dynamic timeLogged;
@dynamic clientId;
@dynamic channelId;
@dynamic lineNumber;

- (BOOL)isMutable
{
	return YES;
}

- (void)setRenderedMessage:(NSAttributedString *)renderedMessage
{
	if (self->_renderedMessage != renderedMessage) {
		self->_renderedMessage = renderedMessage.copy;
	}
}

- (void)setClientId:(NSString *)clientId
{
	if (self->_clientId != clientId) {
		self->_clientId = clientId.copy;
	}
}

- (void)setChannelId:(NSString *)channelId
{
	if (self->_channelId != channelId) {
		self->_channelId = channelId.copy;
	}
}

- (void)setLineNumber:(NSString *)lineNumber
{
	if (self->_lineNumber != lineNumber) {
		self->_lineNumber = lineNumber.copy;
	}
}

- (void)setTimeLogged:(NSDate *)timeLogged
{
	if (self->_timeLogged != timeLogged) {
		self->_timeLogged = timeLogged.copy;
	}
}

@end

NS_ASSUME_NONNULL_END
