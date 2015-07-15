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

#import "TDCLicenseManagerRecoverLostLicenseSheet.h"

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
@interface TDCLicenseManagerDialog ()
@property (nonatomic, weak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *contentViewUnregisteredTextualView;
@property (nonatomic, strong) IBOutlet NSView *contentViewRegisteredTextualView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSTextField *unregisteredViewLicenseKeyTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicenseKeyTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicenseOwnerTextField;
@property (nonatomic, weak) IBOutlet NSTextField *registeredViewLicensePurchaseDateTextField;
@property (nonatomic, weak) IBOutlet NSButton *registeredViewDeactivateTextualButton;
@property (nonatomic, weak) IBOutlet NSButton *unregisteredViewPurchaseTextualButton;
@property (nonatomic, weak) IBOutlet NSButton *unregisteredViewRecoveryLostLicenseButton;
@property (nonatomic, strong) TDCProgressInformationSheet *progressSheet;
@property (nonatomic, strong) TLOLicenseManagerDownloader *licenseManagerDownloader;
@property (nonatomic, strong) TDCLicenseManagerRecoverLostLicenseSheet *recoverLostLicenseSheet;
@property (nonatomic, assign) BOOL textualIsRegistered;

- (IBAction)unregisteredViewLicenseKeyValueChanged:(id)sender;

- (IBAction)unregisteredViewPurchaseTextual:(id)sender;
- (IBAction)unregisteredViewRecoveryLostLicense:(id)sender;

- (IBAction)registeredViewDeactivateTextual:(id)sender;
@end

@implementation TDCLicenseManagerDialog

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCLicenseManagerDialog" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)show
{
	[[self window] restoreWindowStateForClass:[self class]];

	[[self window] makeKeyAndOrderFront:nil];

	[self updateSelectedPane];
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
	}

	[self.contentView attachSubview:contentView
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

- (void)unregisteredViewLicenseKeyValueChanged:(id)sender
{
	if (self.textualIsRegistered) {
		return; // Cancel operation...
	}

	NSString *licenseKeyValue = [self.unregisteredViewLicenseKeyTextField stringValue];

	if (TLOLicenseManagerLicenseKeyIsValid(licenseKeyValue)) {
		[self attemptToActivateLicenseKey:licenseKeyValue];
	}
}

- (void)attemptToActivateLicenseKey:(NSString *)licenseKey
{
	[self beginProgressIndicator];

	__weak TDCLicenseManagerDialog *weakSelf = self;

	self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];

		if (operationSuccessful) {
			[[weakSelf unregisteredViewLicenseKeyTextField] setStringValue:NSStringEmptyPlaceholder];
		}
	}];

	[self.licenseManagerDownloader activateLicense:licenseKey];
}

- (void)unregisteredViewPurchaseTextual:(id)sender
{
	[TLOpenLink openWithString:@"https://www.textualapp.com/"];
}

- (void)unregisteredViewRecoveryLostLicense:(id)sender
{
	 self.recoverLostLicenseSheet = [TDCLicenseManagerRecoverLostLicenseSheet new];

	[self.recoverLostLicenseSheet setWindow:[self window]];

	[self.recoverLostLicenseSheet setDelegate:self];

	[self.recoverLostLicenseSheet start];
}

- (void)licenseManagerRecoverLostLicense:(TDCLicenseManagerRecoverLostLicenseSheet *)sender onOk:(NSString *)contactAddress
{
	__weak TDCLicenseManagerDialog *weakSelf = self;

	 self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	}];

	[self.licenseManagerDownloader requestLostLicenseKeyForContactAddress:contactAddress];
}

- (void)licenseManagerRecoverLostLicenseSheetWillClose:(TDCLicenseManagerRecoverLostLicenseSheet *)sender
{
	self.recoverLostLicenseSheet = nil;

	/* When the recovery sheet closes, if the downloader is active,
	 then show our progress indicator, even if brief. */
	if (self.licenseManagerDownloader) {
		[self beginProgressIndicator];
	}
}

- (void)registeredViewDeactivateTextual:(id)sender
{
	/* License deactivation does not use a progress indicator because
	 it does not have to touch the network. It will only delete a file
	 on the hard drive which is typically instant. */
	__weak TDCLicenseManagerDialog *weakSelf = self;

	 self.licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	[self.licenseManagerDownloader setCompletionBlock:^(BOOL operationSuccessful) {
		[weakSelf licenseManagerDownloaderCompletionBlock];
	}];

	[self.licenseManagerDownloader deactivateLicense];
}

#pragma mark -
#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification *)obj
{
	if ([obj object] == self.unregisteredViewLicenseKeyTextField) {
		[self unregisteredViewLicenseKeyValueChanged:nil];
	}
}

#pragma mark -
#pragma mark Helper Methods

- (void)licenseManagerDownloaderCompletionBlock
{
	/* This block is a catch all for all downloader operations. */
	self.licenseManagerDownloader = nil;

	[self endProgressIndicator];

	[self updateSelectedPane];
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
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[[self window] saveWindowStateForClass:[self class]];

	if ([self.delegate respondsToSelector:@selector(licenseManagerDialogWillClose:)]) {
		[self.delegate licenseManagerDialogWillClose:self];
	}
}

@end
#endif
