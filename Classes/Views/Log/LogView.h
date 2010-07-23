#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface LogView : WebView
{
	id keyDelegate;
	id resizeDelegate;
}

@property (assign) id keyDelegate;
@property (assign) id resizeDelegate;

- (NSString*)contentString;

- (void)clearSelection;
- (BOOL)hasSelection;
- (NSString*)selection;
@end

@interface NSObject (LogViewDelegate)
- (void)logViewKeyDown:(NSEvent*)e;
- (void)logViewWillResize;
- (void)logViewDidResize;
@end