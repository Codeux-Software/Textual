/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

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