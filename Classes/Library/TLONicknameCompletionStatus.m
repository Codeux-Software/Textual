/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

@implementation TLONicknameCompletionStatus

- (instancetype)init
{
	if ((self = [super init])) {
		[self clear:YES];
	}

	return self;
}

- (NSString *)trimNickname:(NSString *)nickname usingCharacterSet:(NSCharacterSet *)charset
{
	for (NSUInteger i = 0; i < [nickname length]; i++) {
		UniChar c = [nickname characterAtIndex:i];

		if ([charset characterIsMember:c]) {
			continue;
		} else {
			return [nickname substringFromIndex:i];
		}
	}

	return nil;
}

- (void)completeNickname:(BOOL)forward
{
	/* Global variables. */
	IRCClient *client = [mainWindow() selectedClient];
	IRCChannel *channel = [mainWindow() selectedChannel];
	
	TVCMainWindowTextView *inputTextField = mainWindowTextField();

	PointerIsEmptyAssert(client);

	/* Focus the text field and get the selected range. */
	[inputTextField focus];

	NSRange selectedRange = [inputTextField selectedRange];

	if (selectedRange.location == NSNotFound) {
		return;
	}

	/* Get the string. */
	NSString *s = [inputTextField stringValue];

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
		if ([self.cachedTextFieldStringValue isEqualToString:s]) {
			[self clear:NO];
		} else {
			[self clear:YES];
		}

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
		 we want it to end on a space or the end of the text field it_ */

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

		backwardCut = [s substringWithRange:self.lastCompletionFragmentRange];

		NSObjectIsEmptyAssert(backwardCut);

		/* Now we gather information about the right side of our backwardCut
		 which will be turned into the selectedCut. The selectedCut will be
		 at one point combined with backwardCut to search our search array 
		 for any possible values to know whether we should move to the next
		 result of a comparison. */
		NSInteger nextIndex = (self.lastCompletionFragmentRange.length + self.lastCompletionFragmentRange.location);

		if (([s length] - nextIndex) > 0) {
			/* Only do work if we have work to do. */

			ci = [s length]; // Default to end of text field.

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
			for (NSInteger i = nextIndex; i < [s length]; i++) {
				UniChar cc = [s characterAtIndex:i];

				if (isucsempty == NO && cc == ucsfc) {
					/* If we have a suffix and the first character of it,
					 then we are going to substring from that index and
					 beyond to check if we have the rest of the suffix. */

					if ([ucs length] == 1) {
						isAtEnd = NO;
						
						ci = i; // Index before this char.

						break;
					} else {
						NSString *css = [s substringFromIndex:i];

						if ([css hasPrefix:ucs]) {
							isAtEnd = NO;

							ci = (i + [css length]); // Index before this char.

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

				selectedCut = [s substringWithRange:scr];

				/* Set the completed range so that we replace
				 anything after the backwardCut when we replace. */
				NSRange fcr = self.lastCompletionFragmentRange;

				if (self.cachedLastCompleteStringValue) {
					if (backwardCut && selectedCut) {
						/* Only cut forward if the combined cut is equal to the previous complete. */
						NSString *combinedCut = [backwardCut stringByAppendingString:selectedCut];
						
						if (NSObjectsAreEqual(self.cachedLastCompleteStringValue, combinedCut)) {
							fcr.length += [selectedCut length];
						}
					}
				}

				/* Update state information. */
				if ((fcr.location + fcr.length + 1) >= [s length]) {
					isAtEnd = YES;
				}

				self.lastCompletionCompletedRange = fcr;
			}
		}
	} else {
		backwardCut = self.cachedBackwardCutStringValue;

		if (self.lastCompletionFragmentRange.location > 0) {
			isAtStart = NO;
		}

		if ((self.lastCompletionCompletedRange.location + self.lastCompletionCompletedRange.length + 1) < [s length]) {
			isAtEnd = NO;
		}

		NSRange fr = self.lastCompletionCompletedRange;

		fr.location += backwardCut.length;
		fr.length -= backwardCut.length;

		selectedCut = [s substringWithRange:fr];
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

		backwardCut = [backwardCut substringFromIndex:1];
		backwardCutLengthAddition = 1;
		backwardCutStringAddition = @"/";
	} else if (c == '@') {
		PointerIsEmptyAssert(channel);

		backwardCut = [backwardCut substringFromIndex:1];
		backwardCutLengthAddition = 1;
		backwardCutStringAddition = @"@";
	} else if (c == '#') {
		channelMode = YES;
	}

	NSObjectIsEmptyAssert(backwardCut);

	/* Define our choices for the completion. The upperChoices array
	 holds all the case-sensitive representations of the completions
	 while the lowerChoices array holds each completion as a lowercase
	 string. The lowercase string is compared against the lowercase
	 backward cut. If they match, then the actual case is requested
	 from the upperChoices array. */

	NSString *lowerBackwardCut = backwardCut.lowercaseString;

	NSMutableArray *upperChoices = [NSMutableArray array];
	NSMutableArray *lowerChoices = [NSMutableArray array];

	if (commandMode) {
		for (NSString *command in [IRCCommandIndex publicIRCCommandList]) {
			[upperChoices addObject:[command lowercaseString]];
		}

		[upperChoices addObjectsFromArray:[sharedPluginManager() supportedUserInputCommands]];
		[upperChoices addObjectsFromArray:[sharedPluginManager() supportedAppleScriptCommands]];
	} else if (channelMode) {
		// Prioritize selected channel for channel completion
		if (channel) {
			[upperChoices addObject:[channel name]];
		}
		
		for (IRCChannel *c in [client channelList]) {
			if ([c isEqual:channel] == NO) {
				[upperChoices addObject:[c name]];
			}
		}
	} else {
		NSArray *memberList = [[channel memberList] sortedArrayUsingSelector:@selector(compareUsingWeights:)];

		for (IRCUser *m in memberList) {
			[upperChoices addObject:[m nickname]];
		}

		[upperChoices addObject:@"NickServ"];
		[upperChoices addObject:@"RootServ"];
		[upperChoices addObject:@"OperServ"];
		[upperChoices addObject:@"HostServ"];
		[upperChoices addObject:@"ChanServ"];
		[upperChoices addObject:@"MemoServ"];
		[upperChoices addObject:[TPCApplicationInfo applicationName]];

		/* Complete network name. */
		NSString *networkName = [[client supportInfo] networkNameActual];
		
		if (networkName) {
			[upperChoices addObject:networkName];
		}
	}

	/* Quick method for replacing the value of each array
	 object based on a provided selector. */
	if (commandMode || channelMode) {
		lowerChoices = [upperChoices mutableCopy];

		[lowerChoices performSelectorOnObjectValueAndReplace:@selector(lowercaseString)];
	} else {
		/* For nickname completes we stripout certain characters. */
		NSArray *tempChoices = [upperChoices copy];

		[upperChoices removeAllObjects];

		/* Add objects to the arrays plus their stripped versions. */
		NSCharacterSet *nonAlphaChars = [NSCharacterSet characterSetWithCharactersInString:@"^[]-_`{}\\"];

		for (NSString *s in tempChoices) {
			[upperChoices addObject:s];
			[lowerChoices addObject:[s lowercaseString]];

			NSString *stripped = [self trimNickname:s usingCharacterSet:nonAlphaChars];

			if ([s isNotEqualTo:stripped] && [stripped length] > 0) {
				stripped = stripped.lowercaseString;

				if ([lowerChoices containsObject:stripped] == NO) {
					[upperChoices addObject:s];
					[lowerChoices addObject:[stripped lowercaseString]];
				}
			}
		}
	}

	/* We will now get a list of matches to our backward cut. */
	NSMutableArray *currentUpperChoices = [NSMutableArray array];
	NSMutableArray *currentLowerChoices = [NSMutableArray array];

	NSInteger i = 0;

	for (NSString *s in lowerChoices) {
		if ([s hasPrefix:lowerBackwardCut]) {
			[currentLowerChoices addObject:s];
			[currentUpperChoices addObject:upperChoices[i]];
		}

		i += 1;
	}

	NSAssertReturn([currentUpperChoices count] >= 1);

	/* Now that we know the choices that are actually available to the
	   string being completed; we can filter through each going backwards
	   or forward depending on the call to this method. */
	NSString *ut = nil;

	NSUInteger index = self.lastCompletionSelectionIndex;

	if (index == NSNotFound || index >= [currentLowerChoices count]) {
		ut = currentUpperChoices[0];

		self.lastCompletionSelectionIndex = 0;
	} else {
		if (forward) {
			index += 1;

			if ([currentUpperChoices count] <= index) {
				index = 0;
			}
		} else {
			if (index == 0) {
				index = ([currentUpperChoices count] - 1);
			} else {
				index -= 1;
			}
		}

		ut = currentUpperChoices[index];

		self.lastCompletionSelectionIndex = index;
	}

	/* Add prefix back to the string? */
	if (backwardCutLengthAddition > 0) {
		backwardCut = [backwardCutStringAddition stringByAppendingString:backwardCut];

		ut = [backwardCutStringAddition stringByAppendingString:ut];
	}
	
	/* Cache value. */
	self.cachedLastCompleteStringValue = ut;

	/* Add the completed string to the spell checker so that a nickname
	 wont show up as spelled incorrectly. The spell checker is cleared
	 of these ignores between channel changes. */
	[RZSpellChecker() ignoreWord:ut inSpellDocumentWithTag:inputTextField.spellCheckerDocumentTag];

	[inputTextField setHasModifiedSpellingDictionary:YES];
	
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
			ut = [ut stringByAppendingString:NSStringWhitespacePlaceholder];
		}
	} else {
		NSString *completeSuffix = [TPCPreferences tabCompletionSuffix];

		if (NSObjectIsNotEmpty(completeSuffix)) {
			BOOL addWhitespace = YES;

			if ([completeSuffix isEqualToString:NSStringWhitespacePlaceholder]) {
				NSUInteger nextIndx = (self.lastCompletionCompletedRange.length + self.lastCompletionCompletedRange.location);
				
				if ([s length] > nextIndx) {
					NSString *nextChar = [s stringCharacterAtIndex:nextIndx];
					
					if ([nextChar isEqualToString:NSStringWhitespacePlaceholder]) {
						addWhitespace = NO;
					}
				}
			}

			if (addWhitespace) {
				ut = [ut stringByAppendingString:completeSuffix];
			}
		}
	}

	/* Update the text field. */
	NSRange fr = NSEmptyRange();

	if (self.lastCompletionCompletedRange.location == NSNotFound) {
		fr.length = [backwardCut length];
	} else {
		fr.length = self.lastCompletionCompletedRange.length;
	}

	fr.location = self.lastCompletionFragmentRange.location;

	if ([inputTextField shouldChangeTextInRange:fr replacementString:ut])
	{
		[[inputTextField textStorage] beginEditing];
		
		[inputTextField replaceCharactersInRange:fr withString:ut];
		
		[[inputTextField textStorage] endEditing];
	}

	[inputTextField scrollRangeToVisible:inputTextField.selectedRange];

	fr.length = [ut length];

	self.lastCompletionCompletedRange = fr;

	/* Update the selected range. */
	fr.location = (fr.location + fr.length);
	fr.length = 0;

	[inputTextField setSelectedRange:fr];

	self.lastTextFieldSelectionRange = fr;

	/* Update cached string values. */
	self.cachedTextFieldStringValue = [inputTextField string];
	self.cachedBackwardCutStringValue = backwardCut;
}

- (void)clear:(BOOL)clearLastValue
{
	self.cachedTextFieldStringValue = nil;
	self.cachedBackwardCutStringValue = nil;
	
	if (clearLastValue) {
		self.cachedLastCompleteStringValue = nil;
	}

	self.lastCompletionSelectionIndex = NSNotFound;

	self.lastTextFieldSelectionRange = NSEmptyRange();
	self.lastCompletionCompletedRange = NSEmptyRange();
	self.lastCompletionFragmentRange = NSEmptyRange();
}

@end
