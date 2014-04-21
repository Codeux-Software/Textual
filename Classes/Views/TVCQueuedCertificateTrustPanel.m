/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

@interface TVCQueuedCertificateTrustPanel ()
/* Each entry is stored as an array with index 0 containing
 the trustRef and index 1 containing the completion block. */
@property (nonatomic, strong) NSMutableArray *queuedEntries;
@end

@implementation TVCQueuedCertificateTrustPanel

+ (TVCQueuedCertificateTrustPanel *)sharedInstance
{
	/* Create a copy of self and maintain as static reference. */
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		 sharedSelf = [self new];

		[sharedSelf setQueuedEntries:[NSMutableArray new]];
	});

	return sharedSelf;
}

- (void)enqueue:(SecTrustRef)trustRef withCompletionBlock:(TVCQueuedCertificateTrustPanelCompletionBlock)completionBlock
{
	/* Add new entry. */
	NSArray *newEntry = @[(__bridge id)(trustRef), completionBlock];

	[_queuedEntries addObject:newEntry];

	/* Maybe present window. */
	if ([_queuedEntries count] == 1) {
		[self presentNextQueuedEntry];
	}
}

- (void)presentNextQueuedEntry
{
	/* Gather information. */
	/* The oldest entry will be at index 0. */
	NSArray *contextInfo = _queuedEntries[0];

	/* Build panel. */
	SFCertificateTrustPanel *panel = [SFCertificateTrustPanel new];

	[panel setAlternateButtonTitle:TXTLS(@"BasicLanguage[1009]")];

	[panel setInformativeText:TXTLS(@"BasicLanguage[1229][2]")];

	/* Begin sheet. */
	[panel beginSheetForWindow:nil
				 modalDelegate:self
				didEndSelector:@selector(certificateSheetDidEnd:returnCode:contextInfo:)
				   contextInfo:(__bridge void *)(contextInfo)
						 trust:(__bridge SecTrustRef)(contextInfo[0])
					   message:TXTLS(@"BasicLanguage[1229][1]")];

}

- (void)certificateSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	/* Inform callback of result. */
	NSArray *contextArray = (__bridge NSArray *)contextInfo;

	BOOL isTrusted = (returnCode == NSOKButton);

	TVCQueuedCertificateTrustPanelCompletionBlock completionBlock = contextArray[1];

	completionBlock(isTrusted);

	/* Remove entry. */
	[_queuedEntries removeObjectAtIndex:0];

	/* Maybe show next window. */
	if ([_queuedEntries count] > 0) {
		[self presentNextQueuedEntry];
	}
}

@end
