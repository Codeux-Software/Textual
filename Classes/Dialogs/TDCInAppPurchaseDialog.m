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

@interface TDCInAppPurchaseDialog ()
@property (nonatomic, strong) TLOTimer *trialTimer;
@property (nonatomic, assign) BOOL windowIsAllowedToClose;
@property (nonatomic, assign) BOOL finishedLoading;
@property (nonatomic, assign) BOOL requestingProducts;
@property (nonatomic, assign) BOOL performRestoreOnShow;
@property (nonatomic, assign) BOOL performingRestore;
@property (nonatomic, assign) BOOL performingPurchase;
@property (nonatomic, assign) NSUInteger purchasedProductState;
@property (nonatomic, copy, nullable) NSString *purchasedProductIdentifier;
@property (nonatomic, copy, nullable) NSError *purchasedProductError;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, copy) NSDictionary<NSString *, SKProduct *> *products;
@property (nonatomic, strong) IBOutlet NSView *contentViewProducts;
@property (nonatomic, strong) IBOutlet NSView *contentViewProgress;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressViewIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *progressViewTextField;

- (IBAction)payForItem:(id)sender;
- (IBAction)restoreTransactions:(id)sender;

/* Temporary actions */
- (IBAction)payForFreeTrial:(id)sender;
- (IBAction)payForStandardEdition:(id)sender;
- (IBAction)payForUpgradeFromV6:(id)sender;
- (IBAction)payForUpgradeFromV6Free:(id)sender;
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

	self.purchasedProductState = SKPaymentTransactionStateUnknown;
}

- (void)prepareForApplicationTermination
{
	[self stopTrialTimer];

	[self removePaymentQueueObserver];
}

- (void)applicationDidFinishLaunching
{
	[self loadReceiptDuringLaunch];

	[self toggleTrialTimer];

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
	}

	[super show];
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

	self.trialTimer = [TLOTimer new];
	self.trialTimer.repeatTimer = NO;
	self.trialTimer.target = self;
	self.trialTimer.action = @selector(onTrialTimer:);

	[self.trialTimer start:timeRemaining];
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

	[self _showTrialIsExpiredMessageInWindow:self.window];

	[RZNotificationCenter() postNotificationName:TDCInAppPurchaseDialogTrialExpiredNotification object:self];
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
									  body:TXTLS(@"TDCInAppPurchaseDialog[0011][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0011][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0011][3]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[0011][4]")
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
									  body:TXTLS(@"TDCInAppPurchaseDialog[0010][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0010][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0010][3]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseDialog[0010][4]")
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
	/* Sort transactions with state as key and value as array of related transactions. */
	NSMutableDictionary<NSNumber *, NSMutableArray<SKPaymentTransaction *> *> *sortedTransactions = [NSMutableDictionary new];

	for (SKPaymentTransaction *transaction in transactions) {
		NSNumber *transactionKey = @(transaction.transactionState);

		NSMutableArray *relatedTransactions = sortedTransactions[transactionKey];

		if (relatedTransactions == nil) {
			relatedTransactions = [NSMutableArray array];

			[sortedTransactions setObject:relatedTransactions forKey:transactionKey];
		}

		[relatedTransactions addObject:transaction];
	} // for loop

	/* Process transactions by state */
	for (NSNumber *transactionState in sortedTransactions) {
		NSArray *transactions = sortedTransactions[transactionState];

		switch (transactionState.unsignedIntegerValue) {
			case SKPaymentTransactionStatePurchasing:
			{
				[self showTransactionsAsInProgress:transactions deferred:NO];

				break;
			}
			case SKPaymentTransactionStateDeferred:
			{
				[self showTransactionsAsInProgress:transactions deferred:YES];

				break;
			}
			case SKPaymentTransactionStateFailed:
			{
				[self failedTransactions:transactions];

				break;
			}
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
			{
				[self processSuccessfulTransactions:transactions];

				break;
			}
			default:
			{
				break;
			}
		} // switch
	} // for loop
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	self.performingRestore = NO;

	[self detachProgressView];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	self.performingRestore = NO;

	[self detachProgressView];

	[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0007][2]", error.localizedDescription)
									 title:TXTLS(@"TDCInAppPurchaseDialog[0007][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:nil
							   otherButton:nil];
}

- (void)showTransactionsAsInProgress:(NSArray<SKPaymentTransaction *> *)transactions deferred:(BOOL)deferred
{
	NSParameterAssert(transactions != nil);
}

- (void)failedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	/* Process transactions */
	NSString *purchaedProductIdentifier = self.purchasedProductIdentifier;

	for (SKPaymentTransaction *transaction in transactions) {
		/* Record product status */
		if (purchaedProductIdentifier != nil) {
			NSString *productIdentifier = transaction.payment.productIdentifier;

			if (NSObjectsAreEqual(productIdentifier, purchaedProductIdentifier)) {
				self.purchasedProductState = transaction.transactionState;

				self.purchasedProductError = transaction.error;
			}
		}

		/* Finish transaction */
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	}

	/* Clear progress */
	[self finishProductPurchase];
}

- (void)processSuccessfulTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	NSParameterAssert(transactions != nil);

	/* This method should never be invoked for transactions that
	 are not finished or restored. */
	/* This method uses asserts on conditions that should never
	 be met unless someone was tampering with the transaction. */
	BOOL receiptLoaded = [self loadReceipt];

	if (receiptLoaded == NO) {
		[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
										  body:TXTLS(@"TDCInAppPurchaseDialog[0003][1]")
										 title:TXTLS(@"TDCInAppPurchaseDialog[0003][2]")
								 defaultButton:TXTLS(@"Prompts[0005]")
							   alternateButton:nil
								   otherButton:nil];

		NSAssert(NO, @"Receipt is invalid");
	}

	/* Process transactions */
	NSString *purchaedProductIdentifier = self.purchasedProductIdentifier;

	for (SKPaymentTransaction *transaction in transactions)	{
		/* Record product status */
		if (purchaedProductIdentifier != nil) {
			NSString *productIdentifier = transaction.payment.productIdentifier;

			if (NSObjectsAreEqual(productIdentifier, purchaedProductIdentifier)) {
				self.purchasedProductState = transaction.transactionState;
			}
		}

		/* Finish transaction */
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	} // for loop

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		/* Post notifications */
		[self postTransactionFinishedNotification:transactions];

		/* This method may be called without the window visible because there
		 may be items left in the queue when launching (e.g. crash). */
		if (self.window.visible == NO) {
			[self show];
		}

		/* Clear progress */
		[self finishProductPurchase];

		[self toggleTrialTimer];

		[self showThankYouAfterProductPurchase];

		/* Reload launch status if necessary */
		if (self.finishedLoading == NO) {
			[self loadReceiptDuringLaunchPostflight];
		}
	});
}

- (void)finishProductPurchase
{
	if (self.performingPurchase == NO) {
		return;
	}

	if (self.purchasedProductState == SKPaymentTransactionStateUnknown ||
		self.purchasedProductState == SKPaymentTransactionStatePurchasing ||
		self.purchasedProductState == SKPaymentTransactionStateDeferred)
	{
		return;
	}

	if (self.purchasedProductState == SKPaymentTransactionStateFailed) {
		if (self.purchasedProductError.code != SKErrorPaymentCancelled) {
			[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
											  body:TXTLS(@"TDCInAppPurchaseDialog[0008][2]", self.purchasedProductError.localizedDescription)
											 title:TXTLS(@"TDCInAppPurchaseDialog[0008][1]")
									 defaultButton:TXTLS(@"Prompts[0005]")
								   alternateButton:nil
									   otherButton:nil];

			self.purchasedProductError = nil;
		}
	}

	self.performingPurchase = NO;

	self.purchasedProductState = SKPaymentTransactionStateUnknown;

	self.purchasedProductIdentifier = nil;

	[self detachProgressView];
}

- (void)showThankYouAfterProductPurchase
{
	if (TLOAppStoreTextualIsRegistered() == NO) {
		[self close];
	}

	[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0012][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0012][1]")
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

- (void)attachProductsView
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		NSView *windowContentView = self.window.contentView;

		NSView *productsContentView = self.contentViewProducts;

		[windowContentView attachSubview:productsContentView
				 adjustedWidthConstraint:nil
				adjustedHeightConstraint:nil];
	});
}

- (void)attachProgressViewWithReason:(NSString *)progressReason
{
	NSParameterAssert(progressReason != nil);

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		NSView *windowContentView = self.window.contentView;

		NSView *progressContentView = self.contentViewProgress;

		[windowContentView attachSubview:progressContentView
				 adjustedWidthConstraint:nil
				adjustedHeightConstraint:nil];

		self.progressViewTextField.stringValue = progressReason;

		[self.progressViewIndicator startAnimation:nil];

		self.windowIsAllowedToClose = NO;
	});
}

- (void)detachProgressView
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		self.windowIsAllowedToClose = YES;

		[self.progressViewIndicator stopAnimation:nil];

		[self attachProductsView];
	});
}

- (void)setWindowIsAllowedToClose:(BOOL)windowIsAllowedToClose
{
	if (self->_windowIsAllowedToClose != windowIsAllowedToClose) {
		self->_windowIsAllowedToClose = windowIsAllowedToClose;

		[self.window standardWindowButton:NSWindowCloseButton].enabled = windowIsAllowedToClose;
	}
}

#pragma mark -
#pragma mark Actions

- (void)payForItem:(id)sender
{

}

- (void)payForFreeTrial:(id)sender
{
	[self payForFreeTrial];
}

- (void)payForStandardEdition:(id)sender
{
	[self payForStandardEdition];
}

- (void)payForUpgradeFromV6:(id)sender
{
	[self payForUpgradeFromV6];
}

- (void)payForUpgradeFromV6Free:(id)sender
{
	[self payForUpgradeFromV6Free];
}

- (void)restoreTransactions:(id)sender
{
	[self restoreTransactions];
}

#pragma mark -
#pragma mark Products

- (nullable NSString *)localizedTitleForProduct:(SKProduct *)product
{
	NSParameterAssert(product != nil);

	return [self localizedTitleForProductIdentifier:product.productIdentifier];
}

- (nullable NSString *)localizedTitleForProductIdentifier:(NSString *)productId
{
	NSParameterAssert(productId);

	NSString *titleKey = [NSString stringWithFormat:@"TDCInAppPurchaseDialog[0001][%@]", productId];

	NSString *title = TXTLS(titleKey);

	return title;
}

- (BOOL)isProductPaidFor:(NSString *)productId
{
	NSParameterAssert(productId != nil);

	return TLOAppStoreIsProductPurchased(productId);
}

- (void)payForFreeTrial
{
	[self payForProductIdentifier:TLOAppStoreIAPFreeTrialProductIdentifier];
}

- (void)payForStandardEdition
{
	[self payForProductIdentifier:TLOAppStoreIAPStandardEditionProductIdentifier];
}

- (void)payForUpgradeFromV6
{
	[self payForProductIdentifier:TLOAppStoreIAPUpgradeFromV6ProductIdentifier];
}

- (void)payForUpgradeFromV6Free
{
	[self payForProductIdentifier:TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier];
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

		[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
										  body:TXTLS(@"TDCInAppPurchaseDialog[0002][2]")
										 title:TXTLS(@"TDCInAppPurchaseDialog[0002][1]", productTitle)
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

	self.purchasedProductIdentifier = product.productIdentifier;

	/* Show progress view */
	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0005]")];

	/* Perform purchase */
	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];

	payment.quantity = quantity;

	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restoreTransactionsOnShow
{
	if (self.performRestoreOnShow) {
		self.performRestoreOnShow = NO;
	} else {
		return;
	}

	[self restoreTransactions];
}

- (void)restoreTransactions
{
	/* Set status properties */
	if (self.performingPurchase) {
		return;
	}

	if (self.performingRestore == NO) {
		self.performingRestore = YES;
	} else {
		return;
	}

	/* Show progress view */
	[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0006]")];

	/* Perform restore */
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)showPleaseSelectItemError
{
	[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0009][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0009][1]")
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
		[self attachProgressViewWithReason:TXTLS(@"TDCInAppPurchaseDialog[0004]")];
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

	/* We only hide the progress view when we have a list of products,
	 otherwise the user will be seeing a blank products page. */
	[self detachProgressView];

	/* Restore transactions if user clicked certain button. */
	[self restoreTransactionsOnShow];
}

- (void)onRequestProductsError:(NSError *)error
{
	[TLOPopupPrompts sheetWindowWithWindow:self.window.deepestWindow
									  body:TXTLS(@"TDCInAppPurchaseDialog[0003][2]")
									 title:TXTLS(@"TDCInAppPurchaseDialog[0003][1]")
							 defaultButton:TXTLS(@"TDCInAppPurchaseDialog[0003][3]")
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

@end

NS_ASSUME_NONNULL_END

#endif
