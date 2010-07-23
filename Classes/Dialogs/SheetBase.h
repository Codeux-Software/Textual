#import <Foundation/Foundation.h>

@interface SheetBase : NSObject
{
	id delegate;
	NSWindow* window;

	IBOutlet NSWindow* sheet;
	IBOutlet NSButton* okButton;
	IBOutlet NSButton* cancelButton;
}

@property (assign) id delegate;
@property (assign) NSWindow* window;
@property (retain) NSWindow* sheet;
@property (retain) NSButton* okButton;
@property (retain) NSButton* cancelButton;

- (void)startSheet;
- (void)endSheet;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;
@end