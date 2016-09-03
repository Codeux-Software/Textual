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

#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@class TVCQueuedCertificateTrustPanelContext;

@interface TVCQueuedCertificateTrustPanel ()
@property (nonatomic, strong) NSMutableArray<TVCQueuedCertificateTrustPanelContext *> *queuedEntries;
@property (nonatomic, strong, nullable) SFCertificateTrustPanel *currentPanel;
@property (nonatomic, weak) GCDAsyncSocket *currentSocket; // The current, open sheet
@property (nonatomic, assign) BOOL doNotInvokeCompletionBlockNextPass;
@end

@interface TVCQueuedCertificateTrustPanelContext : NSObject
@property (nonatomic, weak) GCDAsyncSocket *socket;
@property (nonatomic, copy) TVCQueuedCertificateTrustPanelCompletionBlock completionBlock;
@end

@implementation TVCQueuedCertificateTrustPanel

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];
		
		return self;
	}
	
	return nil;
}

- (void)prepareInitialState
{
	self.queuedEntries = [NSMutableArray array];
}

- (void)enqueue:(GCDAsyncSocket *)socket withCompletionBlock:(TVCQueuedCertificateTrustPanelCompletionBlock)completionBlock
{
	NSParameterAssert(socket != nil);
	NSParameterAssert(completionBlock != nil);

	 TVCQueuedCertificateTrustPanelContext *context =
	[TVCQueuedCertificateTrustPanelContext new];

	context.completionBlock = completionBlock;

	context.socket = socket;
	
	@synchronized(self.queuedEntries) {
		[self.queuedEntries addObject:context];

		if (self.queuedEntries.count == 1) {
			[self presentNextQueuedEntry];
		}
	}
}

- (void)dequeueEntryForSocket:(GCDAsyncSocket *)socket
{
	NSParameterAssert(socket != nil);

	if (self.currentSocket == nil) {
		return;
	}

	/* If the given socket is the socket that's currently presented,
	 then access private API to dismiss the open sheet. */
	if (self.currentSocket == socket) {
		SEL dismissSelector = NSSelectorFromString(@"_dismissWithCode:");

		if ([self.currentPanel respondsToSelector:dismissSelector]) {
			self.doNotInvokeCompletionBlockNextPass = YES;

			(void)objc_msgSend(self.currentPanel, dismissSelector, NSModalResponseCancel);
		}

		return;
	}

	/* Search queued entries for entry that matches socket */
	@synchronized(self.queuedEntries) {
		NSUInteger entryIndex =
			[self.queuedEntries indexOfObjectPassingTest:^BOOL(TVCQueuedCertificateTrustPanelContext *object, NSUInteger index, BOOL *stop) {
				return (object.socket == socket);
			}];

		if (entryIndex != NSNotFound) {
			[self.queuedEntries removeObjectAtIndex:entryIndex];
		}
	}
}

- (void)presentNextQueuedEntry
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		[self _presentNextQueuedEntry];
	});
}

- (void)_presentNextQueuedEntry
{
	TVCQueuedCertificateTrustPanelContext *contextInfo = self.queuedEntries[0];

	self.currentSocket = contextInfo.socket;

	SecTrustRef trustRef = self.currentSocket.sslCertificateTrustInformation;

	NSString *policyName = self.currentSocket.sslCertificateTrustPolicyName;

	NSString *description = TXTLS(@"Prompts[1131][2]", policyName);

	self.currentPanel = [SFCertificateTrustPanel new];

	[self.currentPanel setAlternateButtonTitle:TXTLS(@"Prompts[0004]")];

	[self.currentPanel setInformativeText:description];

	[self.currentPanel beginSheetForWindow:nil
							 modalDelegate:self
							didEndSelector:@selector(_certificateSheetDidEnd_stage1:returnCode:contextInfo:)
							   contextInfo:(__bridge void *)(contextInfo)
									 trust:trustRef
								   message:TXTLS(@"Prompts[1131][1]", policyName)];
}

- (void)_certificateSheetDidEnd_stage1:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	TVCQueuedCertificateTrustPanelContext *contextObject = (__bridge TVCQueuedCertificateTrustPanelContext *)contextInfo;

	[self _certificateSheetDidEnd_stage2:sheet returnCode:returnCode contextInfo:contextObject];
}

- (void)_certificateSheetDidEnd_stage2:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(TVCQueuedCertificateTrustPanelContext *)contextInfo
{
	if (self.doNotInvokeCompletionBlockNextPass) {
		self.doNotInvokeCompletionBlockNextPass = NO;
	} else {
		BOOL isTrusted = (returnCode == NSModalResponseOK);

		contextInfo.completionBlock(isTrusted);
	}

	self.currentPanel = nil;

	self.currentSocket = nil;

	@synchronized(self.queuedEntries) {
		[self.queuedEntries removeObjectAtIndex:0];

		if (self.queuedEntries.count > 0) {
			[self presentNextQueuedEntry];
		}
	}
}

@end

#pragma mark -

@implementation TVCQueuedCertificateTrustPanelContext
@end

NS_ASSUME_NONNULL_END
