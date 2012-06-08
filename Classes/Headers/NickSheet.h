// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NickSheet : SheetBase
{
	NSInteger uid;
	
	IBOutlet NSTextField *currentText;
	IBOutlet NSTextField *nicknameNewInfo;
}

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) NSTextField *currentText;
@property (nonatomic, strong) NSTextField *nicknameNewInfo;

- (void)start:(NSString *)nick;
@end

@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet *)sender didInputNick:(NSString *)nick;
- (void)nickSheetWillClose:(NickSheet *)sender;
@end