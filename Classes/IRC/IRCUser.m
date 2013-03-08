/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

#define _colorNumberMax				 30

@implementation IRCUser

- (id)init
{
	if ((self = [super init])) {
		self.colorNumber = -1;
	}
	
	return self;
}

- (NSString *)hostmask
{
	NSObjectIsEmptyAssertReturn(self.username, nil);
	NSObjectIsEmptyAssertReturn(self.address, nil);
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	
	return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
}

- (NSString *)banMask
{
	NSObjectIsEmptyAssertReturn(self.nickname, nil);
	
	if (NSObjectIsEmpty(self.username) || NSObjectIsEmpty(self.address)) {
		return [NSString stringWithFormat:@"%@!*@*", self.nickname];
	} else {
		switch ([TPCPreferences banFormat]) {
			case TXHostmaskBanWHNINFormat: {
				return [NSString stringWithFormat:@"*!*@%@", self.address];
			} case TXHostmaskBanWHAINNFormat: {
				return [NSString stringWithFormat:@"*!%@@%@", self.username, self.address];
			} case TXHostmaskBanWHANNIFormat: {
				return [NSString stringWithFormat:@"%@!*%@", self.nickname, self.address];
			} case TXHostmaskBanExactFormat: {
				return [NSString stringWithFormat:@"%@!%@@%@", self.nickname, self.username, self.address];
			}
		}
	}
	
	return nil;
}

- (NSString *)mark
{
	if (self.q) {
		return [self.supportInfo userModePrefixSymbol:@"q"];
	} else if (self.a) {
		return [self.supportInfo userModePrefixSymbol:@"a"];
	} else if (self.o) {
		return [self.supportInfo userModePrefixSymbol:@"o"];
	} else if (self.h) {
		return [self.supportInfo userModePrefixSymbol:@"h"];
	} else if (self.v) {
		return [self.supportInfo userModePrefixSymbol:@"v"];
	}
	
	return nil;
}

- (BOOL)isOp
{
	return (self.o || self.a || self.q);
}

- (BOOL)isHalfOp 
{
	return (self.h || self.o || self.a || self.q);
}

- (NSInteger)colorNumber
{
	if (_colorNumber < 0) {
		NSString *hashName = self.nickname.lowercaseString;

		if ([RZUserDefaults() boolForKey:@"UUIDBasedNicknameColorHashing"]) {
			hashName = [NSString stringWithUUID];
		}
		
		self.colorNumber = (hashName.hash % _colorNumberMax);
	}
	
	return _colorNumber;
}

- (BOOL)isEqual:(id)other
{
	NSAssertReturnR([other isKindOfClass:[IRCUser class]], NO);
	
	return [self.nickname isEqualIgnoringCase:[other nickname]];
}

- (NSComparisonResult)compare:(IRCUser *)other
{
	/* Not even going to touch this mess… */

	if (NSDissimilarObjects(self.q, other.q)) {
		return ((self.q) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.q) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else if (NSDissimilarObjects(self.a, other.a)) {
		return ((self.a) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.a) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else if (NSDissimilarObjects(self.o, other.o)) {
		return ((self.o) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.o) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else if (NSDissimilarObjects(self.h, other.h)) {
		return ((self.h) ? NSOrderedAscending : NSOrderedDescending);
	} else if (self.h) {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	} else if (NSDissimilarObjects(self.v, other.v)) {
		return ((self.v) ? NSOrderedAscending : NSOrderedDescending);
	} else {
		return [self.nickname caseInsensitiveCompare:other.nickname];
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<IRCUser %@%@>", self.mark, self.nickname];
}

@end
