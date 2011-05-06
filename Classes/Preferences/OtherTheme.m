// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface OtherTheme (Private)
- (NSColor *)processColorStringValue:(NSString *)value def:(NSString *)defaultv;
- (NSString *)processNSStringValue:(NSString *)value def:(NSString *)defaultv;
- (NSInteger)processIntegerValue:(NSInteger)value def:(NSInteger)defaultv;
- (NSFont *)processFontValue:(NSString *)style_value 
						size:(NSInteger)style_size 
					defaultv:(NSFont *)defaultf 
				   preferred:(NSFont *)pref  
				 allowCustom:(BOOL)custom
					overrode:(BOOL *)overr;
@end

@implementation OtherTheme

@synthesize channelViewFont;
@synthesize channelViewFontOverrode;
@synthesize indentWrappedMessages;
@synthesize inputTextBgColor;
@synthesize inputTextColor;
@synthesize inputTextFont;
@synthesize memberListBgColor;
@synthesize memberListColor;
@synthesize memberListFont;
@synthesize memberListOpColor;
@synthesize memberListSelBottomColor;
@synthesize memberListSelBottomLineColor;
@synthesize memberListSelColor;
@synthesize memberListSelTopColor;
@synthesize memberListSelTopLineColor;
@synthesize nicknameFormat;
@synthesize nicknameFormatFixedWidth;
@synthesize overrideMessageIndentWrap;
@synthesize timestampFormat;
@synthesize treeActiveColor;
@synthesize treeBgColor;
@synthesize treeFont;
@synthesize treeHighlightColor;
@synthesize treeInactiveColor;
@synthesize treeNewTalkColor;
@synthesize treeSelActiveColor;
@synthesize treeSelBottomColor;
@synthesize treeSelBottomLineColor;
@synthesize treeSelInactiveColor;
@synthesize treeSelTopColor;
@synthesize treeSelTopLineColor;
@synthesize treeUnreadColor;
@synthesize underlyingWindowColor;

- (NSString *)path
{
	return path;
}

- (void)setPath:(NSString *)value
{
	if (NSDissimilarObjects(path, value)) {
		[path drain];
		path = [value retain];
	}
	
	[self reload];
}

- (void)dealloc
{
	[inputTextBgColor drain];
	[inputTextColor drain];
	[inputTextFont drain];
	[memberListBgColor drain];
	[memberListColor drain];
	[memberListFont drain];
	[memberListOpColor drain];
	[memberListSelBottomColor drain];
	[memberListSelBottomLineColor drain];
	[memberListSelColor drain];
	[memberListSelTopColor drain];
	[memberListSelTopLineColor drain];
	[nicknameFormat drain];
	[channelViewFont drain];
	[path drain];
	[timestampFormat drain];
	[treeActiveColor drain];
	[treeBgColor drain];
	[treeFont drain];
	[treeHighlightColor drain];
	[treeInactiveColor drain];
	[treeNewTalkColor drain];
	[treeSelActiveColor drain];
	[treeSelBottomColor drain];
	[treeSelBottomLineColor drain];
	[treeSelInactiveColor drain];
	[treeSelTopColor drain];
	[treeSelTopLineColor drain];
	[treeUnreadColor drain];
	[underlyingWindowColor drain];	
	
	[super dealloc];
}

- (NSColor *)processColorStringValue:(NSString *)value def:(NSString *)defaultv
{
	NSString *color = defaultv;
	
	if ([value length] == 7 || [value length] == 4) {
		color = value;
	}
	
	return [NSColor fromCSS:color];
}

- (NSString *)processNSStringValue:(NSString *)value def:(NSString *)defaultv
{
	NSString *data = defaultv;
	
	if (NSObjectIsNotEmpty(value)) {
		data = value;
	}
	
	return data;
}

- (NSInteger)processIntegerValue:(NSInteger)value def:(NSInteger)defaultv
{
	return ((value >= 1) ? value : defaultv);
}

- (NSFont *)processFontValue:(NSString *)style_value 
						size:(NSInteger)style_size 
					defaultv:(NSFont *)defaultf 
				   preferred:(NSFont *)pref 
				 allowCustom:(BOOL)custom
					overrode:(BOOL *)overr
{
	NSFont *theFont = pref;
	
	if (custom) {
		if (NSObjectIsNotEmpty(style_value) && style_size >= 5) {
			if ([NSFont fontIsAvailable:style_value]) {
				theFont = [NSFont fontWithName:style_value size:style_size];
				
				if (PointerIsNotEmpty(overr)) {
					*overr = YES;
				}
			} else {
				theFont = defaultf;
			}
		} else {
			theFont = defaultf;
		}
	}
	
	return theFont;
}

- (void)reload 
{	
	self.channelViewFontOverrode = NO;
	
	NSDictionary *userInterface = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"/userInterface.plist"]];
	
	NSDictionary *inputTextFormat = [userInterface objectForKey:@"Input Box"];
	NSDictionary *memberListFormat = [userInterface objectForKey:@"Member List"];
	NSDictionary *serverListFormat = [userInterface objectForKey:@"Server List"];
	
	self.underlyingWindowColor = [self processColorStringValue:[userInterface objectForKey:@"Underlying Window Color"] def:@"#FFFFFF"];
	
	// ====================================================== //
	
	self.inputTextColor = [self processColorStringValue:[inputTextFormat objectForKey:@"Text Color"] def:@"#ccc"];
	self.inputTextBgColor = [self processColorStringValue:[inputTextFormat objectForKey:@"Background Color"] def:@"#000000"];
	
	self.inputTextFont = [self processFontValue:[inputTextFormat objectForKey:@"Text Font Style"] 
										   size:[inputTextFormat integerForKey:@"Text Font Size"] 
									   defaultv:[NSFont fontWithName:DEFAULT_TEXTUAL_FONT size:13.0]
									  preferred:[NSFont fontWithName:[Preferences themeInputBoxFontName] size:[Preferences themeInputBoxFontSize]]
									allowCustom:[Preferences usesPredeterminedFonts]
									   overrode:NULL];
	
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
									  size:[serverListFormat integerForKey:@"Text Font Size"]
								  defaultv:[NSFont fontWithName:DEFAULT_TEXTUAL_FONT size:11.0]
								 preferred:[NSFont fontWithName:[Preferences themeChannelListFontName] size:[Preferences themeChannelListFontSize]]
							   allowCustom:[Preferences usesPredeterminedFonts]
								  overrode:NULL];
	
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
											size:[memberListFormat integerForKey:@"Text Font Size"] 
										defaultv:[NSFont fontWithName:DEFAULT_TEXTUAL_FONT size:11.0]
									   preferred:[NSFont fontWithName:[Preferences themeMemberListFontName] size:[Preferences themeMemberListFontSize]]
									 allowCustom:[Preferences usesPredeterminedFonts]
										overrode:NULL];
	
	// ====================================================== //
	
	NSDictionary *preferencesOverride = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"/preferencesOverride.plist"]];
	
	NSDictionary *prefOChannelFont = [preferencesOverride objectForKey:@"Override Channel Font"];
	NSDictionary *prefOIndentMessages = [preferencesOverride objectForKey:@"Indent Wrapped Messages"];
	
	// ====================================================== //
	
	self.nicknameFormat = [self processNSStringValue:[preferencesOverride objectForKey:@"Nickname Format"] def:nil];
	self.timestampFormat = [self processNSStringValue:[preferencesOverride objectForKey:@"Timestamp Format"] def:nil];
	
	self.indentWrappedMessages	= [prefOIndentMessages boolForKey:@"New Value"];
	self.overrideMessageIndentWrap = [prefOIndentMessages boolForKey:@"Override Setting"];
	
	self.channelViewFont = [self processFontValue:[prefOChannelFont objectForKey:@"Font Name"] 
											 size:[prefOChannelFont integerForKey:@"Font Size"] 
										 defaultv:[NSFont fontWithName:[Preferences themeChannelViewFontName] size:[Preferences themeChannelViewFontSize]]
										preferred:[NSFont fontWithName:DEFAULT_TEXTUAL_FONT size:12.0]
									  allowCustom:YES
										 overrode:&channelViewFontOverrode];
	
	self.nicknameFormatFixedWidth = [self processIntegerValue:[preferencesOverride integerForKey:@"Nickname Format Fixed Width"] def:0];
	
	// ====================================================== //
	 
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(NSObjectIsEmpty(self.nicknameFormat))				forKey:@"Preferences.Theme.tpoce_nick_format"];
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(NSObjectIsEmpty(self.timestampFormat))				forKey:@"Preferences.Theme.tpoce_timestamp_format"];
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(BOOLReverseValue(self.overrideMessageIndentWrap))	forKey:@"Preferences.Theme.tpoce_indent_onwordwrap"];
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(BOOLReverseValue(self.channelViewFontOverrode))		forKey:@"Preferences.Theme.tpoce_channel_font"];
	
	// ====================================================== //
	
	inputTextFormat = nil;
	memberListFormat = nil;
	prefOChannelFont = nil;
	serverListFormat = nil;
	serverTreeGradient = nil;
	memberListGradient = nil;
	prefOIndentMessages = nil;
	
	userInterface = nil;
	preferencesOverride = nil;
}

@end