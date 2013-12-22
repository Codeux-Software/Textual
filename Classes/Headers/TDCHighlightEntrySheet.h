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

/* TDCHighlightEntrySheet handles management of highlights inside TDCServerSheet. */
/* It should not be mistaken for TDCHighlightListSheet which shows the actual list of
highlights for a server by using Command+5 or the actual Windows menu bar item. */

@interface TDCHighlightEntrySheet : TDCSheetBase
@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, strong) NSString *clientID; // To reference a channel list.
@property (nonatomic, nweak) IBOutlet NSTextField *matchKeywordTextField;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *matchTypePopupButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *matchChannelPopupButton;
@property (nonatomic, strong) TDCHighlightEntryMatchCondition *config;

- (void)start;
@end

@interface TDCHighlightEntryMatchCondition : NSObject <NSMutableCopying>
@property (nonatomic, strong) NSString *itemUUID; // Unique Identifier (UUID)
@property (nonatomic, strong) NSString *matchKeyword;
@property (nonatomic, strong) NSString *matchChannelID; // The itemUUID of the IRCChannelConfig
@property (nonatomic, assign) BOOL matchIsExcluded;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryValue;
@end

@interface NSObject (TDCHighlightEntrySheetDelegate)
- (void)highlightEntrySheetOnOK:(TDCHighlightEntrySheet *)sender;
- (void)highlightEntrySheetWillClose:(TDCHighlightEntrySheet *)sender;
@end
