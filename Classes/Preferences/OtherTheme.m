#import "OtherTheme.h"
#import "NSColorHelper.h"

@implementation OtherTheme

@synthesize inputTextFont;
@synthesize inputTextBgColor;
@synthesize inputTextColor;
@synthesize treeFont;
@synthesize treeBgColor;
@synthesize treeHighlightColor;
@synthesize treeNewTalkColor;
@synthesize treeUnreadColor;
@synthesize treeActiveColor;
@synthesize treeInactiveColor;
@synthesize treeSelActiveColor;
@synthesize treeSelInactiveColor;
@synthesize treeSelTopLineColor;
@synthesize treeSelBottomLineColor;
@synthesize treeSelTopColor;
@synthesize treeSelBottomColor;
@synthesize memberListFont;
@synthesize memberListBgColor;
@synthesize memberListColor;
@synthesize memberListOpColor;
@synthesize memberListSelColor;
@synthesize memberListSelTopLineColor;
@synthesize memberListSelBottomLineColor;
@synthesize memberListSelTopColor;
@synthesize memberListSelBottomColor;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[inputTextFont release];
	[inputTextBgColor release];
	[inputTextColor release];

	[treeFont release];
	[treeBgColor release];
	[treeHighlightColor release];
	[treeNewTalkColor release];
	[treeUnreadColor release];
	
	[treeActiveColor release];
	[treeInactiveColor release];
	
	[treeSelActiveColor release];
	[treeSelInactiveColor release];
	[treeSelTopLineColor release];
	[treeSelBottomLineColor release];
	[treeSelTopColor release];
	[treeSelBottomColor release];
	
	[memberListFont release];
	[memberListBgColor release];
	[memberListColor release];
	[memberListOpColor release];

	[memberListSelColor release];
	[memberListSelTopLineColor release];
	[memberListSelBottomLineColor release];
	[memberListSelTopColor release];
	[memberListSelBottomColor release];
	
	[super dealloc];
}

- (void)populateValues 
{
	inputTextBgColor = [[NSColor fromCSS:@"#000000"] retain];
	inputTextColor = [[NSColor fromCSS:@"#ccc"] retain];
	
	treeBgColor = [[NSColor fromCSS:@"#1e1e27"] retain];
	treeHighlightColor = [[NSColor fromCSS:@"#007f00"] retain];
	treeNewTalkColor = [[NSColor fromCSS:@"#699fcf"] retain];
	treeUnreadColor = [[NSColor fromCSS:@"#699fcf"] retain];
	
	treeActiveColor = [[NSColor fromCSS:@"#fff"] retain];
	treeInactiveColor = [[NSColor fromCSS:@"#ccc"] retain];
	treeSelActiveColor = [[NSColor fromCSS:@"#cfbc99"] retain];
	treeSelInactiveColor = [[NSColor fromCSS:@"#eee"] retain];
	treeSelTopLineColor = [[NSColor fromCSS:@"#3f3e4c"] retain];	
	treeSelBottomLineColor = [[NSColor fromCSS:@"#3f3e4c"] retain];
	treeSelTopColor = [[NSColor fromCSS:@"#3f3e4c"] retain];
	treeSelBottomColor = [[NSColor fromCSS:@"#201f27"] retain];
	
	memberListBgColor = [[NSColor fromCSS:@"#1e1e27"] retain];
	memberListColor = [[NSColor fromCSS:@"#ccc"] retain];
	memberListOpColor = [[NSColor fromCSS:@"#dedede"] retain];
	memberListSelColor = [[NSColor fromCSS:@"#cfbc99"] retain];
	memberListSelTopLineColor = [[NSColor fromCSS:@"#3f3e4c"] retain];
	memberListSelBottomLineColor = [[NSColor fromCSS:@"#3f3e4c"] retain];
	memberListSelTopColor = [[NSColor fromCSS:@"#3f3e4c"] retain];
	memberListSelBottomColor = [[NSColor fromCSS:@"#201f27"] retain];
	
	inputTextFont = [[NSFont systemFontOfSize:0] retain];
	treeFont = [[NSFont fontWithName:@"Lucida Grande" size:11] retain];
	memberListFont = [[NSFont fontWithName:@"Lucida Grande" size:11] retain];	
}

@end