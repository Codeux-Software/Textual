#import "OtherTheme.h"
#import "NSColorHelper.h"
#import "NSDictionaryHelper.h"

@interface OtherTheme (Private)
- (NSColor *)processStringValue:(NSString *)value def:(NSString *)defaultv;

- (NSFont *)processFontValue:(NSString *)style_value 
				   font_size:(NSInteger)style_size
						 def:(NSFont *)defaultv;
@end

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

- (NSString*)fileName
{
	return fileName;
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
	}
	
	[self reload];
}

- (void)dealloc
{
	[fileName release];
	
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

- (NSColor *)processStringValue:(NSString *)value def:(NSString *)defaultv
{
	return [NSColor fromCSS:((value == nil || [[value trim] isEmpty]) ? defaultv : value)];
}

- (NSFont *)processFontValue:(NSString *)style_value 
				   font_size:(NSInteger)style_size
						 def:(NSFont *)defaultv
{
	if (style_size < 1 || (style_value == nil || [[style_value trim] isEmpty])) {
		return defaultv;
	} else {
		return [NSFont fontWithName:style_value size:style_size];
	}
}

- (void)reload 
{	
	NSLog(@"lol?");
	[inputTextFont release];
	inputTextFont = nil;
	[inputTextBgColor release];
	inputTextBgColor = nil;
	[inputTextColor release];
	inputTextColor = nil;
	
	[treeFont release];
	treeFont = nil;
	[treeBgColor release];
	treeBgColor = nil;
	[treeHighlightColor release];
	treeHighlightColor = nil;
	[treeNewTalkColor release];
	treeNewTalkColor = nil;
	[treeUnreadColor release];
	treeUnreadColor = nil;
	
	[treeActiveColor release];
	treeActiveColor = nil;
	[treeInactiveColor release];
	treeInactiveColor = nil;
	
	[treeSelActiveColor release];
	treeSelActiveColor = nil;
	[treeSelInactiveColor release];
	treeSelInactiveColor = nil;
	[treeSelTopLineColor release];
	treeSelTopLineColor = nil;
	[treeSelBottomLineColor release];
	treeSelBottomLineColor = nil;
	[treeSelTopColor release];
	treeSelTopColor = nil;
	[treeSelBottomColor release];
	treeSelBottomColor = nil;
	
	[memberListFont release];
	memberListFont = nil;
	[memberListBgColor release];
	memberListBgColor = nil;
	[memberListColor release];
	memberListColor = nil;
	[memberListOpColor release];
	memberListOpColor = nil;
	
	[memberListSelColor release];
	memberListSelColor = nil;
	[memberListSelTopLineColor release];
	memberListSelTopLineColor = nil;
	[memberListSelBottomLineColor release];
	memberListSelBottomLineColor = nil;
	[memberListSelTopColor release];
	memberListSelTopColor = nil;
	[memberListSelBottomColor release];
	memberListSelBottomColor = nil;
	
	// ====================================================== //
	
	NSDictionary *userInterface = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:fileName];
	
	NSDictionary *inputTextFormat = [userInterface objectForKey:@"Input Box"];
	NSDictionary *memberListFormat = [userInterface objectForKey:@"Member List"];
	NSDictionary *serverListFormat = [userInterface objectForKey:@"Server List"];
	
	// ====================================================== //
	
	inputTextColor = [[self processStringValue:[inputTextFormat objectForKey:@"Text Color"] def:@"#ccc"] retain];
	inputTextBgColor = [[self processStringValue:[inputTextFormat objectForKey:@"Background Color"] def:@"#000000"] retain];
	
	inputTextFont = [[self processFontValue:[inputTextFormat objectForKey:@"Text Font Style"] 
								  font_size:[inputTextFormat intForKey:@"Text Font Size"] 
										def:[NSFont systemFontOfSize:0]] retain];
	
	// ====================================================== //
	
	treeBgColor = [[self processStringValue:[serverListFormat objectForKey:@"Background Color"] def:@"#1e1e27"] retain];
	treeUnreadColor = [[self processStringValue:[serverListFormat objectForKey:@"Unread Color"] def:@"#699fcf"] retain];
	treeHighlightColor = [[self processStringValue:[serverListFormat objectForKey:@"Highlight Color"] def:@"#007f00"] retain];
	treeNewTalkColor = [[self processStringValue:[serverListFormat objectForKey:@"New Private Message Color"] def:@"#699fcf"] retain];
	
	treeActiveColor = [[self processStringValue:[serverListFormat objectForKey:@"Active Color"] def:@"#fff"] retain];
	treeInactiveColor = [[self processStringValue:[serverListFormat objectForKey:@"Inactive Color"] def:@"#ccc"] retain];
	treeSelActiveColor = [[self processStringValue:[serverListFormat objectForKey:@"Active Color (Selected)"] def:@"#cfbc99"] retain];
	treeSelInactiveColor = [[self processStringValue:[serverListFormat objectForKey:@"Inactive Color (Selected)"] def:@"#eee"] retain];
	
	NSDictionary *serverTreeGradient = [serverListFormat objectForKey:@"Gradient"];
	
	treeSelTopColor = [[self processStringValue:[serverTreeGradient objectForKey:@"Top Color"] def:@"#3f3e4c"] retain];
	treeSelBottomColor = [[self processStringValue:[serverTreeGradient objectForKey:@"Bottom Color"] def:@"#201f27"] retain];
	treeSelTopLineColor = [[self processStringValue:[serverTreeGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"] retain];	
	treeSelBottomLineColor = [[self processStringValue:[serverTreeGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"] retain];
	
	treeFont = [[self processFontValue:[serverListFormat objectForKey:@"Text Font Style"] 
							 font_size:[serverListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]] retain];
	
	// ====================================================== //
	
	memberListColor = [[self processStringValue:[memberListFormat objectForKey:@"Text Color"] def:@"#ccc"] retain];
	memberListOpColor = [[self processStringValue:[memberListFormat objectForKey:@"Op Text Color"] def:@"#dedede"] retain];
	memberListBgColor = [[self processStringValue:[memberListFormat objectForKey:@"Background Color"] def:@"#1e1e27"] retain];
	memberListSelColor = [[self processStringValue:[memberListFormat objectForKey:@"Text Color (Selected)"] def:@"#cfbc99"] retain];
	
	NSDictionary *memberListGradient = [memberListFormat objectForKey:@"Gradient"];
	
	memberListSelTopColor = [[self processStringValue:[memberListGradient objectForKey:@"Top Color"] def:@"#3f3e4c"] retain];
	memberListSelBottomColor = [[self processStringValue:[memberListGradient objectForKey:@"Bottom Color"] def:@"#201f27"] retain];
	memberListSelTopLineColor = [[self processStringValue:[memberListGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"] retain];
	memberListSelBottomLineColor = [[self processStringValue:[memberListGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"] retain];
	
	memberListFont = [[self processFontValue:[memberListFormat objectForKey:@"Text Font Style"] 
							 font_size:[memberListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]] retain];
	
	// ====================================================== //
	
	inputTextFormat = memberListFormat = serverListFormat = serverTreeGradient = memberListGradient = nil;
	
	[userInterface release];
	userInterface = nil;
}

@end