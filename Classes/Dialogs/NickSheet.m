#import "NickSheet.h"

@implementation NickSheet

@synthesize uid;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"NickSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)start:(NSString*)nick
{
	[currentText setStringValue:nick];
	[newText setStringValue:nick];
	[sheet makeFirstResponder:newText];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(nickSheet:didInputNick:)]) {
		[delegate nickSheet:self didInputNick:newText.stringValue];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
		[delegate nickSheetWillClose:self];
	}
}

@synthesize currentText;
@synthesize newText;
@end