/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TVCAlert.h"

NS_ASSUME_NONNULL_BEGIN

TEXTUAL_EXTERN NSString * const TDCAlertSuppressionPrefix;

typedef NS_ENUM(NSUInteger, TDCAlertResponse) {
	TDCAlertResponseDefaultButton = 1000,
	TDCAlertResponseAlternateButton = 1001,
	TDCAlertResponseOtherButton = 1002
};

typedef void (^TDCAlertCompletionBlock)(TDCAlertResponse buttonClicked, BOOL suppressed, id _Nullable underlyingAlert);

@interface TDCAlert : NSObject
/* Return the actual suppression key used internally.
 Do not feed this to the suppressionKey: field of these alerts.
 This is what is fed to that field turns into once the alert is processed. */
+ (NSString *)suppressionKeyWithBase:(NSString *)base;

#pragma mark -
#pragma mark Modal Alerts (Panel)

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(nullable NSString *)buttonAlternate;

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(nullable NSString *)buttonAlternate
				 suppressionKey:(nullable NSString *)suppressKey
				suppressionText:(nullable NSString *)suppressText;

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
				accessoryView:(nullable NSView *)accessoryView;

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
		  suppressionResponse:(nullable BOOL *)suppressionResponse;

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
				accessoryView:(nullable NSView *)accessoryView
		  suppressionResponse:(nullable BOOL *)suppressionResponse;

#pragma mark -
#pragma mark Non-blocking Alerts (Panel)

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate;

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText;

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText
		   accessoryView:(nullable NSView *)accessoryView
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

#pragma mark -
#pragma mark Non-blocking Alerts (Sheet)

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton;

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			   accessoryView:(nullable NSView *)accessoryView
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			  suppressionKey:(nullable NSString *)suppressKey
			 suppressionText:(nullable NSString *)suppressText
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			  suppressionKey:(nullable NSString *)suppressKey
			 suppressionText:(nullable NSString *)suppressText
			   accessoryView:(nullable NSView *)accessoryView
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock;
@end

NS_ASSUME_NONNULL_END
