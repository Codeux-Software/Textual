// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TPCOtherTheme

- (void)setPath:(NSString *)value
{
	if (NSDissimilarObjects(self.path, value)) {
		_path = value;
	}
	
	[self reload];
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
    self.indentationOffset       = TXThemeDisabledIndentationOffset;
	
	// ====================================================== //
	
	NSDictionary *userInterface = [NSDictionary dictionaryWithContentsOfFile:[self.path stringByAppendingPathComponent:@"/userInterface.plist"]];
	
	self.renderingEngineVersion = [userInterface doubleForKey:@"Rendering Engine Version"];
	self.underlyingWindowColor	= [self processColorStringValue:userInterface[@"Underlying Window Color"]
														   def:@"#000000"];
	
	
	// ====================================================== //
	
	NSDictionary *preferencesOverride = [NSDictionary dictionaryWithContentsOfFile:[self.path stringByAppendingPathComponent:@"/preferencesOverride.plist"]];
	NSDictionary *prefOChannelFont    = preferencesOverride[@"Override Channel Font"];
	
	// ====================================================== //
	
    if ([preferencesOverride containsKey:@"Indentation Offset"]) {
        self.indentationOffset = [preferencesOverride doubleForKey:@"Indentation Offset"];
    }

	self.forceInvertSidebarColors = [preferencesOverride boolForKey:@"Force Invert Sidebars"];

	self.nicknameFormat  = [self processNSStringValue:preferencesOverride[@"Nickname Format"] def:nil];
	self.timestampFormat = [self processNSStringValue:preferencesOverride[@"Timestamp Format"] def:nil];
	
	self.channelViewFont = [self processFontValue:prefOChannelFont[@"Font Name"] 
											 size:[prefOChannelFont integerForKey:@"Font Size"] 
										 defaultv:[NSFont fontWithName:[TPCPreferences themeChannelViewFontName] size:[TPCPreferences themeChannelViewFontSize]]
										preferred:[NSFont fontWithName:TXDefaultTextualLogFont size:12.0]
									  allowCustom:YES
										 overrode:&_channelViewFontOverrode];
	
	// ====================================================== //
	
	[[_NSUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.nicknameFormat))				forKey:@"Theme -> Nickname Format Preference Enabled"];
	[[_NSUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.timestampFormat))				forKey:@"Theme -> Timestamp Format Preference Enabled"];
    [[_NSUserDefaultsController() values] setValue:@(BOOLReverseValue(self.channelViewFontOverrode))	forKey:@"Theme -> Channel Font Preference Enabled"];
	[[_NSUserDefaultsController() values] setValue:@(BOOLReverseValue(self.forceInvertSidebarColors))	forKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
	
	// ====================================================== //
	
	userInterface = nil;
	prefOChannelFont = nil;  
	preferencesOverride = nil;
}

@end