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

#import "NSObjectHelperPrivate.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCTextViewWithIRCFormatterPrivate.h"
#import "TDCChannelModifyTopicSheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCChannelModifyTopicSheet ()
@property (nonatomic, strong, readwrite) IRCClient *client;
@property (nonatomic, strong, readwrite) IRCChannel *channel;
@property (nonatomic, copy, readwrite) NSString *clientId;
@property (nonatomic, copy, readwrite) NSString *channelId;
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, strong) IBOutlet TVCTextViewWithIRCFormatter *topicValueTextField;
@end

@implementation TDCChannelModifyTopicSheet

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ((self = [super init])) {
		self.client = channel.associatedClient;
		self.clientId = channel.associatedClient.uniqueIdentifier;

		self.channel = channel;
		self.channelId = channel.uniqueIdentifier;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[RZMainBundle() loadNibNamed:@"TDCChannelModifyTopicSheet" owner:self topLevelObjects:nil];

	NSString *headerTitle = [NSString stringWithFormat:self.headerTitleTextField.stringValue, self.channel.name];

	self.headerTitleTextField.stringValue = headerTitle;

	self.topicValueTextField.preferredFont = [NSFont systemFontOfSize:13.0];
	self.topicValueTextField.preferredFontColor = [NSColor blackColor];

	NSString *topic = self.channel.topic;

	if (topic) {
		self.topicValueTextField.stringValueWithIRCFormatting = topic;
	}
}

- (void)start
{
	[self startSheet];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	[self.topicValueTextField textDidChange:aNotification];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (aSelector == @selector(insertNewline:)) {
		[self ok:nil];

		return YES;
	} else if (aSelector == @selector(insertNewlineIgnoringFieldEditor:) ) {
		/* Do not allow a new line to be inserted using Option + Enter */

		return YES;
	}

	return NO;
}

- (void)ok:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(channelModifyTopicSheet:onOk:)]) {
		NSString *formattedTopic = self.topicValueTextField.stringValueWithIRCFormatting;

		NSString *topicWithoutNewlines = [formattedTopic stringByReplacingOccurrencesOfString:@"\n"
																				   withString:@" "];

		[self.delegate channelModifyTopicSheet:self onOk:topicWithoutNewlines];
	}

	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(channelModifyTopicSheetWillClose:)]) {
		[self.delegate channelModifyTopicSheetWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
