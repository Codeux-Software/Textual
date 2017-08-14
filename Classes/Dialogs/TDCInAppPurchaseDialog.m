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

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const TDCInAppPurchaseDialogTransactionFinishedNotification = @"TDCInAppPurchaseDialogTransactionFinishedNotification";
NSString * const TDCInAppPurchaseDialogTransactionRestoredNotification = @"TDCInAppPurchaseDialogTransactionRestoredNotification";
NSString * const TDCInAppPurchaseDialogWillReloadReceiptNotification = @"TDCInAppPurchaseDialogWillReloadReceiptNotification";
NSString * const TDCInAppPurchaseDialogDidReloadReceiptNotification = @"DCInAppPurchaseDialogDidReloadReceiptNotification";
NSString * const TDCInAppPurchaseDialogFinishedLoadingNotification = @"TDCInAppPurchaseDialogFinishedLoadingNotification";
NSString * const TDCInAppPurchaseDialogFinishedLoadingDelayedByLackOfPurchaseNotification = @"TDCInAppPurchaseDialogFinishedLoadingDelayedByLackOfPurchaseNotification";
NSString * const TDCInAppPurchaseDialogTrialExpiredNotification = @"TDCInAppPurchaseDialogTrialExpiredNotification";

enum {
	SKPaymentTransactionStateUnknown = LONG_MAX
};

#define _trialExpiredRemindMeInterval		432000 // 5 days

#define _trialInformationViewDefaultHeight	42

#define _upgradeFromV6FreeThreshold		1497484800 // June 15, 2017

@interface TDCInAppPurchaseDialog ()
@property (nonatomic, strong) TLOTimer *trialTimer;
@property (nonatomic, weak) IBOutlet NSView *trialInformationView;
@property (nonatomic, weak) IBOutlet NSTextField *trialInformationTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *trialInformationHeightConstraint;
@property (nonatomic, assign) BOOL requestingProducts;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, copy) NSDictionary<NSString *, SKProduct *> *products;
@property (nonatomic, weak) IBOutlet NSTableView *productsTable;
@property (nonatomic, strong) IBOutlet NSArrayController *productsTableController;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *productsTableHeightConstraint;
@property (nonatomic, assign) BOOL performingPurchase;
@property (nonatomic, assign) BOOL performRestoreOnShow;
@property (nonatomic, assign) BOOL performingRestore;
@property (nonatomic, assign) BOOL atleastOnePurchaseRestored;
@property (nonatomic, assign) BOOL windowIsAllowedToClose;
@property (nonatomic, assign) BOOL finishedLoading;
@property (nonatomic, strong) IBOutlet NSView *contentViewThankYou;
@property (nonatomic, strong) IBOutlet NSView *contentViewProducts;
@property (nonatomic, strong) IBOutlet NSView *contentViewProgress;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressViewIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *progressViewTextField;
@property (nonatomic, assign) BOOL performingUpgradeEligibilityCheck;
@property (nonatomic, strong) IBOutlet NSWindow *upgradeEligibilityDiscountedSheet;
@property (nonatomic, strong) IBOutlet NSWindow *upgradeEligibilityFreeSheet;

- (IBAction)restoreTransactions:(id)sender;
- (IBAction)writeReview:(id)sender;

- (IBAction)closeUpgradeEligiblitySheet:(id)sender;
@end

@implementation TDCInAppPurchaseDialog

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
	(void)[RZMainBundle() loadNibNamed:@"TDCInAppPurchaseDialog" owner:self topLevelObjects:nil];

	self.windowIsAllowedToClose = YES;
}

- (void)prepareForApplicationTermination
{
	[self stopTrialTimer];

	[self removePaymentQueueObserver];
}

- (void)applicationDidFinishLaunching
{
	[self loadReceiptDuringLaunch];

	[self addPaymentQueueObserver];
}

- (void)postDialogFinishedLoadingNotification
{
	self.finishedLoading = YES;

	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogFinishedLoadingNotification object:self];
}

- (void)show
{
	if (self.products == nil) {
		[self requestProducts];
	} else {
		(void)[self restoreTransactionsOnShow];
	}

	BOOL windowVisible = self.window.visible;

	[super show];

	if (windowVisible == NO) {
		[self.window restoreWindowStateForClass:self.class];
	}
}

#pragma mark -
#pragma mark Trial Timer

- (void)toggleTrialTimer
{
	if (TLOAppStoreIsTrialPurchased() == NO) {
		return;
	}

	if (TLOAppStoreTextualIsRegistered()) {
		[self stopTrialTimer];
	} else {
		[self startTrialTimer];
	}
}

- (void)startTrialTimer
{
	if (self.trialTimer != nil) {
		return;
	}

	NSTimeInterval timeRemaining = (TLOAppStoreTimeReaminingInTrial() * (-1.0));

	if (timeRemaining == 0) {
		return;
	}

	TLOTimer *trialTimer = [TLOTimer new];

	trialTimer.repeatTimer = NO;
	trialTimer.target = self;
	trialTimer.action = @selector(onTrialTimer:);

	[trialTimer start:timeRemaining];

	self.trialTimer = trialTimer;
}

- (void)stopTrialTimer
{
	if (self.trialTimer == nil) {
		return;
	}

	[self.trialTimer stop];
	self.trialTimer = nil;
}

- (void)onTrialTimer:(id)sender
{
	[self show];

	[self refreshTrialInformationView];

	[self _showTrialIsExpiredMessageInWindow:self.window];

	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogTrialExpiredNotification object:self];
}

- (NSString *)timeRemainingInTrialFormattedMessage
{
	NSTimeInterval timeLeft = TLOAppStoreTimeReaminingInTrial();

	if (timeLeft >= 0) {
		return TXTLS(@"TDCInAppPurchaseDialog[0018]");
	}

	NSString *formattedTimeRemainingString = TXHumanReadableTimeInterval(timeLeft, YES, NSCalendarUnitDay);

	return TXTLS(@"TDCInAppPurchaseDialog[0017]", formattedTimeRemainingString);
}

#pragma mark -
#pragma mark Messages

- (void)showTrialIsExpiredMessageInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	/* Is the trial even expired? */
	if (TLOAppStoreIsTrialExpired() == NO) {
		return;
	}

	/* Do not show trial is expired message too often. */
	NSTimeInterval lastCheckTime = [RZUserDefaults() doubleForKey:@"Textual In-App Purchase -> Trial Expired Message Last Presentation"];

	NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];

	if (lastCheckTime > 0) {
		if ((currentTime - lastCheckTime) < _trialExpiredRemindMeInterval) {
			LogToConsoleInfo("Not enough time has passed since last presentation")

			return;
		}
	}

	[RZUserDefaults() setDouble:currentTime forKey:@"Textual In-App Purchase -> Trial Expired Message Last Presentation"];

	/* Show trial expired message */
	[self _showTrialIsExpiredMessageInWindow:window];
}

- (void)_showTrialIsExpiredMessageInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	[TLOPopupPrompts sheetWindowWithWindow:window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0015][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0015][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0015][3]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[0015][4]")
							   otherButton:TXTLS(@"Prompts[0008]")
							suppressionKey:@"trial_is_expired_mas"
						   suppressionText:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   self.performRestoreOnShow = YES;
							   }

							   if (buttonClicked != TLOPopupPromptReturnOtherType) {
								   [self show];
							   }
						   }];
}

- (void)showFeatureIsLimitedMessageInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	[TLOPopupPrompts sheetWindowWithWindow:window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0014][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0014][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0014][3]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[0014][4]")
							   otherButton:TXTLS(@"Prompts[0008]")
							suppressionKey:@"trial_is_expired_mas"
						   suppressionText:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   self.performRestoreOnShow = YES;
							   }

							   if (buttonClicked != TLOPopupPromptReturnOtherType) {
								   [self show];
							   }
						   }];
}

#pragma mark -
#pragma mark Payment Queue Observer

- (void)addPaymentQueueObserver
{
	[[SKPaymentQueue defaultQueue] addTransactionObserver:(id)self];
}

- (void)removePaymentQueueObserver
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:(id)self];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSMutableArray<SKPaymentTransaction *> *finishedTransactions = nil;

	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStateFailed:
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
			{
				if (finishedTransactions == nil) {
					finishedTransactions = [NSMutableArray array];
				}

				[finishedTransactions addObject:transaction];

				break;
			}
			default:
			{
				break;
			}
		}
	}

	if (finishedTransactions == nil) {
		return;
	}

	[self processFinishedTransactions:transactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	[self postflightForRestore];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	[self postflightForRestore];

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0011][2]", error.localizedDescription)
									 title:TXTLS(@"TDCInAppPurchaseDialog[0011][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)processFinishedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	/* Process transactions */
	for (SKPaymentTransaction *transaction in transactions) {
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	}

	/* Complete order */
	[self postflightForTransactions:transactions];
}

- (void)postflightForTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	BOOL performingPurchase = self.performingPurchase;
	BOOL performingRestore = self.performingRestore;

	if (performingPurchase == NO && performingRestore == NO) {
		LogToConsoleInfo("Transaction without ownership received")

		return;
	}

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		BOOL atleastOneTransactionFinished = NO;

		for (SKPaymentTransaction *transaction in transactions) {
			switch (transaction.transactionState) {
				case SKPaymentTransactionStateFailed:
				{
					if (performingPurchase == NO) {
						break;
					}

					NSError *transationError = transaction.error;

					if (transationError.code == SKErrorPaymentCancelled) {
						break;
					}

					[TLOPopupPrompts sheetWindowWithWindow:self.window
													  body:TXTLS(@"TDCInAppPurchaseDialog[0012][2]", transationError.localizedDescription)
													 title:TXTLS(@"TDCInAppPurchaseDialog[0012][1]")
											 defaultButton:TXTLS(@"Prompts[0005]")
										   alternateButton:nil
											   otherButton:nil];

					break;
				}
				case SKPaymentTransactionStatePurchased:
				{
					atleastOneTransactionFinished = YES;

					break;
				}
				case SKPaymentTransactionStateRestored:
				{
					atleastOneTransactionFinished = YES;

					break;
				}
				default:
				{
					LogToConsoleError("Unexpected status");

					return;
				}
			}
		}

		if (performingPurchase) {
			self.performingPurchase = NO;
		}

		if (atleastOneTransactionFinished) {
			if ([self loadReceipt] == NO) {
				[TLOPopupPrompts sheetWindowWithWindow:self.window
												  body:TXTLS(@"TDCInAppPurchaseDialog[0007][2]")
												 title:TXTLS(@"TDCInAppPurchaseDialog[0007][1]")
										 defaultButton:TXTLS(@"Prompts[0005]")
									   alternateButton:nil
										   otherButton:nil];

				atleastOneTransactionFinished = NO;
			}
		}

		if (atleastOneTransactionFinished == NO) {
			[self _updateSelectedPane];
			
			return;
		}
		
		if (performingRestore) {
			self.atleastOnePurchaseRestored = YES;
		}
		
		[self showThankYouAfterProductPurchase];

		[self _updateSelectedPane];

		[self _refreshProductsTableContents];
		
		[self postTransactionFinishedNotification:transactions];

		if (self.finishedLoading == NO) {
			[self loadReceiptDuringLaunchPostflight];
		}
	});
}

- (void)postflightForRestore
{
	if (self.performingRestore) {
		self.performingRestore = NO;
	} else {
		return;
	}

	if (self.atleastOnePurchaseRestored) {
		self.atleastOnePurchaseRestored = NO;
	} else {
		[self updateSelectedPane];
	}
}

- (void)showThankYouAfterProductPurchase
{
	if (TLOAppStoreTextualIsRegistered() == NO) {
		[self close];

		return;
	}

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0016][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0016][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							  [self close];
						   }];
}

- (void)postTransactionFinishedNotification:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	[self postNotification:TDCInAppPurchaseDialogTransactionFinishedNotification withTransactions:transactions];
}

/*
- (void)postTransactionRestoredNotification:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	[self postNotification:TDCInAppPurchaseDialogTransactionRestoredNotification withTransactions:transactions];
}
*/

- (void)postNotification:(NSString *)notification withTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(notification != nil);
	NSParameterAssert(transactions != nil);

	NSMutableArray *productIdentifiers = [NSMutableArray arrayWithCapacity:transactions.count];

	for (SKPaymentTransaction *transaction in transactions) {
		[productIdentifiers addObject:transaction.payment.productIdentifier];
	}

	NSDictionary *userInfo = @{
		@"productIdentifiers" : [productIdentifiers copy]
    };

	[RZNotificationCenter() postNotificationName:notification
										  object:self
										userInfo:userInfo];
}

#pragma mark -
#pragma mark Content Views


- (void)refreshProductsTableContents
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _refreshProductsTableContents];
	});
}

- (void)_refreshProductsTableContents
{
	[self.productsTableController removeAllArrangedObjects];

	if (TLOAppStoreTextualIsRegistered()) {
		return;
	}
	
	if (TLOAppStoreIsTrialPurchased() == NO) {
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPFreeTrialProductIdentifier]];
	}

	[self.productsTableController addObject:
	 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPStandardEditionProductIdentifier]];
	
	TDCInAppPurchaseProductsTableEntry *discountEntry = [self productsTableUpgradeEligibilityEntry];
	
	if (discountEntry != nil) {
		[self.productsTableController addObject:discountEntry];
	}
}

- (void)updateSelectedPane
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _updateSelectedPane];
	});
}

- (void)_updateSelectedPane
{
	[self detachProgressView];

	if (TLOAppStoreTextualIsRegistered()) {
		[self attachThankYouView];

		return;
	}

	[self attachProductsView];

	[self refreshTrialInformationView];
}

- (void)refreshTrialInformationView
{
	if (TLOAppStoreIsTrialPurchased() == NO) {
		self.trialInformationHeightConstraint.constant = 0.0;
	} else {
		self.trialInformationHeightConstraint.constant = _trialInformationViewDefaultHeight;

		NSString *formattedTrialInformation = [self timeRemainingInTrialFormattedMessage];

		self.trialInformationTextField.stringValue = formattedTrialInformation;
	}
}

- (void)attachThankYouView
{
	NSView *windowContentView = self.window.contentView;

	NSView *thankYouContentView = self.contentViewThankYou;

	[windowContentView attachSubviewToHugEdges:thankYouContentView];
}

- (void)attachProductsView
{
	NSView *windowContentView = self.window.contentView;

	NSView *productsContentView = self.contentViewProducts;

	[windowContentView attachSubviewToHugEdges:productsContentView];
}

- (void)attachProgressViewWithReason:(NSString *)progressReason
{
	NSParameterAssert(progressReason != nil);

	NSView *windowContentView = self.window.contentView;

	NSView *progressContentView = self.contentViewProgress;

	[windowContentView attachSubviewToHugEdges:progressContentView];

	self.progressViewTextField.stringValue = progressReason;

	[self.progressViewIndicator startAnimation:nil];

	self.windowIsAllowedToClose = NO;
}

- (void)detachProgressView
{
	self.windowIsAllowedToClose = YES;

	[self.progressViewIndicator stopAnimation:nil];

	self.progressViewTextField.stringValue = NSStringEmptyPlaceholder;
}

- (void)setWindowIsAllowedToClose:(BOOL)windowIsAllowedToClose
{
	if (self->_windowIsAllowedToClose != windowIsAllowedToClose) {
		self->_windowIsAllowedToClose = windowIsAllowedToClose;

		[self.window standardWindowButton:NSWindowCloseButton].enabled = windowIsAllowedToClose;
	}
}

#pragma mark -
#pragma mark Discount

- (void)closeUpgradeEligiblitySheet:(id)sender
{
	[NSApp endSheet:((NSButton *)sender).window];
}

- (void)upgradeEligibilitySheetDidEnd:(NSWindow *)sender returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sender close];
	
	self.performingUpgradeEligibilityCheck = NO;
}

- (void)showEligiblitySheetForDiscountedUpgradeSheet
{
	[NSApp beginSheet:self.upgradeEligibilityDiscountedSheet
	   modalForWindow:self.window
		modalDelegate:self
	   didEndSelector:@selector(upgradeEligibilitySheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)showEligiblitySheetForFreeUpgradeSheet
{
	[NSApp beginSheet:self.upgradeEligibilityFreeSheet
	   modalForWindow:self.window
		modalDelegate:self
	   didEndSelector:@selector(upgradeEligibilitySheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)showApplicationIsNotEligibleForDiscountError:(NSBundle *)applicationBundle
{
	NSParameterAssert(applicationBundle != nil);

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0021][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0021][1]", applicationBundle.displayName)
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)checkUpgradeEligiblityOfApplicationAtURL:(NSURL *)applicationURL
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _checkUpgradeEligiblityOfApplicationAtURL:applicationURL];
	});
}

- (void)_checkUpgradeEligiblityOfApplicationAtURL:(NSURL *)applicationURL
{
	NSParameterAssert(applicationURL != nil);

	NSBundle *applicationBundle = [NSBundle bundleWithURL:applicationURL];
	
	if (applicationBundle == nil) {
		LogToConsoleError("Not application")

		return;
	}

	/* Read receipt contents. */
	ARLReceiptContents *receiptContents = nil;
	
	if (ARLReadReceiptFromBundle(applicationBundle, &receiptContents) == NO) {
		LogToConsoleError("Failed to laod receipt contents: %@", ARLLastErrorMessage())
		
		[self showApplicationIsNotEligibleForDiscountError:applicationBundle];

		self.performingUpgradeEligibilityCheck = NO;
		
		return;
	}

	/* Compare bundle identifier. */
	if (NSObjectsAreEqual(receiptContents.bundleIdentifier, @"com.codeux.irc.textual5") == NO) {
		LogToConsoleError("Bundle identifier mismatch")
		
		[self showApplicationIsNotEligibleForDiscountError:applicationBundle];
		
		self.performingUpgradeEligibilityCheck = NO;
		
		return;
	}

	/* Process receipts contents. */
	NSTimeInterval originalPurchaseDateInterval = receiptContents.originalPurchaseDate.timeIntervalSince1970;
	
	BOOL freeUpgrade = (originalPurchaseDateInterval >= _upgradeFromV6FreeThreshold);
	
	if (freeUpgrade) {
		[self showEligiblitySheetForFreeUpgradeSheet];
	} else {
		[self showEligiblitySheetForDiscountedUpgradeSheet];
	}
	
	[self.productsTableController removeAllArrangedObjects];

	if (freeUpgrade) {
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier]];
	} else {
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPUpgradeFromV6ProductIdentifier]];
	}
}

#pragma mark -
#pragma mark Actions

- (void)checkUpgradeEligiblity:(id)sender
{
	self.performingUpgradeEligibilityCheck = YES;

	NSOpenPanel *d = [NSOpenPanel openPanel];
	
	NSURL *applicationsPath = [TPCPathInfo systemApplicationFolderURL];
	
	if (applicationsPath) {
		d.directoryURL = applicationsPath;
	}
	
	d.allowedFileTypes = @[@"app"];
	
	d.delegate = (id)self;
	
	d.allowsMultipleSelection = NO;
	d.canChooseDirectories = NO;
	d.canChooseFiles = YES;
	d.canCreateDirectories = NO;
	d.resolvesAliases = YES;
	
	d.message = TXTLS(@"TDCInAppPurchaseDialog[0020]");
	
	d.prompt = TXTLS(@"Prompts[0006]");
	
	[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
			[self checkUpgradeEligiblityOfApplicationAtURL:d.URL];
		} else {
			self.performingUpgradeEligibilityCheck = NO;
		}
	}];
}

- (void)writeReview:(id)sender
{
	[menuController() openMacAppStoreWebpage:nil];
}

- (void)restoreTransactions:(id)sender
{
	[self restoreTransactions];
}

#pragma mark -
#pragma mark Table View Delegate

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	TDCInAppPurchaseProductsTableCellView *newView = nil;

	TDCInAppPurchaseProductsTableEntry *entryItem = self.productsTableController.arrangedObjects[row];

	if (entryItem.entryType == TDCInAppPurchaseProductsTableEntryProductType) {
		newView = [tableView makeViewWithIdentifier:@"productType" owner:self];
	} else if (entryItem.entryType == TDCInAppPurchaseProductsTableEntryOtherType) {
		newView = [tableView makeViewWithIdentifier:@"otherType" owner:self];
	}

	return newView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	TDCInAppPurchaseProductsTableEntry *entryItem = self.productsTableController.arrangedObjects[row];

	if (entryItem.rowHeight > 0) {
		return entryItem.rowHeight;
	}

	return tableView.rowHeight;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	[self calculateHeightOfRowInProductsTable:row];

	if ((tableView.numberOfRows - 1) == row) {
		[self calculateHeightOfProductsTable];
	}
}

- (void)calculateHeightOfRowInProductsTable:(NSUInteger)row
{
	NSTableView *tableView = self.productsTable;

	NSSize cellViewSpacing = tableView.intercellSpacing;
	
	TDCInAppPurchaseProductsTableCellView *cellView = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];

	TDCInAppPurchaseProductsTableEntry *entryItem = self.productsTableController.arrangedObjects[row];

	entryItem.rowHeight = (cellView.innerContentViewSize.height + cellViewSpacing.height);

	[NSAnimationContext performBlockWithoutAnimation:^{
		[tableView noteHeightOfRowsWithIndexesChanged:
			 [NSIndexSet indexSetWithIndex:row]];
	}];
}

- (void)calculateHeightOfProductsTable
{
	CGFloat tableViewHeight = 2.0; // 1 pixel margin on top and bottom

	for (TDCInAppPurchaseProductsTableEntry *entryItem in self.productsTableController.arrangedObjects) {
		tableViewHeight += entryItem.rowHeight;
	}

	self.productsTableHeightConstraint.constant = tableViewHeight;
}

#pragma mark -
#pragma mark Products

- (nullable TDCInAppPurchaseProductsTableEntry *)productsTableUpgradeEligibilityEntry
{
	/* Do not offer upgrade if one of these two are disabled (missing) */
	if ([self.products containsKey:TLOAppStoreIAPUpgradeFromV6ProductIdentifier] == NO ||
		[self.products containsKey:TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier] == NO)
	{
		return nil;
	}
	
	/* Create entry */
	TDCInAppPurchaseProductsTableEntry *tableEntry = [TDCInAppPurchaseProductsTableEntry new];
	
	tableEntry.entryType = TDCInAppPurchaseProductsTableEntryOtherType;
	
	tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[0003][1]");
	tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[0003][2]");
	tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[0003][3]");

	tableEntry.target = self;
	tableEntry.action = @selector(checkUpgradeEligiblity:);
	
	return tableEntry;
}

- (nullable TDCInAppPurchaseProductsTableEntry *)productsTableEntryForProduct:(SKProduct *)product
{
	NSParameterAssert(product != nil);

	NSString *productIdentifier = product.productIdentifier;
	
	TLOAppStoreIAPProduct productType = TLOAppStoreProductFromProductIdentifier(productIdentifier);

	TDCInAppPurchaseProductsTableEntry *tableEntry = [TDCInAppPurchaseProductsTableEntry new];

	tableEntry.productIdentifier = productIdentifier;

	tableEntry.productPrice = product.price;
	tableEntry.productPriceLocale = product.priceLocale;

	tableEntry.target = self;
	tableEntry.action = @selector(payForProductsTableEntry:);

	switch (productType) {
		case TLOAppStoreIAPFreeTrialProduct:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryOtherType;
			
			tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[0001][1]");
			tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[0001][2]");
			tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[0001][3]");

			break;
		}
		case TLOAppStoreIAPStandardEditionProduct:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryProductType;
			
			tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[0002][1]");
			tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[0002][2]");
			tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[0002][3]");
			
			break;
		}
		case TLOAppStoreIAPUpgradeFromV6Product:
		case TLOAppStoreIAPUpgradeFromV6FreeProduct:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryProductType;
			
			SKProduct *standardEdition = self.products[TLOAppStoreIAPStandardEditionProductIdentifier];
			
			if (standardEdition == nil) {
				NSAssert(NO, @"The 'Standard Edition' product is missing");
			}
			
			tableEntry.productPriceDiscounted = standardEdition.price;
			
			if (productType == TLOAppStoreIAPUpgradeFromV6Product)
			{
				tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[0004][1]");
				tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[0004][2]");
				tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[0004][3]");
			}
			else if (productType == TLOAppStoreIAPUpgradeFromV6FreeProduct)
			{
				tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[0005][1]");
				tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[0005][2]");
				tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[0005][3]");
			}

			break;
		}
		default:
		{
			return nil;
		}
	}

	return tableEntry;
}

- (nullable TDCInAppPurchaseProductsTableEntry *)productsTableEntryForProductIdentifier:(NSString *)productIdentifier
{
	NSParameterAssert(productIdentifier != nil);

	SKProduct *product = self.products[productIdentifier];

	if (product == nil) {
		return nil;
	}

	return [self productsTableEntryForProduct:product];
}

- (nullable NSString *)localizedTitleForProduct:(SKProduct *)product
{
	NSParameterAssert(product != nil);

	return [self localizedTitleForProductIdentifier:product.productIdentifier];
}

- (nullable NSString *)localizedTitleForProductIdentifier:(NSString *)productIdentifier
{
	NSParameterAssert(productIdentifier != nil);

	TLOAppStoreIAPProduct productType = TLOAppStoreProductFromProductIdentifier(productIdentifier);

	NSString *productTitle = nil;
	
	switch (productType) {
		case TLOAppStoreIAPFreeTrialProduct:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[0001][1]");
			
			break;
		}
		case TLOAppStoreIAPStandardEditionProduct:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[0002][1]");
			
			break;
		}
		case TLOAppStoreIAPUpgradeFromV6Product:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[0004][1]");
			
			break;
		}
		case TLOAppStoreIAPUpgradeFromV6FreeProduct:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[0005][1]");
			
			break;
		}
		default:
		{
			break;
		}
	}
	
	return productTitle;
}

- (void)payForProductsTableEntry:(TDCInAppPurchaseProductsTableEntry *)product
{
	NSParameterAssert(product != nil);

	NSString *productIdentifier = product.productIdentifier;

	[self payForProductIdentifier:productIdentifier];
}

- (void)payForProductIdentifier:(NSString *)productIdentifier
{
	[self payForProductIdentifier:productIdentifier quantity:1];
}

- (void)payForProductIdentifier:(NSString *)productIdentifier quantity:(NSUInteger)quantity
{
	NSParameterAssert(productIdentifier != nil);

	SKProduct *product = self.products[productIdentifier];

	if (product == nil) {
		NSString *productTitle = [self localizedTitleForProductIdentifier:productIdentifier];

		[TLOPopupPrompts sheetWindowWithWindow:self.window
										  body:TXTLS(@"TDCInAppPurchaseDialog[0006][2]")
										 title:TXTLS(@"TDCInAppPurchaseDialog[0006][1]", productTitle)
								 defaultButton:TXTLS(@"Prompts[0005]")
							   alternateButton:nil
								   otherButton:nil];

		return;
	}

	[self payForProduct:product quantity:quantity];
}

- (void)payForProduct:(SKProduct *)product
{
	[self payForProduct:product quantity:1];
}

- (void)payForProduct:(SKProduct *)product quantity:(NSUInteger)quantity
{
	NSParameterAssert(product != nil);
	NSParameterAssert(quantity > 0);

	/* Set status properties */
	if (self.performingRestore) {
		return;
	}

	if (self.performingPurchase == NO) {
		self.performingPurchase = YES;
	} else {
		return;
	}

	/* Show progress view */
	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0009]")];

	/* Perform purchase */
	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];

	payment.quantity = quantity;

	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (BOOL)restoreTransactionsOnShow
{
	if (self.performRestoreOnShow) {
		self.performRestoreOnShow = NO;
	} else {
		return NO;
	}

	[self restoreTransactions];

	return YES;
}

- (void)restoreTransactions
{
	/* Set status properties */
	if (self.requestingProducts) {
		return;
	} else if (self.performingUpgradeEligibilityCheck) {
		return;
	} else if (self.performingPurchase) {
		return;
	}

	if (self.performingRestore == NO) {
		self.performingRestore = YES;
	} else {
		return;
	}

	/* Show progress view */
	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0010]")];

	/* Perform restore */
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)showPleaseSelectItemError
{
	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0013][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0013][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

#pragma mark -
#pragma mark Receipt

- (BOOL)loadReceipt
{
	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogWillReloadReceiptNotification object:self];

	BOOL loadResult = TLOAppStoreLoadReceipt();

	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogDidReloadReceiptNotification object:self];

	return loadResult;
}

- (void)loadReceiptDuringLaunch
{
	(void)[self loadReceipt];

	/* If the receipt fails to load for some reason,
	 then we aren't going to make a stink behind it.
	 At least not during launch. */
	/* If there is no receipt, then we show the normal
	 dialog, which includes the option to restore
	 transactions. Let the user restore transactions
	 instead of trying to get a new receipt. */
	[self loadReceiptDuringLaunchPostflight];
}

- (void)loadReceiptDuringLaunchPostflight
{
	/* Show dialog if registration is not performed. */
	/* We do not fire the launch notification at this
	 point because we want time for the user to make
	 a selection before continuing. */
	if (TLOAppStoreTextualIsRegistered() == NO &&
		TLOAppStoreIsTrialPurchased() == NO)
	{
		[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogFinishedLoadingDelayedByLackOfPurchaseNotification object:self];

		[self show];

		return;
	}

	/* Start trial timer if applicable */
	[self toggleTrialTimer];

	/* User owns something, continue */
	[self postDialogFinishedLoadingNotification];
}

#pragma mark -
#pragma mark Products Request

- (void)requestProducts
{
	[self requestProductsAgain:NO];
}

- (void)requestProductsAgain:(BOOL)requestProductsAgain
{
	if (self.requestingProducts == NO) {
		self.requestingProducts = YES;
	} else {
		return;
	}

	if (requestProductsAgain == NO) {
		[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0008]")];
	}

	NSSet *productIdentifiers =
	[NSSet setWithArray:
	 @[
		TLOAppStoreIAPFreeTrialProductIdentifier,
		TLOAppStoreIAPStandardEditionProductIdentifier,
		TLOAppStoreIAPUpgradeFromV6ProductIdentifier,
		TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier
      ]
    ];

	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];

	productsRequest.delegate = (id)self;

	[productsRequest start];

	self.productsRequest = productsRequest;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSMutableDictionary<NSString *, SKProduct *> *productsDict = [NSMutableDictionary dictionary];

	for (SKProduct *product in response.products) {
		[productsDict setObject:product forKey:product.productIdentifier];
	}

	self.products = productsDict;
	
	if ([self restoreTransactionsOnShow] == NO) {
		[self updateSelectedPane];
	}
	
	[self refreshProductsTableContents];
}

- (void)onRequestProductsError:(NSError *)error
{
	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0019][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0019][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0019][3]")
						   alternateButton:nil
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   [self requestProductsAgain:YES];
						   }];
}

- (void)onRequestProductsFinished
{
	[self onRequestProductsFinishedWithError:nil];
}

- (void)onRequestProductsFinishedWithError:(nullable NSError *)error
{
	self.requestingProducts = NO;

	self.productsRequest = nil;

	/* Error callback is called after the properties have been
	 unset so that when -requestProductsAgain: is called by the
	 error callback, self.requestingProducts is already NO,
	 which would otherwise do nothing if it was YES. */
	if (error) {
		[self onRequestProductsError:error];
	}
}

#pragma mark -
#pragma mark Requests Delegate

- (void)requestDidFinish:(SKRequest *)request
{
	if (request == self.productsRequest) {
		[self onRequestProductsFinished];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if (request == self.productsRequest) {
		[self onRequestProductsFinishedWithError:error];
	}
}

#pragma mark -
#pragma mark Window Delegate

- (BOOL)windowShouldClose:(NSWindow *)sender
{
	if (self.finishedLoading == NO) {
		[self showPleaseSelectItemError];

		return NO;
	}

	if (self.windowIsAllowedToClose == NO) {
		NSBeep();

		return NO;
	}

	return YES;
}

- (void)windowWillClose:(NSNotification *)note
{
	[self.window saveWindowStateForClass:self.class];
}

@end

NS_ASSUME_NONNULL_END

#endif
