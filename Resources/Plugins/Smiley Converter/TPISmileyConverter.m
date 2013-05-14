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

#import "TPISmileyConverter.h"

@interface TPISmileyConverter ()
@property (nonatomic, weak) NSView *preferencePane;
@property (nonatomic, strong) NSDictionary *conversionTable;
@end

@implementation TPISmileyConverter

#pragma mark -
#pragma mark Plugin API

- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
	/* Load Interface. */
	[NSBundle loadNibNamed:@"TPISmileyConverter" owner:self];

	/* Find conversion table. */
	NSBundle *currBundle = [NSBundle bundleForClass:[self class]];

	/* Find ourselves. */
	NSURL *tablePath = [currBundle URLForResource:@"conversionTable" withExtension:@"plist"];

	/* Load dictionary. */
	NSDictionary *tableData = [NSDictionary dictionaryWithContentsOfURL:tablePath];

	if (NSObjectIsEmpty(tableData)) {
		NSAssert(NO, @"Failed to find conversion table.");
	}

	/* Save dictionary contents. */
	self.conversionTable = tableData;
}

- (NSString *)preferencesMenuItemName
{
	return TPILS(@"SmileyConverterPreferencePaneMenuItemTitle");
}

- (NSView *)preferencesView
{
	return self.preferencePane;
}

- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	/* Return input if we are doing nothing with it. */
	NSAssertReturnR([self convertIncoming], input);

	/* Only handle regular messages. */
	if ([input.command isEqualToString:IRCPrivateCommandIndex("privmsg")] == NO) {
		return input;
	}

	/* How IRCMessage is designed, the actual message of PRIVMSG should be the
	 second index of our input params. Let's hope a future version of Textual
	 does not break that. If it does, then we are screwed here. */
	NSString *message = [input.params safeObjectAtIndex:1];

	/* Convert to attributed string. */
	NSAttributedString *finalResult = [NSAttributedString emptyStringWithBase:message];

	/* Do the actual convert. */
	finalResult = [self convertStringToEmoji:finalResult];

	/* Replace old message. */
	NSMutableArray *newParams = [input.params mutableCopy];

	[newParams removeObjectAtIndex:1];

	/* Insert new message. */
	[newParams insertObject:[finalResult string] atIndex:1];

	input.params = newParams;

	/* Return new message. */
	return input;
}

- (id)interceptUserInput:(id)input command:(NSString *)command
{
	/* Return input if we are doing nothing with it. */
	NSAssertReturnR([self convertOutgoing], input);

	/* Input can only be an NSString or NSAttributedString. If it is an 
	 NSString, then we convert it into an NSAttributedString for the 
	 actual convert from smiley to emoji. */
	NSAttributedString *finalResult;

	BOOL returnAsString = NO;
	
	if ([input isKindOfClass:[NSString class]]) {
		returnAsString = YES;

		finalResult = [NSAttributedString emptyStringWithBase:input];
	} else {
		finalResult = input;
	}

	/* Do the actual convert. */
	finalResult = [self convertStringToEmoji:finalResult];

	/* What return type? */
	if (returnAsString) {
		return [finalResult string];
	} else {
		return finalResult;
	}
}

#pragma mark -
#pragma mark Convert API

- (NSAttributedString *)convertStringToEmoji:(NSAttributedString *)string
{
	NSMutableAttributedString *finalString = [string mutableCopy];

	for (NSString *smiley in self.conversionTable) {
		finalString = [self stringWithReplacedSmiley:smiley inString:finalString];
	}

	return finalString;
}

/* The replacement call uses a lot of work done by the actual Textual renderring engine. */
- (NSMutableAttributedString *)stringWithReplacedSmiley:(NSString *)smiley inString:(NSMutableAttributedString *)body
{
	NSInteger start = 0;

	while (1 == 1) {
		/* The body length is dynamic based on replaces so we have to check 
		 it every time compared to start. */

		if (start >= body.length) {
			break;
		}

		/* Find smiley. */
		NSRange r = [body.string rangeOfString:smiley
									   options:NSCaseInsensitiveSearch // Search is not case sensitive.
										 range:NSMakeRange(start, (body.length - start))];

		/* Anything found? */
		if (r.location == NSNotFound) {
			break;
		}

		BOOL enabled = YES;

		/* Validate the surroundings if it is strict matching. */
		if ([self strictMatching]) {
			if (enabled) {
				NSInteger prev = (r.location - 1);

				if (0 <= prev && prev < body.length) {
					UniChar c = [body.string characterAtIndex:prev];

					/* Only accept a space. */
					if (NSDissimilarObjects(c, ' ')) {
						enabled = NO;
					}
				}
			}

			if (enabled) {
				NSInteger next = NSMaxRange(r);

				if (next < body.length) {
					UniChar c = [body.string characterAtIndex:next];

					/* Only accept a space. */
					if (NSDissimilarObjects(c, ' ')) {
						enabled = NO;
					}
				}
			}
		}

		/* Replace the actual smiley. */
		if (enabled) {
			/* Build the emoji. */
			NSString *theEmoji = [self.conversionTable objectForKey:smiley];

			NSAttributedString *replacement = [NSAttributedString emptyStringWithBase:theEmoji];

			/* Replace the smiley. */
			[body replaceCharactersInRange:r withAttributedString:replacement];

			/* The new start is the location where the smiley began plus the length of the
			 newly added addition. By asking for the actual emoji length, instead of assuming
			 a length of one, we support future expansion if we make the conversion table more
			 complex. */
			start = (r.location + theEmoji.length + 1);
		} else {
			start = (NSMaxRange(r) + 1);
		}
	}

	return body;
}

#pragma mark -
#pragma mark Preferences

- (BOOL)strictMatching
{
	return [RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Use Strict Matching"];
}

- (BOOL)convertIncoming
{
	return [RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Convert Incoming"];
}

- (BOOL)convertOutgoing
{
	return [RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Convert Outgoing"];
}

@end
