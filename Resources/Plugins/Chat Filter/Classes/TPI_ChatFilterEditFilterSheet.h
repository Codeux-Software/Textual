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

#import "TPI_ChatFilter.h"

typedef NS_ENUM(NSUInteger, TPI_ChatFilterActionTokenTag) {
	TPI_ChatFilterActionTokenChannelNameTag = 1,
	TPI_ChatFilterActionTokenLocalNicknameTag = 2,
	TPI_ChatFilterActionTokenNetworkNameTag = 3,
	TPI_ChatFilterActionTokenOriginalMessage = 4,
	TPI_ChatFilterActionTokenSenderAddressTag = 5,
	TPI_ChatFilterActionTokenSenderHostmaskTag = 6,
	TPI_ChatFilterActionTokenSenderNicknameTag = 7,
	TPI_ChatFilterActionTokenSenderUsernameTag = 8,
	TPI_ChatFilterActionTokenServerAddressTag = 9
};

@protocol TPI_ChatFilterEditFilterSheetDelegate;

@interface TPI_ChatFilterEditFilterSheet : TDCSheetBase <NSTokenFieldDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
- (void)startWithFilter:(TPI_ChatFilter *)filter;
@end

@protocol TPI_ChatFilterEditFilterSheetDelegate <NSObject>
@optional

- (void)chatFilterEditFilterSheet:(TPI_ChatFilterEditFilterSheet *)sender onOK:(TPI_ChatFilter *)filter;
- (void)chatFilterEditFilterSheetWillClose:(TPI_ChatFilterEditFilterSheet *)sender;
@end
