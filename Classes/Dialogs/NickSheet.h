// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "SheetBase.h"

@interface NickSheet : SheetBase
{
	NSInteger uid;
	
	IBOutlet NSTextField* currentText;
	IBOutlet NSTextField* newText;
}

@property (assign) NSInteger uid;
@property (retain) NSTextField* currentText;
@property (retain) NSTextField* newText;

- (void)start:(NSString*)nick;
@end

@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)nick;
- (void)nickSheetWillClose:(NickSheet*)sender;
@end