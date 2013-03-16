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

#import "TPIWikipediaLinkParser.h"

#define _defaultLinkPrefix          @"https://en.wikipedia.org/wiki/"
#define _linkMatchRegex             @"\\[\\[([^\\]]+)\\]\\]"

@interface TPIWikipediaLinkParser ()
@property (nonatomic, weak) NSView *preferencePane;
@end

@implementation TPIWikipediaLinkParser

#pragma mark -
#pragma mark Init.

- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
    [NSBundle loadNibNamed:@"TPIWikipediaLinkParser" owner:self];
}

#pragma mark -
#pragma mark Server Input.

- (void)messageReceivedByServer:(IRCClient *)client
                         sender:(NSDictionary *)senderDict
                        message:(NSDictionary *)messageDict
{
    /* Gather information about message. */
    NSArray *params = messageDict[@"messageParamaters"];

	NSString *message = messageDict[@"messageSequence"];

	IRCChannel *channel = [client findChannel:params[0]];

    PointerIsEmptyAssert(channel);

    /* Parse the message for all possible matches. */
    NSArray *linkMatches = [TLORegularExpression matchesInString:[message stripIRCEffects] withRegex:_linkMatchRegex];

    if (linkMatches.count > 0) {
        NSInteger loopIndex = 0;

        /* Loop through each match. */
        for (__strong NSString *linkRaw in linkMatches) {
            NSAssertReturnLoopContinue(linkRaw.length > 4);

            loopIndex += 1;

            /* Get the inside of the brackets. */
            NSRange cutRange = NSMakeRange(2, (linkRaw.length - 4));

            linkRaw = [linkRaw safeSubstringWithRange:cutRange];

            /* Get the left side. */
            if ([linkRaw contains:@"|"]) {
                linkRaw = [linkRaw safeSubstringToIndex:[linkRaw stringPosition:@"|"]];
                linkRaw = [linkRaw trim];
            }

            /* Create our message and post it. */
            NSString *message = [NSString stringWithFormat:@" %i: %@ —> %@%@", loopIndex, linkRaw, [self wikipediaLinkPrefix], [linkRaw encodeURIComponent]];

            [client printDebugInformation:message channel:channel];
        }
    }
}

- (NSArray *)pluginSupportsServerInputCommands
{
    return @[@"privmsg"];
}

#pragma mark -
#pragma mark User Input.

- (id)interceptUserInput:(id)input command:(NSString *)command
{
    /* Return input if we are not going to process anything. */
    NSAssertReturnR([self processWikipediaLinks], input);

    /* Do not handle NSString. */
    if ([input isKindOfClass:[NSAttributedString class]] == NO) {
        return input;
    }

    /* Start parser. */
    NSMutableAttributedString *muteString = [input mutableCopy];

    while (1 == 1) {
        /* Get the range of next match. */
        NSRange linkRange = [TLORegularExpression string:[muteString string] rangeOfRegex:_linkMatchRegex];

        /* No match found? Break our loop. */
        if (linkRange.location == NSNotFound) {
            break;
        }

        NSAssertReturnLoopContinue(linkRange.length > 4);

        /* Get inside of brackets. */
        NSRange cutRange = NSMakeRange((linkRange.location + 2),
                                       (linkRange.length - 4));

        NSString *linkInside;

        linkInside = [muteString.string safeSubstringWithRange:cutRange];

        /* Get the left side. */
        if ([linkInside contains:@"|"]) {
            linkInside = [linkInside safeSubstringToIndex:[linkInside stringPosition:@"|"]];
            linkInside = [linkInside trim];
        }

        /* Build our link and replace it in the input. */
        linkInside = [[self wikipediaLinkPrefix] stringByAppendingString:linkInside.encodeURIComponent];

        [muteString replaceCharactersInRange:linkRange withString:linkInside];
    }

    return muteString;
}

#pragma mark -
#pragma mark Preference Pane.

- (NSString *)preferencesMenuItemName
{
    return TPILS(@"TPIWikipediaLinkParserPreferencePaneMenuItemTitle");
}

- (NSView *)preferencesView
{
    return self.preferencePane;
}

#pragma mark -
#pragma mark Utilities.

- (BOOL)processWikipediaLinks
{
    return [RZUserDefaults() boolForKey:@"Wikipedia Link Parser Extension -> Service Enabled"];
}

- (NSString *)wikipediaLinkPrefix
{
    NSString *prefix = [RZUserDefaults() objectForKey:@"Wikipedia Link Parser Extension -> Link Prefix"];
    
    NSObjectIsEmptyAssertReturn(prefix, _defaultLinkPrefix);

    return prefix;
}

@end
