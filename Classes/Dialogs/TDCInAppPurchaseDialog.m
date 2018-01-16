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

#import "TXMasterController.h"
#import "TXMenuController.h"
#import "NSViewHelper.h"
#import "TXGlobalModels.h"
#import "TPCPreferencesUserDefaults.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TLOPopupPrompts.h"
#import "TLOTimer.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TDCInAppPurchaseProductTableCellViewPrivate.h"
#import "TDCInAppPurchaseProductTableEntryPrivate.h"
#import "TDCInAppPurchaseUpgradeEligibilitySheetPrivate.h"
#import "TDCInAppPurchaseDialogPrivate.h"

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
@property (nonatomic, strong) SKReceiptRefreshRequest *receiptRefreshRequest;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, copy) NSDictionary<NSString *, SKProduct *> *products;
@property (nonatomic, weak) IBOutlet NSTableView *productsTable;
@property (nonatomic, strong) IBOutlet NSArrayController *productsTableController;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *productsTableHeightConstraint;
@property (nonatomic, assign) BOOL performingPurchase;
@property (nonatomic, assign) BOOL performingRestore;
@property (nonatomic, assign) BOOL performRestoreOnShow;
@property (nonatomic, assign) BOOL windowIsAllowedToClose;
@property (nonatomic, assign) BOOL finishedLoading;
@property (nonatomic, assign) BOOL workInProgress;
@property (nonatomic, assign) BOOL transactionsPending;
@property (nonatomic, assign) BOOL atleastOnePurchaseFinished;
@property (nonatomic, assign) BOOL atleastOnePurchaseRestored;
@property (nonatomic, assign) BOOL skipRestorePostflight;
@property (nonatomic, strong) IBOutlet NSView *contentViewThankYou;
@property (nonatomic, strong) IBOutlet NSView *contentViewProducts;
@property (nonatomic, strong) IBOutlet NSView *contentViewProgress;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressViewIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *progressViewTextField;
@property (nonatomic, assign) BOOL performingUpgradeEligibilityCheck;
@property (nonatomic, strong, nullable) TDCInAppPurchaseUpgradeEligibilitySheet *upgradeEligibilitySheet;

- (IBAction)restoreTransactions:(id)sender;
- (IBAction)writeReview:(id)sender;
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

	LogToConsoleDebug("Posting 'finished loading' notification");
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

	LogToConsoleDebug("Starting trial timer to end on %d", timeRemaining);
}

- (void)stopTrialTimer
{
	if (self.trialTimer == nil) {
		return;
	}

	[self.trialTimer stop];
	self.trialTimer = nil;

	LogToConsoleDebug("Stopping trial timer");
}

- (void)onTrialTimer:(id)sender
{
	[self show];

	[self refreshTrialInformationView];

	[self _showTrialIsExpiredMessageInWindow:self.window];

	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogTrialExpiredNotification object:self];

	LogToConsoleDebug("Trial timer fired");
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

	if (TLOAppStoreTextualIsRegistered()) {
		return;
	}

	/* Is the trial even expired? */
	if (TLOAppStoreIsTrialExpired() == NO) {
		return;
	}

	/* Do not show trial is expired message too often. */
	NSTimeInterval lastCheckTime = [RZUserDefaults() doubleForKey:@"Textual In-App Purchase -> Trial Expired Message Last Presentation"];

	NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];

	if (lastCheckTime > 0) {
		if ((currentTime - lastCheckTime) < _trialExpiredRemindMeInterval) {
			LogToConsoleInfo("Not enough time has passed since last presentation");

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
	LogToConsoleDebug("Updating %ld transactions", transactions.count);

	BOOL atleastOneTransaction = NO;
	BOOL atleastOneTransactionFinished = NO;
	BOOL atleastOneTransactionRestored = NO;

	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStateFailed:
			{
				atleastOneTransaction = YES;

				break;
			}
			case SKPaymentTransactionStatePurchased:
			{
				atleastOneTransaction = YES;
				atleastOneTransactionFinished = YES;

				break;
			}
			case SKPaymentTransactionStateRestored:
			{
				atleastOneTransaction = YES;
				atleastOneTransactionRestored = YES;

				break;
			}
			default:
			{
				break;
			}
		}
	}

	if (atleastOneTransaction == NO) {
		return;
	}

	self.transactionsPending = atleastOneTransaction;
	self.atleastOnePurchaseFinished = atleastOneTransactionFinished;
	self.atleastOnePurchaseRestored = atleastOneTransactionRestored;
	self.skipRestorePostflight = (atleastOneTransactionFinished ||
								  atleastOneTransactionRestored);

	LogToConsoleDebug("atleastOnePurchaseFinished: %@, atleastOnePurchaseRestored: %@",
		  StringFromBOOL(atleastOneTransactionFinished),
		  StringFromBOOL(atleastOneTransactionRestored));

	[self processFinishedTransactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	LogToConsoleDebug("Transaction restore successful");

	[self postflightForRestore];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	LogToConsoleDebug("Transaction restore failed");

	[self postflightForRestore];

	if (error.code == SKErrorPaymentCancelled) {
		return;
	}

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0011][2]", error.localizedDescription)
									 title:TXTLS(@"TDCInAppPurchaseDialog[0011][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)processFinishedTransactions
{
	[self processFinishedTransactionsOrShowError:YES];
}

- (void)processFinishedTransactionsOrShowError:(BOOL)showErrorIfAny
{
	LogToConsoleDebug("Processing finished transactions");

#define _postflight 	\
	[self postflightForTransactions];

	/* If there are only failed transactions, then there
	 is no need to refresh the contents of the receipt. */
	if (self.atleastOnePurchaseFinished == NO &&
		self.atleastOnePurchaseRestored == NO)
	{
		_postflight;

		return;
	}

	/* Refresh the contents of the receipt. */
	if ([self loadReceipt] == NO) {
		LogToConsoleDebug("Failed to load receipt");

		if (showErrorIfAny == NO || self.products == nil) {
			LogToConsoleDebug("Continuing without a receipt");

			_postflight;
		}

		[TLOPopupPrompts sheetWindowWithWindow:self.window
										  body:TXTLS(@"TDCInAppPurchaseDialog[0020][2]")
										 title:TXTLS(@"TDCInAppPurchaseDialog[0020][1]")
								 defaultButton:TXTLS(@"Prompts[0001]")
							   alternateButton:TXTLS(@"Prompts[0002]")
								   otherButton:nil
							   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
								   if (buttonClicked == TLOPopupPromptReturnPrimaryType) {
									   /* Request new receipt. */
									   /* Request will call the postflight for us. */
									   [self requestReceiptRefresh];
								   } else {
									   /* If the user chose not to refresh the receipt, then
										call out to the postflight so that we can at least
										update the appearance of the user interface. */
									   _postflight;
								   }
							   }];

		return;
	}

	/* Post transactions assuming there were no problems. */
	_postflight;

#undef _postflight
}

- (void)postflightForTransactions
{
	NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];

	LogToConsoleDebug("Processing %ld transactions", transactions.count);

	XRPerformBlockSynchronouslyOnMainQueue(^{
		for (SKPaymentTransaction *transaction in transactions) {
			BOOL finishTransaction = YES;

			switch (transaction.transactionState) {
				case SKPaymentTransactionStateFailed:
				{
					if (self.performingRestore) {
						break; // Do not show errors during restore
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
				case SKPaymentTransactionStateRestored:
				{
					break;
				}
				default:
				{
					finishTransaction = NO;

					break;
				}
			} // switch

			if (finishTransaction) {
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			}
		} // for loop

		BOOL success = (self.atleastOnePurchaseFinished ||
						self.atleastOnePurchaseRestored);

		if (self.performingPurchase) {
			self.performingPurchase = NO;
		}

		if (self.performingRestore) {
			self.performingRestore = NO;
		}

		self.transactionsPending = NO;
		self.atleastOnePurchaseFinished = NO;
		self.atleastOnePurchaseRestored = NO;

		BOOL windowIsVisible = (self.window.visible && self.products != nil);

		if (success == NO) {
			LogToConsoleDebug("Finished processing transactions with only failures");

			if (windowIsVisible) {
				[self _updateSelectedPane];
			}

			return;
		}

		LogToConsoleDebug("Finished processing transactions");

		if (windowIsVisible) {
			[self showThankYouAfterProductPurchase];

			[self _updateSelectedPane];

			[self _refreshProductsTableContents];
		}

		[self postTransactionFinishedNotification:transactions];

		if (self.finishedLoading == NO) {
			[self loadReceiptDuringLaunchPostflight];
		}
	});
}

- (void)postflightForRestore
{
	if (self.skipRestorePostflight) {
		self.skipRestorePostflight = NO;

		return;
	}

	if (self.performingRestore) {
		self.performingRestore = NO;
	}

	[self updateSelectedPane];
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

- (void)_addTrialToProductsTableContents
{
	if (TLOAppStoreIsTrialPurchased() == NO) {
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPFreeTrialProductIdentifier]];
	}
}

- (void)_refreshProductsTableContents
{
	LogToConsoleDebug("Refreshing products table");

	[self.productsTableController removeAllArrangedObjects];

	if (TLOAppStoreTextualIsRegistered()) {
		LogToConsoleDebug("No products displayed because Textual is registered");

		return;
	}

	[self _addTrialToProductsTableContents];

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
	LogToConsoleDebug("Updating selected pane");

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

	self.progressViewTextField.stringValue = @"";
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

- (void)checkUpgradeEligibility
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _checkUpgradeEligibility];
	});
}

- (void)_checkUpgradeEligibility
{
	if (self.workInProgress == NO) {
		self.workInProgress = YES;
	} else {
		return;
	}

	LogToConsoleDebug("Upgrade eligibility check start");

	TDCInAppPurchaseUpgradeEligibilitySheet *eligibilitySheet =
	[[TDCInAppPurchaseUpgradeEligibilitySheet alloc] initWithWindow:self.window];

	eligibilitySheet.delegate = self;

	[eligibilitySheet checkEligibility];

	self.upgradeEligibilitySheet = eligibilitySheet;
}

- (void)closeUpgradeEligibilitySheet
{
	if (self.upgradeEligibilitySheet) {
		[self.upgradeEligibilitySheet endSheet];
	}
}

- (void)upgradeEligibilitySheetContactSupport:(TDCInAppPurchaseUpgradeEligibilitySheet *)sender
{
	[self contactSupport];
}

- (void)upgradeEligibilitySheetChanged:(TDCInAppPurchaseUpgradeEligibilitySheet *)sender
{
	LogToConsoleDebug("Eligibility changed to %ld", sender.eligibility);

	if (sender.eligibility == TLOInAppPurchaseUpgradeEligibilityUnknown ||
		sender.eligibility == TLOInAppPurchaseUpgradeNotEligible)
	{
		return;
	}

	[self.productsTableController removeAllArrangedObjects];

	[self _addTrialToProductsTableContents];

	if (sender.eligibility == TLOInAppPurchaseUpgradeEligibleDiscount)
	{
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPUpgradeFromV6ProductIdentifier]];
	}
	else if (sender.eligibility == TLOInAppPurchaseUpgradeEligibleFree ||
			 sender.eligibility == TLOInAppPurchaseUpgradeAlreadyUpgraded)
	{
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier]];
	}
}

- (void)upgradeEligibilitySheetWillClose:(TDCInAppPurchaseUpgradeEligibilitySheet *)sender
{
	LogToConsoleDebug("Upgrade eligibility check end");

	self.workInProgress = NO;

	self.upgradeEligibilitySheet = nil;
}

#pragma mark -
#pragma mark Actions

- (void)checkUpgradeEligibility:(id)sender
{
	[self checkUpgradeEligibility];
}

- (void)writeReview:(id)sender
{
	[menuController() openMacAppStoreWebpage:nil];
}

- (void)restoreTransactions:(id)sender
{
	[self restoreTransactions];
}

- (void)contactSupport
{
	[menuController() contactSupport:nil];
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

	LogToConsoleDebug("Height of row %ld is %f", row, entryItem.rowHeight);

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
	tableEntry.action = @selector(checkUpgradeEligibility:);

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

	if (self.performingPurchase || self.workInProgress) {
		return;
	}

	self.performingPurchase = YES;

	LogToConsoleDebug("Paying for product '%@'", product.productIdentifier);

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0009]")];

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

	LogToConsoleDebug("Restoring transactions on show");

	return [self restoreTransactions];
}

- (BOOL)restoreTransactions
{
	if (self.performingRestore || self.workInProgress) {
		return NO;
	}

	self.performingRestore = YES;

	LogToConsoleDebug("Restoring transactions");

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0010]")];

	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

	return YES;
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

- (BOOL)_productsListContainMinimum
{
	return (self.products[TLOAppStoreIAPFreeTrialProductIdentifier] != nil &&
			self.products[TLOAppStoreIAPStandardEditionProductIdentifier] != nil);
}

#pragma mark -
#pragma mark Receipt

- (BOOL)loadReceipt
{
	LogToConsoleDebug("Loading receipt");

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
		LogToConsoleDebug("No item purchased. Showing dialog.");

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
#pragma mark Receipt Refresh

- (void)requestReceiptRefresh
{
	if (self.workInProgress == NO) {
		self.workInProgress = YES;
	} else {
		return;
	}

	LogToConsoleDebug("Receipt refresh start");

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0007]")];

	SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];

	receiptRefreshRequest.delegate = (id)self;

	[receiptRefreshRequest start];

	self.receiptRefreshRequest = receiptRefreshRequest;
}

- (void)onRefreshReceiptError:(NSError *)error
{
	NSParameterAssert(error != nil);

	LogToConsoleDebug("Receipt refresh error: %@", error.localizedDescription);

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0021][2]", error.localizedDescription)
									 title:TXTLS(@"TDCInAppPurchaseDialog[0021][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)onRefreshReceiptFinished
{
	[self onRefreshReceiptFinishedWithError:nil];
}

- (void)onRefreshReceiptFinishedWithError:(nullable NSError *)error
{
	LogToConsoleDebug("Receipt refresh end");

	self.workInProgress = NO;

	self.receiptRefreshRequest = nil;

	if (self.transactionsPending) {
		/* Regardless of whether there was an error or not, we still
		 perform transaction postflight because we need it to at least
		 clean up the user interface for us. */
		[self processFinishedTransactionsOrShowError:NO];
	} else {
		/* Dismiss progress view */
		[self updateSelectedPane];
	}

	if (error == nil) {
		[self onRefreshReceiptError:error];
	}
}

#pragma mark -
#pragma mark Products Request

- (void)requestProducts
{
	[self requestProductsAgain:NO];
}

- (void)requestProductsAgain:(BOOL)requestProductsAgain
{
	if (self.workInProgress == NO) {
		self.workInProgress = YES;
	} else {
		return;
	}

	LogToConsoleDebug("Products request start");

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
	/* Populate dictionary of products */
	NSMutableDictionary<NSString *, SKProduct *> *productsDict = [NSMutableDictionary dictionary];

	for (SKProduct *product in response.products) {
		NSString *productIdentifier = product.productIdentifier;

		LogToConsoleDebug("Received %@", productIdentifier);

		[productsDict setObject:product forKey:productIdentifier];
	}

	self.products = productsDict;
}

- (void)onRequestProductsError:(nullable NSError *)error
{
	if (error) {
		LogToConsoleDebug("Products request error: %@", error.localizedDescription);
	}

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseDialog[0019][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0019][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0019][3]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[0019][4]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   [self contactSupport];
							   }

							   [self requestProductsAgain:YES];
						   }];
}

- (void)onRequestProductsFinished
{
	[self onRequestProductsFinishedWithError:nil];
}

- (void)onRequestProductsFinishedWithError:(nullable NSError *)error
{
	LogToConsoleDebug("Products request end");

	self.workInProgress = NO;

	self.productsRequest = nil;

	/* A copy of the app downloaded from the App Store returns
	 an empty array of products for some reason when the receipt
	 file is missing. I cannot replicate this behavior in the
	 developer sandbox which suggests its an issue specific to
	 the signing certificate the App Store replaces the code
	 signature with. To prevent crashes, we check if the list
	 of products contain identifiers we always expect to exist. */
	if (error || [self _productsListContainMinimum] == NO) {
		[self onRequestProductsError:error];

		return;
	}

	/* Perform postflight actions */
	if ([self restoreTransactionsOnShow] == NO) {
		[self updateSelectedPane];
	}

	[self refreshProductsTableContents];
}

#pragma mark -
#pragma mark Requests Delegate

- (void)requestDidFinish:(SKRequest *)request
{
	if (request == self.productsRequest) {
		[self onRequestProductsFinished];
	} else if (request == self.receiptRefreshRequest) {
		[self onRefreshReceiptFinished];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if (request == self.productsRequest) {
		[self onRequestProductsFinishedWithError:error];
	} else if (request == self.receiptRefreshRequest) {
		[self onRefreshReceiptFinishedWithError:error];
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
