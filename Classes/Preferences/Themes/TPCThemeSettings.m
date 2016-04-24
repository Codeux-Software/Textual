/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "BuildConfig.h"

#define _templateEngineVersionMaximum			3
#define _templateEngineVersionMinimum			3

@interface TPCThemeSettings ()
@property (nonatomic, assign, readwrite) BOOL invertSidebarColors;
@property (nonatomic, assign, readwrite) BOOL js_postHandleEventNotifications;
@property (nonatomic, assign, readwrite) BOOL js_postPreferencesDidChangesNotifications;
@property (nonatomic, assign, readwrite) BOOL usesIncompatibleTemplateEngineVersion;
@property (nonatomic, copy, readwrite) NSFont *themeChannelViewFont;
@property (nonatomic, copy, readwrite) NSString *themeNicknameFormat;
@property (nonatomic, copy, readwrite) NSString *themeTimestampFormat;
@property (nonatomic, copy, readwrite) NSString *settingsKeyValueStoreName;
@property (nonatomic, copy, readwrite) NSColor *underlyingWindowColor;
@property (nonatomic, assign, readwrite) double indentationOffset;
@property (nonatomic, assign, readwrite) TPCThemeSettingsNicknameColorStyle nicknameColorStyle;
@property (nonatomic, strong) GRMustacheTemplateRepository *styleTemplateRepository;
@property (nonatomic, strong) GRMustacheTemplateRepository *appTemplateRepository;
@end

@implementation TPCThemeSettings

#pragma mark -
#pragma mark Setting Loaders

/* The following methods read the dictionary of a theme and validates
 their setting values based on the type provided. Most of these calls
 are redundant because NSDictionaryHelper already handles them, but it
 is better to be safe than sorry. */

- (NSString *)stringForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	NSString *hexValue = dict[key];

	if ([hexValue length] == 0) {
		return nil;
	}

	return hexValue;
}

- (NSColor *)colorForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	NSString *hexValue = dict[key];

	/* Supported format: #FFF or #FFFFFF */
	if ([hexValue length] == 7 || [hexValue length] == 4) {
		return [NSColor colorWithHexadecimalValue:hexValue];
	}

	return nil;
}

- (NSFont *)fontForKey:(NSString *)key fromDictionary:(NSDictionary *)dict
{
	NSDictionary *fontDict = [dict dictionaryForKey:key];

	NSString *fontName = [fontDict stringForKey:@"Font Name"];

	if ([NSFont fontIsAvailable:fontName] == NO) {
		return nil;
	}

	NSInteger fontSize = [fontDict integerForKey:@"Font Size"];

	if (fontSize < 5) {
		return nil;
	}

	return [NSFont fontWithName:fontName size:fontSize];
}

#pragma mark -
#pragma mark Template Handle

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
	NSError *load_error = nil;

	GRMustacheTemplate *localTemplate = [self.styleTemplateRepository templateNamed:name error:&load_error];

	if (localTemplate == nil || load_error) {
		if ([load_error code] == GRMustacheErrorCodeTemplateNotFound || [load_error code] == 260) {
			GRMustacheTemplate *defaultTemplate = [self.appTemplateRepository templateNamed:name error:&load_error];

			if (defaultTemplate) {
				return defaultTemplate;
			}
		}

        if (load_error) {
			LogToConsole(@"Failed to load template \"%@\" with error: %@", name, [load_error localizedDescription]);
			LogToConsoleCurrentStackTrace
        }

		return nil;
	}

	return localTemplate;
}

#pragma mark -
#pragma mark Style Settings

- (NSString *)keyValueStoreActualName
{
	NSString *storeName = [self settingsKeyValueStoreName];
	
	if ([storeName length] > 0) {
		return [NSString stringWithFormat:@"Internal Theme Settings Key-value Store -> %@", storeName];
	}
	
	return nil;
}

- (id)styleSettingsRetrieveValueForKey:(NSString *)key error:(NSString * __autoreleasing *)resultError
{
	if ([key length] <= 0) {
		*resultError = @"Empty key value";
	} else {
		NSString *storeKey = [self keyValueStoreActualName];
		
		if (storeKey == nil) {
			*resultError = @"Empty key-value store name in styleSettings.plist — Set the key \"Key-value Store Name\" in styleSettings.plist as a string. The current style name is the recommended value.";
		} else {
			NSDictionary *styleSettings = [RZUserDefaults() dictionaryForKey:storeKey];
			
			return styleSettings[key];
		}
	}

	return nil;
}

- (BOOL)styleSettingsSetValue:(id)objectValue forKey:(NSString *)objectKey error:(NSString * __autoreleasing *)resultError
{
	if ([objectKey length] <= 0) {
		*resultError = @"Empty key value";
	} else {
		NSString *storeKey = [self keyValueStoreActualName];
		
		if (storeKey == nil) {
			*resultError = @"Empty key-value store name in styleSettings.plist — Set the key \"Key-value Store Name\" in styleSettings.plist as a string. The current style name is the recommended value.";
		} else {
			BOOL removeValue = (objectValue == nil || [objectValue isEqual:[WebUndefined undefined]]);
			
			id styleSettings = [RZUserDefaults() dictionaryForKey:storeKey];
			
			if (styleSettings == nil) {
				if (removeValue) {
					return YES;
				}
				
				styleSettings = [NSMutableDictionary dictionaryWithCapacity:1]; // We are only inserting one value
			} else {
				styleSettings = [styleSettings mutableCopy];
			}
			
			if (removeValue) {
				[styleSettings removeObjectForKey:objectKey];
			} else {
				styleSettings[objectKey] = objectValue;
			}
		
			[RZUserDefaults() setObject:[styleSettings copy] forKey:storeKey];
				
			return YES;
		}
	}
	
	return NO;
}

#pragma mark -
#pragma mark Load Settings

- (void)loadApplicationStyleRespository:(NSInteger)version
{
	NSString *filename = [NSString stringWithFormat:@"/Style Default Templates/Version %li/", (long)version];

	NSString *dictPath = [[TPCPathInfo applicationResourcesFolderPath] stringByAppendingPathComponent:filename];

	self.appTemplateRepository = [GRMustacheTemplateRepository templateRepositoryWithBaseURL:[NSURL fileURLWithPath:dictPath]];

	if (self.appTemplateRepository == nil) {
		/* Throw exception if we could not load repository. */

		NSAssert(NO, @"Default template repository not found.");
	}
}

- (void)reloadWithPath:(NSString *)path
{
	/* Load any custom templates. */
	NSString *templatesPath = [path stringByAppendingPathComponent:@"/Data/Templates"];

	NSURL *templatesURL = [NSURL fileURLWithPath:templatesPath];

	self.styleTemplateRepository = [GRMustacheTemplateRepository templateRepositoryWithBaseURL:templatesURL];

	/* Reset old properties. */
	self.themeChannelViewFont = nil;

	self.themeNicknameFormat = nil;
	self.themeTimestampFormat = nil;

	self.settingsKeyValueStoreName = nil;

	self.invertSidebarColors = NO;

	self.underlyingWindowColor = nil;

	self.indentationOffset = TPCThemeSettingsDisabledIndentationOffset;

	self.usesIncompatibleTemplateEngineVersion = YES;

	/* Load style settings dictionary. */
	NSInteger templateEngineVersion = 0;

	NSDictionary *styleSettings = nil;
	
	NSString *dictPath = [path stringByAppendingPathComponent:@"/Data/Settings/styleSettings.plist"];

	if ([RZFileManager() fileExistsAtPath:dictPath]) {
		styleSettings = [NSDictionary dictionaryWithContentsOfFile:dictPath];

		/* Parse the dictionary values. */
		self.themeChannelViewFont = [self fontForKey:@"Override Channel Font" fromDictionary:styleSettings];

		self.themeNicknameFormat = [self stringForKey:@"Nickname Format" fromDictionary:styleSettings];
		self.themeTimestampFormat = [self stringForKey:@"Timestamp Format" fromDictionary:styleSettings];

		self.invertSidebarColors = [styleSettings boolForKey:@"Force Invert Sidebars"];

		self.underlyingWindowColor = [self colorForKey:@"Underlying Window Color" fromDictionary:styleSettings];

		self.settingsKeyValueStoreName = [self stringForKey:@"Key-value Store Name" fromDictionary:styleSettings];

		self.js_postHandleEventNotifications = [styleSettings boolForKey:@"Post Textual.handleEvent() Notifications"];
		self.js_postPreferencesDidChangesNotifications = [styleSettings boolForKey:@"Post Textual.preferencesDidChange() Notifications"];

		/* Disable indentation? */
		id indentationOffset = [styleSettings objectForKey:@"Indentation Offset"];

		if (indentationOffset == nil) {
			self.indentationOffset = TPCThemeSettingsDisabledIndentationOffset;
		} else {
			double indentationOffsetDouble = [indentationOffset doubleValue];

			if (indentationOffsetDouble < 0.0) {
				self.indentationOffset = TPCThemeSettingsDisabledIndentationOffset;
			} else {
				self.indentationOffset = indentationOffsetDouble;
			}
		}

		/* Nickname color style */
		id nicknameColorStyle = [styleSettings objectForKey:@"Nickname Color Style"];

		BOOL computeRGBValue = [TPCPreferences nicknameColorHashingComputesRGBValue];

		if (computeRGBValue && NSObjectsAreEqual(nicknameColorStyle, @"HSL-light")) {
			self.nicknameColorStyle = TPCThemeSettingsNicknameColorHashHueLightStyle;
		} else if (computeRGBValue && NSObjectsAreEqual(nicknameColorStyle, @"HSL-dark")) {
			self.nicknameColorStyle = TPCThemeSettingsNicknameColorHashHueDarkStyle;
		} else {
			self.nicknameColorStyle = TPCThemeSettingsNicknameColorLegacyStyle;
		}

		/* Get style template version */
		NSDictionary *templateVersions = [styleSettings dictionaryForKey:@"Template Engine Versions"];

		if (templateVersions) {
			NSInteger targetVersion = [templateVersions integerForKey:[TPCApplicationInfo applicationVersionShort]];

			if (NSNumberInRange(targetVersion, _templateEngineVersionMinimum, _templateEngineVersionMaximum)) {
				templateEngineVersion = targetVersion;

				self.usesIncompatibleTemplateEngineVersion = NO;
			} else {
				NSInteger defaultVersion = [templateVersions integerForKey:@"default"];

				if (NSNumberInRange(defaultVersion, _templateEngineVersionMinimum, _templateEngineVersionMaximum)) {
					templateEngineVersion = defaultVersion;

					self.usesIncompatibleTemplateEngineVersion = NO;
				}
			}
		}
	}

	/* Fall back to the default repository. */
	[self loadApplicationStyleRespository:templateEngineVersion];

	/* Inform our defaults controller about a few overrides. */
	/* These setValue calls basically tell the NSUserDefaultsController for the "Preferences" 
	 window that the active theme has overrode a few user configurable options. The window then 
	 blanks out the options specified to prevent the user from modifying. */
	[TPCPreferences setInvertSidebarColorsPreferenceUserConfigurable:(self.invertSidebarColors == NO)];
	[TPCPreferences setThemeChannelViewFontPreferenceUserConfigurable:(self.themeChannelViewFont == nil)];
	[TPCPreferences setThemeNicknameFormatPreferenceUserConfigurable:NSObjectIsEmpty(self.themeNicknameFormat)];
	[TPCPreferences setThemeTimestampFormatPreferenceUserConfigurable:NSObjectIsEmpty(self.themeTimestampFormat)];
}

@end
