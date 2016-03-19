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

@interface TDCFileTransferDialogTransferController : NSObject <GCDAsyncSocketDelegate>
@property (nonatomic, weak) IRCClient *associatedClient;
@property (nonatomic, assign) BOOL isHidden; // Is visible on the dialog.
@property (nonatomic, assign) BOOL isReversed; // Is reverse DCC transfer.
@property (nonatomic, assign) BOOL isSender; // Type of transfer.
@property (nonatomic, assign) BOOL isResume; // Whether we are resuming a previous transfer.
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *peerNickname;
@property (nonatomic, copy) NSString *errorMessageToken;
@property (nonatomic, copy) NSString *hostAddress;
@property (nonatomic, copy) NSString *transferToken;
@property (nonatomic, copy) NSString *uniqueIdentifier;
@property (nonatomic, assign) NSInteger transferPort;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, weak) TDCFileTransferDialog *transferDialog;
@property (nonatomic, weak) TDCFileTransferDialogTableCell *parentCell;
@property (nonatomic, assign) TXUnsignedLongLong totalFilesize;
@property (nonatomic, assign) TXUnsignedLongLong processedFilesize;
@property (nonatomic, assign) TXUnsignedLongLong currentRecord;
@property (nonatomic, strong) NSMutableArray *speedRecords;
@property (nonatomic, assign) TDCFileTransferDialogTransferStatus transferStatus;
@property (nonatomic, strong) XRPortMapper *portMapping;
@property (nonatomic, assign) NSInteger sendQueueSize;
@property (nonatomic, strong) dispatch_queue_t serverDispatchQueue;
@property (nonatomic, strong) dispatch_queue_t serverSocketQueue;
@property (nonatomic, strong) GCDAsyncSocket *listeningServer;
@property (nonatomic, strong) GCDAsyncSocket *listeningServerConnectedClient;
@property (nonatomic, strong) GCDAsyncSocket *connectionToRemoteServer;
@property (nonatomic, strong) id transferProgressHandler; // Used to prevent system sleep.

- (void)open;

@property (getter=isActingAsServer, readonly) BOOL actingAsServer;
@property (getter=isActingAsClient, readonly) BOOL actingAsClient;

- (void)setDidErrorOnBadSenderAddress;

- (void)sendTransferRequestToClient;

- (void)localIPAddressWasDetermined;

- (void)didReceiveSendRequestFromClient;

- (void)onMaintenanceTimer;
- (void)prepareForDestruction;

- (void)updateClearButton;

- (void)close;
- (void)close:(BOOL)postNotifications;

- (NSString *)completePath;

@end
