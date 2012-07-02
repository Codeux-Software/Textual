// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCInviteSheet : TDCSheetBase
@property (nonatomic, strong) NSArray *nicks;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSPopUpButton *channelPopup;

- (void)startWithChannels:(NSArray *)channels;
- (void)invite:(id)sender;
@end

@interface NSObject (TXInviteSheetDelegate)
- (void)inviteSheet:(TDCInviteSheet *)sender onSelectChannel:(NSString *)channelName;
- (void)inviteSheetWillClose:(TDCInviteSheet *)sender;
@end