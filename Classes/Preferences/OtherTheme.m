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
@synthesize nicknameFormat;
@synthesize timestampFormat;
@synthesize underlyingWindowColor;
@synthesize indentationOffset;
@synthesize renderingEngineVersion;

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
	[path drain];
	[nicknameFormat drain];
	[channelViewFont drain];
	[timestampFormat drain];
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
    self.indentationOffset       = THEME_DISABLED_INDENTATION_OFFSET;
	
	// ====================================================== //
	
	NSDictionary *userInterface = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"/userInterface.plist"]];
	
	self.renderingEngineVersion = [userInterface doubleForKey:@"Rendering Engine Version"];
	self.underlyingWindowColor	= [self processColorStringValue:[userInterface objectForKey:@"Underlying Window Color"]
														   def:@"#000000"];
	
	
	// ====================================================== //
	
	NSDictionary *preferencesOverride = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"/preferencesOverride.plist"]];
	NSDictionary *prefOChannelFont    = [preferencesOverride objectForKey:@"Override Channel Font"];
	
	// ====================================================== //
	
    if ([preferencesOverride containsKey:@"Indentation Offset"]) {
        self.indentationOffset = [preferencesOverride doubleForKey:@"Indentation Offset"];
    }
    
	self.nicknameFormat  = [self processNSStringValue:[preferencesOverride objectForKey:@"Nickname Format"] def:nil];
	self.timestampFormat = [self processNSStringValue:[preferencesOverride objectForKey:@"Timestamp Format"] def:nil];
	
	self.channelViewFont = [self processFontValue:[prefOChannelFont objectForKey:@"Font Name"] 
											 size:[prefOChannelFont integerForKey:@"Font Size"] 
										 defaultv:[NSFont fontWithName:[Preferences themeChannelViewFontName] size:[Preferences themeChannelViewFontSize]]
										preferred:[NSFont fontWithName:DEFAULT_TEXTUAL_FONT size:12.0]
									  allowCustom:YES
										 overrode:&channelViewFontOverrode];
	
	// ====================================================== //
	
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(NSObjectIsEmpty(self.nicknameFormat))				forKey:@"Preferences.Theme.tpoce_nick_format"];
	[[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(NSObjectIsEmpty(self.timestampFormat))				forKey:@"Preferences.Theme.tpoce_timestamp_format"];
    [[_NSUserDefaultsController() values] setValue:NSNumberWithBOOL(BOOLReverseValue(self.channelViewFontOverrode))		forKey:@"Preferences.Theme.tpoce_channel_font"];
	
	// ====================================================== //
	
	userInterface = nil;
	prefOChannelFont = nil;  
	preferencesOverride = nil;
}

@end