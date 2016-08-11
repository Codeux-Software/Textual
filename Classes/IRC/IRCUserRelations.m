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

NS_ASSUME_NONNULL_BEGIN

@interface IRCUserRelations ()
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, IRCChannelUser *> *relationsPrivate;
@end

@implementation IRCUserRelations

- (NSDictionary<NSString *, IRCChannelUser *> *)relations
{
	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			return @{};
		}

		return [self.relationsPrivate copy];
	}
}

- (NSArray<IRCChannelUser *> *)relatedUsers
{
	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			return @[];
		}

		return self.relationsPrivate.allValues;
	}
}

- (NSUInteger)numberOfRelations
{
	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			return 0;
		}

		return self.relationsPrivate.count;
	}
}

- (void)associateUser:(IRCChannelUser *)user withChannel:(IRCChannel *)channel
{
	NSParameterAssert(user != nil);
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self associateUser:user withChannelNamed:channel.name];
}

- (void)associateUser:(IRCChannelUser *)user withChannelNamed:(NSString *)channel
{
	NSParameterAssert(user != nil);
	NSParameterAssert(channel != nil);

	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			self.relationsPrivate = [NSMutableDictionary dictionary];
		}

		self.relationsPrivate[channel] = user;
	}
}

- (void)disassociateUserWithChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return;
	}

	[self disassociateUserWithChannelNamed:channel.name];
}

- (void)disassociateUserWithChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			return;
		}

		[self.relationsPrivate removeObjectForKey:channel];

		if (self.relationsPrivate.count == 0) {
			self.relationsPrivate = nil;
		}
	}
}

- (nullable IRCChannelUser *)userAssociatedWithChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if (channel.isChannel == NO) {
		return nil;
	}

	return [self userAssociatedWithChannelNamed:channel.name];
}

- (nullable IRCChannelUser *)userAssociatedWithChannelNamed:(NSString *)channel
{
	NSParameterAssert(channel != nil);

	@synchronized (self.relationsPrivate) {
		if (self.relationsPrivate == nil) {
			return nil;
		}

		return self.relationsPrivate[channel];
	}
}

@end

NS_ASSUME_NONNULL_END
