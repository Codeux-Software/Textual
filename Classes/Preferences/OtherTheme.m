// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "OtherTheme.h"
#import "NSColorHelper.h"
#import "NSDictionaryHelper.h"

@interface OtherTheme (Private)
- (NSColor *)processColorStringValue:(NSString *)value def:(NSString *)defaultv;
- (NSString *)processNSStringValue:(NSString *)value def:(NSString *)defaultv;
- (NSInteger)processIntegerValue:(NSInteger)value def:(NSInteger)defaultv;

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
@synthesize nicknameFormat;
@synthesize timestampFormat;
@synthesize overrideChannelFont;
@synthesize indentWrappedMessages;
@synthesize overrideMessageIndentWrap;
@synthesize nicknameFormatFixedWidth;

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

- (NSString*)path
{
	return path;
}

- (void)setPath:(NSString *)value
{
	if (path != value) {
		[path release];
		path = [value retain];
	}
	
	[self reload];
}

- (void)dealloc
{
	[path release];
	
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
	
	[nicknameFormat release];
	[timestampFormat release];
	[overrideChannelFont release];
	
	[super dealloc];
}

- (NSColor *)processColorStringValue:(NSString *)value def:(NSString *)defaultv
{
	return [NSColor fromCSS:(([value length] == 7 || [value length] == 4) ? value : defaultv)];
}

- (NSString *)processNSStringValue:(NSString *)value def:(NSString *)defaultv
{
	return (([value length]) ? value : defaultv);
}

- (NSInteger)processIntegerValue:(NSInteger)value def:(NSInteger)defaultv
{
	return ((value > 0) ? value : defaultv);
}

- (NSFont *)processFontValue:(NSString *)style_value 
				   font_size:(NSInteger)style_size
						 def:(NSFont *)defaultv
{
	return ((style_size < 1 || style_value == nil) ? defaultv : [NSFont fontWithName:style_value size:style_size]);
}

- (void)reload 
{	
	NSDictionary *userInterface = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:[path stringByAppendingPathComponent:@"/userInterface.plist"]];
	
	NSDictionary *inputTextFormat = [userInterface objectForKey:@"Input Box"];
	NSDictionary *memberListFormat = [userInterface objectForKey:@"Member List"];
	NSDictionary *serverListFormat = [userInterface objectForKey:@"Server List"];
	
	self.underlyingWindowColor = [self processColorStringValue:[userInterface objectForKey:@"Underlying Window Color"] def:@"#FFFFFF"];
	
	// ====================================================== //
	
	self.inputTextColor = [self processColorStringValue:[inputTextFormat objectForKey:@"Text Color"] def:@"#ccc"];
	self.inputTextBgColor = [self processColorStringValue:[inputTextFormat objectForKey:@"Background Color"] def:@"#000000"];
	
	self.inputTextFont = [self processFontValue:[inputTextFormat objectForKey:@"Text Font Style"] 
								  font_size:[inputTextFormat intForKey:@"Text Font Size"] 
										def:[NSFont systemFontOfSize:0]];
	
	// ====================================================== //
	
	self.treeBgColor = [self processColorStringValue:[serverListFormat objectForKey:@"Background Color"] def:@"#1e1e27"];
	self.treeUnreadColor = [self processColorStringValue:[serverListFormat objectForKey:@"Unread Color"] def:@"#699fcf"];
	self.treeHighlightColor = [self processColorStringValue:[serverListFormat objectForKey:@"Highlight Color"] def:@"#007f00"];
	self.treeNewTalkColor = [self processColorStringValue:[serverListFormat objectForKey:@"New Private Message Color"] def:@"#699fcf"];
	
	self.treeActiveColor = [self processColorStringValue:[serverListFormat objectForKey:@"Active Color"] def:@"#fff"];
	self.treeInactiveColor = [self processColorStringValue:[serverListFormat objectForKey:@"Inactive Color"] def:@"#ccc"];
	self.treeSelActiveColor = [self processColorStringValue:[serverListFormat objectForKey:@"Active Color (Selected)"] def:@"#cfbc99"];
	self.treeSelInactiveColor = [self processColorStringValue:[serverListFormat objectForKey:@"Inactive Color (Selected)"] def:@"#eee"];
	
	NSDictionary *serverTreeGradient = [serverListFormat objectForKey:@"Gradient"];
	
	self.treeSelTopColor = [self processColorStringValue:[serverTreeGradient objectForKey:@"Top Color"] def:@"#3f3e4c"];
	self.treeSelBottomColor = [self processColorStringValue:[serverTreeGradient objectForKey:@"Bottom Color"] def:@"#201f27"];
	self.treeSelTopLineColor = [self processColorStringValue:[serverTreeGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"];	
	self.treeSelBottomLineColor = [self processColorStringValue:[serverTreeGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"];
	
	self.treeFont = [self processFontValue:[serverListFormat objectForKey:@"Text Font Style"] 
							 font_size:[serverListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]];
	
	// ====================================================== //
	
	self.memberListColor = [self processColorStringValue:[memberListFormat objectForKey:@"Text Color"] def:@"#ccc"];
	self.memberListOpColor = [self processColorStringValue:[memberListFormat objectForKey:@"Op Text Color"] def:@"#dedede"];
	self.memberListBgColor = [self processColorStringValue:[memberListFormat objectForKey:@"Background Color"] def:@"#1e1e27"];
	self.memberListSelColor = [self processColorStringValue:[memberListFormat objectForKey:@"Text Color (Selected)"] def:@"#cfbc99"];
	
	NSDictionary *memberListGradient = [memberListFormat objectForKey:@"Gradient"];
	
	self.memberListSelTopColor = [self processColorStringValue:[memberListGradient objectForKey:@"Top Color"] def:@"#3f3e4c"];
	self.memberListSelBottomColor = [self processColorStringValue:[memberListGradient objectForKey:@"Bottom Color"] def:@"#201f27"];
	self.memberListSelTopLineColor = [self processColorStringValue:[memberListGradient objectForKey:@"Top Line Color"] def:@"#3f3e4c"];
	self.memberListSelBottomLineColor = [self processColorStringValue:[memberListGradient objectForKey:@"Bottom Line Color"] def:@"#3f3e4c"];
	
	self.memberListFont = [self processFontValue:[memberListFormat objectForKey:@"Text Font Style"] 
							 font_size:[memberListFormat intForKey:@"Text Font Size"] 
								   def:[NSFont fontWithName:@"Lucida Grande" size:11]];
	
	// ====================================================== //
	
	NSDictionary *preferencesOverride = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:[path stringByAppendingPathComponent:@"/preferencesOverride.plist"]];
	
	NSDictionary *prefOChannelFont = [preferencesOverride objectForKey:@"Override Channel Font"];
	NSDictionary *prefOIndentMessages = [preferencesOverride objectForKey:@"Indent Wrapped Messages"];
	
	// ====================================================== //
	
	self.nicknameFormat = [self processNSStringValue:[preferencesOverride objectForKey:@"Nickname Format"] def:nil];
	self.timestampFormat = [self processNSStringValue:[preferencesOverride objectForKey:@"Timestamp Format"] def:nil];
	
	self.indentWrappedMessages = [prefOIndentMessages boolForKey:@"New Value"];
	self.overrideMessageIndentWrap = [prefOIndentMessages boolForKey:@"Override Setting"];
	
	self.overrideChannelFont = [self processFontValue:[prefOChannelFont objectForKey:@"Font Name"] 
											font_size:[prefOChannelFont intForKey:@"Font Size"] 
												  def:nil];
	
	self.nicknameFormatFixedWidth = [self processIntegerValue:[preferencesOverride intForKey:@"Nickname Format Fixed Width"] def:0];
	
	// ====================================================== //
	
	inputTextFormat = nil;
	memberListFormat = nil;
	prefOChannelFont = nil;
	serverListFormat = nil;
	serverTreeGradient = nil;
	memberListGradient = nil;
	prefOIndentMessages = nil;
	
	[userInterface release];
	userInterface = nil;
	
	[preferencesOverride release];
	preferencesOverride = nil;
}

@end