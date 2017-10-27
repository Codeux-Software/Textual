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

#import "NSObjectHelperPrivate.h"
#import "NSStringHelper.h"
#import "NSViewHelper.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TPCPreferencesLocal.h"
#import "TLOLanguagePreferences.h"
#import "TLOPopupPrompts.h"
#import "TVCNotificationConfigurationViewControllerPrivate.h"
#import "TVCTextFieldWithValueValidation.h"
#import "TDCPreferencesControllerPrivate.h"
#import "TDCChannelPropertiesNotificationConfigurationPrivate.h"
#import "TDCChannelPropertiesSheetInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCChannelPropertiesSheet ()
@property (nonatomic, strong, readwrite, nullable) IRCClient *client;
@property (nonatomic, strong, readwrite, nullable) IRCChannel *channel;
@property (nonatomic, copy, readwrite, nullable) NSString *clientId;
@property (nonatomic, copy, readwrite, nullable) NSString *channelId;
@property (nonatomic, assign) BOOL isNewConfiguration;
@property (nonatomic, copy) NSArray *navigationTree;
@property (nonatomic, weak) IBOutlet NSButton *autoJoinCheck;
@property (nonatomic, weak) IBOutlet NSButton *disableInlineMediaCheck;
@property (nonatomic, weak) IBOutlet NSButton *enableInlineMediaCheck;
@property (nonatomic, weak) IBOutlet NSButton *pushNotificationsCheck;
@property (nonatomic, weak) IBOutlet NSButton *showTreeBadgeCountCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreHighlightsCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreGeneralEventMessagesCheck;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *contentViewTabView;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *channelNameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *defaultModesTextField;
@property (nonatomic, weak) IBOutlet NSTextField *defaultTopicTextField;
@property (nonatomic, weak) IBOutlet NSTextField *secretKeyTextField;
@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultsView;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneralView;
@property (nonatomic, strong) IBOutlet NSView *contentViewNotifications;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, strong) IBOutlet TVCNotificationConfigurationViewController *notificationsController;

- (IBAction)onMenuBarItemChanged:(id)sender;

- (IBAction)onInlineMediaCheckChanged:(id)sender;
- (IBAction)onPushNotificationsCheckChanged:(id)sender;
@end

@implementation TDCChannelPropertiesSheet

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	return [self initWithConfig:nil onClientWithId:nil];
}

- (instancetype)initWithClient:(IRCClient *)client
{
	return [self initWithConfig:nil onClient:client];
}

- (instancetype)initWithClientId:(NSString *)clientId
{
	return [self initWithConfig:nil onClientWithId:clientId];
}

- (instancetype)initWithChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ((self = [super init])) {
		self.client = channel.associatedClient;
		self.clientId = channel.associatedClient.uniqueIdentifier;

		self.channel = channel;
		self.channelId = channel.uniqueIdentifier;

		if (channel) {
			self.config = [channel.config mutableCopy];
		} else {
			self.config = [IRCChannelConfigMutable new];
		}

		[self prepareInitialState];

		[self loadConfig];

		return self;
	}

	return nil;
}

- (instancetype)initWithConfig:(nullable IRCChannelConfig *)config
{
	return [self initWithConfig:config onClientWithId:nil];
}

- (instancetype)initWithConfig:(nullable IRCChannelConfig *)config onClient:(nullable IRCClient *)client
{
	if ((self = [super init])) {
		self.client = client;
		self.clientId = client.uniqueIdentifier;

		if (config) {
			self.config = [config mutableCopy];
		} else {
			self.config = [IRCChannelConfigMutable new];
		}

		[self prepareInitialState];

		[self loadConfig];

		return self;
	}

	return nil;
}

- (instancetype)initWithConfig:(nullable IRCChannelConfig *)config onClientWithId:(nullable NSString *)clientId
{
	if ((self = [super init])) {
		self.clientId = clientId;

		if (config) {
			self.config = [config mutableCopy];
		} else {
			self.config = [IRCChannelConfigMutable new];
		}

		[self prepareInitialState];

		[self loadConfig];

		return self;
	}

	return nil;
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCChannelPropertiesSheet" owner:self topLevelObjects:nil];

	self.navigationTree = @[
		//		view								first responder
		@[self.contentViewGeneralView,			self.channelNameTextField],
		@[self.contentViewDefaultsView,			self.defaultTopicTextField],
		@[self.contentViewNotifications,		[NSNull null]],
	];

	self.channelNameTextField.onlyShowStatusIfErrorOccurs = YES;

	self.channelNameTextField.stringValueIsInvalidOnEmpty = YES;
	self.channelNameTextField.stringValueUsesOnlyFirstToken = YES;

	self.channelNameTextField.textDidChangeCallback = self;

	self.channelNameTextField.validationBlock = ^(NSString *currentValue) {
		return currentValue.isChannelName;
	};

	[self addConfigurationDidChangeObserver];

	[self setupNotificationsController];
}

- (void)setupNotificationsController
{
	self.notificationsController.allowsMixedState = YES;

	NSMutableArray *notifications = [NSMutableArray array];

	[notifications addObject:[[TDCChannelPropertiesNotificationConfiguration alloc] initWithEventType:TXNotificationHighlightType inSheet:self]];
	[notifications addObject:@" "];
	[notifications addObject:[[TDCChannelPropertiesNotificationConfiguration alloc] initWithEventType:TXNotificationChannelMessageType inSheet:self]];
	[notifications addObject:[[TDCChannelPropertiesNotificationConfiguration alloc] initWithEventType:TXNotificationChannelNoticeType inSheet:self]];
	[notifications addObject:@" "];
	[notifications addObject:[[TDCChannelPropertiesNotificationConfiguration alloc] initWithEventType:TXNotificationUserJoinedType inSheet:self]];
	[notifications addObject:[[TDCChannelPropertiesNotificationConfiguration alloc] initWithEventType:TXNotificationUserPartedType inSheet:self]];

	self.notificationsController.notifications = notifications;

	[self.notificationsController attachToView:self.contentViewNotifications];
}

- (void)reloadNotificationsController
{
	[self.notificationsController reload];
}

- (void)updateNavigationEnabledState
{
	#define _navigationIndexForNotifications			2

	[self.contentViewTabView setEnabled:(self.pushNotificationsCheck.state == NSOnState)
							 forSegment:_navigationIndexForNotifications];
}

- (void)loadConfig
{
	self.channelNameTextField.stringValue = self.config.channelName;

	self.defaultModesTextField.stringValue = self.config.defaultModes;
	self.defaultTopicTextField.stringValue = self.config.defaultTopic;

	self.secretKeyTextField.stringValue = self.config.secretKey;

	self.autoJoinCheck.state = self.config.autoJoin;
	self.pushNotificationsCheck.state = self.config.pushNotifications;
	self.showTreeBadgeCountCheck.state = self.config.showTreeBadgeCount;

	self.ignoreGeneralEventMessagesCheck.state = self.config.ignoreGeneralEventMessages;
	self.ignoreHighlightsCheck.state = self.config.ignoreHighlights;

	if ([TPCPreferences showInlineMedia]) {
		self.disableInlineMediaCheck.state = self.config.ignoreInlineMedia;
	} else {
		self.enableInlineMediaCheck.state = self.config.ignoreInlineMedia;
	}

	[self updateNavigationEnabledState];
}

- (void)onMenuBarItemChanged:(id)sender
{
	[self navigateToIndex:[sender indexOfSelectedItem]];
}

- (void)navigateToIndex:(NSUInteger)row
{
	[self selectPane:self.navigationTree[row][0]];

	id firstResponder = self.navigationTree[row][1];

	if ([firstResponder isKindOfClass:[NSControl class]]) {
		[self.sheet makeFirstResponder:firstResponder];
	}
}

- (void)selectPane:(NSView *)view
{
	[self.contentView attachSubview:view
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

- (void)start
{
	[self navigateToIndex:0];

	[self startSheet];
}

- (void)updateOkButton
{
	self.okButton.enabled = self.channelNameTextField.valueIsValid;

	self.channelNameTextField.editable = (self.config.channelName.length == 0);
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self updateOkButton];
}

- (void)addConfigurationDidChangeObserver
{
	if (self.channel == nil) {
		return;
	}

	[RZNotificationCenter() addObserver:self
							   selector:@selector(underlyingConfigurationChanged:)
								   name:IRCChannelConfigurationWasUpdatedNotification
								 object:self.channel];
}

- (void)removeConfigurationDidChangeObserver
{
	[RZNotificationCenter() removeObserver:self];
}

- (void)underlyingConfigurationChanged:(NSNotification *)notification
{
	IRCChannel *channel = notification.object;

	NSWindow *window = self.sheet;

	[TLOPopupPrompts sheetWindowWithWindow:window
									  body:TXTLS(@"Prompts[1117][2]")
									 title:TXTLS(@"Prompts[1117][1]")
							 defaultButton:TXTLS(@"Prompts[0001]")
						   alternateButton:TXTLS(@"Prompts[0002]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked != TLOPopupPromptReturnPrimaryType) {
								   return;
							   }

							   [self close];

							   self.config = [channel.config copy];

							   [self loadConfig];

							   [self reloadNotificationsController];

							   [self start];
						   }];
}

- (void)onInlineMediaCheckChanged:(id)sender
{
	if (self.enableInlineMediaCheck.state != NSOnState) {
		return;
	}

	[TDCPreferencesController showTorAnonymityNetworkInlineMediaWarning];
}

- (void)onPushNotificationsCheckChanged:(id)sender
{
	[self updateNavigationEnabledState];
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

	self.config.channelName = self.channelNameTextField.value;

	self.config.defaultModes = self.defaultModesTextField.trimmedStringValue;
	self.config.defaultTopic = self.defaultTopicTextField.trimmedStringValue;

	self.config.secretKey = self.secretKeyTextField.trimmedFirstTokenStringValue;

	self.config.autoJoin = self.autoJoinCheck.state;
	self.config.pushNotifications = self.pushNotificationsCheck.state;
	self.config.showTreeBadgeCount = self.showTreeBadgeCountCheck.state;

	self.config.ignoreGeneralEventMessages = self.ignoreGeneralEventMessagesCheck.state;
	self.config.ignoreHighlights = self.ignoreHighlightsCheck.state;

	if ([TPCPreferences showInlineMedia]) {
		self.config.ignoreInlineMedia = self.disableInlineMediaCheck.state;
	} else {
		self.config.ignoreInlineMedia = self.enableInlineMediaCheck.state;
	}

	if ([self.delegate respondsToSelector:@selector(channelPropertiesSheet:onOk:)]) {
		[self.delegate channelPropertiesSheet:self onOk:[self.config copy]];
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

NS_ASSUME_NONNULL_END
