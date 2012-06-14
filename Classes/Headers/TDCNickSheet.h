// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@interface TDCNickSheet : TDCSheetBase
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) NSTextField *currentText;
@property (nonatomic, strong) NSTextField *nicknameNewInfo;

- (void)start:(NSString *)nick;
@end

@interface NSObject (TXNickSheetDelegate)
- (void)nickSheet:(TDCNickSheet *)sender didInputNick:(NSString *)nick;
- (void)nickSheetWillClose:(TDCNickSheet *)sender;
@end