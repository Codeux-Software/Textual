/* *********************************************************************
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#import "TPISmileyConverter.h"

@interface TPISmileyConverter ()
@property (nonatomic, copy) NSDictionary *conversionTable;
@property (nonatomic, copy) NSArray *sortedSmileyList;
@property (nonatomic, strong) IBOutlet NSView *preferencesPane;

- (IBAction)preferenceChanged:(id)sender;
@end

@implementation TPISmileyConverter

#pragma mark -
#pragma mark Plugin API

- (void)pluginLoadedIntoMemory
{
	/* Load Interface. */
	[self performBlockOnMainThread:^{
		[TPIBundleFromClass() loadNibNamed:@"TPISmileyConverter" owner:self topLevelObjects:nil];
	}];

	[self maybeBuildConversionTable];
}

- (void)maybeBuildConversionTable
{
	BOOL serviceEnabled = [RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Enable Service"];

	if (serviceEnabled) {
		[self buildConversionTable];
	}
}

- (void)buildConversionTable
{
	NSMutableDictionary *converstionTable = [NSMutableDictionary dictionary];

	/* Load primary table. */
	/* Find ourselves. */
	NSURL *tablePath = [TPIBundleFromClass() URLForResource:@"conversionTable" withExtension:@"plist"];
	
	/* Load dictionary. */
	NSDictionary *tableData = [NSDictionary dictionaryWithContentsOfURL:tablePath];
	
	if (NSObjectIsEmpty(tableData)) {
		NSAssert(NO, @"Failed to find conversion table.");
	}

	[converstionTable addEntriesFromDictionary:tableData];

	/* Maybe load extras. */
	if ([RZUserDefaults() boolForKey:@"Smiley Converter Extension -> Enable Extra Emoticons"]) {
		/* Find ourselves. */
		NSURL *tablePath2 = [TPIBundleFromClass() URLForResource:@"conversionTable2" withExtension:@"plist"];

		/* Load dictionary. */
		NSDictionary *tableData2 = [NSDictionary dictionaryWithContentsOfURL:tablePath2];

		if (NSObjectIsEmpty(tableData)) {
			NSAssert(NO, @"Failed to find conversion table.");
		}

		[converstionTable addEntriesFromDictionary:tableData2];
	}
	
	/* Save dictionary contents. */
	self.conversionTable	=  converstionTable;

	self.sortedSmileyList	= [converstionTable sortedDictionaryReversedKeys];
}

- (void)destroyConversionTable
{
	self.conversionTable = nil;

	self.sortedSmileyList = nil;
}

- (void)preferenceChanged:(id)sender
{
	[self destroyConversionTable];

	[self maybeBuildConversionTable];
}

- (NSView *)pluginPreferencesPaneView
{
	return self.preferencesPane;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizedString(@"BasicLanguage[1000]");
}

- (NSString *)willRenderMessage:(NSString *)newMessage forViewController:(TVCLogController *)viewController lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
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
			NSString *theEmoji = (self.conversionTable)[smiley];
			
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
