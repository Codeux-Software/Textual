#import <Cocoa/Cocoa.h>
#import "KeyEventHandler.h"

@interface FieldEditorTextView : NSTextView
{
	id pasteDelegate;
	KeyEventHandler* keyHandler;
}

@property (assign) id pasteDelegate;
@property (retain) KeyEventHandler* keyHandler;

- (void)paste:(id)sender;

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
@end

@interface NSObject (FieldEditorTextViewDelegate)
- (BOOL)fieldEditorTextViewPaste:(id)sender;
@end