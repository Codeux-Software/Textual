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

#import "TextualApplication.h"

typedef enum TDCFileTransferDialogTransferStatus : NSInteger {
	TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus,
	TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus,
	TDCFileTransferDialogTransferMappingListeningPortStatus,
	TDCFileTransferDialogTransferInitializingStatus,
	TDCFileTransferDialogTransferErrorStatus,
	TDCFileTransferDialogTransferStoppedStatus,
	TDCFileTransferDialogTransferConnectingStatus,
	TDCFileTransferDialogTransferIsListeningAsSenderStatus,
	TDCFileTransferDialogTransferIsListeningAsReceiverStatus,
	TDCFileTransferDialogTransferReceivingStatus,
	TDCFileTransferDialogTransferSendingStatus,
	TDCFileTransferDialogTransferCompleteStatus
} TDCFileTransferDialogTransferStatus;

typedef enum TDCFileTransferDialogNavigationControllerSelectedTab : NSInteger {
	TDCFileTransferDialogNavigationControllerAllSelectedTab			= 0,
	TDCFileTransferDialogNavigationControllerSendingSelectedTab		= 1,
	TDCFileTransferDialogNavigationControllerReceivingSelectedTab	= 2
} TDCFileTransferDialogNavigationControllerSelectedTab;

#import "TDCFileTransferDialogRemoteAddress.h" // @protocol

@interface TDCFileTransferDialog : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, TDCFileTransferDialogRemoteAddressDelegate>
@property (nonatomic, copy) NSString *cachedIPAddress;
@property (nonatomic, assign) BOOL sourceIPAddressRequestPending;
@property (nonatomic, copy) NSURL *downloadDestination;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *fileTransferTable;

- (void)show:(BOOL)key restorePosition:(BOOL)restoreFrame;

- (void)close;
- (void)prepareForApplicationTermination;

- (void)requestIPAddressFromExternalSource;
- (void)clearCachedIPAddress;

- (void)nicknameChanged:(NSString *)oldNickname
			 toNickname:(NSString *)newNickname
				 client:(IRCClient *)client;

/* The next two method return a unique identifier specific to each
 added request. This identifier is different from a request token
 as it is available always and never is seen by the other user. It
 is used internally for finding specific requests. */
/* Returning nil means that something failed and the transfer was
 never added to list of transfers. */
- (NSString *)addReceiverForClient:(IRCClient *)client
						  nickname:(NSString *)nickname
						   address:(NSString *)hostAddress
							  port:(NSInteger)hostPort
						  filename:(NSString *)filename
						  filesize:(TXUnsignedLongLong)totalFilesize
					   token:(NSString *)transferToken;

- (NSString *)addSenderForClient:(IRCClient *)client
				  nickname:(NSString *)nickname
					  path:(NSString *)completePath
				  autoOpen:(BOOL)autoOpen;

- (BOOL)fileTransferExistsWithToken:(NSString *)transferToken;

- (TDCFileTransferDialogTransferController *)fileTransferSenderMatchingToken:(NSString *)transferToken;
- (TDCFileTransferDialogTransferController *)fileTransferReceiverMatchingToken:(NSString *)transferToken;

- (TDCFileTransferDialogTransferController *)fileTransferFromUniqueIdentifier:(NSString *)identifier;

- (void)updateClearButton;
- (void)updateMaintenanceTimer;

- (IBAction)clear:(id)sender;

- (IBAction)startTransferOfFile:(id)sender;
- (IBAction)stopTransferOfFile:(id)sender;
- (IBAction)removeTransferFromList:(id)sender;
- (IBAction)openReceivedFile:(id)sender;
- (IBAction)revealReceivedFileInFinder:(id)sender;

- (IBAction)navigationSelectionDidChange:(id)sender;

/* Do not call these as a plugin please. */
/* The startUsing* method does not check if the local variable is already set. */
- (void)startUsingDownloadDestinationFolderSecurityScopedBookmark;

- (void)setDownloadDestinationFolder:(id)value;
@end
