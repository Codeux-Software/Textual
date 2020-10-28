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

#import "RCMTrustPanel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCMTrustPanelContext : NSObject
@property (nonatomic, assign) SecTrustRef trustRef;
@property (nonatomic, copy) RCMTrustPanelCompletionBlock completionBlock;
@property (nonatomic, strong, nullable) id contextInfo;
@end

@implementation RCMTrustPanel

+ (SFCertificateTrustPanel *)presentTrustPanelInWindow:(nullable NSWindow *)window
												  body:(NSString *)bodyText
												 title:(NSString *)titleText
										 defaultButton:(NSString *)buttonDefault
									   alternateButton:(nullable NSString *)buttonAlternate
											  trustRef:(SecTrustRef)trustRef
									   completionBlock:(RCMTrustPanelCompletionBlock)completionBlock
{
	return
	[self presentTrustPanelInWindow:window
							   body:bodyText
							  title:titleText
					  defaultButton:buttonDefault
					alternateButton:buttonAlternate
						   trustRef:trustRef
					completionBlock:completionBlock
						contextInfo:nil];
}

+ (SFCertificateTrustPanel *)presentTrustPanelInWindow:(nullable NSWindow *)window
												  body:(NSString *)bodyText
												 title:(NSString *)titleText
										 defaultButton:(NSString *)buttonDefault
									   alternateButton:(nullable NSString *)buttonAlternate
											  trustRef:(SecTrustRef)trustRef
									   completionBlock:(RCMTrustPanelCompletionBlock)completionBlock
										   contextInfo:(nullable id)contextInfo
{
	/* Always work on the main thread */
	if ([NSThread isMainThread] == NO) {
		__block SFCertificateTrustPanel *panel = nil;

		[self performBlockOnMainThread:^{
			panel =
			[self presentTrustPanelInWindow:window
									   body:bodyText
									  title:titleText
							  defaultButton:buttonDefault
							alternateButton:buttonAlternate
								   trustRef:trustRef
							completionBlock:completionBlock
								contextInfo:contextInfo];
		}];

		return panel;
	}

	/* Retain the trust so that it is not released from underneath us. */
	CFRetain(trustRef);

	/* Crate context for callback selector */
	RCMTrustPanelContext *promptObject = [RCMTrustPanelContext new];

	promptObject.trustRef = trustRef;

	promptObject.completionBlock = completionBlock;

	promptObject.contextInfo = contextInfo;

	/* Construct panel and present */
	SFCertificateTrustPanel *panel = [SFCertificateTrustPanel new];

	[panel setDefaultButtonTitle:buttonDefault];
	[panel setAlternateButtonTitle:buttonAlternate];

	[panel setInformativeText:bodyText];

	[panel beginSheetForWindow:window
				 modalDelegate:[self class]
				didEndSelector:@selector(_trustPanelCallback_stage1:returnCode:contextInfo:)
				   contextInfo:(void *)CFBridgingRetain(promptObject)
						 trust:trustRef
					   message:titleText];

	return panel;
}

+ (void)_trustPanelCallback_stage1:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	RCMTrustPanelContext *panelData = (RCMTrustPanelContext *)CFBridgingRelease(contextInfo);

	[self _trustPanelCallback_stage2:sheet returnCode:returnCode contextInfo:panelData];
}

+ (void)_trustPanelCallback_stage2:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(RCMTrustPanelContext *)contextInfo
{
	SecTrustRef trustRef = contextInfo.trustRef;

	BOOL trusted = (returnCode == NSModalResponseOK);

	contextInfo.completionBlock(trustRef, trusted, contextInfo.contextInfo);

	CFRelease(trustRef);
}

@end

#pragma mark -

@implementation RCMTrustPanelContext
@end

NS_ASSUME_NONNULL_END
