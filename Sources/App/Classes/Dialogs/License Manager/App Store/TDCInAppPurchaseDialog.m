/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
#import <StoreKit/StoreKit.h>

#import "TXMasterController.h"
#import "TXMenuController.h"
#import "NSViewHelper.h"
#import "TXGlobalModels.h"
#import "TPCPreferencesUserDefaults.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOLocalization.h"
#import "TLOTimer.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TDCAlert.h"
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

#define _upgradeFromV6FreeThreshold		1497484800 // June 15, 2017

@class TDCInAppPurchaseDialogChangedProductsPayload;

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
@property (nonatomic, assign) BOOL performRestoreNextChance;
@property (nonatomic, assign) BOOL requestingProducts;
@property (nonatomic, assign) BOOL checkingEligibility;
@property (nonatomic, assign) BOOL loadProductsAfterReceiptRefresh;
@property (nonatomic, assign) BOOL windowIsAllowedToClose;
@property (nonatomic, assign) BOOL finishedLoading;
@property (nonatomic, assign) BOOL productsLoaded;
@property (nonatomic, strong) TDCInAppPurchaseDialogChangedProductsPayload *changedPoducts;
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

@interface TDCInAppPurchaseDialogChangedProductsPayload : NSObject
@property (nonatomic, assign) BOOL atleastOne;
@property (nonatomic, copy, nullable) NSArray<NSString *> *failedProductIdentifiers;
@property (nonatomic, copy, nullable) NSArray<NSString *> *finishedProductIdentifiers;
@property (nonatomic, copy, nullable) NSArray<NSString *> *restoredProductIdentifiers;
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
	[RZMainBundle() loadNibNamed:@"TDCInAppPurchaseDialog" owner:self topLevelObjects:nil];

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
	if (self.productsLoaded == NO) {
		[self requestProducts];
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

	if (CGFloatAreEqual(timeRemaining, 0)) {
		return;
	}

	TLOTimer *trialTimer = [TLOTimer timerWithActionBlock:^(TLOTimer *sender) {
		[self onTrialTimer];
	}];

	self.trialTimer = trialTimer;

	[trialTimer start:timeRemaining];

	LogToConsoleDebug("Starting trial timer to end on %f", timeRemaining);
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

- (void)onTrialTimer
{
	[self stopTrialTimer];

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
		return TXTLS(@"TDCInAppPurchaseDialog[ouj-7m]");
	}

	NSString *formattedTimeRemainingString = TXHumanReadableTimeInterval(timeLeft, YES, NSCalendarUnitDay);

	return TXTLS(@"TDCInAppPurchaseDialog[z2z-l6]", formattedTimeRemainingString);
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

	[TDCAlert alertSheetWithWindow:window.deepestWindow
							  body:TXTLS(@"TDCInAppPurchaseDialog[cvb-30]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[92e-sa]")
					 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[abg-mv]")
				   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[bt3-h3]")
					   otherButton:TXTLS(@"Prompts[aqw-q1]")
					suppressionKey:@"trial_is_expired_mas"
				   suppressionText:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   if (buttonClicked == TDCAlertResponseOther) {
						   return;
					   }

					   [self show];

					   if (buttonClicked == TDCAlertResponseAlternate) {
						   [self restoreTransactionsByClick];
					   }
				   }];
}

- (void)showFeatureIsLimitedMessageInWindow:(NSWindow *)window
{
	NSParameterAssert(window != nil);

	[TDCAlert alertSheetWithWindow:window.deepestWindow
							  body:TXTLS(@"TDCInAppPurchaseDialog[pan-12]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[doy-jd]")
					 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[wsb-3b]")
				   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[wl7-9j]")
					   otherButton:TXTLS(@"Prompts[aqw-q1]")
					suppressionKey:@"trial_is_expired_mas"
				   suppressionText:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   if (buttonClicked == TDCAlertResponseOther) {
						   return;
					   }

					   [self show];

					   if (buttonClicked == TDCAlertResponseAlternate) {
						   [self restoreTransactionsByClick];
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
	LogToConsoleDebug("Updating %lu transactions", transactions.count);

	BOOL atleastOneTransaction = NO;
	BOOL atleastOneTransactionFinished = NO;
	BOOL atleastOneTransactionRestored = NO;
	
	NSMutableArray<NSString *> *failedProductIdentifiers = [NSMutableArray array];
	NSMutableArray<NSString *> *finishedProductIdentifiers = [NSMutableArray array];
	NSMutableArray<NSString *> *restoredProductIdentifiers = [NSMutableArray array];

	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStateFailed:
			{
				atleastOneTransaction = YES;

				[failedProductIdentifiers addObject:transaction.payment.productIdentifier];

				break;
			}
			case SKPaymentTransactionStatePurchased:
			{
				atleastOneTransaction = YES;
				atleastOneTransactionFinished = YES;

				[finishedProductIdentifiers addObject:transaction.payment.productIdentifier];

				break;
			}
			case SKPaymentTransactionStateRestored:
			{
				atleastOneTransaction = YES;
				atleastOneTransactionRestored = YES;

				[restoredProductIdentifiers addObject:transaction.payment.productIdentifier];

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

/*	self.skipRestorePostflight = (atleastOneTransactionFinished ||
								  atleastOneTransactionRestored); */
	
	TDCInAppPurchaseDialogChangedProductsPayload *changedProducts =
	[TDCInAppPurchaseDialogChangedProductsPayload new];
	
	changedProducts.atleastOne = atleastOneTransaction;
	changedProducts.failedProductIdentifiers = failedProductIdentifiers;
	changedProducts.finishedProductIdentifiers = finishedProductIdentifiers;
	changedProducts.restoredProductIdentifiers = restoredProductIdentifiers;
	
	self.changedPoducts = changedProducts;

	LogToConsoleDebug("atleastOnePurchaseFinished: %@, atleastOnePurchaseRestored: %@",
		  StringFromBOOL(atleastOneTransactionFinished),
		  StringFromBOOL(atleastOneTransactionRestored));

	[self paymentQueueProcessTransactionChangeStep1];
}

- (void)paymentQueueProcessTransactionChangeStep1
{
	LogToConsoleDebug("Processing finished transactions");

	TDCInAppPurchaseDialogChangedProductsPayload *changedProducts = self.changedPoducts;

	/* If there are only failed transactions, then there
	 is no need to refresh the contents of the receipt. */
	if (changedProducts.finishedProductIdentifiers.count == 0 &&
		changedProducts.restoredProductIdentifiers.count == 0)
	{
		[self paymentQueueProcessTransactionChangeStep2];

		return;
	}

	/* Refresh receipt */
	if ([self loadReceipt] == NO) {
		LogToConsoleDebug("Failed to load receipt");
	}

	/* Post transactions */
	[self paymentQueueProcessTransactionChangeStep2];
}

- (void)paymentQueueProcessTransactionChangeStep2
{
	NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];

	LogToConsoleDebug("Processing %lu transactions", transactions.count);

	XRPerformBlockSynchronouslyOnMainQueue(^{
		for (SKPaymentTransaction *transaction in transactions) {
			BOOL finishTransaction = YES;

			switch (transaction.transactionState) {
				case SKPaymentTransactionStateFailed:
				{
					NSError *transationError = transaction.error;

					if (transationError.code == SKErrorPaymentCancelled) {
						break;
					}

					[TDCAlert alertSheetWithWindow:self.window
											  body:TXTLS(@"TDCInAppPurchaseDialog[cco-a9]", transationError.localizedDescription)
											 title:TXTLS(@"TDCInAppPurchaseDialog[qmn-og]")
									 defaultButton:TXTLS(@"Prompts[c7s-dq]")
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
		
		[self refreshStatusAfterProductsChange];
	});
}

- (void)refreshStatusAfterProductsChange
{
	TDCInAppPurchaseDialogChangedProductsPayload *changedProducts = self.changedPoducts;

	BOOL success = (changedProducts.finishedProductIdentifiers.count > 0 ||
					changedProducts.restoredProductIdentifiers.count > 0);
	
	self.performingPurchase = NO;

	self.changedPoducts = nil;
	
	BOOL windowIsVisible = (self.window.visible && self.products != nil);
	
	if (success == NO) {
		LogToConsoleDebug("Finished processing transactions with only failures");
		
		if (windowIsVisible) {
			[self updateSelectedPane];
		}
		
		return;
	}
	
	LogToConsoleDebug("Finished processing transactions");
	
	if (windowIsVisible) {
		[self showThankYouAfterProductPurchase];
		
		[self updateSelectedPane];
		
		[self refreshProductsTableContents];
	}

	[self postTransactionFinishedNotification:
	 [changedProducts.finishedProductIdentifiers arrayByAddingObjectsFromArray:
	  changedProducts.restoredProductIdentifiers]];
	
	if (self.finishedLoading == NO) {
		[self loadReceiptDuringLaunchPostflight];
	}
}

- (void)showThankYouAfterProductPurchase
{
	if (TLOAppStoreTextualIsRegistered() == NO) {
		return;
	}

	[TDCAlert alertSheetWithWindow:self.window
							  body:TXTLS(@"TDCInAppPurchaseDialog[get-1i]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[2g7-u2]")
					 defaultButton:TXTLS(@"Prompts[c7s-dq]")
				   alternateButton:nil
					   otherButton:nil];
}

- (void)postTransactionFinishedNotification:(NSArray<NSString *> *)products
{
	NSParameterAssert(products != nil);

	[self postNotification:TDCInAppPurchaseDialogTransactionFinishedNotification forProducts:products];
}

- (void)postNotification:(NSString *)notification forProducts:(NSArray<NSString *> *)products
{
	NSParameterAssert(notification != nil);
	NSParameterAssert(products != nil);

	NSDictionary *userInfo = @{
		@"productIdentifiers" : [products copy]
	};

	[RZNotificationCenter() postNotificationName:notification
										  object:self
										userInfo:userInfo];
}

#pragma mark -
#pragma mark Content Views

- (void)refreshProductsTableContents
{
	LogToConsoleDebug("Refreshing products table");

	[self.productsTableController removeAllArrangedObjects];

	if (TLOAppStoreTextualIsRegistered()) {
		LogToConsoleDebug("No products displayed because Textual is registered");

		return;
	}

	[self addTrialToProductsTableContents];

	[self.productsTableController addObject:
	 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPProductIdentifierStandardEdition]];

	TDCInAppPurchaseProductsTableEntry *discountEntry = [self productsTableUpgradeEligibilityEntry];

	if (discountEntry != nil) {
		[self.productsTableController addObject:discountEntry];
	}
}

- (void)addTrialToProductsTableContents
{
	if (TLOAppStoreIsTrialPurchased()) {
		return;
	}
	
	[self.productsTableController addObject:
	 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPProductIdentifierFreeTrial]];
}

- (void)updateSelectedPane
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
		[self.trialInformationHeightConstraint archiveConstantAndZeroOut];
		
		return;
	}

	[self.trialInformationHeightConstraint restoreArchivedConstant];

	NSString *formattedTrialInformation = [self timeRemainingInTrialFormattedMessage];

	self.trialInformationTextField.stringValue = formattedTrialInformation;
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
	self.checkingEligibility = YES;

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
	LogToConsoleDebug("Eligibility changed to %lu", sender.eligibility);

	if (sender.eligibility == TLOInAppPurchaseUpgradeEligibilityUnknown ||
		sender.eligibility == TLOInAppPurchaseUpgradeEligibilityNot)
	{
		return;
	}

	[self.productsTableController removeAllArrangedObjects];

	[self addTrialToProductsTableContents];

	if (sender.eligibility == TLOInAppPurchaseUpgradeEligibilityDiscount)
	{
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPProductIdentifierUpgradeFromV6]];
	}
	else if (sender.eligibility == TLOInAppPurchaseUpgradeEligibilityFree ||
			 sender.eligibility == TLOInAppPurchaseUpgradeEligibilityAlreadyUpgraded)
	{
		[self.productsTableController addObject:
		 [self productsTableEntryForProductIdentifier:TLOAppStoreIAPProductIdentifierUpgradeFromV6Free]];
	}
}

- (void)upgradeEligibilitySheetWillClose:(TDCInAppPurchaseUpgradeEligibilitySheet *)sender
{
	LogToConsoleDebug("Upgrade eligibility check end");

	self.checkingEligibility = NO;

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
	[self restoreTransactionsByClick];
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

	if (entryItem.entryType == TDCInAppPurchaseProductsTableEntryTypeProduct) {
		newView = [tableView makeViewWithIdentifier:@"productType" owner:self];
	} else if (entryItem.entryType == TDCInAppPurchaseProductsTableEntryTypeOther) {
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

	LogToConsoleDebug("Height of row %lu is %f", row, entryItem.rowHeight);

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
	if ([self.products containsKey:TLOAppStoreIAPProductIdentifierUpgradeFromV6] == NO ||
		[self.products containsKey:TLOAppStoreIAPProductIdentifierUpgradeFromV6Free] == NO)
	{
		return nil;
	}

	/* Create entry */
	TDCInAppPurchaseProductsTableEntry *tableEntry = [TDCInAppPurchaseProductsTableEntry new];

	tableEntry.entryType = TDCInAppPurchaseProductsTableEntryTypeOther;

	tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[gaw-8q]");
	tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[e1e-6i]");
	tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[nf3-6r]");

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
		case TLOAppStoreIAPProductFreeTrial:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryTypeOther;

			tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[20h-oi]");
			tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[4ad-nr]");
			tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[xpq-66]");

			break;
		}
		case TLOAppStoreIAPProductStandardEdition:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryTypeProduct;

			tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[yrh-s6]");
			tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[2xq-43]");
			tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[k0r-mf]");

			break;
		}
		case TLOAppStoreIAPProductUpgradeFromV6:
		case TLOAppStoreIAPProductUpgradeFromV6Free:
		{
			tableEntry.entryType = TDCInAppPurchaseProductsTableEntryTypeProduct;

			SKProduct *standardEdition = self.products[TLOAppStoreIAPProductIdentifierStandardEdition];

			if (standardEdition == nil) {
				NSAssert(NO, @"The 'Standard Edition' product is missing");
			}

			tableEntry.productPriceDiscounted = standardEdition.price;

			if (productType == TLOAppStoreIAPProductUpgradeFromV6)
			{
				tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[ako-hb]");
				tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[pnz-0z]");
				tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[xdz-gd]");
			}
			else if (productType == TLOAppStoreIAPProductUpgradeFromV6Free)
			{
				tableEntry.entryTitle = TXTLS(@"TDCInAppPurchaseDialog[7g1-nd]");
				tableEntry.entryDescription = TXTLS(@"TDCInAppPurchaseDialog[877-q1]");
				tableEntry.actionButtonTitle = TXTLS(@"TDCInAppPurchaseDialog[j44-8p]");
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
		case TLOAppStoreIAPProductFreeTrial:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[20h-oi]");

			break;
		}
		case TLOAppStoreIAPProductStandardEdition:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[yrh-s6]");

			break;
		}
		case TLOAppStoreIAPProductUpgradeFromV6:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[ako-hb]");

			break;
		}
		case TLOAppStoreIAPProductUpgradeFromV6Free:
		{
			productTitle = TXTLS(@"TDCInAppPurchaseDialog[7g1-nd]");

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

		[TDCAlert alertSheetWithWindow:self.window
								  body:TXTLS(@"TDCInAppPurchaseDialog[ej5-pi]")
								 title:TXTLS(@"TDCInAppPurchaseDialog[ziy-5r]", productTitle)
						 defaultButton:TXTLS(@"Prompts[c7s-dq]")
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

	self.performingPurchase = YES;

	LogToConsoleDebug("Paying for product '%@'", product.productIdentifier);

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[jpv-e7]")];

	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];

	payment.quantity = quantity;

	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restoreTransactionsByClick
{
	/* Sheets with a restore button aren't dismissed when Textual
	 is unlocked because that is an additional headache. That means
	 that the user can click the restore button after the fact.
	 We intercept that event below. */
	if (TLOAppStoreTextualIsRegistered()) {
		[TDCAlert alertSheetWithWindow:self.window
								  body:TXTLS(@"TDCInAppPurchaseDialog[be0-0g]")
								 title:TXTLS(@"TDCInAppPurchaseDialog[bgq-1w]")
						 defaultButton:TXTLS(@"Prompts[c7s-dq]")
					   alternateButton:nil
						   otherButton:nil];
		
		return;
	}
	
	if (self.performingRestore || self.performRestoreNextChance) {
		NSBeep();
		
		return;
	}
	
	self.performRestoreNextChance = YES;

	[self restoreTransactionsDeferred];
}

- (BOOL)restoreTransactionsDeferred
{
	if (self.productsLoaded == NO) {
		LogToConsoleDebug("Waiting for products to be loaded");

		return NO;
	}

	if (self.performRestoreNextChance) {
		self.performRestoreNextChance = NO;
	} else {
		return NO;
	}
	
	LogToConsoleDebug("Restoring transactions during next chance");

	[self restoreTransactions];
	
	return YES;
}

- (void)restoreTransactions
{
	LogToConsoleDebug("Restoring transactions");

	[self requestReceiptRefresh];
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
	[self loadReceipt];

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
	if (TLOAppStoreNumberOfPurchasedProducts() == 0) {
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
	self.performingRestore = YES;

	LogToConsoleDebug("Receipt refresh start");

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[uyd-ja]")];

	SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];

	receiptRefreshRequest.delegate = (id)self;

	[receiptRefreshRequest start];

	self.receiptRefreshRequest = receiptRefreshRequest;
}

- (void)onRefreshReceiptGenericError:(NSError *)error
{
	NSParameterAssert(error != nil);

	LogToConsoleDebug("Receipt refresh error: %@", error.localizedDescription);

	[TDCAlert alertSheetWithWindow:self.window
							  body:TXTLS(@"TDCInAppPurchaseDialog[3q4-qb]", error.localizedDescription)
							 title:TXTLS(@"TDCInAppPurchaseDialog[dkh-er]")
					 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[3rs-ji]")
				   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[ywm-0b]")
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   if (buttonClicked == TDCAlertResponseAlternate) {
						   [self contactSupport];
					   }

					   [self requestReceiptRefresh];
				   }];
}

- (void)onRefreshReceiptPostflightWithError:(nullable NSError *)error
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _onRefreshReceiptPostflightWithError:error];
	});
}

- (void)_onRefreshReceiptPostflightWithError:(nullable NSError *)error
{
	LogToConsoleDebug("Receipt refresh end");

	self.performingRestore = NO;

	self.receiptRefreshRequest = nil;

	/* "Cancel" button on sign on prompt */
	if (error && [error.domain isEqualToString:@"ISErrorDomain"] && error.code == (-128))
	{
		if (self.productsLoaded == NO) {
			/* We cannot allow an event to be cancelled if we do not have a
			 product list to show the user when progress view is hidden. */
			error = [NSError errorWithDomain:TXErrorDomain
										code:3001
									userInfo:@{
						NSLocalizedDescriptionKey : TXTLS(@"TDCInAppPurchaseDialog[ftc-vw]")
					}];
		} else {
			/* If we do have a product list, then we can safely dismiss
			 the progress view and not worry about what the user sees. */
			[self updateSelectedPane];
			
			return;
		}
	}

	/* Refresh receipt */
	if (error == nil && [self loadReceipt] == NO) {
		error = [NSError errorWithDomain:TXErrorDomain
									code:3002
								userInfo:@{
					NSLocalizedDescriptionKey : TXTLS(@"TDCInAppPurchaseDialog[5ga-lv]")
				}];
	}

	/* Any error is a hard error and nothing is to be
	 continued from this point on. User will be given
	 option to try loading products again. */
	if (error) {
		[self onRefreshReceiptGenericError:error];
		
		return;
	}
	
	/* Finish restoring */
	NSArray *purchasedProducts = TLOAppStorePurchasedProducts();
	
	TDCInAppPurchaseDialogChangedProductsPayload *changedProducts =
	[TDCInAppPurchaseDialogChangedProductsPayload new];
	
	changedProducts.atleastOne = (purchasedProducts.count > 0);
	
	changedProducts.failedProductIdentifiers = @[];
	changedProducts.finishedProductIdentifiers = @[];
	changedProducts.restoredProductIdentifiers = purchasedProducts;
	
	self.changedPoducts = changedProducts;
	
	[self refreshStatusAfterProductsChange];
	
	/* If we failed to load products because of a missing
	 receipt, then we try to load them again once we do
	 have a receipt. */
	if (self.loadProductsAfterReceiptRefresh) {
		self.loadProductsAfterReceiptRefresh = NO;
		
		/* Whether or not Textual is registered when refreshing
		 the receipt. If it changes to registered, then we have
		 no need to request products. */
		if (TLOAppStoreTextualIsRegistered() == NO) {
			[self requestProducts];
		}

		return;
	}
}

#pragma mark -
#pragma mark Products Request

- (void)requestProducts
{
	self.requestingProducts = YES;

	LogToConsoleDebug("Products request start");

	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[703-d3]")];

	NSSet *productIdentifiers =
	[NSSet setWithArray:
	 @[
		TLOAppStoreIAPProductIdentifierFreeTrial,
		TLOAppStoreIAPProductIdentifierStandardEdition,
		TLOAppStoreIAPProductIdentifierUpgradeFromV6,
		TLOAppStoreIAPProductIdentifierUpgradeFromV6Free
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
	
	self.productsLoaded = (productsDict.count > 0);
}

- (void)onRequestProductsGenericError:(NSError *)error
{
	NSParameterAssert(error != nil);
	
	LogToConsoleDebug("Products request error: %@", error.localizedDescription);

	[TDCAlert alertSheetWithWindow:self.window
							  body:TXTLS(@"TDCInAppPurchaseDialog[h2w-2l]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[qaj-hh]")
					 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[4n7-1e]")
				   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[iot-5w]")
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   if (buttonClicked == TDCAlertResponseAlternate) {
						   [self contactSupport];
					   }
					   
					   [self requestProducts];
				   }];
}

- (void)onRequestProductsEmptyProductListError
{
	[TDCAlert alertSheetWithWindow:self.window
							  body:TXTLS(@"TDCInAppPurchaseDialog[n09-d1]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[dg7-y2]")
					 defaultButton:TXTLS(@"Prompts[zjw-bd]")
				   alternateButton:nil
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   self.loadProductsAfterReceiptRefresh = YES;
					   
					   [self requestReceiptRefresh];
				   }];
}

- (void)onRequestProductsPostflightWithError:(nullable NSError *)error
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _onRequestProductsPostflightWithError:error];
	});
}

- (void)_onRequestProductsPostflightWithError:(nullable NSError *)error
{
	LogToConsoleDebug("Products request end");

	self.requestingProducts = YES;

	self.productsRequest = nil;

	/* Any error is a hard error and nothing is to be
	 continued from this point on. User will be given
	 option to try loading products again. */
	if (error) {
		[self onRequestProductsGenericError:error];

		return;
	}

	/* The App Store returns an empty list of products,
	 without error, when a receipt file is missing.
	 We present a specific error in that case which
	 tells the user to refresh the receipt. */
	/* self.productsLoaded is always NO if the list of
	 products does not contain an entry. */
	if (self.productsLoaded == NO) {
		[self onRequestProductsEmptyProductListError];
		
		return;
	}

	/* Perform postflight actions */
	[self refreshProductsTableContents];
	
	if ([self restoreTransactionsDeferred]) {
		return;
	}

	[self updateSelectedPane];
}

#pragma mark -
#pragma mark Requests Delegate

- (void)requestDidFinish:(SKRequest *)request
{
	if (request == self.productsRequest) {
		[self onRequestProductsPostflightWithError:nil];
	} else if (request == self.receiptRefreshRequest) {
		[self onRefreshReceiptPostflightWithError:nil];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if (request == self.productsRequest) {
		[self onRequestProductsPostflightWithError:error];
	} else if (request == self.receiptRefreshRequest) {
		[self onRefreshReceiptPostflightWithError:error];
	}
}

#pragma mark -
#pragma mark Window Delegate

- (void)showPleaseSelectItemError
{
	[TDCAlert alertSheetWithWindow:self.window
							  body:TXTLS(@"TDCInAppPurchaseDialog[zyf-bl]")
							 title:TXTLS(@"TDCInAppPurchaseDialog[e15-d5]")
					 defaultButton:TXTLS(@"Prompts[c7s-dq]")
				   alternateButton:nil
					   otherButton:nil];
}

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

#pragma mark -

@implementation TDCInAppPurchaseDialogChangedProductsPayload
@end

NS_ASSUME_NONNULL_END

#endif
