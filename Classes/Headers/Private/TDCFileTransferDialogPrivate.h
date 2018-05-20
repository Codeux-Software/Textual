/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TDCWindowBase.h"

NS_ASSUME_NONNULL_BEGIN

@class IRCClient, TDCFileTransferDialogTransferController, TVCBasicTableView;

typedef NS_ENUM(NSUInteger, TDCFileTransferDialogTransferStatus) {
	TDCFileTransferDialogTransferCompleteStatus,
	TDCFileTransferDialogTransferConnectingStatus,
	TDCFileTransferDialogTransferFatalErrorStatus,
	TDCFileTransferDialogTransferInitializingStatus,
	TDCFileTransferDialogTransferIsListeningAsReceiverStatus,
	TDCFileTransferDialogTransferIsListeningAsSenderStatus,
	TDCFileTransferDialogTransferMappingListeningPortStatus,
	TDCFileTransferDialogTransferReceivingStatus,
	TDCFileTransferDialogTransferRecoverableErrorStatus,
	TDCFileTransferDialogTransferSendingStatus,
	TDCFileTransferDialogTransferStoppedStatus,
	TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus,
	TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus,
	TDCFileTransferDialogTransferWaitingForResumeAcceptStatus
};

typedef NS_ENUM(NSUInteger, TDCFileTransferDialogNavigationSelectedTab) {
	TDCFileTransferDialogNavigationAllSelectedTab			= 0,
	TDCFileTransferDialogNavigationSendingSelectedTab		= 1,
	TDCFileTransferDialogNavigationReceivingSelectedTab		= 2
};

@class TDCFileTransferDialogTransferController;

@interface TDCFileTransferDialog : TDCWindowBase
@property (readonly, weak) TVCBasicTableView *fileTransferTable;
@property (readonly, copy, nullable) NSString *IPAddress;

- (void)show:(BOOL)makeKeyWindow;
- (void)show:(BOOL)makeKeyWindow restorePosition:(BOOL)restorePosition;

- (void)requestIPAddress; // from external source
- (void)clearIPAddress;

/* The next two method return a unique identifier specific to each
 added request. This identifier is different from a request token
 as it is available always and never is seen by the other user. 
 It is used internally for finding specific requests. */
/* Returning nil means that something failed and the transfer was
 never added to list of transfers. */
- (nullable NSString *)addReceiverForClient:(IRCClient *)client
								   nickname:(NSString *)nickname
									address:(NSString *)hostAddress
									   port:(uint16_t)hostPort
								   filename:(NSString *)filename
								   filesize:(uint64_t)totalFilesize
									  token:(nullable NSString *)transferToken;

- (nullable NSString *)addSenderForClient:(IRCClient *)client
								 nickname:(NSString *)nickname
									 path:(NSString *)path
								 autoOpen:(BOOL)autoOpen;

- (BOOL)fileTransferExistsWithToken:(NSString *)transferToken;

- (nullable TDCFileTransferDialogTransferController *)fileTransferMatchingPort:(uint16_t)port;

- (nullable TDCFileTransferDialogTransferController *)fileTransferSenderMatchingToken:(NSString *)transferToken;
- (nullable TDCFileTransferDialogTransferController *)fileTransferReceiverMatchingToken:(NSString *)transferToken;

- (nullable TDCFileTransferDialogTransferController *)fileTransferWithUniqueIdentifier:(NSString *)identifier;
@end

#pragma mark -

@interface TDCFileTransferDialog (TDCFileTransferDialogDownloadDestinationExtension)
- (nullable NSURL *)downloadDestinationURL;

- (void)setDownloadDestinationURL:(nullable NSData *)downloadDestinationURL;

- (void)startUsingDownloadDestinationURL;
@end

NS_ASSUME_NONNULL_END
