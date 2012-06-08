// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NickSheet : SheetBase
{
	NSInteger uid;
	
	IBOutlet NSTextField *currentText;
	IBOutlet NSTextField *nicknameNewInfo;
}

@property (assign) NSInteger uid;
@property (strong) NSTextField *currentText;
@property (strong) NSTextField *nicknameNewInfo;

- (void)start:(NSString *)nick;
@end

@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet *)sender didInputNick:(NSString *)nick;
- (void)nickSheetWillClose:(NickSheet *)sender;
@end