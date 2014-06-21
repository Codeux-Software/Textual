/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|
 
 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#define _filenameFieldWithProgressBarYCord				44
#define _filenameFieldWithoutProgressBarYCord			35

#define _filesizeFieldWithProgressBarYCord				44
#define _filesizeFieldWithoutProgressBarYCord			36

#define _transferInfoFieldWithProgressBarYCord			6
#define _transferInfoFieldWithoutProgressBarYCord		16

#import "TextualApplication.h"

@implementation TDCFileTransferDialogTableCell

#pragma mark -
#pragma mark Status Information

- (void)populateBasicInformation
{
	/* Progress bar. */
	[_progressIndicator setDoubleValue:0];
	[_progressIndicator setMinValue:0];
	[_progressIndicator setMaxValue:[self totalFilesize]];
	
	/* File information. */
	NSString *totalFilesize = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self totalFilesize]];
	
	[_filesizeTextField setStringValue:totalFilesize];
	[_filenameTextField setStringValue:[self filename]];
	
	/* File icon. */
	NSImage *iconImage = [RZWorkspace() iconForFileType:[[self filename] pathExtension]];
	
	[_fileIconView setImage:iconImage];
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
	NSRect infoFieldRect = [_transferProgressField frame];
	NSRect nameFieldRect = [_filenameTextField frame];
	NSRect sizeFieldRect = [_filesizeTextField frame];
	
	if (transferIsStopped) {
		if ([_progressIndicator isHidden] == NO) {
			[_progressIndicator setHidden:YES];
			
			nameFieldRect.origin.y = _filenameFieldWithoutProgressBarYCord;
			sizeFieldRect.origin.y = _filesizeFieldWithoutProgressBarYCord;
			infoFieldRect.origin.y = _transferInfoFieldWithoutProgressBarYCord;
			
			[_filenameTextField setFrame:nameFieldRect];
			[_filesizeTextField setFrame:sizeFieldRect];
			[_transferProgressField setFrame:infoFieldRect];
		}
	} else {
		if ([_progressIndicator isHidden]) {
			[_progressIndicator setHidden:NO];
			
			nameFieldRect.origin.y = _filenameFieldWithProgressBarYCord;
			sizeFieldRect.origin.y = _filesizeFieldWithProgressBarYCord;
			infoFieldRect.origin.y = _transferInfoFieldWithProgressBarYCord;
			
			[_filenameTextField setFrame:nameFieldRect];
			[_filesizeTextField setFrame:sizeFieldRect];
			[_transferProgressField setFrame:infoFieldRect];
		}
	}
	
	/* Update type of progress bar, if any… */
	if (transferIsStopped == NO) {
		if ([self transferStatus] == TDCFileTransferDialogTransferConnectingStatus) {
			[_progressIndicator setIndeterminate:YES];
			[_progressIndicator startAnimation:nil];
		} else {
			[_progressIndicator setIndeterminate:NO];

			[_progressIndicator setDoubleValue:[self processedFilesize]];
		}
	}
	
	/* Start notifying of specific events. */
	switch ([self transferStatus]) {
		case TDCFileTransferDialogTransferStoppedStatus:
		{
			if ([self isReceiving]) {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1009]", [self peerNickname])];
			} else {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[10001]", [self peerNickname])];
			}
			
			break;
		}
		case TDCFileTransferDialogTransferMappingListeningPortStatus:
		{
			if ([self isReceiving]) {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1010]", [self peerNickname])];
			} else {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1002]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus:
		{
			if ([self isReceiving]) {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1011]", [self peerNickname])];
			} else {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1003]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferInitializingStatus:
		{
			if ([self isReceiving]) {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1012]", [self peerNickname])];
			} else {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1004]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsSenderStatus:
		{
			[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1005]", [self peerNickname])];

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsReceiverStatus:
		{
			[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1013]", [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferErrorStatus:
		{
			[_transferProgressField setStringValue:TXTLS([self errorMessageToken], [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferCompleteStatus:
		{
			if ([self isReceiving]) {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1014]", [self peerNickname])];
			} else {
				[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1006]", [self peerNickname])];
			}

			break;
		}
		case TDCFileTransferDialogTransferSendingStatus:
		case TDCFileTransferDialogTransferReceivingStatus:
		{
			/* Format time remaining. */
			NSInteger timeleft = 0;
			
			NSString *remainingTime;
			
			if ([self currentSpeed] > 0) {
				timeleft = (([self totalFilesize] - [self processedFilesize]) / [self currentSpeed]);
				
				if (timeleft > 0) {
					remainingTime = TXHumanReadableTimeInterval(timeleft, YES, (NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit));
				}
			}
			
			/* Update status. */
			NSString *totalFilesize = [_filesizeTextField stringValue];
			
			NSString *processedSize = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self processedFilesize]];
			NSString *transferSpeed = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:[self currentSpeed]];
			
			NSString *status;
			
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
			
			[_transferProgressField setStringValue:status];
			
			break;
		}
		case TDCFileTransferDialogTransferConnectingStatus:
		{
			[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1015]", [self peerNickname])];
			
			break;
		}
		case TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus:
		{
			[_transferProgressField setStringValue:TXTLS(@"TDCFileTransferDialog[1007]", [self peerNickname])];

			break;
		}
		default:
		{
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
	[_associatedController prepareForDestruction];
}

- (void)onMaintenanceTimer
{
	[_associatedController onMaintenanceTimer];
}

- (void)updateClearButton
{
	[_associatedController updateClearButton];
}

#pragma mark -
#pragma mark Properties

- (TDCFileTransferDialogTransferStatus)transferStatus
{
	return [_associatedController transferStatus];
}

- (BOOL)isReceiving
{
	return ([_associatedController isSender] == NO);
}

- (BOOL)isHidden
{
	return [_associatedController isHidden];
}

- (NSString *)path
{
	return [_associatedController path];
}

- (NSString *)filename
{
	return [_associatedController filename];
}

- (NSString *)peerNickname
{
	return [_associatedController peerNickname];
}

- (NSString *)errorMessageToken
{
	return [_associatedController errorMessageToken];
}

- (NSString *)hostAddress
{
	return [_associatedController hostAddress];
}

- (NSInteger)transferPort
{
	return [_associatedController transferPort];
}

- (TXUnsignedLongLong)totalFilesize
{
	return [_associatedController totalFilesize];
}

- (TXUnsignedLongLong)processedFilesize
{
	return [_associatedController processedFilesize];
}

- (TXUnsignedLongLong)currentRecord
{
	return [_associatedController currentRecord];
}

- (NSArray *)speedRecords
{
	return [_associatedController speedRecords];
}

- (NSString *)completePath
{
	return [_associatedController completePath];
}

@end
