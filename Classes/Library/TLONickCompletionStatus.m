/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

@implementation TLONickCompletionStatus

- (id)init
{
	if ((self = [super init])) {
		[self clear];
	}

	return self;
}

- (void)completeNick:(BOOL)forward
{
	/* Global variables. */
	IRCClient *client = self.worldController.selectedClient;
	IRCChannel *channel = self.worldController.selectedChannel;
	
	TVCInputTextField *inputTextField = self.masterController.inputTextField;

	PointerIsEmptyAssert(client);

	/* Focus the text field and get the selected range. */
	[self.masterController.inputTextField focus];

	NSRange selectedRange = inputTextField.selectedRange;

	if (selectedRange.location == NSNotFound) {
		return;
	}

	/* Get the string. */
	NSString *s = inputTextField.stringValue;

	/* Time to start comparing values. */
	BOOL canContinuePreviousScan = YES;

	if (self.lastTextFieldSelectionRange.location == NSNotFound ||
		self.lastCompletionFragmentRange.location == NSNotFound ||
		self.lastCompletionCompletedRange.location == NSNotFound)
	{
		canContinuePreviousScan = NO;
	}

	if (NSObjectIsEmpty(self.cachedTextFieldStringValue)) {
		canContinuePreviousScan = NO;
	} else {
		if ([self.cachedTextFieldStringValue isEqualToString:s] == NO) {
			canContinuePreviousScan = NO;
		}
	}

	if (NSEqualRanges(selectedRange, self.lastTextFieldSelectionRange) == NO) {
		canContinuePreviousScan = NO;
	}

	/* 
	 There are two important variables defined by this completion system.
	 They are the backwardCut and selectedCut. The backwardCut is the fragment
	 being compared against all other items. The selectedCut anything right 
	 of the backwardCut left over from a previous scan. 
	 
	 "Hello Mikey"
		  >|  |<		— "Mi" the backwardCut, also lastCompletionFragmentRange
		     >|  |<		— "key" — the selectedCut, left over from last scan.
		  >|     |<		- "Mikey" — th entire last completion, also lastCompletionCompletedRange.

	 The above design only applies when canContinuePreviousScan is YES. Otherwise,
	 we have to start over by scrapping everything and finding the new backwardCut.
	 */

	/* Get the backward cut. */
	BOOL isAtStart = YES;
	BOOL isAtEnd = YES;

	NSString *backwardCut = NSStringEmptyPlaceholder;
	NSString *selectedCut = NSStringEmptyPlaceholder;

	if (canContinuePreviousScan == NO) {
		/* If this is a new scan, then reset all our ranges to begin with. */
		[self clear];

		/* Before we do anything, we must establish where we are starting. 
		 If the length of selectedRange is above zero, then it means the
		 user actually has something selected. If that is the case, we want
		 the end of that seelection to be where backwardCut should end. */
		if (selectedRange.length > 0) {
			selectedRange.location += selectedRange.length;
			selectedRange.length = 0;
		}

		/* We can back out the moment we aren't anywhere. */
		if (selectedRange.location == 0) {
			return;
		}

		/* Now that we know where our backwardCut check will begin, we must
		 start checking the all around it. For the left side of backwardCut
		 we want it to end on a space or the end of the text field itself. */

		NSInteger si = (selectedRange.location - 1);
		NSInteger ci = 0; // The cut index.

		for (NSInteger i = si; i >= 0; i--) {
			/* Scanning backwards from the origin unti we find a space
			 or the end of the text field. */

			UniChar cc = [s characterAtIndex:i];

			if (cc == ' ' || cc == ',') {
				ci = (i + 1); // Character right of the space.

				isAtStart = NO;

				break; // Exit scan loop;
			}
		}

		/* We now have the left side maximum index of the backwardCut
		 in the variable ci. The character at ci until the location
		 of the selectedRange will make up the backwardCut. */
		NSInteger bcl = (selectedRange.location - ci);

		if (bcl <= 0) {
			return; // Do not cut empty strings.
		}

		self.lastCompletionFragmentRange = NSMakeRange(ci, (selectedRange.location - ci));

		backwardCut = [s safeSubstringWithRange:self.lastCompletionFragmentRange];

		NSObjectIsEmptyAssert(backwardCut);

		/* Now we gather information about the right side of our backwardCut
		 which will be turned into the selectedCut. The selectedCut will be
		 at one point combined with backwardCut to search our search array 
		 for any possible values to know whether we should move to the next
		 result of a comparison. */
		NSInteger nextIndex = (self.lastCompletionFragmentRange.length + self.lastCompletionFragmentRange.location);

		if ((s.length - nextIndex) > 0) {
			/* Only do work if we have work to do. */

			ci = s.length; // Default to end of text field.

			/* We use the user configured suffix when scanning. */
			NSString *ucs = [TPCPreferences tabCompletionSuffix];

			/* State variable of the suffix. */
			BOOL isucsempty = NSObjectIsEmpty(ucs);

			UniChar ucsfc;

			/* Does user even have a suffix? */
			if (isucsempty == NO) {
				ucsfc = [ucs characterAtIndex:0]; // Get first character of suffix.
			}
			
			/* Start scan. */
			for (NSInteger i = nextIndex; i < s.length; i++) {
				UniChar cc = [s characterAtIndex:i];

				if (isucsempty == NO && cc == ucsfc) {
					/* If we have a suffix and the first character of it,
					 then we are going to substring from that index and
					 beyond to check if we have the rest of the suffix. */

					if (ucs.length == 1) {
						isAtEnd = NO;
						ci = i; // Index before this char.

						break;
					} else {
						NSString *css = [s safeSubstringFromIndex:i];

						if ([css hasPrefix:ucs]) {
							isAtEnd = NO;
							ci = (i + css.length); // Index before this char.

							break;
						}
					}
				} else {
					/* Continue with a normal scan. */

					if (cc == ' ' || cc == ':' || cc == ',') {
						ci = i; // Index before this char.

						isAtEnd = NO;

						break;
					}
				}
			}

			if (ci > 0) { // Do the actual truncate.
				NSRange scr = NSMakeRange(nextIndex, (ci - nextIndex));

				selectedCut = [s safeSubstringWithRange:scr];

				/* Set the completed range so that we replace
				 anything after the backwardCut when we replace. */
				NSRange fcr = self.lastCompletionFragmentRange;

				fcr.length += selectedCut.length;

				/* Update state information. */
				if ((fcr.location + fcr.length + 1) >= s.length) {
					isAtEnd = YES;
				}

				self.lastCompletionCompletedRange = fcr;
			}
		}
	} else {
		backwardCut = [s safeSubstringWithRange:self.lastCompletionFragmentRange];

		if (self.lastCompletionFragmentRange.location > 0) {
			isAtStart = NO;
		}

		if ((self.lastCompletionCompletedRange.location + self.lastCompletionCompletedRange.length + 1) < s.length) {
			isAtEnd = NO;
		}

		NSRange fr = self.lastCompletionCompletedRange;

		fr.location += backwardCut.length;
		fr.length -= backwardCut.length;

		selectedCut = [s safeSubstringWithRange:fr];
	}

	NSObjectIsEmptyAssert(backwardCut);

	/* What type of message are we completing? There are three
	 prefixes that can be matched to determine this: "/" for a
	 command, "@" (like Twitter) for a Nickname, and of course
	 "#" for a channel. The fourth prefix would be nothing which
	 also means a nickname. */
	BOOL channelMode = NO;
	BOOL commandMode = NO;

	NSInteger backwardCutLengthAddition = 0;

	NSString *backwardCutStringAddition = NSStringEmptyPlaceholder;

	UniChar c = [backwardCut characterAtIndex:0];

	if (isAtStart && c == '/') {
		commandMode = YES;

		backwardCut = [backwardCut safeSubstringFromIndex:1];
		backwardCutLengthAddition = 1;
		backwardCutStringAddition = @"/";
	} else if (c == '@') {
		PointerIsEmptyAssert(channel);

		backwardCut = [backwardCut safeSubstringFromIndex:1];
		backwardCutLengthAddition = 1;
		backwardCutStringAddition = @"@";
	} else if (c == '#') {
		channelMode = YES;
	}

	NSObjectIsEmptyAssert(backwardCut);

	/* The combined cut is used to compare for the next result. */
	NSString *combinedCut = [backwardCut stringByAppendingString:selectedCut];

	for (NSInteger i = 0; i < combinedCut.length; ++i) {
		UniChar c = [combinedCut characterAtIndex:i];

		/* Skip everything that is not a space or ":" then break the string
		 there so that a completion like "Nickname: " or "/command " will
		 be seen as only "Nickname" and "/command" */
		if (NSDissimilarObjects(c, ' ') && NSDissimilarObjects(c, ':') && NSDissimilarObjects(c, ',')) {
			;
		} else {
			combinedCut = [combinedCut safeSubstringToIndex:i];

			break;
		}
	}

	NSObjectIsEmptyAssert(combinedCut);

	/* Define our choices for the completion. The upperChoices array
	 holds all the case-sensitive representations of the completions
	 while the lowerChoices array holds each completion as a lowercase
	 string. The lowercase string is compared against the lowercase
	 backward cut. If they match, then the actual case is requested
	 from the upperChoices array. */

	NSString *lowerBackwardCut = backwardCut.lowercaseString;
	NSString *lowerCombinedCut = combinedCut.lowercaseString;

	NSMutableArray *upperChoices = [NSMutableArray array];
	NSMutableArray *lowerChoices;

	if (commandMode) {
		for (NSString *command in [TPCPreferences publicIRCCommandList]) {
			[upperChoices safeAddObject:[command lowercaseString]];
		}

		[upperChoices addObjectsFromArray:[RZPluginManager() supportedUserInputCommands]];
		[upperChoices addObjectsFromArray:[RZPluginManager() supportedAppleScriptCommands]];
	} else if (channelMode) {
		// Prioritize selected channel for channel completion
		[upperChoices safeAddObject:channel.name];

		for (IRCChannel *c in client.channels) {
			if ([c isEqual:channel] == NO) {
				[upperChoices safeAddObject:c.name];
			}
		}
	} else {
		NSArray *memberList = [channel.memberList sortedArrayUsingSelector:@selector(compareUsingWeights:)];

		for (IRCUser *m in memberList) {
			[upperChoices safeAddObject:m.nickname];
		}

		[upperChoices safeAddObject:@"NickServ"];
		[upperChoices safeAddObject:@"RootServ"];
		[upperChoices safeAddObject:@"OperServ"];
		[upperChoices safeAddObject:@"HostServ"];
		[upperChoices safeAddObject:@"ChanServ"];
		[upperChoices safeAddObject:@"MemoServ"];
		[upperChoices safeAddObject:[TPCPreferences applicationName]];

		/* Complete network name. */
		[upperChoices safeAddObject:client.isupport.networkNameActual];
	}

/*  lowerChoices = [upperChoices mutableCopy];

  /* Quick method for replacing the value of each array
   object based on a provided selector. */
  [lowerChoices performSelectorOnObjectValueAndReplace:@selector(lowercaseString)];
*/

  NSArray *tempChoices = [upperChoices copy];
  NSCharacterSet *nonAlpha = [NSCharacterSet characterSetWithCharactersInString:@"^[]-_`{}"]
  [upperChoices removeAllObjects];
  for (NSString *s in tempChoices) {
    [lowerChoices safeAddObject:s];
    [upperChoices safeAddObject:s];
    NSString *stripped = [s stringByTrimmingCharactersInSet:nonAlpha];
    if (stripped != s ) {
      [lowerChoices safeAddObject:stripped];
      [upperChoices safeAddObject:s];
    }
  }

	/* We will now get a list of matches to our backward cut. */
	NSMutableArray *currentUpperChoices = [NSMutableArray array];
	NSMutableArray *currentLowerChoices = [NSMutableArray array];

	NSInteger i = 0;

	for (NSString *s in lowerChoices) {
		if ([s hasPrefix:lowerBackwardCut]) {
			[currentLowerChoices safeAddObject:s];
			[currentUpperChoices safeAddObject:[upperChoices safeObjectAtIndex:i]];
		}

		i += 1;
	}

	NSAssertReturn(currentUpperChoices.count >= 1);

	/* Now that we know the choices that are actually available to the
	   string being completed; we can filter through each going backwards
	   or forward depending on the call to this method. */
	NSString *t = nil;

	NSUInteger index = [currentLowerChoices indexOfObject:lowerCombinedCut];

	if (index == NSNotFound) {
		t = [currentUpperChoices safeObjectAtIndex:0];
	} else {
		if (forward) {
			index += 1;

			if (currentUpperChoices.count <= index) {
				index = 0;
			}
		} else {
			if (index == 0) {
				index = (currentUpperChoices.count - 1);
			} else {
				index -= 1;
			}
		}

		t = [currentUpperChoices safeObjectAtIndex:index];
	}

	/* Add prefix back to the string? */
	if (backwardCutLengthAddition > 0) {
		backwardCut = [backwardCutStringAddition stringByAppendingString:backwardCut];

		t = [backwardCutStringAddition stringByAppendingString:t];
	}

	/* Add the completed string to the spell checker so that a nickname
	 wont show up as spelled incorrectly. The spell checker is cleared
	 of these ignores between channel changes. */
	[RZSpellChecker() ignoreWord:t inSpellDocumentWithTag:inputTextField.spellCheckerDocumentTag];

	/* Create our final string. */
	if (commandMode || channelMode || isAtStart == NO) {
		BOOL addWhitespace = YES;

		if (isAtEnd == NO) {
			if ([selectedCut hasPrefix:NSStringWhitespacePlaceholder]) {
				if (canContinuePreviousScan) {
					addWhitespace = NO;
				}
			}
		}

		if (addWhitespace) {
			t = [t stringByAppendingString:NSStringWhitespacePlaceholder];
		}
	} else {
		NSString *completeSuffix = [TPCPreferences tabCompletionSuffix];

		if (NSObjectIsNotEmpty(completeSuffix)) {
			t = [t stringByAppendingString:completeSuffix];
		}
	}

	/* Update the text field. */
	NSRange fr = NSEmptyRange();

	if (self.lastCompletionCompletedRange.location == NSNotFound) {
		fr.length = backwardCut.length;
	} else {
		fr.length = self.lastCompletionCompletedRange.length;
	}

	fr.location = self.lastCompletionFragmentRange.location;

	if ([inputTextField shouldChangeTextInRange:fr replacementString:t]) {
		[inputTextField.textStorage beginEditing];
		[inputTextField replaceCharactersInRange:fr withString:t];
		[inputTextField.textStorage endEditing];
	}

	[inputTextField scrollRangeToVisible:inputTextField.selectedRange];

	fr.length = t.length;

	self.lastCompletionCompletedRange = fr;

	/* Update the selected range. */
	fr.location = (fr.location + fr.length);
	fr.length = 0;

	inputTextField.selectedRange = fr;

	self.lastTextFieldSelectionRange = fr;
	self.cachedTextFieldStringValue = inputTextField.string;
}

- (void)clear
{
	self.cachedTextFieldStringValue = nil;

	self.lastTextFieldSelectionRange = NSEmptyRange();
	self.lastCompletionCompletedRange = NSEmptyRange();
	self.lastCompletionFragmentRange = NSEmptyRange();
}

@end
