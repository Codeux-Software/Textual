/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

@interface TVCNotificationConfigurationViewController ()
@property (nonatomic, weak) NSView *attachedView;
@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, weak) IBOutlet NSButton *alertBounceDockIconButton;
@property (nonatomic, weak) IBOutlet NSButton *alertBounceDockIconRepeatedlyButton;
@property (nonatomic, weak) IBOutlet NSButton *alertDisableWhileAwayButton;
@property (nonatomic, weak) IBOutlet NSButton *alertPushNotificationButton;
@property (nonatomic, weak) IBOutlet NSButton *alertSpeakEventButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *alertSoundChoiceButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *alertTypeChoiceButton;
@property (nonatomic, weak) IBOutlet NSTextField *alertNotificationDestinationTextField;
@property (nonatomic, strong) TLONotificationConfiguration *activeAlert;
@property (nonatomic, copy) NSArray *alertSounds;

- (IBAction)onChangedAlertBounceDockIcon:(id)sender;
- (IBAction)onChangedAlertBounceDockIconRepeatedly:(id)sender;
- (IBAction)onChangedAlertDisableWhileAway:(id)sender;
- (IBAction)onChangedAlertPushNotification:(id)sender;
- (IBAction)onChangedAlertSound:(id)sender;
- (IBAction)onChangedAlertSpoken:(id)sender;
- (IBAction)onChangedAlertType:(id)sender;
@end

@implementation TVCNotificationConfigurationViewController

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[RZMainBundle() loadNibNamed:@"TVCNotificationConfigurationView" owner:self topLevelObjects:nil];

	[self updateAvailableSounds];

	if ([GrowlApplicationBridge isGrowlRunning]) {
		self.alertNotificationDestinationTextField.stringValue = TXTLS(@"TVCNotificationConfigurationView[1000]");
	} else {
		self.alertNotificationDestinationTextField.stringValue = TXTLS(@"TVCNotificationConfigurationView[1001]");
	}
}

- (void)attachToView:(NSView *)view
{
	NSParameterAssert(view != nil);

	if (self.attachedView == nil) {
		self.attachedView = view;
	} else {
		NSAssert(NO, @"View is already attached to a view");
	}

	NSView *contentView = self.contentView;

	[view addSubview:contentView];

	[view addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[contentView]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(contentView)]];

	[view addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(contentView)]];
}

- (void)setAllowsMixedState:(BOOL)allowsMixedState
{
	if (self->_allowsMixedState != allowsMixedState) {
		self->_allowsMixedState = allowsMixedState;

		[self updateMixedState];
	}
}

- (void)updateMixedState
{
	BOOL allowsMixedState = self.allowsMixedState;

	self.alertSpeakEventButton.allowsMixedState = allowsMixedState;
	self.alertBounceDockIconButton.allowsMixedState = allowsMixedState;
	self.alertBounceDockIconRepeatedlyButton.allowsMixedState = allowsMixedState;
	self.alertDisableWhileAwayButton.allowsMixedState = allowsMixedState;
	self.alertPushNotificationButton.allowsMixedState = allowsMixedState;
}

- (void)setNotifications:(NSArray *)notifications
{
	if (self->_notifications != notifications) {
		self->_notifications = [notifications copy];

		[self availableAlertsChanged];
	}
}

- (void)availableAlertsChanged
{
	if (self.notifications.count == 0) {
		[self resetControls];
	} else {
		[self updateAlertSelection];
	}
}

- (void)resetControls
{
	[self.alertTypeChoiceButton removeAllItems];

	self.alertSpeakEventButton.state = NSOffState;
	self.alertBounceDockIconButton.state = NSOffState;
	self.alertBounceDockIconRepeatedlyButton.enabled = NO;
	self.alertBounceDockIconRepeatedlyButton.state = NSOffState;
	self.alertDisableWhileAwayButton.state = NSOffState;
	self.alertPushNotificationButton.state = NSOffState;

	[self.alertSoundChoiceButton removeAllItems];
}

- (void)updateAlertSelection
{
	[self.alertTypeChoiceButton removeAllItems];

	[self.notifications enumerateObjectsUsingBlock:^(id alert, NSUInteger index, BOOL *stop) {
		if ([alert isKindOfClass:[TLONotificationConfiguration class]]) {
			NSMenuItem *item = [NSMenuItem new];

			item.tag = index;

			item.title = [alert displayName];

			[self.alertTypeChoiceButton.menu addItem:item];
		} else {
			[self.alertTypeChoiceButton.menu addItem:[NSMenuItem separatorItem]];
		}
	}];

	[self.alertTypeChoiceButton selectItemAtIndex:0];

	[self onChangedAlertType:nil];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertTag = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

	TLONotificationConfiguration *alert = self.notifications[alertTag];

	self.alertSpeakEventButton.state = alert.speakEvent;
	self.alertBounceDockIconButton.state = alert.bounceDockIcon;
	self.alertBounceDockIconRepeatedlyButton.enabled = (self.alertBounceDockIconButton.state == NSOnState);
	self.alertBounceDockIconRepeatedlyButton.state = alert.bounceDockIconRepeatedly;
	self.alertDisableWhileAwayButton.state = alert.disabledWhileAway;
	self.alertPushNotificationButton.state = alert.pushNotification;

	NSUInteger soundIndex = [self.alertSounds indexOfObject:alert.alertSound];

	if (soundIndex == NSNotFound) {
		[self.alertSoundChoiceButton selectItemAtIndex:0];
	} else {
		[self.alertSoundChoiceButton selectItemAtIndex:soundIndex];
	}

	self.activeAlert = alert;
}

- (void)onChangedAlertPushNotification:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	alert.pushNotification = self.alertPushNotificationButton.state;
}

- (void)onChangedAlertSpoken:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	alert.speakEvent = self.alertSpeakEventButton.state;
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	alert.disabledWhileAway = self.alertDisableWhileAwayButton.state;
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	alert.bounceDockIcon = self.alertBounceDockIconButton.state;

	self.alertBounceDockIconRepeatedlyButton.enabled = (self.alertBounceDockIconButton.state == NSOnState);
}

- (void)onChangedAlertBounceDockIconRepeatedly:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	alert.bounceDockIconRepeatedly = self.alertBounceDockIconRepeatedlyButton.state;
}

- (void)onChangedAlertSound:(id)sender
{
	TLONotificationConfiguration *alert = self.activeAlert;

	NSString *alertSound = self.alertSoundChoiceButton.titleOfSelectedItem;

	if ([alertSound isEqualToString:[TLONotificationConfiguration localizedAlertEmptySoundTitle]]) { // Do not set the default, none label
		alertSound = TXEmptyAlertSoundPreferenceValue;
	}

	if (alertSound) {
		[TLOSoundPlayer playAlertSound:alertSound];
	}

	alert.alertSound = alertSound;
}

- (void)updateAvailableSounds
{
	[self.alertSoundChoiceButton removeAllItems];

	self.alertSounds = [self availableSounds];

	[self.alertSounds enumerateObjectsUsingBlock:^(id alertSound, NSUInteger index, BOOL *stop) {
		if ([alertSound isKindOfClass:[NSString class]]) {
			NSMenuItem *item = [NSMenuItem new];

			item.title = alertSound;

			[self.alertSoundChoiceButton.menu addItem:item];
		} else {
			[self.alertSoundChoiceButton.menu addItem:alertSound];
		}
	}];

	[self.alertSoundChoiceButton selectItemAtIndex:0];
}

- (NSArray *)availableSounds
{
	NSMutableArray *sounds = [NSMutableArray array];

	[sounds addObject:[TLONotificationConfiguration localizedAlertEmptySoundTitle]];

	[sounds addObject:[NSMenuItem separatorItem]];

	[sounds addObjectsFromArray:[TLOSoundPlayer uniqueListOfSounds]];

	return [sounds copy];
}

@end

NS_ASSUME_NONNULL_END
