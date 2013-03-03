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

@implementation IRCSendingMessage

+ (NSInteger)colonIndexForCommand:(NSString *)command
{
	/* The command index that Textual uses is complex for anyone who 
	 has never seen it before, but on the other hand, it is also very
	 convenient for storing static information about any IRC command
	 that Textual may handle. For example, the internal command list
	 keeps track of where the colon (:) should be placed for specific
	 outgoing commands. Better than guessing. */
	
	NSArray *searchPath = [TPCPreferences IRCCommandIndex:NO];

	for (NSArray *indexInfo in searchPath) {
		if (indexInfo.count == 5) {
			NSString *matValue = indexInfo[1];

			if ([matValue isEqualIgnoringCase:command] && [indexInfo boolAtIndex:3] == YES) {
				return [indexInfo integerAtIndex:4];
			}
		}
 	}
	
	return -1;
}

+ (NSString *)stringWithCommand:(NSString *)command arguments:(NSArray *)argList
{
	NSMutableString *builtString = [NSMutableString string];

	[builtString appendString:command.uppercaseString];

	NSObjectIsEmptyAssertReturn(argList, builtString);

	NSInteger colonIndexBase = [IRCSendingMessage colonIndexForCommand:command];
	NSInteger colonIndexCount = 0;

	for (NSString *param in argList) {
		NSObjectIsEmptyAssertLoopContinue(param);
		
		[builtString appendString:NSStringWhitespacePlaceholder];

		if (colonIndexBase == -1) {
			// Guess where the colon (:) should go.
			//
			// A colon is supposed to represent a section of an outgoing command
			// that has a paramater which contains spaces. For example, PRIVMSG
			// is in the formoat "PRIVMSG #channel :long message" — The message
			// will have spaces part of it, so we inform the server.
			
			if (colonIndexCount == (argList.count - 1) && ([param hasPrefix:@":"] || [param contains:NSStringWhitespacePlaceholder])) {
				[builtString appendString:@":"];
			}
		} else {
			// We know where it goes thanks to the command index.
			
			if (colonIndexCount == colonIndexBase) {
				[builtString appendString:@":"];
			}
		}

		[builtString appendString:param];

		colonIndexCount += 1;
	}

	return builtString;
}

@end
