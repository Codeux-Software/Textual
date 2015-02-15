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

#define _windowPadding					98
#define _windowStaringPosition			61

@interface TDChannelSheet ()
/* Each entry of the array is an array with index 0 equal to the
 view and index 1 equal to the first responder wanted in that view. */
@property (nonatomic, strong) NSArray *navigationTree;
@property (nonatomic, nweak) IBOutlet NSButton *JPQActivityCheck;
@property (nonatomic, nweak) IBOutlet NSButton *autoJoinCheck;
@property (nonatomic, nweak) IBOutlet NSButton *disableInlineImagesCheck;
@property (nonatomic, nweak) IBOutlet NSButton *enableInlineImagesCheck;
@property (nonatomic, nweak) IBOutlet NSButton *ignoreHighlightsCheck;
@property (nonatomic, nweak) IBOutlet NSButton *pushNotificationsCheck;
@property (nonatomic, nweak) IBOutlet NSButton *showTreeBadgeCountCheck;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *encryptionModeOfOperationPopup;
@property (nonatomic, nweak) IBOutlet NSSegmentedControl *contentViewTabView;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *channelNameField;
@property (nonatomic, nweak) IBOutlet NSTextField *defaultModesField;
@property (nonatomic, nweak) IBOutlet NSTextField *defaultTopicField;
@property (nonatomic, nweak) IBOutlet NSTextField *encryptionKeyField;
@property (nonatomic, nweak) IBOutlet NSTextField *secretKeyField;
@property (nonatomic, nweak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *defaultsView;
@property (nonatomic, strong) IBOutlet NSView *encryptionView;
@property (nonatomic, strong) IBOutlet NSView *generalView;
@end

@implementation TDChannelSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDChannelSheet" owner:self topLevelObjects:nil];
		
		IRCChannel *channel = [worldController() findChannelByClientId:self.clientID channelId:self.channelID];
		
		[RZNotificationCenter() addObserver:self
								   selector:@selector(underlyingConfigurationChanged:)
									   name:IRCChannelConfigurationWasUpdatedNotification
									 object:channel];
		
		self.navigationTree = @[
			//    view				  first responder
			@[self.generalView,			self.channelNameField],
			@[self.encryptionView,		self.encryptionKeyField],
			@[self.defaultsView,		self.defaultTopicField],
		];
		
		[self.channelNameField setOnlyShowStatusIfErrorOccurs:YES];
		[self.channelNameField setStringValueUsesOnlyFirstToken:YES];
		[self.channelNameField setStringValueIsInvalidOnEmpty:YES];
		
		[self.channelNameField setTextDidChangeCallback:self];
		
		[self.channelNameField setValidationBlock:^(NSString *currentValue) {
			return [currentValue isChannelName];
		}];
	}

	return self;
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender
{
	/* Get selected tab. */
	NSInteger row = [sender indexOfSelectedItem];
	
	/* Switch to that view. */
	[self firstPane:(self.navigationTree[row][0])];
	
	/* Move to appropriate first responder. */
	[self.sheet makeFirstResponder:(self.navigationTree[row][1])];
}

- (NSRect)currentSheetFrame
{
	return [self.sheet frame];
}

- (void)firstPane:(NSView *)view 
{
	/* Modify frame to match new view. */
	NSRect windowFrame = [self currentSheetFrame];
	
	windowFrame.size.width  =  view.frame.size.width;
	windowFrame.size.height = (view.frame.size.height + _windowPadding);

	windowFrame.origin.y = (NSMaxY([self currentSheetFrame]) - windowFrame.size.height);
	
	/* Remove any old subviews. */
	NSArray *subviews = [self.contentView subviews];
	
	if ([subviews count] > 0) {
		[subviews[0] removeFromSuperview];
	}
	
	/* Set new frame. */
	[self.sheet setFrame:windowFrame display:YES animate:YES];
	
	NSRect viewFrame = [view frame];
	
	viewFrame.origin.y = _windowStaringPosition;
	
	[self.contentView setFrame:viewFrame];
	
	/* Add new view. */
	[self.contentView addSubview:view];
	
	/* Reclaulate loop for tab key. */
	[self.sheet recalculateKeyViewLoop];
}

#pragma mark -
#pragma mark KVC Properties

- (id)userDefaultsValues
{
	return RZUserDefaultsValueProxy();
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start
{
	[self load];
	[self update];
	
	[self startSheet];
	
	[self.contentViewTabView setSelectedSegment:0];
	
	[self onMenuBarItemChanged:self.contentViewTabView];
}

- (void)load
{
	[self.channelNameField setStringValue:[self.config channelName]];
	
	[self.defaultModesField setStringValue:[self.config defaultModes]];
	[self.defaultTopicField setStringValue:[self.config defaultTopic]];
	
	[self.encryptionKeyField setStringValue:[self.config encryptionKeyValue]];
	
	[self.secretKeyField setStringValue:[self.config secretKeyValue]];
	
	[self.encryptionModeOfOperationPopup selectItemWithTag:[self.config encryptionModeOfOperation]];

	[self.autoJoinCheck	setState:[self.config autoJoin]];
	[self.JPQActivityCheck setState:[self.config ignoreJPQActivity]];
	[self.ignoreHighlightsCheck	setState:[self.config ignoreHighlights]];
	[self.pushNotificationsCheck setState:[self.config pushNotifications]];
	[self.showTreeBadgeCountCheck setState:[self.config showTreeBadgeCount]];

	if ([TPCPreferences showInlineImages]) {
		[self.disableInlineImagesCheck setState:[self.config ignoreInlineImages]];
	} else {
		[self.enableInlineImagesCheck setState:[self.config ignoreInlineImages]];
	}
}

- (void)save
{
	[self.config setChannelName:[self.channelNameField value]];
	
	[self.config setDefaultModes:[self.defaultModesField trimmedStringValue]];
	[self.config setDefaultTopic:[self.defaultTopicField trimmedStringValue]];
	
	[self.config setSecretKey:[self.secretKeyField firstTokenStringValue]];
	[self.config setEncryptionKey:[self.encryptionKeyField trimmedStringValue]];
	
	[self.config setEncryptionModeOfOperation:[self.encryptionModeOfOperationPopup selectedTag]];
	
	[self.config setAutoJoin:[self.autoJoinCheck state]];
	[self.config setIgnoreJPQActivity:[self.JPQActivityCheck state]];
	[self.config setIgnoreHighlights:[self.ignoreHighlightsCheck state]];
	[self.config setPushNotifications:[self.pushNotificationsCheck state]];
	[self.config setShowTreeBadgeCount:[self.showTreeBadgeCountCheck state]];

	if ([TPCPreferences showInlineImages]) {
		[self.config setIgnoreInlineImages:[self.disableInlineImagesCheck state]];
	} else {
		[self.config setIgnoreInlineImages:[self.enableInlineImagesCheck state]];
	}
}

- (void)update
{
	[self.okButton setEnabled:[self.channelNameField valueIsValid]];
	
	[self.channelNameField setEditable:self.newItem];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self update];
}

- (void)close
{
	[self cancel:nil];
}

- (void)updateUnderlyingConfigurationProfileCallback:(TLOPopupPromptReturnType)returnType withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnType == TLOPopupPromptReturnPrimaryType) {
		IRCChannel *channel = [worldController() findChannelByClientId:self.clientID channelId:self.channelID];
		
		[self close];
		
		self.config = [channel config];
		
		[self start];
	}
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	TLOPopupPrompts *popup = [TLOPopupPrompts new];
	
	[popup sheetWindowWithQuestion:self.sheet
							target:self
							action:@selector(updateUnderlyingConfigurationProfileCallback:withOriginalAlert:)
							  body:TXTLS(@"BasicLanguage[1241][2]", self.config.channelName)
							 title:TXTLS(@"BasicLanguage[1241][1]")
					 defaultButton:TXTLS(@"BasicLanguage[1241][3]")
				   alternateButton:TXTLS(@"BasicLanguage[1241][4]")
					   otherButton:nil
					suppressionKey:nil
				   suppressionText:nil];
}

#pragma mark -
#pragma mark Actions

- (void)cancel:(id)sender
{
	[RZNotificationCenter() removeObserver:self];

	[super cancel:sender];
}

- (void)ok:(id)sender
{
	[RZNotificationCenter() removeObserver:self];

	[self save];
	
	if ([self.delegate respondsToSelector:@selector(channelSheetOnOK:)]) {
		[self.delegate channelSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(channelSheetWillClose:)]) {
		[self.delegate channelSheetWillClose:self];
	}
}

@end
