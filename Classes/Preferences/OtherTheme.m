// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
@synthesize underlyingWindowColor;

- (id)init
{
	if ((self = [super init])) {
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
	
	[underlyingWindowColor release];
	
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
	NSDictionary *userInterface = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:fileName];
	
	NSDictionary *inputTextFormat = [userInterface objectForKey:@"Input Box"];
	NSDictionary *memberListFormat = [userInterface objectForKey:@"Member List"];
	NSDictionary *serverListFormat = [userInterface objectForKey:@"Server List"];
	
	self.underlyingWindowColor = [self processStringValue:[userInterface objectForKey:@"Underlying Window Color"] def:@"#FFFFFF"];
	
	// ====================================================== //
	
	self.inputTextColor = [self processStringValue:[inputTextFormat objectForKey:@"Text Color"] def:@"#ccc"];
	self.inputTextBgColor = [self processStringValue:[inputTextFormat objectForKey:@"Background Color"] def:@"#000000"];
	
	self.inputTextFont = [self processFontValue:[inputTextFormat objectForKey:@"Text Font Style"] 
								  font_size:[inputTextFormat intForKey:@"Text Font Size"] 
										def:[NSFont systemFontOfSize:0]];
	
	// ====================================================== //
	
	self.treeBgColor = [self processStringValue:[serverListFormat objectForKey:@"Background Color"] def:@"#1e1e27"];
	self.treeUnreadColor = [self processStringValue:[serverListFormat objectForKey:@"Unread Color"] def:@"#699fcf"];
	self.treeHighlightColor = [self processStringValue:[serverListFormat objectForKey:@"Highlight Color"] def:@"#007f00"];
	self.treeNewTalkColor = [self processStringValue:[serverListFormat objectForKey:@"New Private Message Color"] def:@"#699fcf"];
	
	self.treeActiveColor = [self processStringValue:[serverListFormat objectForKey:@"Active Color"] def:@"#fff"];
	self.treeInactiveColor = [self processStringValue:[serverListFormat objectForKey:@"Inactive Color"] def:@"#ccc"];
	self.treeSelActiveColor = [self processStringValue:[serverListFormat objectForKey:@"Active Color (Selected)"] def:@"#cfbc99"];
	self.treeSelInactiveColor = [self processStringValue:[serverListFormat objectForKey:@"Inactive Color (Selected)"] def:@"#eee"];
	
	NSDictionary *serverTreeGradient = [serverListFormat objectForKey:@"Gradient"];
	
	self.treeSelTopColor = [self processStringValue:[serverTreeGradient objectForKey:@"Top Color"] def:@"#3f3e4c"];
	self.treeSelBottomColor = [self processStringValue:[serverTreeGradient objectForKey:@"Bottom Color"] def:@"#201f27"];
	self.treeSelTopLineColor = [self processStringValue:[serverTreeGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"];	
	self.treeSelBottomLineColor = [self processStringValue:[serverTreeGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"];
	
	self.treeFont = [self processFontValue:[serverListFormat objectForKey:@"Text Font Style"] 
							 font_size:[serverListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]];
	
	// ====================================================== //
	
	self.memberListColor = [self processStringValue:[memberListFormat objectForKey:@"Text Color"] def:@"#ccc"];
	self.memberListOpColor = [self processStringValue:[memberListFormat objectForKey:@"Op Text Color"] def:@"#dedede"];
	self.memberListBgColor = [self processStringValue:[memberListFormat objectForKey:@"Background Color"] def:@"#1e1e27"];
	self.memberListSelColor = [self processStringValue:[memberListFormat objectForKey:@"Text Color (Selected)"] def:@"#cfbc99"];
	
	NSDictionary *memberListGradient = [memberListFormat objectForKey:@"Gradient"];
	
	self.memberListSelTopColor = [self processStringValue:[memberListGradient objectForKey:@"Top Color"] def:@"#3f3e4c"];
	self.memberListSelBottomColor = [self processStringValue:[memberListGradient objectForKey:@"Bottom Color"] def:@"#201f27"];
	self.memberListSelTopLineColor = [self processStringValue:[memberListGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"];
	self.memberListSelBottomLineColor = [self processStringValue:[memberListGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"];
	
	self.memberListFont = [self processFontValue:[memberListFormat objectForKey:@"Text Font Style"] 
							 font_size:[memberListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]];
	
	// ====================================================== //
	
	inputTextFormat = nil;
	memberListFormat = nil;
	serverListFormat = nil;
	serverTreeGradient = nil;
	memberListGradient = nil;
	
	[userInterface release];
	userInterface = nil;
}

@end