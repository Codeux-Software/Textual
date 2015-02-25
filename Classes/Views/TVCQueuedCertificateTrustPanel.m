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

#define _descriptionIncludesAdditionalInformation			0

@interface TVCQueuedCertificateTrustPanel ()
/* Each entry is stored as an array with index 0 containing
 the trustRef and index 1 containing the completion block. */
@property (nonatomic, strong) NSMutableArray *queuedEntries;
@property (nonatomic, strong) SFCertificateTrustPanel *currentPanel;
@property (nonatomic, uweak) id activeSocket; // The current, open sheet
@property (nonatomic, assign) BOOL doNotInvokeCompletionBlockNextPass;
@end

@implementation TVCQueuedCertificateTrustPanel

- (instancetype)init
{
	if ((self = [super init])) {
		_queuedEntries = [NSMutableArray array];
		
		return self;
	}
	
	return nil;
}

- (void)enqueue:(SecTrustRef)trustRef withCompletionBlock:(TVCQueuedCertificateTrustPanelCompletionBlock)completionBlock forSocket:(id)socket
{
	/* Add new entry. */
	if (completionBlock == nil) {
		NSAssert(NO, @"'completionBlock' cannot be nil");
	}

	if (trustRef == NULL) {
		NSAssert(NO, @"'trustRef' cannot be NULL");
	}

	if (socket == nil) {
		NSAssert(NO, @"'socket' cannot be nil");
	}

	if ([socket isKindOfClass:[GCDAsyncSocket class]] == NO) {
		NSAssert(NO, @"'socket' is not kind of class 'GCDAsyncSocket'");
	}

	NSArray *newEntry = @[(__bridge id)(trustRef), [completionBlock copy], socket];
	
	@synchronized(_queuedEntries) {
		[_queuedEntries addObject:newEntry];

		if ([_queuedEntries count] == 1) {
			[self presentNextQueuedEntry];
		}
	}
}

- (void)dequeueEntryForSocket:(id)socket
{
	if (_activeSocket) {
		if (_activeSocket == socket) {
			if (_currentPanel) {
				if ([_currentPanel respondsToSelector:@selector(_dismissWithCode:)]) {
					[self setDoNotInvokeCompletionBlockNextPass:YES];

					(void)objc_msgSend(_currentPanel, @selector(_dismissWithCode:), NSModalResponseCancel);
				}
			}
		} else {
			@synchronized(_queuedEntries) {
				NSArray *_entries = [_queuedEntries copy];

				[_entries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					id _socket = obj[2];

					if (_socket == socket) {
						[_queuedEntries removeObjectAtIndex:idx];

						*stop = YES;
					}
				}];
			}
		}
	}
}

- (void)presentNextQueuedEntry
{
	XRPerformBlockSynchronouslyOnMainQueue(^{
		/* Gather information. */
		/* The oldest entry will be at index 0. */
		NSArray *contextInfo = _queuedEntries[0];

		[self setActiveSocket:contextInfo[2]];

		/* Build panel. */
		NSString *certificateHost = [_activeSocket sslCertificateTrustPolicyName];

#if _descriptionIncludesAdditionalInformation == 1
		NSString *ownershipInformation = [_activeSocket sslCertificateLocalizedOwnershipInformation];

		NSMutableString *description = [NSMutableString string];

		[description appendString:TXTLS(@"BasicLanguage[1229][2]", certificateHost)];

		if (ownershipInformation) {
			[description appendString:@"\n\n"];
			[description appendString:ownershipInformation];
		}
#else
		NSString *description = TXTLS(@"BasicLanguage[1229][2]", certificateHost);
#endif

		 _currentPanel = [SFCertificateTrustPanel new];
		
		[_currentPanel setAlternateButtonTitle:BLS(1009)];
		
		[_currentPanel setInformativeText:description];
		
		/* Begin sheet. */
		[_currentPanel beginSheetForWindow:nil
							 modalDelegate:self
							didEndSelector:@selector(_certificateSheetDidEnd_stage1:returnCode:contextInfo:)
							   contextInfo:(__bridge void *)(contextInfo)
									 trust:(__bridge SecTrustRef)(contextInfo[0])
								   message:TXTLS(@"BasicLanguage[1229][1]", certificateHost)];
	});
}

- (void)_certificateSheetDidEnd_stage1:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSArray *contextArray = (__bridge NSArray *)contextInfo;

	[self _certificateSheetDidEnd_stage2:sheet returnCode:returnCode contextInfo:contextArray];
}

- (void)_certificateSheetDidEnd_stage2:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSArray *)contextInfo
{
	/* Inform callback of result. */
	if (_doNotInvokeCompletionBlockNextPass == NO) {
		BOOL isTrusted = (returnCode == NSModalResponseOK);

		((TVCQueuedCertificateTrustPanelCompletionBlock)contextInfo[1])(isTrusted); // Perform the completion block
	}

	[self setCurrentPanel:nil];

	[self setActiveSocket:nil];

	[self setDoNotInvokeCompletionBlockNextPass:NO];

	@synchronized(_queuedEntries) {
		/* Remove entry. */
		[_queuedEntries removeObjectAtIndex:0];

		/* Maybe show next window. */
		if ([_queuedEntries count] > 0) {
			[self presentNextQueuedEntry];
		}
	}
}

@end
