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

	/* Which range do we use? */
	if (selectedRange.length == 0									&&
		[self.stringValue isEqualToString:s]						&&
		NSMaxRange(self.stringRange) == selectedRange.location		&&
		NSDissimilarObjects(self.stringRange.location, NSNotFound))
	{
		selectedRange = self.stringRange;
	}

	/* Get the backward cut. */
	BOOL isAtStart = YES;
	BOOL isAtEnd = YES;

	NSString *backwardCut = [s safeSubstringToIndex:selectedRange.location];
	NSString *selectedCut = [s safeSubstringWithRange:selectedRange];

	/* Scan the selected string backwards looking for the first space,
	 then cut the selected string from there, forward. */
	for (NSInteger i = (backwardCut.length - 1); i >= 0; --i) {
		UniChar c = [backwardCut characterAtIndex:i];

		if (c == ' ') {
			i += 1;

			NSAssertReturn(i < backwardCut.length);

			isAtStart = NO; // String is not at the start of text field.

			backwardCut = [backwardCut safeSubstringFromIndex:i];

			break;
		}
	}

	/* Check ahead of our selected range to see if anything exists. 
	 If it does, tell the controller. For command and channel name
	 completion we normally insert a space after the completion, but
	 if there is already one there, then this tells it not to. */

	NSInteger cutCombinedLength = NSMaxRange(selectedRange);
	
	if (cutCombinedLength < s.length) {
		UniChar c = [s characterAtIndex:cutCombinedLength];

		if (c == ' ') {
			isAtEnd = NO;
		}
	}

	NSObjectIsEmptyAssert(backwardCut);

	/* What type of message are we completing? There are three
	 prefixes that can be matched to determine this: "/" for a
	 command, "@" (like Twitter) for a Nickname, and of course
	 "#" for a channel. The fourth prefix would be nothing which
	 also means a nickname. */
	BOOL channelMode = NO;
	BOOL commandMode = NO;

	UniChar c = [backwardCut characterAtIndex:0];

	if (isAtStart && c == '/') {
		commandMode = YES;

		backwardCut = [backwardCut safeSubstringFromIndex:1];
	} else if (c == '@') {
		PointerIsEmptyAssert(channel);

		backwardCut = [backwardCut safeSubstringFromIndex:1];
	} else if (c == '#') {
		channelMode = YES;
	}

	NSObjectIsEmptyAssert(backwardCut);

	/* Combine the selected string and the backward cut. */
	NSString *currentCombined = [backwardCut stringByAppendingString:selectedCut];

	for (NSInteger i = 0; i < currentCombined.length; ++i) {
		UniChar c = [currentCombined characterAtIndex:i];

		/* Skip everything that is not a space or ":" then break the string
		 there so that a completion like "Nickname: " or "/command " will
		 be seen as only "Nickname" and "/command" */
		if (NSDissimilarObjects(c, ' ') && NSDissimilarObjects(c, ':')) {
			;
		} else {
			currentCombined = [currentCombined safeSubstringToIndex:i];

			break;
		}
	}

	NSObjectIsEmptyAssert(currentCombined);

	/* Define our choices for the completion. The upperChoices array
	 holds all the case-sensitive representations of the completions
	 while the lowerChoices array holds each completion as a lowercase 
	 string. The lowercase string is compared against the lowercase 
	 backward cut. If they match, then the actual case is requested
	 from the upperChoices array. */
	
	NSString *lowerBackwardCut = backwardCut.lowercaseString;
	NSString *lowerCurrentCombined = currentCombined.lowercaseString;

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
			if (![c isEqual:channel]) {
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

	lowerChoices = [upperChoices mutableCopy];

	/* Quick method for replacing the value of each array 
	 object based on a provided selector. */
	[lowerChoices performSelectorOnObjectValueAndReplace:@selector(lowercaseString)];

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

	NSUInteger index = [currentLowerChoices indexOfObject:lowerCurrentCombined];

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

	/* Add the completed string to the spell checker so that a nickname
	 wont show up as spelled incorrectly. The spell checker is cleared
	 of these ignores between channel changes. */
	
	[RZSpellChecker() ignoreWord:t inSpellDocumentWithTag:inputTextField.spellCheckerDocumentTag];

	/* Create our final string. */
	if (commandMode || channelMode || isAtStart == NO) {
		if (isAtEnd) {
			t = [t stringByAppendingString:NSStringWhitespacePlaceholder];
		}
	} else {
		NSString *completeSuffix = [TPCPreferences tabCompletionSuffix];
		
		if (NSObjectIsNotEmpty(completeSuffix)) {
			t = [t stringByAppendingString:completeSuffix];
		}
	}

	/* Update the text field. */
	NSRange r = selectedRange;

	r.location -= backwardCut.length;
	r.length += backwardCut.length;

	[inputTextField replaceCharactersInRange:r withString:t];
	[inputTextField scrollRangeToVisible:inputTextField.selectedRange];

	/* Update the selected range. */
	r.location += t.length;
	r.length = 0;

	inputTextField.selectedRange = r;

	/* Update our internal status range. */
	if (currentUpperChoices.count == 1) {
		[self clear];
	} else {
		selectedRange.length = (t.length - backwardCut.length);

		self.stringValue = inputTextField.stringValue;
		self.stringRange = selectedRange;
	}
}

- (void)clear
{
	self.stringValue = nil;
	self.stringRange = NSEmptyRange();
}

@end
