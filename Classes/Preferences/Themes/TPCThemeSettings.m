/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@implementation TPCThemeSettings

#pragma mark -
#pragma mark Setting Loaders

/* The following methods read the dictionary of a theme and validates
 their setting values based on the type provided. Most of these calls
 are redundant because NSDictionaryHelper already handles them, but it
 is better to be safe than sorry. */

- (NSColor *)colorForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	NSString *hexValue = [dict objectForKey:key];

	/* Supported format: #FFF or #FFFFFF */
	if ([hexValue length] == 7 || [hexValue length] == 4) {
		return [NSColor fromCSS:hexValue];
	}

	return nil;
}

- (NSInteger)integerForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	return [dict integerForKey:key];
}

- (double)doubleForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	return [dict doubleForKey:key];
}

- (NSString *)stringForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	return [dict stringForKey:key];
}

- (BOOL)boolForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	return [dict boolForKey:key];
}

- (NSFont *)fontForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	NSDictionary *fontDict = [dict dictionaryForKey:key];

	NSAssertReturnR((fontDict.count == 2), nil);
	
	NSString *fontName = [fontDict stringForKey:@"Font Name"];

	NSInteger fontSize = [fontDict integerForKey:@"Font Size"];

	NSObjectIsEmptyAssertReturn(fontName, nil);

	if ([NSFont fontIsAvailable:fontName] && fontSize >= 5.0) {
		NSFont *theFont = [NSFont fontWithName:fontName size:fontSize];

		PointerIsEmptyAssertReturn(theFont, nil);

		return theFont;
	}

	return nil;
}

#pragma mark -
#pragma mark Template Handle

- (NSString *)templateNameWithLineType:(TVCLogLineType)type
{
	NSString *typestr = [TVCLogLine lineTypeString:type];

	return [@"Line Types/" stringByAppendingString:typestr];
}

- (NSString *)applicationTemplateRepositoryPath
{
	NSString *baseURL = [TPCPreferences applicationResourcesFolderPath];
	
	return [baseURL stringByAppendingPathComponent:@"/Style Default Templates/"];
}

- (NSString *)customTemplateRepositoryPath
{
	NSString *filename = [TPCThemeController extractThemeName:[TPCPreferences themeName]];
	NSString *source = [TPCThemeController extractThemeSource:[TPCPreferences themeName]];

	NSString *path;

	if ([source isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix]) {
		path = [[TPCPreferences bundledThemeFolderPath] stringByAppendingPathComponent:filename];
	} else {
		path = [[TPCPreferences customThemeFolderPath] stringByAppendingPathComponent:filename];
	}

	return [path stringByAppendingPathComponent:@"/Data/Templates/"];
}

- (GRMustacheTemplate *)templateWithLineType:(TVCLogLineType)type
{
	return [self templateWithName:[self templateNameWithLineType:type]];
}

- (GRMustacheTemplate *)templateWithName:(NSString *)name
{
	if ([name hasSuffix:@".mustache"] == NO) {
		name = [name stringByAppendingString:@".mustache"];
	}
	
	NSError *load_error = nil;

	NSString *customTemplPath = [[self customTemplateRepositoryPath] stringByAppendingPathComponent:name];
	NSString *applicationPath = [[self applicationTemplateRepositoryPath] stringByAppendingPathComponent:name];

	/* First look for a custom template. */
	GRMustacheTemplate *tmpl = [GRMustacheTemplate templateFromContentsOfFile:customTemplPath error:&load_error];

	if (PointerIsEmpty(tmpl) || load_error) {
		/* If no custom template is found, then revert to application defaults. */
		if (load_error.code == GRMustacheErrorCodeTemplateNotFound || load_error.code == 260) {
			load_error = nil;
			
			tmpl = [GRMustacheTemplate templateFromContentsOfFile:applicationPath error:&load_error];

			if (PointerIsNotEmpty(tmpl)) {
				return tmpl; // Return default template. 
			}
		}

		/* If either template failed to load, then log a error. */
        if (load_error) {
			LogToConsole(TXTLS(@"StyleTemplateLoadFailed"), load_error);
        }
        
		return nil;
	}

	return tmpl; // Return custom template. 
}

#pragma mark -
#pragma mark Load Settings

- (void)reloadWithPath:(NSString *)path
{
	/* Load style settings dictionary. */
	NSDictionary *styleSettings = nil;
	
	NSString *dictPath = [path stringByAppendingPathComponent:@"/Data/Settings/styleSettings.plist"];

	if ([RZFileManager() fileExistsAtPath:dictPath]) {
		styleSettings = [NSDictionary dictionaryWithContentsOfFile:dictPath];

		/* Parse the dictionary values. */
		self.channelViewFont			= [self fontForKey:@"Override Channel Font" fromDictionary:styleSettings];

		self.nicknameFormat				= [self stringForKey:@"Nickname Format" fromDictionary:styleSettings];
		self.timestampFormat			= [self stringForKey:@"Timestamp Format" fromDictionary:styleSettings];

		self.forceInvertSidebarColors	= [self boolForKey:@"Force Invert Sidebars" fromDictionary:styleSettings];

		self.underlyingWindowColor		= [self colorForKey:@"Underlying Window Color" fromDictionary:styleSettings];

		self.indentationOffset			= [self doubleForKey:@"Indentation Offset" fromDictionary:styleSettings];

		/* Disable indentation? */
		if (self.indentationOffset <= 0.0) {
			self.indentationOffset = TXThemeDisabledIndentationOffset;
		}
	}

	/* Load localizations. */
	self.languageLocalizations = nil;

	dictPath = [path stringByAppendingPathComponent:@"/Data/Settings/styleLocalizations.plist"];

	if ([RZFileManager() fileExistsAtPath:dictPath]) {
		self.languageLocalizations = [NSDictionary dictionaryWithContentsOfFile:dictPath];
	}

	/* Inform our defaults controller about a few overrides. */
	/* These setValue calls basically tell the NSUserDefaultsController for the "Preferences" 
	 window that the active theme has overrode a few user configurable options. The window then 
	 blanks out the options specified to prevent the user from modifying. */
	
	[[RZUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.nicknameFormat))		forKey:@"Theme -> Nickname Format Preference Enabled"];
	[[RZUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.timestampFormat))		forKey:@"Theme -> Timestamp Format Preference Enabled"];
    [[RZUserDefaultsController() values] setValue:@(PointerIsEmpty(self.channelViewFont))		forKey:@"Theme -> Channel Font Preference Enabled"];
	[[RZUserDefaultsController() values] setValue:@(self.forceInvertSidebarColors == NO)		forKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
}

@end
