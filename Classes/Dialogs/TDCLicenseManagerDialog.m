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

#import "TLOLicenseManager.h"
#import "TLOLicenseManagerDownloader.h"

#import "TDCLicenseManagerDialog.h"

#import "TDCLicenseManagerMigrateAppStoreSheet.h"
#import "TDCLicenseManagerRecoverLostLicenseSheet.h"

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
@property (nonatomic, strong) TDCProgressInformationSheet *progressSheet;
@property (nonatomic, strong) TLOLicenseManagerDownloader *licenseManagerDownloader;
@property (nonatomic, strong) TDCLicenseManagerMigrateAppStoreSheet *migrateAppStoreSheet;
@property (nonatomic, strong) TDCLicenseManagerRecoverLostLicenseSheet *recoverLostLicenseSheet;
@property (nonatomic, assign) BOOL textualIsRegistered;

- (IBAction)unregisteredViewCancel:(id)sender;
- (IBAction)unregisteredViewActivateTextual:(id)sender;
- (IBAction)unregisteredViewPurchaseTextual:(id)sender;
- (IBAction)unregisteredViewRecoveryLostLicense:(id)sender;
- (IBAction)unregisteredViewMigrateMacAppStorePurchase:(id)sender;

- (IBAction)registeredViewDeactivateTextual:(id)sender;
@end

@implementation TDCLicenseManagerDialog

#pragma mark -
#pragma mark Dialog Foundation

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCLicenseManagerDialog" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)show
{
	[[self window] makeKeyAndOrderFront:nil];

	[self populateMacAppStoreIconImageView];

	[self updateSelectedPane];
}

+ (void)applicationDidFinishLaunching
{
	[self activateLicenseKeyUsingArgumentDictionary];
}

- (void)populateMacAppStoreIconImageView
{
	/* Read the app store icon image from the actual App Store app so 
	 that we do not have to update it if Apple does. */
	NSBundle *appStoreApplication = [NSBundle bundleWithPath:@"/Applications/App Store.app"];

	if (appStoreApplication) {
		NSString *appStoreIconPath = [appStoreApplication pathForResource:@"appStore" ofType:@"icns"];

		if (appStoreIconPath) {
			NSImage *appStoreIconImage = [[NSImage alloc] initWithContentsOfFile:appStoreIconPath];

			[self.unregisteredViewMacAppStoreIconImageView setImage:appStoreIconImage];
		}
	}
}

- (void)updateSelectedPane
{
	NSView *contentView = nil;

		self.textualIsRegistered = TLOLicenseManagerTextualIsRegistered();

	if (self.textualIsRegistered) {
		NSString *licenseKey = TLOLicenseManagerLicenseKey();

		NSString *licenseKeyOwner = TLOLicenseManagerLicenseOwnerName();

		NSString *licenseKeyCreationDate = TLOLicenseManagerLicenseCreationDateFormatted();

		[self.registeredViewLicenseKeyTextField setStringValue:licenseKey];

		[self.registeredViewLicenseOwnerTextField setStringValue:licenseKeyOwner];

		[self.registeredViewLicensePurchaseDateTextField setStringValue:licenseKeyCreationDate];

		contentView = self.contentViewRegisteredTextualView;
	} else {
		contentView = self.contentViewUnregisteredTextualView;

		NSString *formattedTrialInformation = [TDCLicenseManagerDialog timeRemainingInTrialFormattedMessage];

		[self.unregisteredViewTrialInformationTextField setStringValue:formattedTrialInformation];
	}

	[self.contentView attachSubview:contentView
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

#pragma mark -
#pragma mark Activate License

- (void)unregisteredViewPurchaseTextual:(id)sender
{
	[menuController() openFastSpringStoreWebpage:nil];
}

- (void)unregisteredViewCancel:(id)sender
{
	[[self window] close];
}

- (void)updateUnregisteredViewActivationButton
{
	if (self.textualIsRegistered) {
		return; // Cancel operation...
	}

	NSString *licenseKeyValue = [self.unregisteredViewLicenseKeyTextField stringValue];

	if (TLOLicenseManagerLicenseKeyIsValid(licenseKeyValue)) {
		[self.unregisteredViewActivateTextualButton setEnabled:YES];
	} else {
		[self.unregisteredViewActivateTextualButton setEnabled:NO];
	}
}

- (void)unregisteredViewActivateTextual:(id)sender
{
	NSString *licenseKeyValue = [self.unregisteredViewLicenseKeyTextField stringValue];

	[self attemptToActivateLicenseKey:licenseKeyValue];
}

+ (void)activateLicenseKeyUsingArgumentDictionary
{
	if (TLOLicenseManagerTextualIsRegistered()) {
		return; // Nothing to do here...
	}

	NSDictionary *commandLineArguments = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];;

	NSString *argumentLicenseKey = commandLineArguments[@"-licenseKey"];

	if (argumentLicenseKey) {
		[menuController() manageLicense:nil activateLicenseKey:argumentLicenseKey licenseKeyPassedByArgument:YES];
	} else {
		[self scheduleTimeRemainingInTrialNotification];
	}
}

- (void)activateLicenseKey:(NSString *)licenseKey
{
	/* This method is allowed to be invoked by another class in order
	 to activate a license. It is not invoked by this class on its own. */

	if (TLOLicenseManagerLicenseKeyIsValid(licenseKey)) {
		[self attemptToActivateLicenseKey:licenseKey];
	}
}

- (void)attemptToActivateLicenseKey:(NSString *)licenseKey
{
	[self beginProgressIndicator];

	__weak TDCLicenseManagerDialog *weakSelf = self;

	self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setIsSilentOnSuccess:self.isSilentOnSuccess];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];

		if (operationSuccessful) {
			[[weakSelf unregisteredViewLicenseKeyTextField] setStringValue:NSStringEmptyPlaceholder];

			[weakSelf reloadMainWindowLoadingScreen];
		}
	}];

	[self.licenseManagerDownloader activateLicense:licenseKey];
}

#pragma mark -
#pragma mark Recover Lost License

- (void)unregisteredViewRecoveryLostLicense:(id)sender
{
	 self.recoverLostLicenseSheet = [TDCLicenseManagerRecoverLostLicenseSheet new];

	[self.recoverLostLicenseSheet setWindow:[self window]];

	[self.recoverLostLicenseSheet setDelegate:self];

	[self.recoverLostLicenseSheet start];
}

- (void)licenseManagerRecoverLostLicenseSheet:(TDCLicenseManagerRecoverLostLicenseSheet *)sender onOk:(NSString *)contactAddress
{
	__weak TDCLicenseManagerDialog *weakSelf = self;

	 self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setIsSilentOnSuccess:self.isSilentOnSuccess];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	}];

	[self.licenseManagerDownloader requestLostLicenseKeyForContactAddress:contactAddress];
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

	 self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setIsSilentOnSuccess:self.isSilentOnSuccess];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];

		[weakSelf reloadMainWindowLoadingScreen];
	}];

	[self.licenseManagerDownloader deactivateLicense];
}

#pragma mark -
#pragma mark Mac App Store Receipt Processing

- (void)unregisteredViewMigrateMacAppStorePurchase:(id)sender
{
	 self.migrateAppStoreSheet = [TDCLicenseManagerMigrateAppStoreSheet new];

	[self.migrateAppStoreSheet setWindow:[self window]];

	[self.migrateAppStoreSheet setDelegate:self];

	[self.migrateAppStoreSheet start];
}

- (void)licenseManagerMigrateAppStoreSheet:(TDCLicenseManagerMigrateAppStoreSheet *)sender
							convertReceipt:(NSString *)receiptData
						  licenseOwnerName:(NSString *)licenseOwnerName
				licenseOwnerContactAddress:(NSString *)licenseOwnerContactAddress
{
	__weak TDCLicenseManagerDialog *weakSelf = self;

	self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setIsSilentOnSuccess:self.isSilentOnSuccess];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	}];

	[self.licenseManagerDownloader migrateMacAppStorePurcahse:receiptData
											 licenseOwnerName:licenseOwnerName
								   licenseOwnerContactAddress:licenseOwnerContactAddress];
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
	if ([obj object] == self.unregisteredViewLicenseKeyTextField) {
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
	 self.progressSheet = [TDCProgressInformationSheet new];

	[self.progressSheet startWithWindow:[self window]];
}

- (void)endProgressIndicator
{
	if ( self.progressSheet) {
		[self.progressSheet stop];

		 self.progressSheet = nil;
	}
}

#pragma mark -
#pragma mark Notification Center

+ (NSString *)timeRemainingInTrialFormattedMessage
{
	NSTimeInterval timeLeft = TLOLicenseManagerTimeReaminingInTrial();

	if (timeLeft <= 0) {
		return TXTLS(@"TLOLicenseManager[1016]");
	} else {
		NSString *formattedTimeRemainingString = TXHumanReadableTimeInterval(timeLeft, YES, NSCalendarUnitDay);

		return TXTLS(@"TLOLicenseManager[1015]", formattedTimeRemainingString);
	}
}

+ (void)scheduleTimeRemainingInTrialNotification
{
	if (TLOLicenseManagerIsTrialExpired()) {
		return; // Do not schedule notification...
	}

	NSString *formattedNotificationTitle = [TDCLicenseManagerDialog timeRemainingInTrialFormattedMessage];

	NSUserNotification *notification = [NSUserNotification new];

	[notification setTitle:formattedNotificationTitle];

	[notification setInformativeText:TXTLS(@"TLOLicenseManager[1017][2]")];

	[notification setDeliveryDate:[NSDate date]];

	[notification setUserInfo:@{@"isLicenseManagerTimeRemainingInTrialNotification" : @(YES)}];

	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		[notification setValue:@(YES) forKey:@"_showsButtons"];

		[notification setActionButtonTitle:TXTLS(@"TLOLicenseManager[1017][3]")];
	}

	[RZUserNotificationCenter() scheduleNotification:notification];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(licenseManagerDialogWillClose:)]) {
		[self.delegate licenseManagerDialogWillClose:self];
	}
}

@end
#endif
