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

#import "TPCPreferencesImportExportPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCPreferencesThemeNameMissingLocallyDefaultsKey		= @"Theme -> Name -> Did Not Exist During Last Sync";
NSString * const TPCPreferencesThemeFontNameMissingLocallyDefaultsKey	= @"Theme -> Font Name -> Did Not Exist During Last Sync";

@implementation TPCPreferencesImportExport

+ (void)import
{
	[TLOPopupPrompts sheetWindowWithWindow:mainWindow()
									  body:TXTLS(@"Prompts[1124][2]")
									 title:TXTLS(@"Prompts[1124][1]")
							 defaultButton:TXTLS(@"Prompts[1124][3]")
						   alternateButton:TXTLS(@"Prompts[0004]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   [self importPreflight:buttonClicked withOriginalAlert:originalAlert];
						   }];
}

+ (void)importPreflight:(TLOPopupPromptReturnType)buttonPressed withOriginalAlert:(NSAlert *)originalAlert
{
	if (buttonPressed == TLOPopupPromptReturnPrimaryType) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setCanChooseFiles:YES];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:NO];
		[d setCanCreateDirectories:NO];
		[d setAllowsMultipleSelection:NO];

		[d beginWithCompletionHandler:^(NSInteger returnCode) {
			if (returnCode == NSModalResponseOK) {
				NSURL *pathURL = [d URLs][0];

				[self importPostflight:pathURL];
			}
		}];
	}
}

+ (void)importPostflight:(NSURL *)pathURL
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		/* The loading screen is a generic way to show something during import. */
		[mainWindowLoadingScreen() hideAll:NO];

		[mainWindowLoadingScreen() popLoadingConfigurationView];
		
		/* isPopulatingSeeds tells the world to not close the loading screen on state
		 changes when creating new connections. */
		[worldController() setIsPopulatingSeeds:YES];
		
		/* Before we do anything at all, we create a backup of the old configuration. */
		/* We refuse to continue unless that wrote successfully. */
		/* These are stored in the home directory of our container. */
		NSString *basePath = [NSString stringWithFormat:@"/Textual-importBackup-%@.plist", [NSString stringWithUUID]];
		
		NSString *backupPath = [NSHomeDirectory() stringByAppendingPathComponent:basePath];
		
		BOOL backupWrite = [self exportPostflightForURL:[NSURL fileURLWithPath:backupPath] filterJunk:NO];
		
		if (backupWrite == NO) {
			LogToConsole(@"Import cancelled. Creation of backup file failed.");
			
			return;
		}
		
		/* Begin import. */
		NSData *rawData = [NSData dataWithContentsOfURL:pathURL];

		NSDictionary *propertyList = [NSPropertyListSerialization
			propertyListWithData:rawData options:NSPropertyListImmutable format:NULL error:NULL];
		
		/* Perform actual import if we have the dictionary. */
		if (propertyList == nil) {
			LogToConsole(@"Import failed. Could not read property list.");

			return;
		}

		/* Import data */
		[self importContentsOfDictionary:propertyList withAutomaticReload:NO];
		
		/* Do not push the loading screen right away. Add a little delay to give everything
		 a chance to settle down before presenting the changes to the user. */
		[self performSelector:@selector(importPostflightCleanup:) withObject:[propertyList allKeys] afterDelay:2.0];
	});
}

+ (void)importContentsOfDictionary:(NSDictionary<NSString *, id> *)aDict
{
	[self importContentsOfDictionary:aDict withAutomaticReload:YES];
}

+ (void)importContentsOfDictionary:(NSDictionary<NSString *, id> *)aDict withAutomaticReload:(BOOL)reloadPreferences
{
	PointerIsEmptyAssert(aDict)

	[aDict enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		[self import:object withKey:key];
	}];

	if (reloadPreferences) {
		[TPCPreferences performReloadActionForKeyValues:[aDict allKeys]];
	}
}

+ (void)import:(id)object withKey:(id)key
{
	PointerIsEmptyAssert(object)
	PointerIsEmptyAssert(key)

	if ([key isEqual:TPCPreferencesThemeNameDefaultsKey])
	{
		NSObjectIsKindOfClassAssert(object, NSString);
		
		[TPCPreferences setThemeNameWithExistenceCheck:object];
	}
	else if ([key isEqual:TPCPreferencesThemeFontNameDefaultsKey])
	{
		NSObjectIsKindOfClassAssert(object, NSString);
		
		[TPCPreferences setThemeChannelViewFontNameWithExistenceCheck:object];
	}
	else if ([key isEqual:IRCWorldControllerDefaultsStorageKey])
	{
		NSObjectIsKindOfClassAssert(object, NSDictionary);

		NSArray<NSDictionary *> *clientList = object[IRCWorldControllerClientListDefaultsStorageKey];
		
		NSObjectIsEmptyAssert(clientList);

		[clientList enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
			[self importWorldControllerClientConfiguration:object isCloudBasedImport:NO];
		}];
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	else if ([key hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix] ||
			 [key hasPrefix:IRCWorldControllerCloudDeletedClientsStorageKey])
	{
		; // Ignore key...
	}
#endif

	else
	{
		[RZUserDefaults() setObject:object forKey:key];
	}
}

+ (void)importWorldControllerClientConfiguration:(NSDictionary<NSString *, id> *)client isCloudBasedImport:(BOOL)isCloudImport
{
	PointerIsEmptyAssert(client)

	IRCClientConfig *config = [[IRCClientConfig alloc] initWithDictionary:client];

	if (config) {
		IRCClient *u = [worldController() findClientById:[config itemUUID]];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		if (isCloudImport) {
			if (u && u.config.excludedFromCloudSyncing) {
				return;
			}
		}
#endif
		
		if (u) {
			if (isCloudImport) {
				[u updateConfigFromTheCloud:config];
			} else {
				[u updateConfig:config];
			}
		} else {
			[worldController() createClient:config reload:YES];
		}
	}
}

+ (void)importPostflightCleanup:(NSArray<NSString *> *)changedKeys
{
	[TPCPreferences performReloadActionForKeyValues:changedKeys];

	[worldController() setIsPopulatingSeeds:NO];

	(void)[mainWindow() reloadLoadingScreen];
}

#pragma mark -
#pragma mark Export

+ (BOOL)isKeyNameSupposedToBeIgnored:(NSString *)key
{
	return [TPCPreferencesUserDefaults keyIsExcludedFromBeingExported:key];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionaryRepresentationForCloud
{
	return [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation:YES removeDefaults:NO];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionaryRepresentation
{
	return [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation:YES removeDefaults:YES];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionaryRepresentation:(BOOL)removeJunk
{
	return [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation:removeJunk removeDefaults:YES];
}

+ (NSDictionary<NSString *, id> *)exportedPreferencesDictionaryRepresentation:(BOOL)removeJunk removeDefaults:(BOOL)removeDefaults
{
	NSDictionary *exportedPreferences = [RZUserDefaults() dictionaryRepresentation];

	NSDictionary *argumentsDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];

	NSDictionary *defaultsDomain = nil;

	NSDictionary *globalsDomain = nil;

	if (removeDefaults) {
		defaultsDomain = [TPCPreferences defaultPreferences];
	}

	if (removeJunk) {
		globalsDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
	}

	NSMutableDictionary<NSString *, id> *fnlsettings = [NSMutableDictionary dictionary];

	[exportedPreferences enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		if (NSObjectsAreEqual(object, argumentsDomain[key])) {
			return;
		}

		if (removeJunk && [self isKeyNameSupposedToBeIgnored:key]) {
			return;
		} else if (removeJunk && NSObjectsAreEqual(object, globalsDomain[key])) {
			return;
		} else if (removeDefaults && NSObjectsAreEqual(object, defaultsDomain[key])) {
			return;
		}

		fnlsettings[key] = object;
	}];

	return fnlsettings;
}

+ (void)export
{
	[TLOPopupPrompts sheetWindowWithWindow:mainWindow()
									  body:TXTLS(@"Prompts[1123][2]")
									 title:TXTLS(@"Prompts[1123][1]")
							 defaultButton:TXTLS(@"Prompts[1123][3]")
						   alternateButton:TXTLS(@"Prompts[0004]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   [self exportPreflight:buttonClicked withOriginalAlert:originalAlert];
						   }];
}

/* +exportPostflightForURL: handles the actual export. */
/* This method is also called internally to backup the old configuration file. */
+ (BOOL)exportPostflightForURL:(NSURL *)pathURL filterJunk:(BOOL)removeJunk
{
	NSDictionary *mutsettings = [self exportedPreferencesDictionaryRepresentation:removeJunk];

	/* The export will be saved as binary. Two reasons: 1) Discourages user from
	 trying to tamper with stuff. 2) Smaller, faster. Mostly #1. */
	NSError *parseError = nil;

	NSData *propertyList = [NSPropertyListSerialization
		dataWithPropertyList:mutsettings format:NSPropertyListBinaryFormat_v1_0 options:0 error:&parseError];

	if (propertyList == nil) {
		if (parseError) {
			LogToConsole(@"Error Creating Property List: %@", [parseError localizedDescription]);
		}

		return NO;
	}

	BOOL writeResult = [propertyList writeToURL:pathURL atomically:YES];

	if (writeResult == NO) {
		LogToConsole(@"Write failed.");

		return NO;
	}

	return YES;
}

+ (void)exportPreflight:(TLOPopupPromptReturnType)buttonPressed withOriginalAlert:(NSAlert *)originalAlert
{
	if (buttonPressed == TLOPopupPromptReturnPrimaryType) {
		NSSavePanel *d = [NSSavePanel savePanel];

		[d setCanCreateDirectories:YES];

		[d setNameFieldStringValue:@"TextualPreferences.plist"];

		[d beginWithCompletionHandler:^(NSInteger returnCode) {
			if (returnCode == NSModalResponseOK) {
				(void)[self exportPostflightForURL:[d URL] filterJunk:YES];
			}
		}];
	}
}

@end

NS_ASSUME_NONNULL_END
