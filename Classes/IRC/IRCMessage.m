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

@interface IRCMessageBatchMessageContainer ()
@property (nonatomic, strong) NSMutableDictionary *internalBatchEntries;
@end

@interface IRCMessageBatchMessage ()
@property (nonatomic, strong) NSMutableArray *internalBatchEntries;
@end

@implementation IRCMessage

- (instancetype)initWithLine:(NSString *)line
{
	if ((self = [super init])) {
		[self parseLine:line];
	}
	
	return self;
}

- (void)parseLine:(NSString *)line
{
	[self parseLine:line forClient:nil];
}

- (void)parseLine:(NSString *)line forClient:(IRCClient *)client
{
	/* Establish base pair. */
	self.command = nil;

	self.isHistoric = NO;

	IRCPrefix *sender = [IRCPrefix new];
	
	NSMutableArray *params = [NSMutableArray new];
	
	/* Begin parsing. */
	NSMutableString *s = [line mutableCopy];

	// ---- //

    /* Get extensions from in front of input string. See IRCv3.atheme.org for
     more information regarding extensions in the IRC protocol. */
	if ([s hasPrefix:@"@"]) {
		/* Get leading string up to first space. */
		NSString *extensionInfo = [s getToken];
		
		/* Check for malformed message. */
		if ([extensionInfo length] <= 1) {
			return; // Do not continue as message is malformed.
		}
		
		/* Remove the leading at sign from the string. */
		extensionInfo = [extensionInfo substringFromIndex:1];
		
		/* Chop the tags up using ; as a divider as defined by the syntax
		 located at: <http://ircv3.org/specification/message-tags-3.2> */
		/* An example grouping would look like the following:
				@aaa=bbb;ccc;example.com/ddd=eee */
		/* The specification does not speicfy what is to happen if the value
		 of an extension will contain a semicolon so at this point we will
		 assume that they will not exist and only be there as a divider. */
		NSArray *values = [extensionInfo componentsSeparatedByString:@";"];

		NSMutableDictionary *valueMatrix = [NSMutableDictionary dictionary];
		
		/* We now go through each tag using an equal sign as a divider and
		 placing each into a dictionary. */
		for (NSString *comp in values) {
			NSArray *info = [comp componentsSeparatedByString:@"="];

			NSAssertReturnLoopContinue([info count] == 2);

			NSString *extKey = info[0];
			NSString *extVal = info[1];
			
			valueMatrix[extKey] = extVal;
		}
		
		/* Now that we have values, we can check against our capacities. */
		if ([client isCapacityEnabled:ClientIRCv3SupportedCapacityServerTime]) {
			/* We support two time extensions. The time= value is the date and
			 time in the format as defined by ISO 8601:2004(E) 4.3.2. */
			/* The t= value is a legacy value in a epoch time. We always favor
			 the new time= format over the old. */
			NSString *timeObject = valueMatrix[@"time"];
			
			NSDate *date = nil;
			
			if (timeObject == nil) {
				/* time= does not exist so now we try t= */
				timeObject = valueMatrix[@"t"];
				
				if (timeObject) {
					date = [NSDate dateWithTimeIntervalSince1970:[timeObject doubleValue]];
				}
			} else {
				date = [TXSharedISOStandardDateFormatter() dateFromString:timeObject];
			}
			
			/* If we have a time, we are done. */
			if (date) {
				self.receivedAt = date;
				
				self.isHistoric = YES;
			}
		}

		/* Process batch token if available. */
		if ([client isCapacityEnabled:ClientIRCv3SupportedCapacityBatch]) {
			NSString *batchToken = valueMatrix[@"batch"];

			if (batchToken) {
				if ([batchToken onlyContainsCharacters:CSCEF_LatinAlphabetIncludingUnderscoreDashCharacterSet]) {
					self.batchToken = batchToken;
				}
			}
		}
	}
			
	/* Set a date if there is none already set. */
	if (self.receivedAt == nil) {
		self.receivedAt = [NSDate date];
	}

	// ---- //

    /* Begin the parsing of the actual input string. */
    /* First thing to do is get the sender information from in 
     front of the message. */
	/* Under certain cirumstances, the user may not exist 
	 at all. For example, some IRCds may send a complete input
	 string that looks like "PING :daRYdkOuVL" — as seen, the
	 input string begins with the command and that is it. */
	if ([s hasPrefix:@":"]) {
		/* Get user info section. */
		NSString *userInfo = [s getToken];
		
		/* Check that the input is valid. */
		if ([userInfo length] <= 1) {
			return; // Current input is malformed, do nothing with it.
		}
		
		NSString *t = [userInfo substringFromIndex:1];

		NSString *nicknameInt = nil;
		NSString *usernameInt = nil;
		NSString *addressInt = nil;

		[sender setHostmask:t]; // Declare entire section as host.
		
		[sender setIsServer:NO]; // Do not set as server until host is parsed...
		
		/* Parse the user info into their appropriate sections or return NO if we can't. */
		if ([t hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt]) {
			[sender setNickname:nicknameInt];
			[sender setUsername:usernameInt];
			[sender setAddress:addressInt];
        } else {
			[sender setNickname:t];
			
			[sender setIsServer:YES];
		}
	}
	
	self.sender = sender;

    /* Now that we have the sender information... continue to the
     actual command being used. */
	NSString *foundCommand = [s getToken];
	
	/* Check that the input is valid. */
	if ([foundCommand length] <= 1) {
		return; // Current input is malformed, do nothing with it.
	}
	
	/* Set command and numeric value. */
	self.command = [foundCommand uppercaseString];

	if ([self.command isNumericOnly]) {
		self.commandNumeric = [foundCommand integerValue];
	} else {
		self.commandNumeric = 0;
	}

    /* After the sender information and command information is extracted,
     there is not much left to the parse. Just searching for the beginning
     of a message segment or getting the next token. */
	while ([s length] > 0) {
		if ([s hasPrefix:@":"]) {
			[params addObject:[s substringFromIndex:1]];
			
			break;
		} else {
			[params addObject:[s getToken]];
		}
	}
	
	/* Finish up. */
	self.params = params;
	
	params = nil;
}

- (NSInteger)paramsCount
{
	return [self.params count];
}

- (NSString *)paramAt:(NSInteger)index
{
	if (index < [self paramsCount]) {
		return self.params[index];
	} else {
		return NSStringEmptyPlaceholder;
	}
}

- (NSString *)sequence
{
	if ([self paramsCount] < 2) {
		return [self sequence:0];
	} else {
		return [self sequence:1];
	}
}

- (NSString *)sequence:(NSInteger)index
{
	NSMutableString *s = [NSMutableString string];
	
	for (NSInteger i = index; i < [self paramsCount]; i++) {
		NSString *e = self.params[i];
		
		if (NSDissimilarObjects(i, index)) {
			[s appendString:NSStringWhitespacePlaceholder];
		}
		
		[s appendString:e];
	}
	
	return s;
}

- (NSString *)senderNickname
{
	return self.sender.nickname;
}

- (NSString *)senderUsername
{
	return self.sender.username;
}

- (NSString *)senderAddress
{
	return self.sender.address;
}

- (NSString *)senderHostmask
{
	return self.sender.hostmask;
}

- (BOOL)senderIsServer
{
	return self.sender.isServer;
}

@end

#pragma mark -

@implementation IRCMessageBatchMessageContainer

- (NSDictionary *)queuedEntries
{
	@synchronized(self.internalBatchEntries) {
		return [NSDictionary dictionaryWithDictionary:self.internalBatchEntries];
	}
}

- (void)clearQueue
{
	@synchronized(self.internalBatchEntries) {
		if (self.internalBatchEntries == nil) {
			return;
		}

		[self.internalBatchEntries removeAllObjects];
	}
}

- (void)dequeueEntry:(id)entry
{
	if (entry == nil) {
		return;
	}

	if ([entry isKindOfClass:[IRCMessageBatchMessage class]]) {
		[self dequeueEntryWithBatchToken:[entry batchToken]];
	} else if ([entry isKindOfClass:[NSString class]]) {
		[self dequeueEntryWithBatchToken:entry];
	}
}

- (void)dequeueEntryWithBatchToken:(NSString *)batchToken
{
	if (NSObjectIsEmpty(batchToken)) {
		return;
	}

	@synchronized(self.internalBatchEntries) {
		if (self.internalBatchEntries == nil) {
			return;
		}

		[self.internalBatchEntries removeObjectForKey:batchToken];
	}
}

- (void)queueEntry:(id)entry
{
	if (entry == nil) {
		return;
	}

	if ([entry isKindOfClass:[IRCMessageBatchMessage class]] == NO) {
		return;
	}

	NSString *batchToken = [entry batchToken];

	if (NSObjectIsEmpty(batchToken)) {
		return;
	}

	@synchronized(self.internalBatchEntries) {
		if (self.internalBatchEntries == nil) {
			self.internalBatchEntries = [NSMutableDictionary dictionary];
		}

		[self.internalBatchEntries setObject:entry forKey:batchToken];
	}
}

- (id)queuedEntryWithBatchToken:(NSString *)batchToken
{
	if (NSObjectIsEmpty(batchToken)) {
		return nil;
	}

	@synchronized(self.internalBatchEntries) {
		if (self.internalBatchEntries == nil) {
			return nil;
		}

		return [self.internalBatchEntries objectForKey:batchToken];
	}
}

@end

#pragma mark -

@implementation IRCMessageBatchMessage

- (NSArray *)queuedEntries
{
	@synchronized(self.internalBatchEntries) {
		return [NSArray arrayWithArray:self.internalBatchEntries];
	}
}

- (void)queueEntry:(id)entry
{
	if (entry == nil) {
		return;
	}

	if ([entry isKindOfClass:[IRCMessage class]] == NO &&
		[entry isKindOfClass:[IRCMessageBatchMessage class]] == NO)
	{
		return;
	}

	@synchronized(self.internalBatchEntries) {
		if (self.internalBatchEntries == nil) {
			self.internalBatchEntries = [NSMutableArray array];
		}

		[self.internalBatchEntries addObject:entry];
	}
}

@end
