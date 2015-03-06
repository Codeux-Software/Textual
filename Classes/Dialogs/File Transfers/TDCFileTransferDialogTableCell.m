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

#define _filenameFieldWithProgressBarYCord				44
#define _filenameFieldWithoutProgressBarYCord			35

#define _filesizeFieldWithProgressBarYCord				44
#define _filesizeFieldWithoutProgressBarYCord			36

#define _transferInfoFieldWithProgressBarYCord			6
#define _transferInfoFieldWithoutProgressBarYCord		16

#import "TextualApplication.h"

@interface TDCFileTransferDialogTableCell ()
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, weak) IBOutlet NSImageView *fileIconView;
@property (nonatomic, weak) IBOutlet NSTextField *filenameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filesizeTextField;
@property (nonatomic, weak) IBOutlet NSTextField *transferProgressField;
@end

@implementation TDCFileTransferDialogTableCell

#pragma mark -
#pragma mark Status Information

- (void)populateBasicInformation
{
	/* Progress bar. */
	[self.progressIndicator setDoubleValue:0];
	[self.progressIndicator setMinValue:0];
	[self.progressIndicator setMaxValue:[self totalFilesize]];
	
	/* File information. */
	NSString *totalFilesize = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self totalFilesize]];
	
	[self.filesizeTextField setStringValue:totalFilesize];
	[self.filenameTextField setStringValue:[self filename]];
	
	/* File icon. */
	NSImage *iconImage = [RZWorkspace() iconForFileType:[[self filename] pathExtension]];
	
	[self.fileIconView setImage:iconImage];
}

- (void)reloadStatusInformation
{
	/* Don't bother with updates if we are hidden. */
	NSAssertReturn([self isHidden] == NO);
	
	/* Set info into some relevant vars. */
	BOOL transferIsStopped = ([self transferStatus] == TDCFileTransferDialogTransferCompleteStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferErrorStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferStoppedStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferIsListeningAsSenderStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferIsListeningAsReceiverStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferInitializingStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferMappingListeningPortStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus ||
							  [self transferStatus] == TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus);
	
	/* Update position of text fields. */
	NSRect infoFieldRect = [self.transferProgressField frame];
	NSRect nameFieldRect = [self.filenameTextField frame];
	NSRect sizeFieldRect = [self.filesizeTextField frame];
	
	if (transferIsStopped) {
		if ([self.progressIndicator isHidden] == NO) {
			[self.progressIndicator setHidden:YES];
			
			nameFieldRect.origin.y = _filenameFieldWithoutProgressBarYCord;
			sizeFieldRect.origin.y = _filesizeFieldWithoutProgressBarYCord;
			infoFieldRect.origin.y = _transferInfoFieldWithoutProgressBarYCord;
			
			[self.filenameTextField setFrame:nameFieldRect];
			[self.filesizeTextField setFrame:sizeFieldRect];
			[self.transferProgressField setFrame:infoFieldRect];
		}
	} else {
		if ([self.progressIndicator isHidden]) {
			[self.progressIndicator setHidden:NO];
			
			nameFieldRect.origin.y = _filenameFieldWithProgressBarYCord;
			sizeFieldRect.origin.y = _filesizeFieldWithProgressBarYCord;
			infoFieldRect.origin.y = _transferInfoFieldWithProgressBarYCord;
			
			[self.filenameTextField setFrame:nameFieldRect];
			[self.filesizeTextField setFrame:sizeFieldRect];
			[self.transferProgressField setFrame:infoFieldRect];
		}
	}
	
	/* Update type of progress bar, if any… */
	if (transferIsStopped == NO) {
		if ([self transferStatus] == TDCFileTransferDialogTransferConnectingStatus) {
			[self.progressIndicator setIndeterminate:YES];
			[self.progressIndicator startAnimation:nil];
		} else {
			[self.progressIndicator setIndeterminate:NO];

			[self.progressIndicator setDoubleValue:[self processedFilesize]];
		}
	}
	
	/* Start notifying of specific events. */
	switch ([self transferStatus]) {
		case TDCFileTransferDialogTransferStoppedStatus:
		{
			if ([self isReceiving]) {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1009]", [self peerNickname])];
			} else {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[10001]", [self peerNickname])];
			}
			
			break;
		}
		case TDCFileTransferDialogTransferMappingListeningPortStatus:
		{
			if ([self isReceiving]) {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1010]", [self peerNickname])];
			} else {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1002]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus:
		{
			if ([self isReceiving]) {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1011]", [self peerNickname])];
			} else {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1003]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferInitializingStatus:
		{
			if ([self isReceiving]) {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1012]", [self peerNickname])];
			} else {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1004]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsSenderStatus:
		{
			[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1005]", [self peerNickname])];

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsReceiverStatus:
		{
			[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1013]", [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferErrorStatus:
		{
			[self.transferProgressField setStringValue:TXTLS([self errorMessageToken], [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferCompleteStatus:
		{
			if ([self isReceiving]) {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1014]", [self peerNickname])];
			} else {
				[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1006]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferSendingStatus:
		case TDCFileTransferDialogTransferReceivingStatus:
		{
			/* Format time remaining. */
			NSInteger timeleft = 0;
			
			NSString *remainingTime = nil;
			
			if ([self currentSpeed] > 0) {
				timeleft = (([self totalFilesize] - [self processedFilesize]) / [self currentSpeed]);
				
				if (timeleft > 0) {
					remainingTime = TXHumanReadableTimeInterval(timeleft, YES, (NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond));
				}
			}
			
			/* Update status. */
			NSString *totalFilesize = [self.filesizeTextField stringValue];
			
			NSString *processedSize = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self processedFilesize]];
			NSString *transferSpeed = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self currentSpeed]];
			
			NSString *status = nil;
			
			if ([self isReceiving]) {
				if (remainingTime) {
					status = TXTLS(@"TDCFileTransferDialog[1008][2]", processedSize, totalFilesize, transferSpeed, [self peerNickname], remainingTime);
				} else {
					status = TXTLS(@"TDCFileTransferDialog[1008][1]", processedSize, totalFilesize, transferSpeed, [self peerNickname]);
				}
			} else {
				if (remainingTime) {
					status = TXTLS(@"TDCFileTransferDialog[1000][2]", processedSize, totalFilesize, transferSpeed, [self peerNickname], remainingTime);
				} else {
					status = TXTLS(@"TDCFileTransferDialog[1000][1]", processedSize, totalFilesize, transferSpeed, [self peerNickname]);
				}
			}
			
			[self.transferProgressField setStringValue:status];
			
			break;
		}
		case TDCFileTransferDialogTransferConnectingStatus:
		{
			[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1015]", [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus:
		{
			[self.transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1007]", [self peerNickname])];

			break;
		}
	}
	
	/* Update clear button. */
	[self updateClearButton];
}

- (TXUnsignedLongLong)currentSpeed
{
	NSObjectIsEmptyAssertReturn([self speedRecords], 0);
	
	TXUnsignedLongLong total = 0;
	
    for (NSNumber *num in [self speedRecords]) {
        total += [num longLongValue];
    }
	
    return (total / [[self speedRecords] count]);
}

#pragma mark -
#pragma mark Proxy Methods

- (void)prepareForDestruction
{
	[self.associatedController prepareForDestruction];
}

- (void)onMaintenanceTimer
{
	[self.associatedController onMaintenanceTimer];
}

- (void)updateClearButton
{
	[self.associatedController updateClearButton];
}

#pragma mark -
#pragma mark Properties

- (TDCFileTransferDialogTransferStatus)transferStatus
{
	return [self.associatedController transferStatus];
}

- (BOOL)isReceiving
{
	return ([self.associatedController isSender] == NO);
}

- (BOOL)isHidden
{
	return [self.associatedController isHidden];
}

- (NSString *)path
{
	return [self.associatedController path];
}

- (NSString *)filename
{
	return [self.associatedController filename];
}

- (NSString *)peerNickname
{
	return [self.associatedController peerNickname];
}

- (NSString *)errorMessageToken
{
	return [self.associatedController errorMessageToken];
}

- (NSString *)hostAddress
{
	return [self.associatedController hostAddress];
}

- (NSInteger)transferPort
{
	return [self.associatedController transferPort];
}

- (TXUnsignedLongLong)totalFilesize
{
	return [self.associatedController totalFilesize];
}

- (TXUnsignedLongLong)processedFilesize
{
	return [self.associatedController processedFilesize];
}

- (TXUnsignedLongLong)currentRecord
{
	return [self.associatedController currentRecord];
}

- (NSArray *)speedRecords
{
	@synchronized([self.associatedController speedRecords]) {
		return [self.associatedController speedRecords];
	}
}

- (NSString *)completePath
{
	return [self.associatedController completePath];
}

@end
