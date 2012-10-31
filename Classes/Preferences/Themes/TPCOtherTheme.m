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

@interface TPCOtherTheme ()
@property (nonatomic, strong) NSDictionary *styleSettings;
@property (nonatomic, strong) GRMustacheTemplateRepository *styleTemplateRepository;
@property (nonatomic, strong) GRMustacheTemplateRepository *appTemplateRepository;
@end

@implementation TPCOtherTheme

- (void)setPath:(NSString *)value
{
	if (NSDissimilarObjects(self.path, value)) {
		_path = value;
	}
	
	[self reload];
}

#pragma mark -

- (NSColor *)colorForKey:(NSString *)key
{
	NSString *hexValue = [self.styleSettings objectForKey:key];

	if ([hexValue length] == 7 || [hexValue length] == 4) {
		return [NSColor fromCSS:hexValue];
	}

	return nil;
}

- (NSInteger)integerForKey:(NSString *)key
{
	return [self.styleSettings integerForKey:key];
}

- (TXNSDouble)doubleForKey:(NSString *)key
{
	return [self.styleSettings doubleForKey:key];
}

- (NSString *)stringForKey:(NSString *)key
{
	return [self.styleSettings stringForKey:key];
}

- (BOOL)boolForKey:(NSString *)key
{
	return [self.styleSettings boolForKey:key];
}

- (NSFont *)fontForKey:(NSString *)key
{
	NSDictionary *fontDict = [self.styleSettings dictionaryForKey:key];

	if (NSObjectIsNotEmpty(fontDict) && fontDict.count == 2) {
		NSString *fontName = [fontDict stringForKey:@"Font Name"];

		NSInteger fontSize = [fontDict integerForKey:@"Font Size"];

		if (NSObjectIsNotEmpty(fontName) && fontSize >= 5.0) {
			if ([NSFont fontIsAvailable:fontName]) {
				NSFont *theFont = [NSFont fontWithName:fontName size:fontSize];

				if (PointerIsNotEmpty(theFont)) {
					return theFont;
				}
			}
		}
	}

	return nil;
}

- (NSString *)templateNameWithLineType:(TVCLogLineType)type
{
	NSString *typestr = [TVCLogLine lineTypeString:type];

	return [@"Line Types/" stringByAppendingString:typestr];
}

- (GRMustacheTemplate *)templateWithLineType:(TVCLogLineType)type
{
	return [self templateWithName:[self templateNameWithLineType:type]];
}

- (GRMustacheTemplate *)templateWithName:(NSString *)name
{
	NSError *load_error;

	GRMustacheTemplate *tmpl = [self.styleTemplateRepository templateNamed:name error:&load_error];

	if (PointerIsEmpty(tmpl) || load_error) {
		if (load_error.code == GRMustacheErrorCodeTemplateNotFound || load_error.code == 260) {
			GRMustacheTemplate *tmpl = [self.appTemplateRepository templateNamed:name error:&load_error];

			if (PointerIsNotEmpty(tmpl)) {
				return tmpl;
			}
		}
		
		LogToConsole(TXTLS(@"StyleTemplateLoadFailed"),
			  name, [load_error localizedDescription]);

		return nil;
	}

	return tmpl;
}

#pragma mark -

- (void)reload 
{
	NSString *dictPath;

	// ---- //
	
	dictPath = [self.path stringByAppendingPathComponent:@"/Data/Templates"];

	self.styleTemplateRepository = [GRMustacheTemplateRepository templateRepositoryWithBaseURL:[NSURL fileURLWithPath:dictPath]];

	if (PointerIsEmpty(self.styleTemplateRepository)) {
		exit(10);
	}

	// ---- //

	if (PointerIsEmpty(self.appTemplateRepository)) {
		dictPath = [[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Style Default Templates"];

		self.appTemplateRepository = [GRMustacheTemplateRepository templateRepositoryWithBaseURL:[NSURL fileURLWithPath:dictPath]];

		if (PointerIsEmpty(self.appTemplateRepository)) {
			exit(10);
		}
	}

	// ---- //
	
	self.styleSettings = nil;
	
	dictPath = [self.path stringByAppendingPathComponent:@"/Data/Settings/styleSettings.plist"];

	if ([_NSFileManager() fileExistsAtPath:dictPath]) {
		self.styleSettings = [NSDictionary dictionaryWithContentsOfFile:dictPath];
	}

	// ---- //

	self.channelViewFont			= [self fontForKey:@"Override Channel Font"];

	self.nicknameFormat				= [self stringForKey:@"Nickname Format"];
	self.timestampFormat			= [self stringForKey:@"Timestamp Format"];

	self.forceInvertSidebarColors	= [self boolForKey:@"Force Invert Sidebars"];

	self.underlyingWindowColor		= [self colorForKey:@"Underlying Window Color"];

	self.indentationOffset			= [self doubleForKey:@"Indentation Offset"];

	if (self.indentationOffset <= 0.0) {
		self.indentationOffset = TXThemeDisabledIndentationOffset;
	}

	// ---- //

	[[_NSUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.nicknameFormat))				forKey:@"Theme -> Nickname Format Preference Enabled"];
	[[_NSUserDefaultsController() values] setValue:@(NSObjectIsEmpty(self.timestampFormat))				forKey:@"Theme -> Timestamp Format Preference Enabled"];
    [[_NSUserDefaultsController() values] setValue:@(PointerIsEmpty(self.channelViewFont))				forKey:@"Theme -> Channel Font Preference Enabled"];
	[[_NSUserDefaultsController() values] setValue:@(BOOLReverseValue(self.forceInvertSidebarColors))	forKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
}

@end