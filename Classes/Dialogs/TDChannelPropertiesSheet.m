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

#import "TextualApplication.h"

@interface TDChannelPropertiesSheet ()
/* Each entry of the array is an array with index 0 equal to the
 view and index 1 equal to the first responder wanted in that view. */
@property (nonatomic, copy) NSArray *navigationTree;
@property (nonatomic, weak) IBOutlet NSButton *autoJoinCheck;
@property (nonatomic, weak) IBOutlet NSButton *disableInlineImagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *enableInlineImagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *pushNotificationsCheck;
@property (nonatomic, weak) IBOutlet NSButton *showTreeBadgeCountCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreHighlightsCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreGeneralEventMessagesCheck;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *contentViewTabView;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *channelNameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *defaultModesTextField;
@property (nonatomic, weak) IBOutlet NSTextField *defaultTopicTextField;
@property (nonatomic, weak) IBOutlet NSTextField *secretKeyTextField;
@property (nonatomic, weak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultsView;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneralView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

- (IBAction)onMenuBarItemChanged:(id)sender;

- (IBAction)onChangedInlineMediaOption:(id)sender;
@end

@implementation TDChannelPropertiesSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDChannelPropertiesSheet" owner:self topLevelObjects:nil];

		self.navigationTree = @[
			//		view								first responder
			@[self.contentViewGeneralView,			self.channelNameTextField],
			@[self.contentViewDefaultsView,			self.defaultTopicTextField],
		];
		
		[self.channelNameTextField setOnlyShowStatusIfErrorOccurs:YES];
		[self.channelNameTextField setStringValueUsesOnlyFirstToken:YES];
		[self.channelNameTextField setStringValueIsInvalidOnEmpty:YES];

		[self.channelNameTextField setTextDidChangeCallback:self];
		
		[self.channelNameTextField setValidationBlock:^(NSString *currentValue) {
			return [currentValue isChannelName];
		}];
	}

	return self;
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender
{
	[self navigateToIndex:[sender indexOfSelectedItem]];
}

- (void)navigateToIndex:(NSInteger)row
{
	[self selectPane:self.navigationTree[row][0]];

	[self.sheet makeFirstResponder:self.navigationTree[row][1]];
}

- (void)selectPane:(NSView *)view
{
	[self.contentView attachSubview:view
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start
{
	[self load];
	[self update];
	[self navigateToIndex:0];
	[self startSheet];
	[self addConfigurationDidChangeObserver];
}

- (void)load
{
	[self.channelNameTextField		setStringValue:[self.config channelName]];
	
	[self.defaultModesTextField		setStringValue:[self.config defaultModes]];
	[self.defaultTopicTextField		setStringValue:[self.config defaultTopic]];

	[self.secretKeyTextField		setStringValue:[self.config secretKeyValue]];

	[self.autoJoinCheck				setState:[self.config autoJoin]];
	[self.pushNotificationsCheck	setState:[self.config pushNotifications]];
	[self.showTreeBadgeCountCheck	setState:[self.config showTreeBadgeCount]];

	[self.ignoreGeneralEventMessagesCheck	setState:[self.config ignoreGeneralEventMessages]];
	[self.ignoreHighlightsCheck				setState:[self.config ignoreHighlights]];

	if ([TPCPreferences showInlineImages]) {
		[self.disableInlineImagesCheck setState:[self.config ignoreInlineImages]];
	} else {
		[self.enableInlineImagesCheck setState:[self.config ignoreInlineImages]];
	}
}

- (void)save
{
	[self.config setChannelName:		[self.channelNameTextField value]];
	
	[self.config setDefaultModes:		[self.defaultModesTextField trimmedStringValue]];
	[self.config setDefaultTopic:		[self.defaultTopicTextField trimmedStringValue]];
	
	[self.config setSecretKey:			[self.secretKeyTextField trimmedFirstTokenStringValue]];

	[self.config setAutoJoin:					[self.autoJoinCheck state]];
	[self.config setPushNotifications:			[self.pushNotificationsCheck state]];
	[self.config setShowTreeBadgeCount:			[self.showTreeBadgeCountCheck state]];

	[self.config setIgnoreGeneralEventMessages:		[self.ignoreGeneralEventMessagesCheck state]];
	[self.config setIgnoreHighlights:				[self.ignoreHighlightsCheck state]];

	if ([TPCPreferences showInlineImages]) {
		[self.config setIgnoreInlineImages:[self.disableInlineImagesCheck state]];
	} else {
		[self.config setIgnoreInlineImages:[self.enableInlineImagesCheck state]];
	}
}

- (void)update
{
	[self.okButton setEnabled:[self.channelNameTextField valueIsValid]];
	
	[self.channelNameTextField setEditable:self.newItem];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self update];
}

- (void)close
{
	[self cancel:nil];
}

- (void)addConfigurationDidChangeObserver
{
	if (self.observeChanges) {
		IRCChannel *channel = [self channelObjectByProperties];

		if (channel) {
			[RZNotificationCenter() addObserver:self
									   selector:@selector(underlyingConfigurationChanged:)
										   name:IRCChannelConfigurationWasUpdatedNotification
										 object:channel];
		}
	}
}

- (void)removeConfigurationDidChangeObserver
{
	if (self.observeChanges) {
		IRCChannel *channel = [self channelObjectByProperties];

		if (channel) {
			[RZNotificationCenter() removeObserver:self
											  name:IRCChannelConfigurationWasUpdatedNotification
											object:[self channelObjectByProperties]];
		}
	}
}

- (IRCChannel *)channelObjectByProperties
{
	return [worldController() findChannelWithId:self.channelID onClientWithId:self.clientID];
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	IRCChannel *channel = [notification object];

	[TLOPopupPrompts sheetWindowWithWindow:self.sheet
									  body:TXTLS(@"Prompts[1117][2]")
									 title:TXTLS(@"Prompts[1117][1]")
							 defaultButton:TXTLS(@"Prompts[0001]")
						   alternateButton:TXTLS(@"Prompts[0002]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnPrimaryType) {
								   [self close];

								   [self setConfig:[channel config]];
								   
								   [self start];
							   }
						   }];
}

- (void)onChangedInlineMediaOption:(id)sender
{
	if ([self.enableInlineImagesCheck state] == NSOnState) {
		[TDCPreferencesController showTorAnonymityNetworkInlineMediaWarning];
	}
}

#pragma mark -
#pragma mark Actions

- (void)cancel:(id)sender
{
	[self removeConfigurationDidChangeObserver];

	[super cancel:sender];
}

- (void)ok:(id)sender
{
	[self removeConfigurationDidChangeObserver];
	
	[self save];
	
	if ([self.delegate respondsToSelector:@selector(channelPropertiesSheetOnOK:)]) {
		[self.delegate channelPropertiesSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.sheet makeFirstResponder:nil];

	if ([self.delegate respondsToSelector:@selector(channelPropertiesSheetWillClose:)]) {
		[self.delegate channelPropertiesSheetWillClose:self];
	}
}

@end
