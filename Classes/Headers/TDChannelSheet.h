/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@interface TDChannelSheet : TDCSheetBase
@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, strong) NSString *clientID;
@property (nonatomic, strong) NSString *channelID;
@property (nonatomic, strong) IRCChannelConfig *config;
@property (nonatomic, nweak) NSTextField *channelNameField;
@property (nonatomic, nweak) NSTextField *defaultModesField;
@property (nonatomic, nweak) NSTextField *defaultTopicField;
@property (nonatomic, nweak) NSTextField *encryptionKeyField;
@property (nonatomic, nweak) NSTextField *secretKeyField;
@property (nonatomic, nweak) NSButton *autoJoinCheck;
@property (nonatomic, nweak) NSButton *ignoreHighlightsCheck;
@property (nonatomic, nweak) NSButton *inlineImagesCheck;
@property (nonatomic, nweak) NSButton *pushNotificationsCheck;
@property (nonatomic, nweak) NSButton *JPQActivityCheck;
@property (nonatomic, nweak) NSSegmentedControl *contentViewTabView;
@property (nonatomic, nweak) NSView *contentView;
@property (nonatomic, nweak) NSView *defaultsView;
@property (nonatomic, nweak) NSView *encryptionView;
@property (nonatomic, nweak) NSView *generalView;

- (void)start;

- (void)onMenuBarItemChanged:(id)sender;
@end

@interface NSObject (TDChannelSheetDelegate)
- (void)channelSheetOnOK:(TDChannelSheet *)sender;
- (void)channelSheetWillClose:(TDChannelSheet *)sender;
@end
