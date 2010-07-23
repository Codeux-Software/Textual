#import <Foundation/Foundation.h>

@interface AboutPanel : NSWindowController
{
	id delegate;
	
	IBOutlet NSTextField *versionInfo;
}

@property (assign) id delegate;
@property (retain) NSTextField *versionInfo;

- (void)show;
@end

@interface NSObject (AboutPanelDelegate)
- (void)aboutPanelWillClose:(AboutPanel*)sender;
@end