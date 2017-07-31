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

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
@interface TDCLicenseManagerDialog ()
@property (nonatomic, weak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *contentViewUnregisteredTextualView;
@property (nonatomic, strong) IBOutlet NSView *contentViewRegisteredTextualView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSTextField *unregisteredViewLicenseKeyTextField;
@property (nonatomic, weak) IBOutlet NSTextField *unregisteredViewTrialInformationTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicenseKeyTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicenseOwnerTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicensePurchaseDateTextField;
@property (nonatomic, weak) IBOutlet NSButton *registeredViewDeactivateTextualButton;
@property (nonatomic, weak) IBOutlet NSButton *unregisteredViewActivateTextualButton;
@property (nonatomic, weak) IBOutlet NSButton *unregisteredViewCancelButton;
@property (nonatomic, weak) IBOutlet NSButton *unregisteredViewRecoveryLostLicenseButton;
@property (nonatomic, weak) IBOutlet NSImageView *unregisteredViewMacAppStoreIconImageView;
@property (nonatomic, strong, nullable) TDCProgressIndicatorSheet *progressIndicator;
@property (nonatomic, strong, nullable) TLOLicenseManagerDownloader *licenseManagerDownloader;
@property (nonatomic, strong, nullable) TDCLicenseManagerMigrateAppStoreSheet *migrateAppStoreSheet;
@property (nonatomic, strong, nullable) TDCLicenseManagerRecoverLostLicenseSheet *recoverLostLicenseSheet;
@property (nonatomic, strong, nullable) TDCLicenseUpgradeDialog *upgradeDialog;
@property (nonatomic, assign) BOOL textualIsRegistered;
@property (nonatomic, assign) BOOL isSilentOnSuccess;
@property (nonatomic, assign) BOOL operationInProgress;

- (IBAction)unregisteredViewActivateTextual:(id)sender;
- (IBAction)unregisteredViewCancel:(id)sender;
- (IBAction)unregisteredViewMigrateMacAppStorePurchase:(id)sender;
- (IBAction)unregisteredViewPurchaseTextual:(id)sender;
- (IBAction)unregisteredViewRecoveryLostLicense:(id)sender;

- (IBAction)registeredViewDeactivateTextual:(id)sender;
@end

@implementation TDCLicenseManagerDialog

#pragma mark -
#pragma mark Dialog Foundation

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return self;
}

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCLicenseManagerDialog" owner:self topLevelObjects:nil];

	[self populateMacAppStoreIconImageView];

	[self updateSelectedPane];
}

- (void)show
{
	BOOL windowVisible = self.window.visible;

	[super show];

	if (windowVisible == NO) {
		[self.window restoreWindowStateForClass:self.class];
	}
}

- (void)applicationDidFinishLaunching
{
	[self scheduleTimeRemainingInTrialNotification];

	[self activateLicenseKeyUsingArgumentDictionary];
}

- (void)populateMacAppStoreIconImageView
{
	/* Read the app store icon image from the actual App Store app so 
	 that we do not have to update it if Apple does. */
	NSBundle *appStoreApplication = [NSBundle bundleWithPath:@"/Applications/App Store.app"];

	if (appStoreApplication == nil) {
		return;
	}

	NSString *appStoreIconPath = nil;

	if (TEXTUAL_RUNNING_ON(10.12, Sierra)) {
		appStoreIconPath = [appStoreApplication pathForResource:@"AppIcon" ofType:@"icns"];
	} else {
		appStoreIconPath = [appStoreApplication pathForResource:@"appStore" ofType:@"icns"];
	}

	if (appStoreIconPath == nil) {
		return;
	}

	NSImage *appStoreIconImage = [[NSImage alloc] initWithContentsOfFile:appStoreIconPath];

	self.unregisteredViewMacAppStoreIconImageView.image = appStoreIconImage;
}

- (void)updateSelectedPane
{
	NSView *contentView = nil;

	self.textualIsRegistered = TLOLicenseManagerTextualIsRegistered();

	if (self.textualIsRegistered)
	{
		NSString *licenseKey = TLOLicenseManagerLicenseKey();
		NSString *licenseKeyOwner = TLOLicenseManagerLicenseOwnerName();
		NSString *licenseKeyCreationDate = TLOLicenseManagerLicenseCreationDateFormatted();

		self.registeredViewLicenseKeyTextField.stringValue = licenseKey;
		self.registeredViewLicenseOwnerTextField.stringValue = licenseKeyOwner;
		self.registeredViewLicensePurchaseDateTextField.stringValue = licenseKeyCreationDate;

		contentView = self.contentViewRegisteredTextualView;
	}
	else // textualIsRegistered
	{
		contentView = self.contentViewUnregisteredTextualView;

		NSString *formattedTrialInformation = [self timeRemainingInTrialFormattedMessage];

		self.unregisteredViewTrialInformationTextField.stringValue = formattedTrialInformation;
	}

	[self.contentView attachSubview:contentView
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

#pragma mark -
#pragma mark Activate License

- (void)unregisteredViewPurchaseTextual:(id)sender
{
	[menuController() openStandaloneStoreWebpage:nil];
}

- (void)unregisteredViewCancel:(id)sender
{
	[self close];
}

- (void)updateUnregisteredViewActivationButton
{
	if (self.textualIsRegistered) {
		return; // Cancel operation...
	}

	NSString *licenseKeyValue = self.unregisteredViewLicenseKeyTextField.stringValue.trim;

	if (TLOLicenseManagerLicenseKeyIsValid(licenseKeyValue)) {
		self.unregisteredViewActivateTextualButton.enabled = YES;
	} else {
		self.unregisteredViewActivateTextualButton.enabled = NO;
	}
}

- (void)unregisteredViewActivateTextual:(id)sender
{
	NSString *licenseKeyValue = self.unregisteredViewLicenseKeyTextField.stringValue;

	[self attemptToActivateLicenseKey:licenseKeyValue];
}

- (void)activateLicenseKeyUsingArgumentDictionary
{
	if (TLOLicenseManagerTextualIsRegistered()) {
		return; // Nothing to do here...
	}

	NSDictionary *commandLineArguments = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];;

	NSString *argumentLicenseKey = commandLineArguments[@"-licenseKey"];

	if (argumentLicenseKey == nil) {
		return;
	}

	[self activateLicenseKey:argumentLicenseKey silently:YES];
}

- (void)activateLicenseKey:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	[self activateLicenseKey:licenseKey silently:NO];
}

- (void)activateLicenseKey:(NSString *)licenseKey silently:(BOOL)silently
{
	NSParameterAssert(licenseKey != nil);

	/* This method is allowed to be invoked by another class in order
	 to activate a license. It is not invoked by this class on its own. */
	if (TLOLicenseManagerLicenseKeyIsValid(licenseKey)) {
		[self attemptToActivateLicenseKey:licenseKey];
	}
}

- (void)attemptToActivateLicenseKey:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	[self attemptToActivateLicenseKey:licenseKey silently:NO];
}

- (void)attemptToActivateLicenseKey:(NSString *)licenseKey silently:(BOOL)silently
{
	NSParameterAssert(licenseKey != nil);

	/* User can click a link or do something else while an activation is already in
	 progress, so we try to recognize when that happens so that we can prevent
	 confusion when an operation is already in progress. */
	/* This is the only place in the dialog where user can perform an action by
	 outside influence. Everything else is internalized which means this check is
	 only necessary here... at least for now. */
	if (self.operationInProgress) {
		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1020][2]")
										   title:TXTLS(@"TLOLicenseManager[1020][1]", licenseKey)
								   defaultButton:TXTLS(@"Prompts[0005]")
								 alternateButton:nil];

		return;
	}

	/* Do not activate license we are already using. */
	if (licenseKey == TLOLicenseManagerLicenseKey()) {
		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1021][2]")
										   title:TXTLS(@"TLOLicenseManager[1021][1]", licenseKey)
								   defaultButton:TXTLS(@"Prompts[0005]")
								 alternateButton:nil];

		return;
	}

	self.isSilentOnSuccess = silently;

	[self beginProgressIndicator];

	__weak TDCLicenseManagerDialog *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.actionBlock = ^BOOL(NSUInteger statusCode, id _Nullable statusContext) {
		return TLOLicenseManagerWriteLicenseFileContents(statusContext);
	};

	licenseManagerDownloader.errorBlock = ^BOOL(NSUInteger statusCode, id _Nullable statusContext) {
		if (statusCode != 0 || statusContext == nil) {
			return NO;
		}

		/* lastGenLicenseKey will only be non-nil if the contents of licenseContents
		 are for a license that have not been upgraded to Textual 7 yet. */
		NSString *lastGenLicenseKey = [TLOLicenseManagerLastGen licenseKeyForLicenseContents:statusContext];

		if (lastGenLicenseKey != nil) {
			[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1022][2]")
											   title:TXTLS(@"TLOLicenseManager[1022][1]", lastGenLicenseKey)
									   defaultButton:TXTLS(@"TLOLicenseManager[1022][3]")
									 alternateButton:nil];

			[weakSelf showUpgradeDialogForLicenseKey:lastGenLicenseKey];

			/* We return YES so no error is displayed except the one above. */
			return YES;
		}

		/* We did not handle the error. */
		return NO;
	};

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf licenseManagerDownloaderCompletionBlock];

		if (operationSuccessful) {
			weakSelf.unregisteredViewLicenseKeyTextField.stringValue = NSStringEmptyPlaceholder;

			[weakSelf reloadMainWindowLoadingScreen];

			/* We close the upgrade dialog if a key is activated because
			 why would we keep it around under that condition? */
			[self closeUpgradeDialog];
		}

		weakSelf.operationInProgress = NO;
	};

	licenseManagerDownloader.isSilentOnSuccess = self.isSilentOnSuccess;

	[licenseManagerDownloader activateLicense:licenseKey.trim];

	self.licenseManagerDownloader = licenseManagerDownloader;
}

#pragma mark -
#pragma mark License Upgrade

- (void)showUpgradeDialogForLicenseKey:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	if (self.upgradeDialog) {
		if ([self.upgradeDialog.licenseKey isEqualToString:licenseKey]) {
			[self.upgradeDialog show];

			return;
		} else {
			[self.upgradeDialog close];
		}
	}

	  TDCLicenseUpgradeDialog *upgradeDialog =
	[[TDCLicenseUpgradeDialog alloc] initWithLicenseKey:licenseKey];

	upgradeDialog.delegate = self;

	[upgradeDialog show];

	self.upgradeDialog = upgradeDialog;
}

- (void)closeUpgradeDialog
{
	if (self.upgradeDialog) {
		[self.upgradeDialog close];
	}
}

- (void)licenseUpgradeDialogEligibilityChanged:(TDCLicenseUpgradeDialog *)sender
{
	LogToConsoleInfo("Eligibility changed");
}

- (void)licenseUpgradeDialogWillClose:(TDCLicenseUpgradeDialog *)sender
{
	self.upgradeDialog = nil;
}

#pragma mark -
#pragma mark Recover Lost License

- (void)unregisteredViewRecoveryLostLicense:(id)sender
{
	  TDCLicenseManagerRecoverLostLicenseSheet *recoverLostLicenseSheet =
	[[TDCLicenseManagerRecoverLostLicenseSheet alloc] initWithWindow:self.window];

	recoverLostLicenseSheet.delegate = self;

	[recoverLostLicenseSheet start];

	self.recoverLostLicenseSheet = recoverLostLicenseSheet;
}

- (void)licenseManagerRecoverLostLicenseSheet:(TDCLicenseManagerRecoverLostLicenseSheet *)sender onOk:(NSString *)contactAddress
{
	__weak TDCLicenseManagerDialog *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	};

	licenseManagerDownloader.isSilentOnSuccess = self.isSilentOnSuccess;

	[licenseManagerDownloader requestLostLicenseKeyForContactAddress:contactAddress];

	self.licenseManagerDownloader = licenseManagerDownloader;
}

- (void)licenseManagerRecoverLostLicenseSheetWillClose:(TDCLicenseManagerRecoverLostLicenseSheet *)sender
{
	self.recoverLostLicenseSheet = nil;

	if (self.licenseManagerDownloader) {
		[self beginProgressIndicator];
	}
}

#pragma mark -
#pragma mark Deactivate License

- (void)registeredViewDeactivateTextual:(id)sender
{
	BOOL deactivateCopy = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"TLOLicenseManager[1007][2]")
															 title:TXTLS(@"TLOLicenseManager[1007][1]")
													 defaultButton:TXTLS(@"Prompts[0001]")
												   alternateButton:TXTLS(@"Prompts[0002]")];

	if (deactivateCopy == NO) {
		return; // Cancel operation...
	}

	/* License deactivation does not use a progress indicator because
	 it does not have to touch the network. It will only delete a file
	 on the hard drive which is typically instant. */
	__weak TDCLicenseManagerDialog *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.actionBlock = ^BOOL(NSUInteger statusCode, id _Nullable statusContext) {
		return TLOLicenseManagerDeleteLicenseFile();
	};

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf licenseManagerDownloaderCompletionBlock];

		[weakSelf reloadMainWindowLoadingScreen];
	};

	licenseManagerDownloader.isSilentOnSuccess = self.isSilentOnSuccess;

	[licenseManagerDownloader deactivateLicense];

	self.licenseManagerDownloader = licenseManagerDownloader;
}

#pragma mark -
#pragma mark Mac App Store Receipt Processing

- (void)unregisteredViewMigrateMacAppStorePurchase:(id)sender
{
	  TDCLicenseManagerMigrateAppStoreSheet *migrateAppStoreSheet =
	[[TDCLicenseManagerMigrateAppStoreSheet alloc] initWithWindow:self.window];

	migrateAppStoreSheet.delegate = self;

	[migrateAppStoreSheet start];

	self.migrateAppStoreSheet = migrateAppStoreSheet;
}

- (void)licenseManagerMigrateAppStoreSheet:(TDCLicenseManagerMigrateAppStoreSheet *)sender
							convertReceipt:(NSString *)receiptData
						  licenseOwnerName:(NSString *)licenseOwnerName
				licenseOwnerContactAddress:(NSString *)licenseOwnerContactAddress
{
	__weak TDCLicenseManagerDialog *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	};

	licenseManagerDownloader.isSilentOnSuccess = self.isSilentOnSuccess;

	[licenseManagerDownloader migrateMacAppStorePurcahse:receiptData
											 licenseOwnerName:licenseOwnerName
								   licenseOwnerContactAddress:licenseOwnerContactAddress];

	self.licenseManagerDownloader = licenseManagerDownloader;
}

- (void)licenseManagerMigrateAppStoreSheetWillClose:(TDCLicenseManagerMigrateAppStoreSheet *)sender
{
	self.migrateAppStoreSheet = nil;

	if (self.licenseManagerDownloader) {
		[self beginProgressIndicator];
	}
}

#pragma mark -
#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification *)obj
{
	if (obj.object == self.unregisteredViewLicenseKeyTextField) {
		[self updateUnregisteredViewActivationButton];
	}
}

#pragma mark -
#pragma mark Helper Methods

- (void)reloadMainWindowLoadingScreen
{
	(void)[mainWindow() reloadLoadingScreen];
}

- (void)licenseManagerDownloaderCompletionBlock
{
	self.licenseManagerDownloader = nil;

	[self endProgressIndicator];

	[self updateSelectedPane];

	[self updateUnregisteredViewActivationButton];

	self.isSilentOnSuccess = NO; // Reset flag regardless of state.
								 // This flag is one-time use.
}

- (void)beginProgressIndicator
{
	self.progressIndicator = [[TDCProgressIndicatorSheet alloc] initWithWindow:self.window];

	[self.progressIndicator start];
}

- (void)endProgressIndicator
{
	if (self.progressIndicator == nil) {
		return;
	}

	[self.progressIndicator stop];

	self.progressIndicator = nil;
}

#pragma mark -
#pragma mark Notification Center

- (NSString *)timeRemainingInTrialFormattedMessage
{
	NSTimeInterval timeLeft = TLOLicenseManagerTimeReaminingInTrial();

	if (timeLeft >= 0) {
		return TXTLS(@"TLOLicenseManager[1016]");
	}

	NSString *formattedTimeRemainingString = TXHumanReadableTimeInterval(timeLeft, YES, NSCalendarUnitDay);

	return TXTLS(@"TLOLicenseManager[1015]", formattedTimeRemainingString);
}

- (void)scheduleTimeRemainingInTrialNotification
{
	if (TLOLicenseManagerIsTrialExpired()) {
		return; // Do not schedule notification...
	}

	NSUserNotification *notification = [NSUserNotification new];

	notification.deliveryDate = [NSDate date];

	notification.informativeText = TXTLS(@"TLOLicenseManager[1017][2]");

	notification.title = [self timeRemainingInTrialFormattedMessage];

	notification.userInfo = @{@"isLicenseManagerTimeRemainingInTrialNotification" : @(YES)};

	if (TEXTUAL_RUNNING_ON(10.9, Mavericks)) {
		[notification setValue:@(YES) forKey:@"_showsButtons"];

		notification.actionButtonTitle = TXTLS(@"TLOLicenseManager[1017][3]");
	}

	[RZUserNotificationCenter() scheduleNotification:notification];
}

#pragma mark -
#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.window saveWindowStateForClass:self.class];
}

@end
#endif

NS_ASSUME_NONNULL_END
