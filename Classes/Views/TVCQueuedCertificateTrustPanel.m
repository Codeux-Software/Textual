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

#import <objc/message.h>

@interface TVCQueuedCertificateTrustPanel ()
@property (nonatomic, strong) NSMutableArray *queuedEntries;
@property (nonatomic, strong) SFCertificateTrustPanel *currentPanel;
@property (nonatomic, weak) id activeSocket; // The current, open sheet
@property (nonatomic, assign) BOOL doNotInvokeCompletionBlockNextPass;
@end

@interface TVCQueuedCertificateTrustPanelObject : NSObject
@property (nonatomic, weak) id socketHandler;
@property (nonatomic, copy) TVCQueuedCertificateTrustPanelCompletionBlock completionBlock;
@end

@implementation TVCQueuedCertificateTrustPanel

- (instancetype)init
{
	if ((self = [super init])) {
		self.queuedEntries = [NSMutableArray array];
		
		return self;
	}
	
	return nil;
}

- (void)enqueue:(id)socket withCompletionBlock:(TVCQueuedCertificateTrustPanelCompletionBlock)completionBlock
{
	TVCQueuedCertificateTrustPanelObject *newObject = [TVCQueuedCertificateTrustPanelObject new];

	[newObject setSocketHandler:socket];

	[newObject setCompletionBlock:completionBlock];
	
	@synchronized(self.queuedEntries) {
		[self.queuedEntries addObject:newObject];

		if ([self.queuedEntries count] == 1) {
			[self presentNextQueuedEntry];
		}
	}
}

- (void)dequeueEntryForSocket:(id)socket
{
	if (self.activeSocket) {
		if (self.activeSocket == socket) {
			if (self.currentPanel) {
				SEL selectorName = NSSelectorFromString(@"_dismissWithCode:");

				if ([self.currentPanel respondsToSelector:selectorName]) {
					[self setDoNotInvokeCompletionBlockNextPass:YES];

					(void)objc_msgSend(self.currentPanel, selectorName, NSModalResponseCancel);
				}
			}
		} else {
			@synchronized(self.queuedEntries) {
				__block NSInteger matchedIndex = -1;

				[self.queuedEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					if ([obj socketHandler] == socket) {
						matchedIndex = idx;

						*stop = YES;
					}
				}];

				if (matchedIndex > -1) {
					[self.queuedEntries removeObjectAtIndex:matchedIndex];
				}
			}
		}
	}
}

- (void)presentNextQueuedEntry
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		/* Gather information. */
		/* The oldest entry will be at index 0. */
		TVCQueuedCertificateTrustPanelObject *contextInfo = self.queuedEntries[0];

		self.activeSocket = [contextInfo socketHandler];

		/* Build panel. */
		SecTrustRef trustInfo = [self.activeSocket sslCertificateTrustInformation];

		NSString *certificateHost = [self.activeSocket sslCertificateTrustPolicyName];

		NSString *description = TXTLS(@"Prompts[1131][2]", certificateHost);

		 self.currentPanel = [SFCertificateTrustPanel new];
		
		[self.currentPanel setAlternateButtonTitle:TXTLS(@"Prompts[0004]")];
		
		[self.currentPanel setInformativeText:description];
		
		/* Begin sheet. */
		[self.currentPanel beginSheetForWindow:nil
							 modalDelegate:self
							didEndSelector:@selector(_certificateSheetDidEnd_stage1:returnCode:contextInfo:)
							   contextInfo:(__bridge void *)(contextInfo)
									 trust:trustInfo
								   message:TXTLS(@"Prompts[1131][1]", certificateHost)];
	});
}

- (void)_certificateSheetDidEnd_stage1:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	TVCQueuedCertificateTrustPanelObject *contextObject = (__bridge TVCQueuedCertificateTrustPanelObject *)contextInfo;

	[self _certificateSheetDidEnd_stage2:sheet returnCode:returnCode contextInfo:contextObject];
}

- (void)_certificateSheetDidEnd_stage2:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(TVCQueuedCertificateTrustPanelObject *)contextInfo
{
	/* Inform callback of result. */
	if (self.doNotInvokeCompletionBlockNextPass == NO) {
		BOOL isTrusted = (returnCode == NSModalResponseOK);

		[contextInfo completionBlock](isTrusted);
	} else {
		self.doNotInvokeCompletionBlockNextPass = NO;
	}

	[self setCurrentPanel:nil];

	[self setActiveSocket:nil];

	[self setDoNotInvokeCompletionBlockNextPass:NO];

	@synchronized(self.queuedEntries) {
		[self.queuedEntries removeObjectAtIndex:0];

		if ([self.queuedEntries count] > 0) {
			[self presentNextQueuedEntry];
		}
	}
}

@end

@implementation TVCQueuedCertificateTrustPanelObject
@end
