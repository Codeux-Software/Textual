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

@protocol TDCAboutPanelDelegate <NSObject>
@required

- (void)aboutPanelWillClose:(TDCAboutPanel *)sender;
@end

#pragma mark -

@protocol TDCAddressBookSheetDelegate <NSObject>
@required

- (void)ignoreItemSheetOnOK:(TDCAddressBookSheet *)sender;
- (void)ignoreItemSheetWillClose:(TDCAddressBookSheet *)sender;
@end

#pragma mark -

@protocol TDChannelBanListSheetDelegate <NSObject>
@required


- (void)channelBanListSheetOnUpdate:(TDChannelBanListSheet *)sender;
- (void)channelBanListSheetWillClose:(TDChannelBanListSheet *)sender;
@end

#pragma mark -

@protocol TDChannelPropertiesSheetDelegate <NSObject>
@required

- (void)channelPropertiesSheetOnOK:(TDChannelPropertiesSheet *)sender;
- (void)channelPropertiesSheetWillClose:(TDChannelPropertiesSheet *)sender;
@end

#pragma mark -

@protocol TDCHighlightEntrySheetDelegate <NSObject>
@required

- (void)highlightEntrySheetOnOK:(TDCHighlightEntrySheet *)sender;
- (void)highlightEntrySheetWillClose:(TDCHighlightEntrySheet *)sender;
@end

#pragma mark -

@protocol TDCHighlightListSheetDelegate <NSObject>
@required

- (void)highlightListSheetWillClose:(TDCHighlightListSheet *)sender;
@end

#pragma mark -

@protocol TDChannelInviteSheetDelegate <NSObject>
@required

- (void)channelInviteSheet:(TDChannelInviteSheet *)sender onSelectChannel:(NSString *)channelName;
- (void)channelInviteSheetWillClose:(TDChannelInviteSheet *)sender;
@end

#pragma mark -

@protocol TDCListDialogDelegate <NSObject>
@required

- (void)listDialogOnUpdate:(TDCListDialog *)sender;
- (void)listDialogOnJoin:(TDCListDialog *)sender channel:(NSString *)channel;
- (void)listDialogWillClose:(TDCListDialog *)sender;
@end

#pragma mark -

@protocol TDCModeSheetDelegate <NSObject>
@required

- (void)modeSheetOnOK:(TDCModeSheet *)sender;
- (void)modeSheetWillClose:(TDCModeSheet *)sender;
@end

#pragma mark -

@protocol TDCNickSheetDelegate <NSObject>
@required

- (void)nickSheet:(TDCNickSheet *)sender didInputNickname:(NSString *)nickname;
- (void)nickSheetWillClose:(TDCNickSheet *)sender;
@end

#pragma mark -

@protocol TDCPreferencesControllerDelegate <NSObject>
@required

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender;
@end

#pragma mark -

@protocol TDCServerSheetDelegate <NSObject>
@required

- (void)serverSheetOnOK:(TDCServerSheet *)sender;
- (void)serverSheetWillClose:(TDCServerSheet *)sender;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)serverSheetRequestedCloudExclusionByDeletion:(TDCServerSheet *)sender;
#endif
@end

#pragma mark -

@protocol TDCTopicSheetDelegate <NSObject>
@required

- (void)topicSheet:(TDCTopicSheet *)sender onOK:(NSString *)topic;
- (void)topicSheetWillClose:(TDCTopicSheet *)sender;
@end

#pragma mark -

@protocol TDCWelcomeSheetDelegate <NSObject>
@required

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOK:(IRCClientConfig *)config;
- (void)welcomeSheetWillClose:(TDCWelcomeSheet *)sender;
@end
