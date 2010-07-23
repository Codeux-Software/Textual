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