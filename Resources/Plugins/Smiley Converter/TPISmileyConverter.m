/* *********************************************************************
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#import "TPISmileyConverter.h"

@interface TPISmileyConverter ()
@property (nonatomic, copy) NSDictionary *conversionTable;
@property (nonatomic, copy) NSArray *sortedSmileyList;
@property (nonatomic, strong) IBOutlet NSView *preferencesPane;
@end

@implementation TPISmileyConverter

#pragma mark -
#pragma mark Plugin API

- (void)pluginLoadedIntoMemory
{
	/* Load Interface. */
	[TPIBundleFromClass() loadCustomNibNamed:@"TPISmileyConverter" owner:self topLevelObjects:nil];

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
	self.conversionTable	=  tableData;
	self.sortedSmileyList	= [tableData sortedDictionaryReversedKeys];
}

- (NSView *)pluginPreferencesPaneView
{
	return self.preferencesPane;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizatedString(@"BasicLanguage[1000]");
}

- (NSString *)willRenderMessage:(NSString *)newMessage lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	BOOL serviceEnabled = [RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Enable Service"];
	
	if (serviceEnabled == NO) {
		return newMessage;
	}
	
	if (lineType == TVCLogLineActionType ||
		lineType == TVCLogLinePrivateMessageType)
	{
		return [self convertStringToEmoji:newMessage];
	} else {
		return newMessage;
	}
}

#pragma mark -
#pragma mark Convert API

- (NSString *)convertStringToEmoji:(NSString *)string
{
	NSMutableString *finalString = [string mutableCopy];

	for (NSString *smiley in self.sortedSmileyList) {
		finalString = [self stringWithReplacedSmiley:smiley inString:finalString];
	}

	return finalString;
}

/* The replacement call uses a lot of work done by the actual Textual renderring engine. */
- (NSMutableString *)stringWithReplacedSmiley:(NSString *)smiley inString:(NSMutableString *)body
{
	NSInteger start = 0;

	while (1 == 1) {
		/* The body length is dynamic based on replaces so we have to check 
		 it every time compared to start. */

		if (start >= [body length]) {
			break;
		}

		/* Find smiley. */
		NSRange r = [body rangeOfString:smiley
								options:NSCaseInsensitiveSearch // Search is not case sensitive.
								  range:NSMakeRange(start, ([body length] - start))];

		/* Anything found? */
		if (r.location == NSNotFound) {
			break;
		}

		BOOL enabled = YES;

		/* Validate the surroundings if it is strict matching. */
		if (enabled) {
			NSInteger prev = (r.location - 1);

			if (0 <= prev && prev < [body length]) {
				UniChar c = [body characterAtIndex:prev];

				/* Only allow certain characters. */
				if (NSDissimilarObjects(c, ' ')) {
					enabled = NO;
				}
			}
		}

		if (enabled) {
			NSInteger next = NSMaxRange(r);

			if (next < [body length]) {
				UniChar c = [body characterAtIndex:next];

				/* Only accept a space. */
				if (NSDissimilarObjects(c, ' ')) {
					enabled = NO;
				}
			}
		}

		/* Replace the actual smiley. */
		if (enabled) {
			/* Build the emoji. */
			NSString *theEmoji = [self.conversionTable objectForKey:smiley];
			
			/* Replace the smiley. */
			[body replaceCharactersInRange:r withString:theEmoji];

			/* The new start is the location where the smiley began plus the length of the
			 newly added addition. By asking for the actual emoji length, instead of assuming
			 a length of one, we support future expansion if we make the conversion table more
			 complex. */
			start = (r.location + [theEmoji length] + 1);
		} else {
			start = (NSMaxRange(r) + 1);
		}
	}

	return body;
}

@end
