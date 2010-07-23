#import <Cocoa/Cocoa.h>
#import "KeyEventHandler.h"

@interface MainWindow : NSWindow
{
	KeyEventHandler* keyHandler;
}

@property (retain) KeyEventHandler* keyHandler;

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
@end